function callbacks = Calibration(model, view)
%% CALIBRATION Controller

    %% callbacks Calibration
    set(view.calibration.calibrateButton, 'Callback', {@calibrate, model, view});
    
    set(view.calibration.samples, 'Callback', {@selectSample, model});
    
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
    
    set(view.calibration.openBrillouinShift, 'Callback', {@openBrillouinShift, model, view});
    
    set(view.calibration.valuesTable, 'CellEditCallback', {@toggleActiveState, model});
    
    set(view.calibration.extrapolate, 'Callback', {@toggleExtrapolation, model});
    set(view.calibration.weighted, 'Callback', {@toggleWeighting, model});
    set(view.calibration.correctOffset, 'Callback', {@toggleOffsetCorrection, model});
    
    callbacks = struct( ...
        'testCavitySlope', @()testCavitySlope(model, view), ...
        'setActive', @()setActive(view), ...
        'findPeaks', @()findPeaks(model), ...
        'setDefaultParameters', @()setDefaultParameters(model), ...
        'calibrateAll', @()calibrateAll(model, view) ...
    );
end

function testCavitySlope(model, view)
    d = linspace(0.006791, 0.006797, 20);
    calibration = model.parameters.calibration;         % general calibration
    selectedMeasurement = calibration.selected;
    sample = calibration.samples.(selectedMeasurement); % selected sample
    fac = NaN(1,4);
    
    for jj = 1:length(d)
        sample.start.d = d(jj);
        calibration.samples.(selectedMeasurement) = sample; % selected sample
        model.parameters.calibration = calibration;         % general calibration
        calibrate(0, 0, model, view);
        fac(jj) = model.parameters.calibration.samples.(selectedMeasurement).fac;
        disp(jj);
    end
    
    figure;
    plot(d, fac);
end

function calibrateAll(model, view)
    calibration = model.parameters.calibration;
    cals = fields(calibration.samples);
    for jj = 1:length(cals)
        try
            name = calibration.samples.(cals{jj}).sampleType;
            if strcmp(name, 'measurement')
                break;
            else
                model.parameters.calibration.selected = cals{jj};
                model.parameters.calibration.selectedValue = jj;
            end
            findPeaks(model);
            drawnow;
            calibrate(0, 0, model, view);
            drawnow;
            model.log.log(['I/Calibration: Calibration of sample "' cals{jj} '" finished.']);
        catch
            model.log.log(['E/Calibration: Error: Calibration of sample "' cals{jj} '" failed.']);
        end
    end
    model.log.log('I/Calibration: Finished.');
end

function findPeaks(model)
    %% store often used values in separate variables for convenience
    calibration = model.parameters.calibration;         % general calibration
    selectedMeasurement = calibration.selected;
    sample = calibration.samples.(selectedMeasurement); % selected sample
    
    mm = 1;     % selected image
    %% Plot
    if strcmp(selectedMeasurement, 'measurement')
        imgs = model.file.readPayloadData(sample.imageNr.x, sample.imageNr.y, sample.imageNr.z, 'data');
    else
        imgs = model.file.readCalibrationData(sample.position, 'data');
    end
    imgs = medfilt1(imgs,3);
    img = imgs(:,:,mm);
    data = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction.interpolationPositions);
    
    [peaks.height,peaks.locations,peaks.widths,peaks.proms] = findpeaks(data,'Annotate','extents','MinPeakProminence',calibration.peakProminence);
    
    sample.indRayleigh = [];
    sample.indBrillouin = [];
    Rayleigh_int = [];
    Brillouin_int = [];
    for jj = 1:length(calibration.peakTypes)
        try
            % find Rayleigh peaks
            if strcmp(calibration.peakTypes{jj}, 'R')
                sample.indRayleigh = [sample.indRayleigh; round(peaks.locations(jj) + peaks.widths(jj) * [-3 3])];
                Rayleigh_int = [Rayleigh_int; peaks.height(jj)]; %#ok<AGROW>
            end
            % find Brillouin peaks
            if strcmp(calibration.peakTypes{jj}, 'B1')
                sample.indBrillouin = [sample.indBrillouin; round(peaks.locations(jj) + peaks.widths(jj) * [-2 2])];
                Brillouin_int = [Brillouin_int; peaks.height(jj)]; %#ok<AGROW>
            end
        catch
        end
    end
    %% The Brillouin and Rayleigh peaks should have approx. the same height, respectively
    %  if not, there is likely something wrong
    try
        Rayleigh_dif = abs(1 - (Rayleigh_int(1) / Rayleigh_int(2)));
        Brillouin_dif = abs(1 - (Brillouin_int(1) / Brillouin_int(2)));
        if Rayleigh_dif > 0.4 || Brillouin_dif > 0.4
            model.log.log(['E/Calibration: Error: Peak detection of sample "' selectedMeasurement '" likely failed. Please check.']);
        end
    catch
        model.log.log(['E/Calibration: Error: There were less than two Rayleigh and Brillouin peaks found for sample "' ...
            selectedMeasurement '". Please check.']);
    end
    
    calibration.samples.(selectedMeasurement) = sample; % selected sample
    model.parameters.calibration = calibration;         % general calibration
end

function setDefaultParameters(model)
    
    calibration = model.parameters.calibration;
    calibration.correctOffset = 0;
    calibration.extrapolate = 1;
    calibration.weighted = 0;
    model.parameters.calibration = calibration;

    %% calculate the Brillouin shift corresponding to each calibration measurement
    updateCalibrationBrillouinShift(model);
    
    %% calculate the Brillouin shift for the measurements
    updateMeasurementBrillouinShift(model);
end

function setActive(view)
    tabgroup = get(view.calibration.parent, 'parent');
    tabgroup.SelectedTab = view.calibration.parent;
end

function calibrate(~, ~, model, view)
    %% store often used values in separate variables for convenience
    calibration = model.parameters.calibration;         % general calibration
    selectedMeasurement = calibration.selected;
    if strcmp(selectedMeasurement, '')
        return
    end
    sample = calibration.samples.(selectedMeasurement); % selected sample
    
    %% 
	startTime = model.file.date;
	refTime = datetime(startTime, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
	datestring = datetime(sample.time, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
	calibration.times(sample.position) = etime(datevec(datestring),datevec(refTime));
    
    if ~isfield(sample, 'start')
        sample.start = calibration.start;
    end
    
    %% find the positions of the Rayleigh and Brillouin peaks
    if strcmp(selectedMeasurement, 'measurement')
        imgs = model.file.readPayloadData(sample.imageNr.x, sample.imageNr.y, sample.imageNr.z, 'data');
    else
        imgs = model.file.readCalibrationData(sample.position, 'data');
    end
    
    

    indRayleigh = sample.indRayleigh;
    indBrillouin = sample.indBrillouin;
    nrPeaks = size(indRayleigh,1) + size(indBrillouin,1);
    if size(indRayleigh,1) ~= 2
        errorStr = ['Please select two Rayleigh peaks for sample "' selectedMeasurement '".'];
        ex = MException('MATLAB:toLessValues', errorStr);
        model.log.log(['E/Calibration: Error: ' errorStr]);
        disp(ex.message);
        return;
    end
    if size(indBrillouin,1) < 2
        errorStr = ['Please select at least one pair of Brillouin peaks for sample "' selectedMeasurement '".'];
        ex = MException('MATLAB:toLessValues', errorStr);
        
        model.log.log(['E/Calibration: Error: ' errorStr]);
        disp(ex.message);
        return;
    end
    if mod(size(indBrillouin,1),2)
        errorStr = ['Please select an even number of Brillouin peaks for sample "' selectedMeasurement '".'];
        ex = MException('MATLAB:toLessValues', errorStr);
        
        model.log.log(['E/Calibration: Error: ' errorStr]);
        disp(ex.message);
        return;
    end
    
    %% prepare variables for parfoor loop
    imgs = medfilt1(imgs,3);
    data = BE_SharedFunctions.getIntensity1D(imgs(:,:,1), model.parameters.extraction.interpolationPositions);
    nrPositions = size(data,2)/0.1;
    calibration.pixels = linspace(1,size(data,2),nrPositions);
    
    pixels = calibration.pixels;
    constants = model.parameters.constants;
    constants.bShiftCal = sample.shift*1e9;
    pixelSize = model.parameters.constants.pixelSize;
    
    interpolationPositions = model.parameters.extraction.interpolationPositions;
    fwhm = model.parameters.evaluation.fwhm;
    
    %% workaround in case two pairs of peaks are used to calibrate
    %  necessary because currently only one Brillouin shift value is stored
    %  in the raw data file
    sample.shift = 3.769;
    if size(indBrillouin,1) > 2 && size(constants.bShiftCal,1) < 2
        sample.shift(1) = 3.769;
        sample.shift(2) = 5.098;
    end
    constants.bShiftCal = sample.shift*1e9;
    
    %%
    totalRuns = size(imgs,3);
    offset = NaN(totalRuns,length(pixels));
    
    %% parfor loop
    clc;
    view.calibration.progressBar.setValue(0);
    view.calibration.progressBar.setString(sprintf('%01.0f%%', 0));
    
    % in order to optimize the cavity width, three runs are necessary
    cavityWidths = NaN(1,3);
    facs = NaN(1,3);
    for ii = 1:3
        cavityWidths(ii) = sample.start.d;
        start = sample.start;
        parfor mm = 1:totalRuns
            data = BE_SharedFunctions.getIntensity1D(imgs(:,:,mm), interpolationPositions);

    %         nrPositions = size(data,2)/0.1;
    %         calibration.pixels = linspace(1,size(data,2),nrPositions);

            %% find the measured peaks
            peakPos = NaN(1,nrPeaks);
            for jj = 1:length(indRayleigh)
                spectrumSection = data(indRayleigh(jj,1):indRayleigh(jj,2));
                [tmp, ~, ~] = BE_SharedFunctions.fitLorentzDistribution(spectrumSection, fwhm, 1, [6 20], 0);
                peakPos(jj) = tmp+indRayleigh(jj,1)-1;
            end
            for jj = 1:length(indBrillouin)
                spectrumSection = data(indBrillouin(jj,1):indBrillouin(jj,2));
                [tmp, ~, ~] = BE_SharedFunctions.fitLorentzDistribution(spectrumSection, fwhm, 1, [6 20], 0);
                peakPos(jj+length(indRayleigh)) = tmp+indBrillouin(jj,1)-1;
            end
            peakPos = sort(peakPos, 'ascend');
            peaksMeasured(mm,:) = peakPos;

            %% find the fitted peaks, do the VIPA fit            
            [VIPAparams, peakPos] = fitVIPA(peakPos, start, constants);
            VIPAparams.x0Initial = VIPAparams.x0;

            d(mm) = VIPAparams.d;
            n(mm) = VIPAparams.n;
            theta(mm) = VIPAparams.theta;
            x0Initial(mm) = VIPAparams.x0Initial;
            x0(mm) = VIPAparams.x0;
            xs(mm) = VIPAparams.xs;
            error(mm) = VIPAparams.error;
    %             params = {'d', 'n', 'theta', 'x0Initial', 'x0', 'xs', 'error'};
    %             for jj = 1:length(params)
    %                 sample.values.(params{jj})(mm) = VIPAparams.(params{jj});
    %             end
            peakPos = sort(peakPos, 'ascend');
            peaksFitted(mm,:) = peakPos;

            wavelength = BE_SharedFunctions.getWavelength(pixelSize * pixels, VIPAparams, constants, 1);

            wavelengths(mm,:) = wavelength;

            offset(mm,:) = interp1(peaksFitted(mm,:), peaksMeasured(mm,:) - peaksFitted(mm,:), pixels, 'spline');
        end

        %% store variables which were separated for parfor loop in structure again
        sample.peaksMeasured = peaksMeasured;
        sample.peaksFitted = peaksFitted;
        sample.values.d = d;
        sample.values.n = n;
        sample.values.theta = theta;
        sample.values.x0Initial = x0Initial;
        sample.values.x0 = x0;
        sample.values.xs = xs;
        sample.values.error = error;
        sample.wavelengths = wavelengths;
        sample.offset = offset;

        %% check if cavity width needs to be adjusted
        % if the cavity width is to low, the calculated Brillouin shifts are to
        % high. --> R1:--, B1:++, B2:--, R2:++
        % If the cavity width is to high, the calculated shifts are to low.
        % -->  R1:++, B1:--, B2:++, R2:--
        if size(sample.peaksMeasured,2) == 4
            signs = [-1 1 -1 1];    % signs how sum up the differences between measured and fitted peaks
            signs = repmat(signs, size(sample.peaksMeasured,1), 1);
            deviations = signs .* (sample.peaksMeasured - sample.peaksFitted);
            fac = mean(deviations(:));      % if fac > 0, d has to be increased, otherwise decreased
            sample.fac = fac;
            facs(ii) = fac;
        elseif size(sample.peaksMeasured,2) == 6
            signs = [-1 1 1 -1 -1 1];    % signs how sum up the differences between measured and fitted peaks
            signs = repmat(signs, size(sample.peaksMeasured,1), 1);
            deviations = signs .* (sample.peaksMeasured - sample.peaksFitted);
            fac = mean(deviations(:));      % if fac > 0, d has to be increased, otherwise decreased
            sample.fac = fac;
            facs(ii) = fac;
        end
        if (ii==1)
            cavityWidths(2) = sample.start.d - facs(ii)/constants.cavitySlope;
            sample.start.d = cavityWidths(2);
        elseif (ii == 2)
            m = (facs(1) - facs(2)) / (cavityWidths(1) - cavityWidths(2));
            n = facs(2) - m * cavityWidths(2);
            cavityWidths(3) = - n/m;
            sample.start.d = cavityWidths(3);
        end
        val = ii*100/3;
        view.calibration.progressBar.setValue(val);
        view.calibration.progressBar.setString(sprintf('%01.0f%%', val));
    end
    if abs(sample.fac) > 0.005
        model.log.log(['W/Calibration: Warning: Calibration of sample "' selectedMeasurement '" is inaccurate. Please check.']);
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
    
    [wavelength, offset] = averageCalibration(sample, calibration.weighted);
    calibration.wavelength(sample.position,1:size(wavelength,2)) = wavelength;
    calibration.offset(sample.position,1:size(offset,2)) = offset;
    
    %% save the results
    calibration.samples.(selectedMeasurement) = sample;
    model.parameters.calibration = calibration;
    
    %% calculate the Brillouin shift corresponding to each calibration measurement
    updateCalibrationBrillouinShift(model);
    
    %% calculate the Brillouin shift for the measurements
    updateMeasurementBrillouinShift(model);
    
    view.calibration.progressBar.setValue(100);
    view.calibration.progressBar.setString(sprintf('%01.0f%%', 100));
end

function [wavelength, offset] = averageCalibration(sample, weight)
    try
        if weight
            %% average the single calibrations according to their uncertainty
            wavelength = sample.wavelengths(logical(sample.active), :);         % wavelengths from calibration, only select active calibration images
            offset = sample.offset(logical(sample.active), :);                  % offset from the calibration, only select active calibration images
            weights = repmat(sample.values.error(:,logical(sample.active)).', 1, size(wavelength,2));  % map of the weights, only select active calibration images
            weights(isnan(wavelength)) = NaN;                                   % set weights to NaN in case wavelength is NaN
            norm = repmat(nansum(1./weights,1), size(wavelength,1), 1);         % calculate the normalization value

            weights = 1 ./ (norm .* weights);

            wavelength = nansum((wavelength .* weights), 1);                    % calculate the weighted average of the wavelengths
            offset = nansum((offset .* weights), 1);                            % calculate the weighted average of the offset
        else
            wavelength = nanmean(sample.wavelengths,1);
            offset = nanmean(sample.offset,1);
        end
    catch
        disp('Please run the calibration for this sample again.');
        wavelength = NaN;
        offset = NaN;
    end
end

function updateMeasurementBrillouinShift(model)
    try
        wavelengthRayleigh = BE_SharedFunctions.getWavelengthFromMap(model.results.peaksRayleigh_pos, model.results.times, model.parameters.calibration);
        wavelengthBrillouin = BE_SharedFunctions.getWavelengthFromMap(model.results.peaksBrillouin_pos, model.results.times, model.parameters.calibration);

        model.results.BrillouinShift_frequency = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(wavelengthBrillouin, wavelengthRayleigh));
    catch
        disp('Please run the evaluation again.');
    end
end

function updateCalibrationBrillouinShift(model)
    calibration = model.parameters.calibration;
    samples = fields(model.parameters.calibration.samples);
    
    if isempty(model.file)
        return;
    end
    
    %%
    startTime = model.file.date;
    refTime = datetime(startTime, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    
    for jj = 1:length(samples)
        sample = calibration.samples.(samples{jj});
        if ~isempty(sample.peaksMeasured)
            datestring = datetime(sample.time, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
            calibration.times(sample.position) = etime(datevec(datestring),datevec(refTime));
            times = calibration.times(sample.position) * ones(size(sample.peaksMeasured));
            wavelengths = BE_SharedFunctions.getWavelengthFromMap(sample.peaksMeasured, times, calibration);
            
            wave = wavelengths(:,2:(end-1));
            ref = repelem(wavelengths(:,[1, end]),1,length(sample.shift));
            sample.BrillouinShift = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(ref, wave));
            
            calibration.samples.(samples{jj}) = sample;
        end
    end
    model.parameters.calibration = calibration;
end

function toggleExtrapolation(src, ~, model)
    model.parameters.calibration.extrapolate = get(src, 'Value');
    
    %% calculate the Brillouin shift corresponding to each calibration measurement
    updateCalibrationBrillouinShift(model);
    
    %% calculate the Brillouin shift for the measurements
    updateMeasurementBrillouinShift(model);
end

function toggleWeighting(src, ~, model)
    model.parameters.calibration.weighted = get(src, 'Value');
    
    averageCalibrations(model);
    
    %% calculate the Brillouin shift corresponding to each calibration measurement
    updateCalibrationBrillouinShift(model);
    
    %% calculate the Brillouin shift for the measurements
    updateMeasurementBrillouinShift(model);
end

function toggleOffsetCorrection(src, ~, model)
    model.parameters.calibration.correctOffset = get(src, 'Value');
    
    %% calculate the Brillouin shift corresponding to each calibration measurement
    updateCalibrationBrillouinShift(model);
    
    %% calculate the Brillouin shift for the measurements
    updateMeasurementBrillouinShift(model);
end

function averageCalibrations(model)
    calibration = model.parameters.calibration;
    samples = fields(model.parameters.calibration.samples);
    
    for jj = 1:length(samples)
        sample = calibration.samples.(samples{jj});
        if isfield(sample, 'wavelengths') && ~isempty(sample.wavelengths)
            [wavelength, offset] = averageCalibration(sample, calibration.weighted);
            calibration.wavelength(sample.position,:) = wavelength;
            calibration.offset(sample.position,:) = offset;
        end
    end
    model.parameters.calibration = calibration;
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
        if ~isfield(model.handles, 'calibration')
            return;
        end
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
    if strcmp(model.parameters.calibration.selected, '')
        return;
    end
    model.parameters.calibration.samples.(model.parameters.calibration.selected).(['ind' type]) = [];
end

function editPeaks(~, table, model, type)
    if strcmp(model.parameters.calibration.selected, '')
        return;
    end
    model.parameters.calibration.samples.(model.parameters.calibration.selected).(['ind' type])(table.Indices(1), table.Indices(2)) = table.NewData;
end

function editStartParameters(~, table, model)
    fields = {'d', 'n', 'theta', 'x0', 'xs', 'order', 'iterNum'};
    if isfield(model.parameters.calibration.samples.(model.parameters.calibration.selected), 'start')
        model.parameters.calibration.samples.(model.parameters.calibration.selected).start.(fields{table.Indices(2)}) = str2double(table.NewData);
    else
        model.parameters.calibration.samples.(model.parameters.calibration.selected).start = model.parameters.calibration.start;
        model.parameters.calibration.samples.(model.parameters.calibration.selected).start.(fields{table.Indices(2)}) = str2double(table.NewData);
    end
end

function toggleActiveState(~, table, model)
    sample = model.parameters.calibration.samples.(model.parameters.calibration.selected);
    calibration = model.parameters.calibration;
    if table.Indices(2) == 7
        sample.active(table.Indices(1)) = table.NewData;
    end
    calibration.samples.(model.parameters.calibration.selected) = sample;
    
    if isfield(sample, 'wavelengths') && ~isempty(sample.wavelengths)
        [wavelength, offset] = averageCalibration(sample, calibration.weighted);
        calibration.wavelength(sample.position,:) = wavelength;
        calibration.offset(sample.position,:) = offset;
    end
    model.parameters.calibration = calibration;
    
    %% calculate the Brillouin shift corresponding to each calibration measurement
    updateCalibrationBrillouinShift(model);
    
    %% calculate the Brillouin shift for the measurements
    updateMeasurementBrillouinShift(model);
end

function clearCalibration(~, ~, model)
    calibration = model.parameters.calibration;
    selectedMeasurement = calibration.selected;
    if strcmp(selectedMeasurement, '')
        return;
    end
    calibration.samples.(selectedMeasurement).values = struct( ...
        'd',            [], ... % [m]   width of the cavity
        'n',            [], ... % [1]   refractive index of the VIPA
        'theta',        [], ... % [rad] angle of the VIPA
        'x0Initial',    [], ... % [m]   offset for fitting
        'x0',           [], ... % [m]   offset for fitting, corrected for each measurement
        'xs',           [], ... % [1]   scale factor for fitting
        'error',        []  ... % [1]   uncertainty of the fit
    );
    calibration.samples.(selectedMeasurement).wavelengths = [];
    pos = calibration.samples.(selectedMeasurement).position;
    calibration.times(pos) = NaN;
    calibration.wavelength(pos,:) = NaN;
    calibration.offset(pos,:) = 0;

    model.parameters.calibration = calibration;
    
    %% calculate the Brillouin shift corresponding to each calibration measurement
    updateCalibrationBrillouinShift(model);
    
    %% calculate the Brillouin shift for the measurements
    updateMeasurementBrillouinShift(model);
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

function [VIPAparams, peakPosFitted] = fitVIPA(peakPos, VIPAstart, constants)
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
    lambdaS = NaN(1,length(constants.bShiftCal));
    lambdaAS = lambdaS;
    for jj = 1:length(constants.bShiftCal)
        lambdaS(jj) = 1/(1/constants.lambda0 - constants.bShiftCal(jj)/constants.c);
        lambdaAS(jj) = 1/(1/constants.lambda0 + constants.bShiftCal(jj)/constants.c);
    end
    lambdaS = sort(lambdaS, 'descend');
    lambdaAS = sort(lambdaAS, 'descend');
    
    orders = [startOrders(1), ones(1,length(constants.bShiftCal)), 2*ones(1,length(constants.bShiftCal)), startOrders(2)];
    lambdas = [constants.lambda0, lambdaAS, lambdaS, constants.lambda0];

    %% calculation
    
    VIPAparams = struct;
%     total = VIPAstart.iterNum * nrIter.d;
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
%             done = 100*((gg-1)*nrIter.d + ii)/total;
%             view.calibration.progressBar.setValue(done);
%             view.calibration.progressBar.setString(sprintf('%01.0f%%', done));
            for jj = 1:length(nRange)
                for kk = 1:length(thetaRange)
                    for ll = 1:length(x0Range)
                        for mm = 1:length(xsRange)
                            VIPAparams.d     = dRange(ii);
                            VIPAparams.n     = nRange(jj);
                            VIPAparams.theta = thetaRange(kk);
                            VIPAparams.x0    = x0Range(ll);
                            VIPAparams.xs    = xsRange(mm);
                            
                            % position of the two Rayleigh peaks and the (multiple) Stokes and Anti-Stokes peaks
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

    % position of the two Rayleigh peaks and the Stokes and Anti-Stokes peaks
    [peakPosFitted, ~] = BE_SharedFunctions.peakPosition(VIPAparams, constants, orders, lambdas);
    
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

function openBrillouinShift(~, ~, model, view)
    calibration = model.parameters.calibration;
    
    BrillouinShiftsS = NaN(1,2);
    BrillouinShiftsAS = BrillouinShiftsS;
    BrillouinShiftsS_mean = BrillouinShiftsS;
    BrillouinShiftsAS_mean = BrillouinShiftsAS;
    calibrationFrequency = NaN(1,1);
    
    sampleNames = fields(calibration.samples);
    totalImages = 0;
    for jj = 1:length(sampleNames)
        sample = calibration.samples.(sampleNames{jj});
        if isfield(sample, 'BrillouinShift')
            shift = sample.BrillouinShift;
            nrImages = size(shift,1);
            for kk = 1:length(sample.shift)
                BrillouinShiftsS((totalImages + (1:nrImages)), kk) = shift(:,kk);
                BrillouinShiftsAS((totalImages + (1:nrImages)), kk) = shift(:,end-kk+1);
                BrillouinShiftsS_mean((totalImages + (1:nrImages)), kk) = repmat(nanmean(shift(:,kk),1), nrImages, 1);
                BrillouinShiftsAS_mean((totalImages + (1:nrImages)), kk) = repmat(nanmean(shift(:,end-kk+1),1), nrImages, 1);
            end
            calibrationFrequency((totalImages + (1:nrImages)), 1:length(sample.shift)) = ones(nrImages,1) * sample.shift;
        else
            nrImages = 1;
            BrillouinShiftsS((totalImages + (1:nrImages)), :) = NaN;
            BrillouinShiftsAS((totalImages + (1:nrImages)), :) = NaN;
            BrillouinShiftsS_mean((totalImages + (1:nrImages)), :) = NaN;
            BrillouinShiftsAS_mean((totalImages + (1:nrImages)), :) = NaN;
        end
        totalImages = totalImages + nrImages;
    end
    
    BrillouinShiftsS(BrillouinShiftsS == 0) = NaN;
    BrillouinShiftsAS(BrillouinShiftsAS == 0) = NaN;
    BrillouinShiftsS_mean(BrillouinShiftsS_mean == 0) = NaN;
    BrillouinShiftsAS_mean(BrillouinShiftsAS_mean == 0) = NaN;
    calibrationFrequency(calibrationFrequency == 0) = NaN;
    
    if isfield(view.calibration, 'BrillouinShiftView') && ishandle(view.calibration.BrillouinShiftView)
        return;
    else
        width = 500;
        height = 400;
        figPos = view.figure.Position;
        x = figPos(1) + (figPos(3) - width)/2;
        y = figPos(2) + (figPos(4) - height)/2;
        BrillouinShiftView = figure('Position',[x,y,width,height]);
        % hide the menubar and prevent resizing
        view.calibration.BrillouinShiftView = BrillouinShiftView;
    end
    
    ax = gca;
    hold(ax, 'on');
    Stokes = plot(ax, BrillouinShiftsS, 'color', [0    0.4470    0.7410]);
    Stokes_m = plot(ax, BrillouinShiftsS_mean, 'LineStyle', '--', 'LineWidth', 0.8, 'color', [0    0.4470    0.7410]);
    AntiStokes = plot(ax, BrillouinShiftsAS, 'color', [0.9290    0.6940    0.1250]);
    AntiStokes_m = plot(ax, BrillouinShiftsAS_mean, 'LineStyle', '--', 'LineWidth', 0.8, 'color', [0.9290    0.6940    0.1250]);
    ax.ColorOrderIndex = 3;
    calibration = plot(ax, calibrationFrequency, 'color', [0.8500    0.3250    0.0980]);
    xlabel(ax, 'Calibration image #');
    ylabel(ax, '$f$ [GHz]', 'interpreter', 'latex');
    if sum(~isnan(BrillouinShiftsS(:)))
        leg = legend(ax, [Stokes(1); Stokes_m(1); AntiStokes(1); AntiStokes_m(1); calibration(1)], ...
            'Stokes Peak', 'Stokes Peak Mean', 'AntiStokes Peak', 'AntiStokes Peak Mean', 'Calibration Frequency');
        if size(BrillouinShiftsS_mean,2) > 1
            set(leg, 'Location', 'East');
        else
            set(leg, 'Location', 'NorthEast');
        end
    end
end