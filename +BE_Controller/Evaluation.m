function callbacks = Evaluation(model, view)
%% EVALUATION Controller

    %% callbacks Calibration
    set(view.evaluation.evaluate, 'Callback', {@startEvaluation, view, model});
    set(view.evaluation.newFig, 'Callback', {@openNewFig, view, model});
    
    set(view.evaluation.livePreview, 'Callback', {@toggleLivePreview, view, model});
    set(view.evaluation.discardInvalid, 'Callback', {@toggleDiscardInvalid, view, model});
    set(view.evaluation.interpRayleigh, 'Callback', {@toggleInterpRayleigh, view, model});
    
    set(view.evaluation.intFac, 'Callback', {@setValue, model, 'intFac'});
    set(view.evaluation.validity, 'Callback', {@setValue, model, 'valThreshould'});
    
    set(view.evaluation.showSpectrum, 'Callback', {@showSpectrum, view, model});
    set(view.evaluation.selectbright, 'Callback', {@selectbright, view, model});
    set(view.evaluation.getbrightposition, 'Callback', {@getpstn, view, model});
    set(view.evaluation.startMasking, 'Callback', {@startMasking, view, model});
    
    set(view.evaluation.zoomIn, 'Callback', {@zoom, 'in', view});
    set(view.evaluation.zoomOut, 'Callback', {@zoom, 'out', view});
    set(view.evaluation.panButton, 'Callback', {@pan, view});
    set(view.evaluation.rotate3dButton, 'Callback', {@rotate3d, view});
    
    set(view.evaluation.plotTypes, 'Callback', {@selectPlotType, model});
    
    set(view.evaluation.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.evaluation.cap, 'Callback', {@setClim, model});
    set(view.evaluation.floor, 'Callback', {@setClim, model});
    
    set(view.evaluation.increaseFloor, 'Callback', {@changeClim, model, 1});
    set(view.evaluation.decreaseFloor, 'Callback', {@changeClim, model, -1});
    set(view.evaluation.increaseCap, 'Callback', {@changeClim, model, 1});
    set(view.evaluation.decreaseCap, 'Callback', {@changeClim, model, -1});
    
    callbacks = struct( ...
        'setActive', @()setActive(view), ...
        'startEvaluation', @()startEvaluation(0, 0, view, model) ...
    ); 
end

function setActive(view)
    tabgroup = get(view.evaluation.parent, 'parent');
    tabgroup.SelectedTab = view.evaluation.parent;
end

function startEvaluation(~, ~, view, model)
    model.status.evaluation.evaluate = ~model.status.evaluation.evaluate;
    if model.status.evaluation.evaluate
        evaluate(view, model);
        model.status.evaluation.evaluate = 0;
    end
end

function evaluate(view, model)
    totalPoints = (model.parameters.resolution.X*model.parameters.resolution.Y*model.parameters.resolution.Z);
    
    if isempty(model.parameters.peakSelection.Rayleigh) || isempty(model.parameters.peakSelection.Brillouin)
        disp('Please select at least one Rayleigh and one Brillouin peak.');
        return;
    end
    
    ind_Rayleigh = model.parameters.peakSelection.Rayleigh(1,1):model.parameters.peakSelection.Rayleigh(1,2);
    ind_Brillouin = model.parameters.peakSelection.Brillouin(1,1):model.parameters.peakSelection.Brillouin(1,2);
    
    try
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    
    nrPeaks = 1;
    parameters.peaks = [6 20];
    
    %% find the position of the Rayleigh peaks during calibration
    % this enables evaluating measurements with no valid Rayleigh peaks
    
    calibration = model.parameters.calibration;
    samples = fields(calibration.samples);

    peaksRayleigh_pos_cal = [];
    caltimes = [];
    initRayleighPos = NaN;
    shift = 0;
    lastValidRayleighPeakPos = NaN;
    for jj = 1:length(samples)
        sample = calibration.samples.(samples{jj});
        if strcmp(sample.sampleType, 'measurement')
            break;
        end
        imgs = model.controllers.data.getCalibration('data', sample.position);
        imgs(imgs >= (2^16 - 1)) = NaN;
        try
            date = datetime(sample.time, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
        catch
            date = datetime(sample.time, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
        end
        time = etime(datevec(date),datevec(refTime));
        caltimes = [caltimes, time]; %#ok<AGROW>

        RayleighPosSample = NaN(size(imgs, 3), 1);
        for kk = 1:size(imgs,3)
            spectrum = BE_SharedFunctions.getIntensity1D(imgs(:,:,kk), model.parameters.extraction, time);
            spectrumSection = spectrum(ind_Rayleigh);

            if ~sum(isnan(spectrumSection))
                [tmp, ~, ~] = ...
                    BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
                 RayleighPosSample(kk) = tmp + min(ind_Rayleigh(:)) - 1;
            end
        end
        peaksRayleigh_pos_cal = [peaksRayleigh_pos_cal, nanmean(RayleighPosSample)]; %#ok<AGROW>
        initRayleighPos = peaksRayleigh_pos_cal(1);
        lastValidRayleighPeakPos = peaksRayleigh_pos_cal(1);
    end
    
    imgs = model.controllers.data.getPayload('data', 1, 1, 1);
    datestring = model.controllers.data.getPayload('date', 1, 1, 1);
    try
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    
    time = etime(datevec(date),datevec(refTime));
%     imgs = medfilt1(imgs,3);
    img = imgs(:,:,1);
    img(img >= (2^16 - 1)) = NaN;
    spectrum = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction, time);
    spectrumSection = spectrum(ind_Rayleigh);
    
    if ~sum(isnan(spectrumSection))
        [initRayleighPos, ~, ~] = ...
            BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
        lastValidRayleighPeakPos = initRayleighPos;
    end
        
    intensity = NaN(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3));
    peaksBrillouin_pos = NaN(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3), nrPeaks);
    peaksBrillouin_dev = peaksBrillouin_pos;
    peaksBrillouin_fwhm = peaksBrillouin_pos;
    peaksBrillouin_int = peaksBrillouin_pos;
    peaksRayleigh_pos_exact = peaksBrillouin_pos;
    peaksRayleigh_pos = peaksBrillouin_pos;
    peaksRayleigh_fwhm = peaksBrillouin_pos;
    peaksRayleigh_int = peaksBrillouin_pos;
    times = peaksBrillouin_pos;
    validity = true(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3));
    validity_Rayleigh = validity;
    validity_Brillouin = validity;
    
%     spectra = NaN(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3), size(model.parameters.extraction.interpolationPositions.x,2));
    %% start evaluation
    warningRayleigh = false;
    warningBrillouin = false;
    for jj = 1:1:model.parameters.resolution.X
        if ~model.status.evaluation.evaluate
            break
        end
        for kk = 1:1:model.parameters.resolution.Y
            if ~model.status.evaluation.evaluate
                break
            end
            for ll = 1:1:model.parameters.resolution.Z
                if ~model.status.evaluation.evaluate
                    break
                end
                try
                    % read data from the file
                    imgs = model.controllers.data.getPayload('data', jj, kk, ll);
                    
                    datestring = model.controllers.data.getPayload('date', jj, kk, ll);
                    try
                        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
                    catch
                        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
                    end

                    for mm = 1:size(imgs,3)
                        time = etime(datevec(date),datevec(refTime)) + (mm-1) * model.parameters.exposureTime;
                        times(kk, jj, ll, mm) = time;
                        if ~model.status.evaluation.evaluate
                            break
                        end
                        img = imgs(:,:,mm);
                        %% calculate intensity before setting invalid values to NaN.
                        %  The intensity will be underestimated, but
                        %  otherwise no value will be available at all at
                        %  saturated measurement points
                        intensity(kk, jj, ll, mm) = nansum(img(:));
                        
                        %% set invalid values to NaN
                        img(img >= (2^16 - 1)) = NaN;
                        
                        spectrum = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction, time);
                        
%                         spectra(kk, jj, ll, mm, :) = spectrum;

                        ind_Rayleigh_shifted = ind_Rayleigh + shift;
                        spectrumSection = spectrum(ind_Rayleigh_shifted);
%                         figure(123)
%                         imagesc(img)
                        if ~sum(isnan(spectrumSection))
                            [peakPos, fwhm, int, ~, thres, ~] = ...
                                BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
                        else
                            [peakPos, fwhm, int] = deal(NaN);
                        end
                        
                        %% check if peak position is valid
                        if peakPos <= 0 || peakPos >= length(ind_Rayleigh_shifted) || isnan(peakPos) || (int - thres) < model.parameters.evaluation.minRayleighPeakHeight
                            validity_Rayleigh(kk, jj, ll, mm) = false;
                            [peakPos, fwhm, int] = deal(NaN);
                            warningRayleigh = true;
                        else
                            lastValidRayleighPeakPos = peakPos;
                        end
                        
                        peaksRayleigh_pos_exact(kk, jj, ll, mm, :) = peakPos + min(ind_Rayleigh_shifted(:)) - 1;
                        peaksRayleigh_fwhm(kk, jj, ll, mm, :) = fwhm;
                        peaksRayleigh_int(kk, jj, ll, mm, :) = int;
                        shift = round(lastValidRayleighPeakPos - initRayleighPos + shift);

                        secInd = ind_Brillouin + shift;
                        spectrumSection = spectrum(secInd);
                        if ~sum(isnan(spectrumSection))
                            [peakPos, fwhm, int, ~, thres, deviation] = ...
                                BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
                        else
                            [peakPos, fwhm, int, thres, deviation] = deal(NaN);
                        end
                        
                        %% check if peak position is valid
                        if peakPos <= 0 || peakPos >= length(secInd) || isnan(peakPos)
                            validity_Brillouin(kk, jj, ll, mm) = false;
                            [peakPos, fwhm, deviation] = deal(NaN);
                            warningBrillouin = true;
                        end
                        
                        peaksBrillouin_fwhm(kk, jj, ll, mm, :) = fwhm;
                        peaksBrillouin_dev(kk, jj, ll, mm, :) = deviation;
                        peaksBrillouin_pos(kk, jj, ll, mm, :) = peakPos + min(secInd(:)) - 1;
                        peaksBrillouin_int(kk, jj, ll, mm, :) = int - thres;

                    end
                    if model.displaySettings.evaluation.preview
                        
                        %% interpolate Rayleigh peak position for invalid/saturated peaks
                        t_vec = times(:);
                        peaksRayleigh_pos_vec = peaksRayleigh_pos_exact(:);

                        [t_vec_sort, sortOrder] = sort(t_vec);
                        peaksRayleigh_pos_vec_sort = peaksRayleigh_pos_vec(sortOrder);
                        
                        % concat Rayleigh peak positions from calibration and sort again
                        t_vec_sort_cal = [t_vec_sort; caltimes(:)];
                        peaksRayleigh_pos_vec_sort_cal = [peaksRayleigh_pos_vec_sort; peaksRayleigh_pos_cal(:)];
                        
                        [t_vec_sort_cal, sortOrderCal] = sort(t_vec_sort_cal);
                        peaksRayleigh_pos_vec_sort_cal = peaksRayleigh_pos_vec_sort_cal(sortOrderCal);

                        % only use not NaN values
                        notnan = ~isnan(peaksRayleigh_pos_vec_sort_cal);

                        % actually interpolate
                        peaksRayleigh_pos_vec_sort_int = interp1(t_vec_sort_cal(notnan), peaksRayleigh_pos_vec_sort_cal(notnan), t_vec_sort);

                        % reverse sorting
                        [~, invSortOrder] = sort(sortOrder);

                        peaksRayleigh_pos_vec_sort_int_inv = peaksRayleigh_pos_vec_sort_int(invSortOrder);

                        peaksRayleigh_pos_interp = reshape(peaksRayleigh_pos_vec_sort_int_inv, size(peaksRayleigh_pos));

                        if model.parameters.evaluation.interpRayleigh
                            peaksRayleigh_pos = peaksRayleigh_pos_interp;
                            validity = validity_Brillouin & ~isnan(peaksRayleigh_pos_interp);
                        else
                            peaksRayleigh_pos = peaksRayleigh_pos_exact;
                            validity = validity_Rayleigh & validity_Brillouin;
                        end

                        %% calculate the Brillouin shift in [pix]
                        brillouinShift = abs(peaksRayleigh_pos-peaksBrillouin_pos);
                        
                        %% calculate the Brillouin shift in [GHz]
                        calibration = model.parameters.calibration;
                        
                        wavelengthRayleigh = BE_SharedFunctions.getWavelengthFromMap(peaksRayleigh_pos, times, calibration);
                        wavelengthBrillouin = BE_SharedFunctions.getWavelengthFromMap(peaksBrillouin_pos, times, calibration);
                        
                        brillouinShift_frequency = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(wavelengthBrillouin, wavelengthRayleigh));
                        
                        wavelengthLeftSlope = BE_SharedFunctions.getWavelengthFromMap(peaksBrillouin_pos - peaksBrillouin_fwhm/2, times, calibration);
                        wavelengthRightSlope = BE_SharedFunctions.getWavelengthFromMap(peaksBrillouin_pos + peaksBrillouin_fwhm/2, times, calibration);
                        
                        peaksBrillouin_fwhm_frequency = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(wavelengthLeftSlope, wavelengthRightSlope));
                        
                        %% save the results
                        results = model.results;
                        results.BrillouinShift            = brillouinShift;           % [pix]  the Brillouin shift in pixels
                        results.BrillouinShift_frequency  = brillouinShift_frequency; % [GHz]  the Brillouin shift in GHz
                        results.peaksBrillouin_pos        = peaksBrillouin_pos;       % [pix]  the position of the Brillouin peak(s) in the spectrum
                        results.peaksBrillouin_dev        = peaksBrillouin_dev;       % [pix]  the deviation of the Brillouin fit
                        results.peaksBrillouin_int        = peaksBrillouin_int;       % [a.u.] the intensity of the Brillouin peak(s)
                        results.peaksBrillouin_fwhm       = peaksBrillouin_fwhm;      % [pix]  the FWHM of the Brillouin peak
                        results.peaksBrillouin_fwhm_frequency = peaksBrillouin_fwhm_frequency;  % [GHz] the FWHM of the Brillouin peak in GHz
                        results.peaksRayleigh_pos_interp  = peaksRayleigh_pos_interp; % [pix]  the position of the Rayleigh peak(s) in the spectrum (interpoalted)
                        results.peaksRayleigh_pos_exact   = peaksRayleigh_pos_exact;  % [pix]  the position of the Rayleigh peak(s) in the spectrum (exact)
                        results.peaksRayleigh_pos         = peaksRayleigh_pos;        % [pix]  the position of the Rayleigh peak(s) in the spectrum
                        results.peaksRayleigh_int         = peaksRayleigh_int;        % [a.u.] the intensity of the Rayleigh peak(s)
                        results.peaksRayleigh_fwhm        = peaksRayleigh_fwhm;       % [pix]  the FWHM of the Rayleigh peak(s)
                        results.intensity                 = intensity;                % [a.u.] the overall intensity of the image
                        results.validity_Rayleigh         = validity_Rayleigh;        % [logical] the validity of the Rayleigh peaks
                        results.validity_Brillouin        = validity_Brillouin;       % [logical] the validity of the Brillouin peaks
                        results.validity                  = validity;                 % [logical] the validity of the general results
                        results.times                     = times;                    % [s]    time of the measurement
                        model.results = results;
                    end
                    drawnow;

                    finishedPoints = ((jj-1)*(model.parameters.resolution.Y*model.parameters.resolution.Z) + (kk-1)*model.parameters.resolution.Z + ll);
                    prog = 100*finishedPoints/totalPoints;
                    view.evaluation.progressBar.setValue(prog);
                    view.evaluation.progressBar.setString(sprintf('%01.1f%%',prog));
                catch e
                    disp(e);
                end
            end
        end
    end
    
%     save('Brillouin_spectra.mat', 'spectra');

    %% issue warnings when Rayleigh or Brillouin peaks could not be fitted
    if warningRayleigh
        model.log.log('W', 'Some Rayleigh peaks could not be fitted.');
    end
    if warningBrillouin
        model.log.log('W', 'Some Brillouin peaks could not be fitted.');
    end
                        
    %% interpolate Rayleigh peak position for invalid/saturated peaks
    t_vec = times(:);
    peaksRayleigh_pos_vec = peaksRayleigh_pos_exact(:);

    [t_vec_sort, sortOrder] = sort(t_vec);
    peaksRayleigh_pos_vec_sort = peaksRayleigh_pos_vec(sortOrder);

    % concat Rayleigh peak positions from calibration and sort again
    t_vec_sort_cal = [t_vec_sort; caltimes(:)];
    peaksRayleigh_pos_vec_sort_cal = [peaksRayleigh_pos_vec_sort; peaksRayleigh_pos_cal(:)];

    [t_vec_sort_cal, sortOrderCal] = sort(t_vec_sort_cal);
    peaksRayleigh_pos_vec_sort_cal = peaksRayleigh_pos_vec_sort_cal(sortOrderCal);

    % only use not NaN values
    notnan = ~isnan(peaksRayleigh_pos_vec_sort_cal);
    
    % actually interpolate
    peaksRayleigh_pos_vec_sort_int = interp1(t_vec_sort_cal(notnan), peaksRayleigh_pos_vec_sort_cal(notnan), t_vec_sort);

    % reverse sorting
    [~, invSortOrder] = sort(sortOrder);

    peaksRayleigh_pos_vec_sort_int_inv = peaksRayleigh_pos_vec_sort_int(invSortOrder);

    peaksRayleigh_pos_interp = reshape(peaksRayleigh_pos_vec_sort_int_inv, size(peaksRayleigh_pos));

    if model.parameters.evaluation.interpRayleigh
        peaksRayleigh_pos = peaksRayleigh_pos_interp;
        validity = validity_Brillouin & ~isnan(peaksRayleigh_pos_interp);
    else
        peaksRayleigh_pos = peaksRayleigh_pos_exact;
        validity = validity_Rayleigh & validity_Brillouin;
    end
    
    %% calculate the Brillouin shift in [pix]
    brillouinShift = abs(peaksRayleigh_pos-peaksBrillouin_pos);

    %% calculate the Brillouin shift in [GHz]
    calibration = model.parameters.calibration;
    
    wavelengthRayleigh = BE_SharedFunctions.getWavelengthFromMap(peaksRayleigh_pos, times, calibration);
    wavelengthBrillouin = BE_SharedFunctions.getWavelengthFromMap(peaksBrillouin_pos, times, calibration);
    
    brillouinShift_frequency = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(wavelengthBrillouin, wavelengthRayleigh));
    
    wavelengthLeftSlope = BE_SharedFunctions.getWavelengthFromMap(peaksBrillouin_pos - peaksBrillouin_fwhm/2, times, calibration);
    wavelengthRightSlope = BE_SharedFunctions.getWavelengthFromMap(peaksBrillouin_pos + peaksBrillouin_fwhm/2, times, calibration);

    peaksBrillouin_fwhm_frequency = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(wavelengthLeftSlope, wavelengthRightSlope));
    
    %% save the results
    results = model.results;
    results.BrillouinShift            = brillouinShift;           % [pix]  the Brillouin shift in pixels
    results.BrillouinShift_frequency  = brillouinShift_frequency; % [GHz]  the Brillouin shift in GHz
    results.peaksBrillouin_pos        = peaksBrillouin_pos;       % [pix]  the position of the Brillouin peak(s) in the spectrum
    results.peaksBrillouin_dev        = peaksBrillouin_dev;       % [pix]  the deviation of the Brillouin fit
    results.peaksBrillouin_int        = peaksBrillouin_int;       % [a.u.] the intensity of the Brillouin peak(s)
    results.peaksBrillouin_fwhm       = peaksBrillouin_fwhm;      % [pix]  the FWHM of the Brillouin peak
    results.peaksBrillouin_fwhm_frequency = peaksBrillouin_fwhm_frequency;  % [GHz] the FWHM of the Brillouin peak in GHz
    results.peaksRayleigh_pos_interp  = peaksRayleigh_pos_interp; % [pix]  the position of the Rayleigh peak(s) in the spectrum (interpoalted)
    results.peaksRayleigh_pos_exact   = peaksRayleigh_pos_exact;  % [pix]  the position of the Rayleigh peak(s) in the spectrum (exact)
    results.peaksRayleigh_pos         = peaksRayleigh_pos;        % [pix]  the position of the Rayleigh peak(s) in the spectrum
    results.peaksRayleigh_int         = peaksRayleigh_int;        % [a.u.] the intensity of the Rayleigh peak(s)
    results.peaksRayleigh_fwhm        = peaksRayleigh_fwhm;       % [pix]  the FWHM of the Rayleigh peak(s)
    results.intensity                 = intensity;                % [a.u.] the overall intensity of the image
    results.validity_Rayleigh         = validity_Rayleigh;        % [logical] the validity of the Rayleigh peaks
    results.validity_Brillouin        = validity_Brillouin;       % [logical] the validity of the Brillouin peaks
    results.validity                  = validity;                 % [logical] the validity of the general results
    results.times                     = times;                    % [s]    time of the measurement
    model.results = results;
    model.log.log('I/Evaluation: Finished.');
end

function zoom(src, ~, str, view)
switch get(src, 'UserData')
    case 0
        set(view.evaluation.panButton,'UserData',0);
        set(view.evaluation.panHandle,'Enable','off');
        set(view.evaluation.rotate3dButton,'UserData',0);
        set(view.evaluation.rotate3dHandle,'Enable','off');
        switch str
            case 'in'
                set(view.evaluation.zoomHandle,'Enable','on','Direction','in');
                set(view.evaluation.zoomIn,'UserData',1);
                set(view.evaluation.zoomOut,'UserData',0);
            case 'out'
                set(view.evaluation.zoomHandle,'Enable','on','Direction','out');
                set(view.evaluation.zoomOut,'UserData',1);
                set(view.evaluation.zoomIn,'UserData',0);
        end
    case 1
        set(view.evaluation.zoomHandle,'Enable','off','Direction','in');
        set(view.evaluation.zoomOut,'UserData',0);
        set(view.evaluation.zoomIn,'UserData',0);
end
        
end

function pan(src, ~, view)
    set(view.evaluation.zoomHandle,'Enable','off','Direction','in');
    set(view.evaluation.zoomOut,'UserData',0);
    set(view.evaluation.zoomIn,'UserData',0);
    set(view.evaluation.rotate3dButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.evaluation.panButton,'UserData',1);
            set(view.evaluation.panHandle,'Enable','on');
        case 1
            set(view.evaluation.panButton,'UserData',0);
            set(view.evaluation.panHandle,'Enable','off');
    end
end

function rotate3d(src, ~, view)
    set(view.evaluation.zoomHandle,'Enable','off','Direction','in');
    set(view.evaluation.zoomOut,'UserData',0);
    set(view.evaluation.zoomIn,'UserData',0);
    set(view.evaluation.panHandle,'Enable','off');
    set(view.evaluation.panButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.evaluation.rotate3dButton,'UserData',1);
            set(view.evaluation.rotate3dHandle,'Enable','on');
        case 1
            set(view.evaluation.rotate3dButton,'UserData',0);
            set(view.evaluation.rotate3dHandle,'Enable','off');
    end
end

function setClim(UIControl, ~, model)
    evaluation = model.displaySettings.evaluation;
    field = get(UIControl, 'Tag');
    evaluation.(field) = str2double(get(UIControl, 'String'));
    evaluation.autoscale = 0;
    model.displaySettings.evaluation = evaluation;
end

function toggleAutoscale(~, ~, model, view)
    model.displaySettings.evaluation.autoscale = get(view.evaluation.autoscale, 'Value');
end

function changeClim(UIControl, ~, model, sign)
    evaluation = model.displaySettings.evaluation;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(evaluation.cap - evaluation.floor));
    evaluation.autoscale = 0;
    evaluation.(field) = evaluation.(field) + sign * dif;
    model.displaySettings.evaluation = evaluation;
end

function selectPlotType(src, ~, model)
    val = get(src,'Value');
    types = get(src,'String');
    model.displaySettings.evaluation.type = types{val};
end

function toggleLivePreview(~, ~, view, model)
    evaluation = model.displaySettings.evaluation;
    evaluation.preview = get(view.evaluation.livePreview, 'Value');
    if evaluation.preview
        evaluation.intFac = 1;
    end
    model.displaySettings.evaluation = evaluation;
end

function toggleDiscardInvalid(~, ~, view, model)
    model.displaySettings.evaluation.discardInvalid = get(view.evaluation.discardInvalid, 'Value');
end

function toggleInterpRayleigh(~, ~, view, model)
    model.parameters.evaluation.interpRayleigh = get(view.evaluation.interpRayleigh, 'Value');
    
    results = model.results;
    
    if model.parameters.evaluation.interpRayleigh
        peaksRayleigh_pos = results.peaksRayleigh_pos_interp;
        validity = results.validity_Brillouin & ~isnan(results.peaksRayleigh_pos_interp);
    else
        peaksRayleigh_pos = results.peaksRayleigh_pos_exact;
        validity = results.validity_Rayleigh & results.validity_Brillouin;
    end
    
    %% calculate the Brillouin shift in [pix]
    brillouinShift = abs(peaksRayleigh_pos-results.peaksBrillouin_pos);

    %% calculate the Brillouin shift in [GHz]
    calibration = model.parameters.calibration;
    
    wavelengthRayleigh = BE_SharedFunctions.getWavelengthFromMap(peaksRayleigh_pos, results.times, calibration);
    wavelengthBrillouin = BE_SharedFunctions.getWavelengthFromMap(results.peaksBrillouin_pos, results.times, calibration);
    
    brillouinShift_frequency = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(wavelengthBrillouin, wavelengthRayleigh));
    
    %% save the results
    results.BrillouinShift            = brillouinShift;           % [pix]  the Brillouin shift in pixels
    results.BrillouinShift_frequency  = brillouinShift_frequency; % [GHz]  the Brillouin shift in GHz
    results.peaksRayleigh_pos         = peaksRayleigh_pos;        % [pix]  the position of the Rayleigh peak(s) in the spectrum
    results.validity                  = validity;                 % [logical] the validity of the results
    model.results = results;
end

function setValue(src, ~, model, value)
    model.displaySettings.evaluation.(value) = str2double(get(src, 'String'));
end

function openNewFig(~, ~, view, model)
    view.evaluation.functions.plotData(view, model, 'ext');
end

function showSpectrum(~, ~, view, model)
     model.status.evaluation.showSpectrum = ~model.status.evaluation.showSpectrum;
     if model.status.evaluation.showSpectrum
            set(model.handles.results,'ButtonDownFcn',{@ImageClickCallback model});
            set(view.evaluation.axesImage,'ButtonDownFcn',{@ImageClickCallback model});
     else
            set(model.handles.results,'ButtonDownFcn',[]);
            set(view.evaluation.axesImage,'ButtonDownFcn',[]);
    end
end

function ImageClickCallback(~, event, model)

    data = model.results.(model.displaySettings.evaluation.type);
    data = double(data);
    data = nanmean(data,4);
    %% find non-singleton dimensions
    dimensions = size(data);
    dimension = sum(dimensions > 1);
    
    %% define possible dimensions and their labels
    dims = {'Y', 'X', 'Z'};
    dimslabel = {'y', 'x', 'z'};

    nsdims = cell(dimension,1);
    otherdims = cell(dimension,1);
    nsdimslabel = cell(dimension,1);
    ind = 0;
    ind2 = 0;
    for jj = 1:length(dimensions)
        if dimensions(jj) > 1
            ind = ind + 1;
            nsdims{ind} = dims{jj};
            nsdimslabel{ind} = dimslabel{jj};
        else
            ind2 = ind2 + 1;
            otherdims{ind2} = dims{jj};
        end
    end
    
    if (dimension > 1)
        position.X = event.IntersectionPoint(1);
        position.Y = event.IntersectionPoint(2);
        position.Z = event.IntersectionPoint(3);
    else
        position.([nsdims{1}]) = event.IntersectionPoint(1);
        position.([otherdims{1}]) = 0;
        position.([otherdims{2}]) = 0;
    end
    
    positions.X = ...
            model.parameters.positions.X - mean(model.parameters.positions.X(:));
    positions.Y = ...
            model.parameters.positions.Y - mean(model.parameters.positions.Y(:));
    positions.Z = ...
            model.parameters.positions.Z - mean(model.parameters.positions.Z(:));
    
    x_min = min(positions.X(:));
    x_max = max(positions.X(:));

    x_lin = linspace(x_min,x_max,model.parameters.resolution.X);
    
    y_min = min(positions.Y(:));
    y_max = max(positions.Y(:));

    y_lin = linspace(y_min,y_max,model.parameters.resolution.Y);
    
    z_min = min(positions.Z(:));
    z_max = max(positions.Z(:));

    z_lin = linspace(z_min,z_max,model.parameters.resolution.Z);

    [~, jj] = min(abs(x_lin-position.X));
    
    [~, kk] = min(abs(y_lin-position.Y));
    
    [~, ll] = min(abs(z_lin-position.Z));
    
    try
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    
    imgs = model.controllers.data.getPayload('data', jj, kk, ll);
    datestring = model.controllers.data.getPayload('date', jj, kk, ll);
    try
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    time = etime(datevec(date),datevec(refTime));
    
    spectrum = BE_SharedFunctions.getIntensity1D(imgs(:,:,1), model.parameters.extraction, time);
    
    figure(123);
    imagesc(imgs(:,:,1));
    caxis([100 500]);
    
    figure(124);
    plot(spectrum);
    ylim([100 500]);
end

function selectbright(~, ~, ~, model)

    defaultFileName = fullfile(pwd, '*.png');
    [baseFileName, folder] = uigetfile(defaultFileName, 'Select a file');
    if baseFileName == 0
        return;
    end
    
    fullFileName = fullfile(folder, baseFileName);

    I = imread(fullFileName);
    I = I(:,:,1);
    I = imcrop(I, [600 500 1500 1500]);
    model.results.brightfield_raw = I;
    overlayBrightfield(model);
end
    
function overlayBrightfield(model)

    model.parameters.evaluation.scaling = 0.086;
    model.parameters.evaluation.centerx = 800;
    model.parameters.evaluation.centery = 860;
    model.parameters.evaluation.rotationAngle = -135;

    scaling = model.parameters.evaluation.scaling;   % [micro m / pix]   scaling factor
    
    dims = {'Y', 'X', 'Z'};
    for jj = 1:length(dims)
        positions.([dims{jj} '_zm']) = ...
            model.parameters.positions.(dims{jj}) - mean(model.parameters.positions.(dims{jj})(:))*ones(size(model.parameters.positions.(dims{jj})));
    end
    
    maxx = max(max(positions.X_zm));
    minx = min(min(positions.X_zm));
    maxy = max(max(positions.Y_zm));
    miny = min(min(positions.Y_zm));
    
    width = (maxx - minx)/(scaling);
    height = (maxy - miny)/(scaling);
    
    startx = model.parameters.evaluation.centerx - width/2;
    starty = model.parameters.evaluation.centery - height/2;

    I = imrotate(model.results.brightfield_raw, model.parameters.evaluation.rotationAngle);
    model.results.brightfield_rot = I;
    
    I = imcrop(I, [startx starty width height]);
    
    x = linspace(minx, maxx, size(I,2));
    y = linspace(miny, maxy, size(I,1));
    [X,Y,Z] = meshgrid(x, y, 1);
    
    parameters = model.parameters;
    parameters.positions_brightfield.X = X;
    parameters.positions_brightfield.Y = Y;
    parameters.positions_brightfield.Z = Z;
    model.parameters = parameters;
    
    model.results.brightfield = I;
end

function getpstn(~, ~, view, model)
    valids = ~isnan(model.results.brightfield_rot);
    if isempty(model.results.brightfield_rot) || sum(valids(:)) == 0
        disp('Please load a brightfield image first.');
        return;
    end
    if isempty(model.file)
        disp('Please load a Brillouin file first.');
        return;
    end
    if isfield(view.overlay, 'parent') && ishandle(view.overlay.parent)
        return;
    else
        parent = figure('Position',[500,200,900,650]);
        % hide the menubar and prevent resizing
        set(parent, 'menubar', 'none', 'Resize','off');
    end

    view.overlay = BE_View.Overlay(parent, model);

    BE_Controller.Overlay(model, view);
end

function startMasking(~, ~, view, model)
    data = nanmean(model.results.BrillouinShift,4);
    dimensions = size(data);
    dimension = sum(dimensions > 1);
    if dimension ~= 2
        disp('Masking is only available for 2D data yet.');
        return;
    end
    
    if isfield(view.masking, 'parent') && ishandle(view.masking.parent)
        return;
    else
        parent = figure('Position',[500,200,900,650]);
        % hide the menubar and prevent resizing
        set(parent, 'menubar', 'none', 'Resize','off', 'units', 'pixels');
    end
    
    if ~isfield(model.results, 'masks')
        model.results.masks = struct();
    end
    
    model.tmp.masks = model.results.masks;
    
    model.displaySettings.masking.autoscale = model.displaySettings.evaluation.autoscale;
    model.displaySettings.masking.floor = model.displaySettings.evaluation.floor;
    model.displaySettings.masking.cap = model.displaySettings.evaluation.cap;

    view.masking = BE_View.Masking(parent, model);

    BE_Controller.Masking(model, view);
end

