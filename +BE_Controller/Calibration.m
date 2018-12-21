function callbacks = Calibration(model, view)
%% CALIBRATION Controller

    %% callbacks Calibration
    set(view.calibration.calibrateButton, 'Callback', {@calibrate, model, view});
    
    set(view.calibration.samples, 'Callback', {@selectSample, model});
    
    set(view.calibration.findPeaks, 'Callback', {@findPeaks, model});
    
    set(view.calibration.selectBrillouin, 'Callback', {@selectPeaks, view, model, 'Brillouin'});
    set(view.calibration.selectRayleigh, 'Callback', {@selectPeaks, view, model, 'Rayleigh'});
    
    set(view.calibration.peakTableBrillouin, 'CellEditCallback', {@editPeaks, model, 'Brillouin'});
    set(view.calibration.peakTableRayleigh, 'CellEditCallback', {@editPeaks, model, 'Rayleigh'});
    
    set(view.calibration.clearBrillouin, 'Callback', {@clearPeaks, model, 'Brillouin'});
    set(view.calibration.clearRayleigh, 'Callback', {@clearPeaks, model, 'Rayleigh'});
    
    set(view.calibration.clearCalibration, 'Callback', {@clearCalibration, model});
    set(view.calibration.overlay, 'Callback', {@setOverlay, model});
    
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
        'setActive', @()setActive(view), ...
        'findPeaks', @()findPeaks(0, 0, model), ...
        'setDefaultParameters', @()setDefaultParameters(model), ...
        'calibrateAll', @(selectPeaks)calibrateAll(model, view, selectPeaks), ...
        'updateCalibration', @()updateCalibration(model) ...
    );
end

function calibrateAll(model, view, selectPeaks)
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
            if selectPeaks
                findPeaks(0, 0, model);
            end
            drawnow;
            calibrate(0, 0, model, view);
            drawnow;
            model.log.log(['I/Calibration: Calibration of sample "' cals{jj} '" finished.']);
        catch
            model.log.log('E', ['Error: Calibration of sample "' cals{jj} '" failed.']);
        end
    end
    model.log.log('I/Calibration: Finished.');
end

function findPeaks(~, ~, model)
	%% selected calibration image
    %% store often used values in separate variables for convenience
    calibration = model.parameters.calibration;         % general calibration
    selectedMeasurement = calibration.selected;         % name of the selected calibration
    sample = calibration.samples.(selectedMeasurement); % selected sample
    
    %% read the calibration images
    if strcmp(selectedMeasurement, 'measurement')
        % either the first images of the measurement
        imgs = model.controllers.data.getPayload('data', sample.imageNr.x, sample.imageNr.y, sample.imageNr.z);
        datestring = model.controllers.data.getPayload('date', sample.imageNr.x, sample.imageNr.y, sample.imageNr.z);
    else
        % or all images of the selected calibration measurement
        imgs = model.controllers.data.getCalibration('data', sample.position);
        datestring = model.controllers.data.getCalibration('date', sample.position);
    end
    
    %% handle timepoints
    % get the reference timepoint and convert the calibration date to a date object
    try
        % old timestamp format without milliseconds
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        % new timestamp format with higher precision
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    % calculate duration since beginning of measurement
    time = etime(datevec(date), datevec(refTime));
    
    %% handle images and roughly find peaks
    imgs = medfilt1(imgs,3);    % median filter to remove salt and pepper noise
    img = nanmean(imgs, 3);
    %% Overlay the calibration image with a measurement image if requested
    if sample.overlay
        img = BE_SharedFunctions.overlayMeasurementImage(model, img, calibration.selectedValue);
    end
    data = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction, time);
    
    [peaks.height, peaks.locations, peaks.widths, peaks.proms] = findpeaks(data, 'Annotate', 'extents', 'MinPeakProminence', calibration.peakProminence);
    
    %% we want to find the peaks closest to the center of mass
    %  They are likely the Stokes peaks of the first order and the
    %  Anti-Stokes peaks of the second order. Since the frequency axis is
    %  non-linear, we choose the n/2 peaks on the left and n/2 on the right
    %  of the CoM. Otherwise we might find a peak closer to the CoM which
    %  does not belong to the wanted ones.
    
    % find the center of mass for the spectrum
    spectrum = data - min(data(:));
    spectrum(isnan(spectrum)) = 0;
    CoM = sum(spectrum .* (1:length(spectrum))) / sum(spectrum(:));
    
    nrPeaks = length(calibration.peakTypes);
    nrPeaksLeft = ceil(nrPeaks/2);
    nrPeaksRight = floor(nrPeaks/2);
    
    inds = 1:length(peaks.locations);
    locs = (peaks.locations - CoM);
    
    % peaks left of CoM
    indsl = inds(locs < 0);
    nrPeaksLeft = min([nrPeaksLeft length(indsl)]);
    indsl = sort(indsl, 'descend');
    indsl = indsl(1:nrPeaksLeft);
    
    % peaks right of CoM
    indsr = inds(locs > 0);
    nrPeaksRight = min([nrPeaksRight length(indsr)]);
    indsr = sort(indsr, 'ascend');
    indsr = indsr(1:nrPeaksRight);
    
    % create index array
    inds = sort([indsl indsr]);
    
    % chose selected peaks
    peaks.locations = peaks.locations(inds);
    peaks.height = peaks.height(inds);
    peaks.widths = peaks.widths(inds);
    peaks.proms = peaks.proms(inds);
    
    %% sort the peaks by Rayleigh and Brillouin
    sample.indRayleigh = [];
    sample.indBrillouin = [];
    Rayleigh_int = [];
    Brillouin_int = [];
    for jj = 1:length(calibration.peakTypes)
        try
            % find Rayleigh peaks
            if strcmp(calibration.peakTypes{jj}, 'R')
                sample.indRayleigh = [sample.indRayleigh; round(peaks.locations(jj) + peaks.widths(jj) * [-3 3])];
                Rayleigh_int = [Rayleigh_int; peaks.proms(jj)]; %#ok<AGROW>
            end
            % find Brillouin peaks
            if strcmp(calibration.peakTypes{jj}, 'B')
                sample.indBrillouin = [sample.indBrillouin; round(peaks.locations(jj) + peaks.widths(jj) * [-1.5 1.5])];
                Brillouin_int = [Brillouin_int; peaks.proms(jj)]; %#ok<AGROW>
            end
        catch
        end
    end
    
    %% Merge the Brillouin peaks
    indBrillouin = NaN(2, 2);
    indBrillouin(1, 1) = sample.indBrillouin(1, 1);
    indBrillouin(1, 2) = sample.indBrillouin(sample.nrBrillouinSamples, 2);
    indBrillouin(2, 1) = sample.indBrillouin(sample.nrBrillouinSamples+1, 1);
    indBrillouin(2, 2) = sample.indBrillouin(end, 2);
    sample.indBrillouin = indBrillouin;
    
    %% The Brillouin and Rayleigh peaks should have approx. the same height, respectively
    %  if not, there is likely something wrong
    try
        Rayleigh_dif = abs(Rayleigh_int(1) - Rayleigh_int(2)) / max(Rayleigh_int(:));
        if ~mod(size(Brillouin_int,1), 2)
            Brillouin_int = reshape(Brillouin_int, [], 2);
            Brillouin_int(2,:) = fliplr(Brillouin_int(2,:));
            difference = abs(Brillouin_int(1,:) - Brillouin_int(2,:)) ./ max(Brillouin_int, [], 1);
            Brillouin_dif = max(difference(:));
        else
            Brillouin_dif = 0;
        end
        if Rayleigh_dif > 0.4 || Brillouin_dif > 0.4
            model.log.log('E', ['Error: Peak detection of sample "' selectedMeasurement '" likely failed. Please check.']);
        end
    catch
        model.log.log('E', ['Error: There were less than two Rayleigh and Brillouin peaks found for sample "' ...
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
    try
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
        datestring = datetime(sample.time, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
        datestring = datetime(sample.time, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
	calibration.times(sample.position) = etime(datevec(datestring), datevec(refTime));
    
    %% find the positions of the Rayleigh and Brillouin peaks    
    if strcmp(selectedMeasurement, 'measurement')
        imgs = model.controllers.data.getPayload('data', sample.imageNr.x, sample.imageNr.y, sample.imageNr.z);
        datestring = model.controllers.data.getPayload('date', sample.imageNr.x, sample.imageNr.y, sample.imageNr.z);
    else
        imgs = model.controllers.data.getCalibration('data', sample.position);
        datestring = model.controllers.data.getCalibration('date', sample.position);
    end
    try
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    time = etime(datevec(date), datevec(refTime));
    
    indRayleigh = sample.indRayleigh;
    indBrillouin = sample.indBrillouin;
    nrPeaks = size(indRayleigh,1) + sample.nrBrillouinSamples*size(indBrillouin,1);
    if size(indRayleigh,1) ~= 2
        errorStr = ['Please select two Rayleigh peaks for sample "' selectedMeasurement '".'];
        ex = MException('MATLAB:toLessValues', errorStr);
        model.log.log('E', ['Error: ' errorStr]);
        disp(ex.message);
        return;
    end
    if size(indBrillouin,1) < 2
        errorStr = ['Please select at least one pair of Brillouin peaks for sample "' selectedMeasurement '".'];
        ex = MException('MATLAB:toLessValues', errorStr);
        
        model.log.log('E', ['Error: ' errorStr]);
        disp(ex.message);
        return;
    end
    if mod(size(indBrillouin,1),2)
        errorStr = ['Please select an even number of Brillouin peaks for sample "' selectedMeasurement '".'];
        ex = MException('MATLAB:toLessValues', errorStr);
        
        model.log.log('E', ['Error: ' errorStr]);
        disp(ex.message);
        return;
    end
    
    %% prepare variables for parfoor loop
    extraction = model.parameters.extraction;
    fwhm = model.parameters.evaluation.fwhm;
    
    imgs = medfilt1(imgs,3);
    
    % set invalid values to NaN
    imgs(imgs >= (2^16 - 1)) = NaN;
    
    data = BE_SharedFunctions.getIntensity1D(imgs(:,:,1), extraction, time);
    nrPositions = size(data,2)/0.1;
    calibration.pixels = linspace(1,size(data,2),nrPositions);
    
    pixels = calibration.pixels;
    constants = model.parameters.constants_setup;
    constants.c = model.parameters.constants_general.c;

    %% calculate dependent values
    constants.f_0 = constants.c/constants.lambda0;                                              % [Hz]  frequency of the laser
    constants.VIPA.FSR = constants.c/(2*constants.VIPA.n*constants.VIPA.d*cos(constants.VIPA.theta));   %[Hz]  free spectral range of the VIPAs
    constants.VIPA.m = round(constants.c/(constants.lambda0 * constants.VIPA.FSR));                 % [1]   order
    
    %% get the Brillouin shift of the calibration sample from the setup constants
    sample.shift = constants.calibration.shifts;
    sample.nrBrillouinSamples = constants.calibration.nrBrillouinSamples;
    
    model.parameters.constants_setup = constants;
    
    %%
    nrImages = size(imgs,3);
    offset = NaN(nrImages,length(pixels));
    frequencies = offset;
    
    %%
    
    A = NaN(1, nrImages);
    B = A;
    C = A;
    FSR = A;
    error = A;
    peaksMeasured = NaN(nrImages, nrPeaks);
    peaksFitted = peaksMeasured;
    view.calibration.progressBar.setValue(0);
    view.calibration.progressBar.setString(sprintf('%01.0f%%', 0));
    
    for mm = 1:nrImages
        data = BE_SharedFunctions.getIntensity1D(imgs(:,:,mm), extraction, time);
        dataRayleigh = data;
        
        %% Overlay the calibration image with a measurement image if requested
        % we only take into account the Rayleigh peak region, because we
        % don't want to alter the Brillouin region with peaks from the
        % sample
        if sample.overlay
            overlayedImage = BE_SharedFunctions.overlayMeasurementImage(model, imgs(:,:,mm), calibration.selectedValue);
            dataRayleigh = BE_SharedFunctions.getIntensity1D(overlayedImage, extraction, time);
        end

%         nrPositions = size(data,2)/0.1;
%         calibration.pixels = linspace(1,size(data,2),nrPositions);

        %% find the measured peaks
        peakPos = NaN(1, nrPeaks);
        for jj = 1:length(indRayleigh)
            spectrumSection = dataRayleigh(indRayleigh(jj,1):indRayleigh(jj,2));
            [tmp, ~, ~] = BE_SharedFunctions.fitLorentzDistribution(spectrumSection, fwhm, 1, [6 20], 0);
            peakPos(jj) = tmp+indRayleigh(jj,1)-1;
        end
        for jj = 1:2
            spectrumSection = data(indBrillouin(jj,1):indBrillouin(jj, 2));
            [tmp, ~, ~] = BE_SharedFunctions.fitLorentzDistribution(spectrumSection, fwhm, sample.nrBrillouinSamples, [6 20], 0);
            peakPos(2*jj-1+length(indRayleigh)) = tmp(1) + indBrillouin(jj, 1)-1;
            peakPos(2*jj+length(indRayleigh)) = tmp(2) + indBrillouin(jj, 1)-1;
        end
        peakPos = sort(peakPos, 'ascend');
        peaksMeasured(mm,:) = peakPos;

        %% find the fitted peaks, do the VIPA fit
        [VIPAparams, peakPos] = fitVIPA(peakPos, constants);

        A(mm) = VIPAparams.A;
        B(mm) = VIPAparams.B;
        C(mm) = VIPAparams.C;
        FSR(mm) = VIPAparams.FSR;
        error(mm) = VIPAparams.error;

        peakPos = sort(peakPos, 'ascend');
        peaksFitted(mm,:) = peakPos;
        
        params = [VIPAparams.A, VIPAparams.B, VIPAparams.C, VIPAparams.FSR];
        frequencies(mm, :) = VIPAtheory(pixels, params, constants.f_0);

        offset(mm,:) = interp1(peaksFitted(mm,:), peaksMeasured(mm,:) - peaksFitted(mm,:), pixels, 'spline');

        %% show progress
        val = mm*100/nrImages;
        view.calibration.progressBar.setValue(val);
        view.calibration.progressBar.setString(sprintf('%01.0f%%', val));
    end

    %% store variables which were separated for parfor loop in structure again
    sample.peaksMeasured = peaksMeasured;
    sample.peaksFitted = peaksFitted;
    sample.values.A = A;
    sample.values.B = B;
    sample.values.C = C;
    sample.values.FSR = FSR;
    sample.values.error = error;
    sample.frequencies = frequencies;
    sample.offset = offset;
    
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
    
    [frequency, offset] = averageCalibration(sample, calibration.weighted);
    calibration.frequency(sample.position,1:size(frequency,2)) = frequency;
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

function [frequency, offset] = averageCalibration(sample, weight)
    try
        if weight
            %% average the single calibrations according to their uncertainty
            frequency = sample.frequencies(logical(sample.active), :);          % wavelengths from calibration, only select active calibration images
            offset = sample.offset(logical(sample.active), :);                  % offset from the calibration, only select active calibration images
            weights = repmat(sample.values.error(:,logical(sample.active)).', 1, size(frequency,2));  % map of the weights, only select active calibration images
            weights(isnan(frequency)) = NaN;                                    % set weights to NaN in case wavelength is NaN
            norm = repmat(nansum(1./weights,1), size(frequency,1), 1);          % calculate the normalization value

            weights = 1 ./ (norm .* weights);

            frequency = nansum((frequency .* weights), 1);                      % calculate the weighted average of the wavelengths
            offset = nansum((offset .* weights), 1);                            % calculate the weighted average of the offset
        else
            frequency = nanmean(sample.frequencies,1);
            offset = nanmean(sample.offset,1);
        end
    catch
        disp('Please run the calibration for this sample again.');
        frequency = NaN;
        offset = NaN;
    end
end

function updateMeasurementBrillouinShift(model)
    try
        %% Calculate the frequency of the Brillouin shift
        frequencyRayleigh = BE_SharedFunctions.getFrequencyFromMap(...
            model.results.peaksRayleigh_pos, model.results.times, model.parameters.calibration);
        frequencyBrillouin = BE_SharedFunctions.getFrequencyFromMap(...
            model.results.peaksBrillouin_pos, model.results.times, model.parameters.calibration);

        model.results.BrillouinShift_frequency = abs(frequencyBrillouin - frequencyRayleigh);

        %% Calculate the FWHM of the peaks
        frequencyLeftSlope = BE_SharedFunctions.getFrequencyFromMap(...
            model.results.peaksBrillouin_pos - model.results.peaksBrillouin_fwhm/2, model.results.times, model.parameters.calibration);
        frequencyRightSlope = BE_SharedFunctions.getFrequencyFromMap(...
            model.results.peaksBrillouin_pos + model.results.peaksBrillouin_fwhm/2, model.results.times, model.parameters.calibration);

        model.results.peaksBrillouin_fwhm_frequency = abs(frequencyLeftSlope - frequencyRightSlope);
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
    try
        refTime = datetime(startTime, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        refTime = datetime(startTime, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    
    for jj = 1:length(samples)
        sample = calibration.samples.(samples{jj});
        if ~isempty(sample.peaksMeasured)
            try
                datestring = datetime(sample.time, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
            catch
                datestring = datetime(sample.time, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
            end
            calibration.times(sample.position) = etime(datevec(datestring),datevec(refTime));
            times = calibration.times(sample.position) * ones(size(sample.peaksMeasured));
            frequencies = BE_SharedFunctions.getFrequencyFromMap(sample.peaksMeasured, times, calibration);
            
            Brillouin = frequencies(:,2:(end-1));
            Rayleigh = repelem(frequencies(:,[1, end]),1,length(sample.shift));
            sample.BrillouinShift = abs(Rayleigh - Brillouin);
            
            calibration.samples.(samples{jj}) = sample;
        end
    end
    model.parameters.calibration = calibration;
end

function setOverlay(src, ~, model)
    model.parameters.calibration.samples.(model.parameters.calibration.selected).overlay = get(src, 'Value');
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

function updateCalibration(model)
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
        if isfield(sample, 'frequencies') && ~isempty(sample.frequencies)
            [frequency, offset] = averageCalibration(sample, calibration.weighted);
            calibration.frequency(sample.position,:) = frequency;
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

function toggleActiveState(~, table, model)
    sample = model.parameters.calibration.samples.(model.parameters.calibration.selected);
    calibration = model.parameters.calibration;
    if table.Indices(2) == 7
        sample.active(table.Indices(1)) = table.NewData;
    end
    calibration.samples.(model.parameters.calibration.selected) = sample;
    
    if isfield(sample, 'frequencies') && ~isempty(sample.frequencies)
        [frequency, offset] = averageCalibration(sample, calibration.weighted);
        calibration.frequency(sample.position,:) = frequency;
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
        'A',            [], ... % []    
        'B',            [], ... % []    
        'C',            [], ... % []    
        'FSR',          [], ... % [GHZ] 
        'error',        [] ...  % [GHz]
    );
    calibration.samples.(selectedMeasurement).frequencies = [];
    pos = calibration.samples.(selectedMeasurement).position;
    calibration.times(pos) = NaN;
    calibration.frequency(pos,:) = NaN;
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

function [VIPAparams, peakPosFitted] = fitVIPA(peaks, const)
    %% FITVIPA
    %   this function fits the VIPA parameters to the measured peaks. To
    %   calculate the Parameters, 2 Rayleigh peaks and 2 Brillouin peaks within
    %   one FSR are required
    % 
    %   ##INPUT
    %   peakPos:        [m]     peak locations on the camera
    %   constants =
    %          VIPA: struct
    %                  d:   [m]     width of the cavity
    %                  n:   [1]     refractive index
    %              theta:   [rad]   angle of the VIPA
    %              order:   [1]     observed order of the VIPA spectrum
    %             c:    [m/s]   speed of light
    %             F:    [m]     focal length of the lens behind the VIPA
    %     pixelSize:    [m]     pixel size of the camera
    %       lambda0:    [m]     laser wavelength
    %     calibration: struct
    %             shifts:   [Hz]    calibration shift frequency
    % nrBrillouinSamples:   [1]     number of Brillouin calibration samples
    % 
    %   ##OUTPUT
    %   VIPAparams =
    %             A:    []      
    %             B:    []      
    %             C:    []      
    %           FSR:    []      
    
    %% Calculate start parameters for the fit
    a = (2*pi*const.VIPA.n*const.VIPA.d*cos(const.VIPA.theta)) / const.c;
    b = -(2*pi*const.VIPA.n*const.VIPA.d*tan(const.VIPA.theta)) / (const.c*const.F) * sqrt(1 - (const.VIPA.n*sin(const.VIPA.theta))^2);
    c = -pi/const.c*const.VIPA.d*cos(const.VIPA.theta) / (const.F^2);
    r0 = peaks(1)*const.pixelSize;
    A = (a + b*r0 + c*r0^2) / ((const.VIPA.m + const.VIPA.order)*pi);
    B = (b + 2*c*r0) / ((const.VIPA.m + const.VIPA.order)*pi)*const.pixelSize;
    C = c / ((const.VIPA.m + const.VIPA.order)*pi)*const.pixelSize^2;
    start = [A, B, C, 1e-9*const.VIPA.FSR];
    start = 1e9 * start; % normalize to GHz
    
    %% Fitting
    % define theoretical frequency function
    model = @(x, params) VIPAtheory(x, params, const.f_0);
    
    shifts = [ ...
        0, ...
        const.calibration.shifts(1), ...
        const.calibration.shifts(2), ...
        -const.calibration.shifts(2), ...
        -const.calibration.shifts(1), ...
        0 ...
    ];
    
    errorFunction = @(parameters) calibrationfunc(model, parameters, peaks, 1e-9*shifts);
    options = optimset('MaxFunEvals', 100000, 'MaxIter', 100000, 'TolFun', 1e-8, 'TolX', 1e-8);

    [fitted, deviation, ~, ~] = fminsearch(errorFunction, start, options);

    %% return fitted parameters
    VIPAparams = {};
    VIPAparams.A = fitted(1);
    VIPAparams.B = fitted(2);
    VIPAparams.C = fitted(3);
    VIPAparams.FSR = fitted(4);
    VIPAparams.error = deviation;

    % position of the two Rayleigh peaks and the Stokes and Anti-Stokes peaks
    [peakPosFitted] = BE_SharedFunctions.peakPosition(VIPAparams, const, 1e-9*(shifts + [0 0 0 VIPAparams.FSR VIPAparams.FSR VIPAparams.FSR]));
end

function [error, fitted] = calibrationfunc(model, parameters, x, shifts)
    fitted = model(x, parameters);
    
    FSR = parameters(4);
    
    % The values should fit the theoretical frequencies
    errorVector = fitted - shifts - 1e-9*[0 0 0 FSR FSR FSR];
    
    % The found Brillouin shifts should be equal for Stokes and Anti-Stokes
    errorVector1 = [(fitted(2)-fitted(1))-(fitted(6)-fitted(5)), ...
                    (fitted(3)-fitted(1))-(fitted(6)-fitted(4))];
    
	% The Brillouin shifts should fit the theoretical Brillouin shifts
    vB = [ ...
        shifts(2) - shifts(1), ...
        shifts(3) - shifts(1), ...
        shifts(6) - shifts(4), ...
        shifts(6) - shifts(5) ...
    ];
    vB1 = [ ...
        fitted(2) - fitted(1), ...
        fitted(3) - fitted(1), ...
        fitted(6) - fitted(4), ...
        fitted(6) - fitted(5) ...
    ];
    errorVector2 = vB - vB1;
    
    error = sum(errorVector.^2) + sum(errorVector1.^2) + sum(errorVector2.^2);
end

function frequency = VIPAtheory(x, params, f_0)
    % define theoretical frequency function
    frequency = 1 ./ (params(1) + params(2)*x + params(3)*x.^2) - 1e-9*f_0;  % returns frequency in GHz
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
    calibration = plot(ax, 1e-9*calibrationFrequency, 'color', [0.8500    0.3250    0.0980]);
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