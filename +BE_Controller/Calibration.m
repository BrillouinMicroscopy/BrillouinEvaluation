function calibration = Calibration(model, view)
%% CALIBRATION Controller

    %% callbacks Calibration
    set(view.calibration.calibrateButton, 'Callback', {@calibrate, model, view});
    
    set(view.calibration.samples, 'Callback', {@selectSample, model});
    
    set(view.calibration.BrillouinShift, 'Callback', {@setBrillouinShift, model});
    
    set(view.calibration.selectBrillouin, 'Callback', {@selectPeaks, view, model, 'Brillouin'});
    set(view.calibration.selectRayleigh, 'Callback', {@selectPeaks, view, model, 'Rayleigh'});
    
    set(view.calibration.peakTableBrillouin, 'CellEditCallback', {@editPeaks, model, 'Brillouin'});
    set(view.calibration.peakTableRayleigh, 'CellEditCallback', {@editPeaks, model, 'Rayleigh'});
    
    set(view.calibration.startTable, 'CellEditCallback', {@editStartParameters, model});
    
    set(view.calibration.clearBrillouin, 'Callback', {@clearPeaks, model, 'Brillouin'});
    set(view.calibration.clearRayleigh, 'Callback', {@clearPeaks, model, 'Rayleigh'});
    
    set(view.calibration.clearCalibration, 'Callback', {@clearCalibration, model});
    
    set(view.calibration.zoomIn, 'Callback', {@zoom, 'in', view});
    set(view.calibration.zoomOut, 'Callback', {@zoom, 'out', view});
    set(view.calibration.panButton, 'Callback', {@pan, view});
    set(view.calibration.cursorButton, 'Callback', {@cursor, view});
    
    set(view.calibration.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.calibration.cap, 'Callback', {@setClim, model});
    set(view.calibration.floor, 'Callback', {@setClim, model});
    
    set(view.calibration.increaseFloor, 'Callback', {@changeClim, model, 1});
    set(view.calibration.decreaseFloor, 'Callback', {@changeClim, model, -1});
    set(view.calibration.increaseCap, 'Callback', {@changeClim, model, 1});
    set(view.calibration.decreaseCap, 'Callback', {@changeClim, model, -1});
    
    set(view.calibration.openBrillouinShift, 'Callback', {@openBrillouinShift, model});
    
    calibration = struct( ...
    );
end

function calibrate(~, ~, model, view)
    %% store often used values in separate variables for convenience
    calibration = model.parameters.calibration;         % general calibration
    selectedMeasurement = calibration.selected;
    sample = calibration.samples.(selectedMeasurement); % selected sample
    
    %% 
    startTime = model.file.date;
    refTime = datetime(startTime, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    datestring = datetime(sample.time, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    calibration.times(sample.position) = etime(datevec(datestring),datevec(refTime));
    
    %% find the positions of the Rayleigh and Brillouin peaks
    if strcmp(selectedMeasurement, 'measurement')
        imgs = model.file.readPayloadData(sample.imageNr.x, sample.imageNr.y, sample.imageNr.z, 'data');
    else
        imgs = model.file.readCalibrationData(sample.position, 'data');
    end
    
    imgs = medfilt1(imgs,3);
    for mm = 1:size(imgs,3)
        data = BE_SharedFunctions.getIntensity1D(imgs(:,:,mm), model.parameters.extraction.interpolationPositions);
        
        nrPositions = size(data,2)/0.1;
        calibration.pixels = linspace(1,size(data,2),nrPositions);

        indRayleigh = sample.indRayleigh;
        indBrillouin = sample.indBrillouin;
        if size(indRayleigh,1) == 2 && size(indBrillouin,1) == 2
            %% find the measured peaks
            peakPos = NaN(1,4);
            for jj = 1:length(indRayleigh)
                spectrumSection = data(indRayleigh(jj,1):indRayleigh(jj,2));
                [tmp, ~, ~] = BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, 1, [6 20], 0);
                peakPos(jj) = tmp+indRayleigh(jj,1)-1;
            end
            for jj = 1:length(indBrillouin)
                spectrumSection = data(indBrillouin(jj,1):indBrillouin(jj,2));
                [tmp, ~, ~] = BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, 1, [6 20], 0);
                peakPos(jj+2) = tmp+indBrillouin(jj,1)-1;
            end
            sample.peaksMeasured(mm,:) = peakPos;

            %% find the fitted peaks, do the VIPA fit
            constants = model.parameters.constants;
            constants.bShiftCal = sample.shift*1e9;
            
            [VIPAparams, peakPos] = fitVIPA(peakPos, calibration.start, constants, view);
            VIPAparams.x0Initial = VIPAparams.x0;
            
            params = {'d', 'n', 'theta', 'x0Initial', 'x0', 'xs', 'error'};
            for jj = 1:length(params)
                sample.values.(params{jj})(mm) = VIPAparams.(params{jj});
            end
            sample.peaksFitted(mm,:) = peakPos;
            
            wavelengths = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * calibration.pixels, ...
                VIPAparams, model.parameters.constants, 1);
            
            sample.wavelengths(mm,:) = wavelengths;
        else
            ex = MException('MATLAB:toLessValues', ...
                    'Please select two Rayleigh and two Brillouin peaks.');
            throw(ex);
        end
    end

    %% check if field for weighted calibration is available, set default value if not
    if ~isfield(calibration, 'weighted')
        calibration.weighted = true;
    end
    
    %% check if field for extrapolating the calibration is available, set default value if not
    if ~isfield(calibration, 'extrapolate')
        calibration.extrapolate = false;
    end

    %% check if field for selecting calibration images is available, set default value if not
    if ~isfield(sample, 'active')
        sample.active = ones(size(imgs,3),1);
        sample.nrImages = size(imgs,3);
    end
    
    if calibration.weighted
        %% average the single calibrations according to their uncertainty
        wavelengths = sample.wavelengths(logical(sample.active), :);        % wavelengths from calibration, only select active calibration images
        weights = repmat(sample.values.error(:,logical(sample.active)).', 1, size(wavelengths,2));    % map of the weights, only select active calibration images
        weights(isnan(wavelengths)) = NaN;                                  % set weights to NaN in case wavelength is NaN
        norm = nansum(1./weights,1);                                        % calculate the normalization value

        weighted = nansum((wavelengths ./ weights), 1) ./ norm;             % calculate the weighted average

        calibration.wavelength(sample.position,:) = weighted;               % store the result
    else
        calibration.wavelength(sample.position,:) = nanmean(sample.wavelengths,1);
    end
    
    %% calculate the Brillouin shift corresponding to each calibration measurement
    times = calibration.times(sample.position) * ones(size(sample.peaksMeasured));
    wavelengths = BE_SharedFunctions.getWavelengthFromMap(sample.peaksMeasured, times, calibration);
    sample.BrillouinShift = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(wavelengths(:,[3, 4]), wavelengths(:,[1, 2])));
    
    %% save the results
    calibration.samples.(selectedMeasurement) = sample;
    model.parameters.calibration = calibration;
    
    wavelengthRayleigh = BE_SharedFunctions.getWavelengthFromMap(model.results.peaksRayleigh_pos, model.results.times, calibration);
    wavelengthBrillouin = BE_SharedFunctions.getWavelengthFromMap(model.results.peaksBrillouin_pos, model.results.times, calibration);

    model.results.BrillouinShift_frequency = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(wavelengthBrillouin, wavelengthRayleigh));
end

function selectSample(src, ~, model)
    val = get(src,'Value');
    types = get(src,'String');
    model.parameters.calibration.selectedValue = val;
    model.parameters.calibration.selected = types{val};
end

function setBrillouinShift(src, ~, model)
    model.parameters.calibration.samples.(model.parameters.calibration.selected).shift = str2double(get(src, 'String'));
end

function selectPeaks(~, ~, view, model, type)
    model.status.calibration.(['select' type]) = ~model.status.calibration.(['select' type]);
    if model.status.calibration.(['select' type])
        switch type
            case 'Brillouin'
                model.status.calibration.selectRayleigh = 0;
                color = [0 0 1];
            case 'Rayleigh'
                model.status.calibration.selectBrillouin = 0;
                color = [1 0 0];
        end
        set(view.calibration.brushHandle, 'Enable', 'on', 'color', color);
    else
        brushed = logical(get(model.handles.calibration.plotSpectrum, 'BrushData'));
        set(view.calibration.brushHandle, 'Enable', 'off');
        
        xd = 1:length(brushed);
        ind = xd(brushed);
        model.parameters.calibration.samples.(model.parameters.calibration.selected).(['ind' type]) = ...
            vertcat(model.parameters.calibration.samples.(model.parameters.calibration.selected).(['ind' type]), findBorders(ind));
    end
end

function borders = findBorders(ind)
    try
        borderPosition = diff(ind);

        t = find((borderPosition>1));

        borders = NaN((length(t)+1),2);
        for jj = 1:(length(t)+1)
            if jj == 1
                start = ind(1);
            else
                start = ind(t(jj-1)+1);
            end
            if jj == (length(t)+1)
                stop = ind(end);
            else
                stop = ind(t(jj));
            end
            borders(jj,:) = [start stop];
        end
    catch
        borders = [];
    end
end

function clearPeaks(~, ~, model, type)
    model.parameters.calibration.samples.(model.parameters.calibration.selected).(['ind' type]) = [];
end

function editPeaks(~, table, model, type)
    model.parameters.calibration.samples.(model.parameters.calibration.selected).(['ind' type])(table.Indices(1), table.Indices(2)) = table.NewData;
end

function editStartParameters(~, table, model)
    fields = {'d', 'n', 'theta', 'x0', 'xs', 'order', 'iterNum'};
    model.parameters.calibration.start.(fields{table.Indices(2)}) = table.NewData;
end

function clearCalibration(~, ~, model)
    calibration = model.parameters.calibration;
    selectedMeasurement = calibration.selected;
    calibration.samples.(selectedMeasurement).values = struct( ...
        'd',            [], ... % [m]   width of the cavity
        'n',            [], ... % [1]   refractive index of the VIPA
        'theta',        [], ... % [rad] angle of the VIPA
        'x0Initial',    [], ... % [m]   offset for fitting
        'x0',           [], ... % [m]   offset for fitting, corrected for each measurement
        'xs',           [], ... % [1]   scale factor for fitting
        'error',        []  ... % [1]   uncertainty of the fit
    );
    pos = calibration.samples.(selectedMeasurement).position;
    calibration.times(pos) = NaN;
    calibration.wavelength(pos,:) = NaN;
    model.parameters.calibration = calibration;
end

function zoom(src, ~, str, view)
    switch get(src, 'UserData')
        case 0
            set(view.calibration.panButton,'UserData',0);
            set(view.calibration.panHandle,'Enable','off');
            set(view.calibration.cursorButton,'UserData',0);
            set(view.calibration.cursorHandle,'Enable','off');
            switch str
                case 'in'
                    set(view.calibration.zoomHandle,'Enable','on','Direction','in');
                    set(view.calibration.zoomIn,'UserData',1);
                    set(view.calibration.zoomOut,'UserData',0);
                case 'out'
                    set(view.calibration.zoomHandle,'Enable','on','Direction','out');
                    set(view.calibration.zoomOut,'UserData',1);
                    set(view.calibration.zoomIn,'UserData',0);
            end
        case 1
            set(view.calibration.zoomHandle,'Enable','off','Direction','in');
            set(view.calibration.zoomOut,'UserData',0);
            set(view.calibration.zoomIn,'UserData',0);
    end
end

function pan(src, ~, view)
    set(view.calibration.zoomHandle,'Enable','off','Direction','in');
    set(view.calibration.cursorHandle,'Enable','off');
    set(view.calibration.zoomOut,'UserData',0);
    set(view.calibration.zoomIn,'UserData',0);
    set(view.calibration.cursorButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.calibration.panButton,'UserData',1);
            set(view.calibration.panHandle,'Enable','on');
        case 1
            set(view.calibration.panButton,'UserData',0);
            set(view.calibration.panHandle,'Enable','off');
    end
end

function cursor(src, ~, view)
    set(view.calibration.zoomHandle,'Enable','off','Direction','in');
    set(view.calibration.panHandle,'Enable','off');
    set(view.calibration.zoomOut,'UserData',0);
    set(view.calibration.zoomIn,'UserData',0);
    set(view.calibration.panButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.calibration.cursorButton,'UserData',1);
            set(view.calibration.cursorHandle,'Enable','on');
        case 1
            set(view.calibration.cursorButton,'UserData',0);
            set(view.calibration.cursorHandle,'Enable','off');
    end
end

function setClim(UIControl, ~, model)
    calibration = model.displaySettings.calibration;
    field = get(UIControl, 'Tag');
    calibration.(field) = str2double(get(UIControl, 'String'));
    calibration.autoscale = 0;
    model.displaySettings.calibration = calibration;
end

function toggleAutoscale(~, ~, model, view)
    model.displaySettings.calibration.autoscale = get(view.calibration.autoscale, 'Value');
end

function changeClim(UIControl, ~, model, sign)
    calibration = model.displaySettings.calibration;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(calibration.cap - calibration.floor));
    calibration.autoscale = 0;
    calibration.(field) = calibration.(field) + sign * dif;
    model.displaySettings.calibration = calibration;
end

function [VIPAparams, peakPosFitted] = fitVIPA(peakPos, VIPAstart, constants, view)
    %% FITVIPA
    %   this function fits the VIPA parameters to the measured peaks. To
    %   calculate the Parameters, 2 Rayleigh peaks and 2 Brillouin peaks within
    %   one FSR are required
    % 
    %   ##INPUT
    %   peakPos:        [m]     peak locations on the camera
    %   VIPAstart =
    %              d:   [m]     width of the cavity
    %              n:   [1]     refractive index
    %          theta:   [rad]   angle of the VIPA
    %             x0:   [m]     offset for fitting
    %             xs:   [1]     scale factor for fitting
    %          order:   [1]     observed order of the VIPA spectrum
    %        iterNum:   [1]     number of iterations for the fit
    %   constants =
    %             c:    [m/s]   speed of light
    %              F:   [m]     focal length of the lens behind the VIPA
    %     pixelSize:    [m]     pixel size of the camera
    %       lambda0:    [m]     laser wavelength
    %     bshiftCal:    [Hz]    calibration shift frequency
    % 
    %   ##OUTPUT
    %   VIPAparams =
    %             d:    [m]     width of the cavity
    %             n:    [1]     refractive index
    %         theta:    [rad]   angle of the VIPA
    %            x0:    [m]     offset for fitting
    %            xs:    [1]     scale factor for fitting
    
    %% numer of iterations for every parameter
    nrIter.d     = 111;
    nrIter.n     = 1;
    nrIter.theta = 1;
    nrIter.x0    = 22;
    nrIter.xs    = 22;
    
    variation.d     = 2.5e-5;
    variation.n     = 0;%2.0e-5;
    variation.theta = 0;%0.001;
    variation.x0    = 0.3;
    variation.xs    = 0.1;

    %%
    startOrders = VIPAstart.order:(VIPAstart.order + 1);

    % peaks = peaks - peaks(1);
    peakPos = sort(peakPos, 'ascend');
    peakPos = constants.pixelSize * peakPos;
    lambdaS  = 1/(1/constants.lambda0 - constants.bShiftCal/constants.c);
    lambdaAS = 1/(1/constants.lambda0 + constants.bShiftCal/constants.c);

    %% calculation
    
    VIPAparams = struct;
    total = VIPAstart.iterNum * nrIter.d;
    for gg = 1:1:VIPAstart.iterNum

        if exist('ItRun', 'var')
            ItRun = ItRun + 1;
        else
            ItRun = 0;
        end

        %
        dVariation = variation.d/(2^ItRun);
        if exist('dInd', 'var')
            dcenter = dRange(dInd);
        else
            dcenter = VIPAstart.d;
        end
        dRange = linspace((1-dVariation)*dcenter, (1+dVariation)*dcenter, nrIter.d);

        %
        nVariation = variation.n/(2^ItRun);
        if exist('nInd', 'var')
            ncenter = nRange(nInd);
        else
            ncenter = VIPAstart.n;
        end
        nRange = linspace((1-nVariation)*ncenter, (1+nVariation)*ncenter, nrIter.n);

        %
        thetaVariation = variation.theta/(2^ItRun);
        if exist('thetaInd', 'var')
            thetacenter = thetaRange(thetaInd);
        else
            thetacenter = VIPAstart.theta;
        end
        thetaRange = linspace((1-thetaVariation)*thetacenter, (1+thetaVariation)*thetacenter, nrIter.theta);

        %
        x0Variation = variation.x0/(2^ItRun);
        if exist('x0Ind', 'var')
            x0center = x0Range(x0Ind);
        else
            x0center = VIPAstart.x0;
        end
        x0Range = linspace((1-x0Variation)*x0center, (1+x0Variation)*x0center, nrIter.x0);

        %
        xsVariation = variation.xs/(2^ItRun);
        if exist('xsInd', 'var')
            xscenter = xsRange(xsInd);
        else
            xscenter = VIPAstart.xs;
        end
        xsRange = linspace((1-xsVariation)*xscenter, (1+xsVariation)*xscenter, nrIter.xs);

        ErrorVector = NaN(length(dRange), length(nRange), length(thetaRange), length(x0Range), length(xsRange));
        
        for ii = 1:length(dRange)
            done = 100*((gg-1)*nrIter.d + ii)/total;
            view.calibration.progressBar.setValue(done);
            view.calibration.progressBar.setString(sprintf('%01.0f%%', done));
            for jj = 1:length(nRange)
                for kk = 1:length(thetaRange)
                    for ll = 1:length(x0Range)
                        for mm = 1:length(xsRange)
                            VIPAparams.d     = dRange(ii);
                            VIPAparams.n     = nRange(jj);
                            VIPAparams.theta = thetaRange(kk);
                            VIPAparams.x0    = x0Range(ll);
                            VIPAparams.xs    = xsRange(mm);

                            orders = [startOrders(1), 1, 2, startOrders(2)];
                            lambdas = [constants.lambda0, lambdaAS, lambdaS, constants.lambda0];
                            % position of the two Rayleigh peaks and the Stokes and Anti-Stokes peaks
                            [x_F, ~] = BE_SharedFunctions.peakPosition(VIPAparams, constants, orders, lambdas);

                            % difference between measurement and fit
                            ErrorVector(ii,jj,kk,ll,mm) = sum((peakPos - x_F).^2);
                        end
                    end
                end
            end
        end
        [~, ind] = min(ErrorVector(:));

        [dInd, nInd, thetaInd, x0Ind, xsInd] = ind2sub(size(ErrorVector),ind);

    end

    %% return fitted parameters
    VIPAparams = {};
    VIPAparams.d     = dRange(dInd);
    VIPAparams.n     = nRange(nInd);
    VIPAparams.theta = thetaRange(thetaInd);
    VIPAparams.x0    = x0Range(x0Ind);
    VIPAparams.xs    = xsRange(xsInd);
    VIPAparams.error = ErrorVector(ind);

    peakPosFitted = NaN(1,4);
    % position of the two Rayleigh peaks
    [peakPosFitted(1,[1 4]), ~] = BE_SharedFunctions.peakPosition( VIPAparams, constants, startOrders, constants.lambda0);
    % position of the Stokes and Anti-Stokes peaks
    [peakPosFitted(2), ~] = BE_SharedFunctions.peakPosition(VIPAparams, constants, 1, lambdaAS);
    [peakPosFitted(3), ~] = BE_SharedFunctions.peakPosition(VIPAparams, constants, 2, lambdaS);
    peakPosFitted = peakPosFitted / constants.pixelSize;

    %% Plot Results
    % 
    % figure;
    % hold on
    % box on
    % ylim([0.7, 1.5])
    % set(gca,'YTick',[])
    % xlabel('distance [mm]')
    % meas = plot(peakPos*1e3, ones(length(peakPos)), 'or');
    % fit = plot(x_F*1e3, ones(length(x_F)), 'xb');
    % legend([meas(1), fit(1)], 'Measurement', 'Fit');

end

function openBrillouinShift(~, ~, model)
    calibration = model.parameters.calibration;
    
    BrillouinShifts = NaN(10,2);
    BrillouinShifts_mean = BrillouinShifts;
    calibrationFrequency = NaN(10,1);
    
    sampleNames = fields(calibration.samples);
    for jj = 1:length(sampleNames)
        sample = calibration.samples.(sampleNames{jj});
        if isfield(sample, 'BrillouinShift')
            shift = sample.BrillouinShift;
            BrillouinShifts(((jj-1)*10 + 1 + (1:10)), :) = shift;
            BrillouinShifts_mean(((jj-1)*10 + 1 + (1:10)), :) = repmat(nanmean(shift,1), 10, 1);
            calibrationFrequency(((jj-1)*10 + 1 + (1:10)), 1) = ones(10,1) * sample.shift;
        else
            BrillouinShifts(((jj-1)*10 + 1 + (1:10)), :) = NaN(10,2);
            BrillouinShifts_mean(((jj-1)*10 + 1 + (1:10)), :) = NaN(10,2);
        end
    end

    figure;
    plot(BrillouinShifts);
    hold on;
    ax = gca;
    ax.ColorOrderIndex = 1;
    plot(BrillouinShifts_mean, 'LineStyle', '--', 'LineWidth', 0.8);
    plot(calibrationFrequency);
    xlabel('Calibration image #');
    ylabel('$f$ [GHz]', 'interpreter', 'latex');
    legend('Stokes Peak', 'AntiStokes Peak', 'Stokes Peak Mean', 'AntiStokes Peak Mean', 'Calibration Frequency');
end