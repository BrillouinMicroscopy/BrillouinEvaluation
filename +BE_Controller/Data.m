function callbacks = Data(model, view)
%% DATA Controller

    %% general panel
    set(view.menubar.fileOpen, 'Callback', {@selectLoadData, model});
    set(view.menubar.fileClose, 'Callback', {@closeFile, model});
    set(view.menubar.fileSave, 'Callback', {@selectSaveData, model});
    
    set(view.data.repetition, 'Callback', {@selectRepetition, model});
    
    set(view.data.setup, 'Callback', {@selectSetup, model});
    
    set(view.data.vertically, 'Callback', {@toggleVertically, model, view});
    set(view.data.horizontally, 'Callback', {@toggleHorizontally, model, view});
    set(view.data.rotation, 'Callback', {@setRotation, model, view});

    callbacks = struct( ...
        'setActive', @()setActive(view), ...
        'closeFile', @()closeFile('', '', model), ...
        'load', @(filePath)loadData(model, filePath), ...
        'save', @(filePath)saveData(model, filePath), ...
        'setParameters', @(parameters)setParameters(model, parameters), ...
        'getPayload', @(type, indX, indY, indZ)getPayload(model, type, indX, indY, indZ), ...
        'getCalibration', @(type, index)getCalibration(model, type, index), ...
        'getBackground', @(type)getBackground(model, type, index) ...
    );
end

function setActive(view)
    tabgroup = get(view.data.parent, 'parent');
    tabgroup.SelectedTab = view.data.parent;
end

function setParameters(model, parameters)
    model.parameters = copyFields(model.parameters, parameters);
    
    %% recursively copy parameters into model
    function target = copyFields(target, source)
        for fn = fieldnames(source).'
            if isstruct(source.(fn{1}))
                target.(fn{1}) = copyFields(target.(fn{1}), source.(fn{1}));
            else
                target.(fn{1}) = source.(fn{1});
            end
        end
    end
end

function selectLoadData(~, ~, model)
    [FileName,PathName,~] = uigetfile('*.h5','Select the Brillouin file to evaluate.');
    filePath = [PathName FileName];
    model.repetition = 0;
    loadData(model, filePath);
end

function loadData(model, filePath)
    model.reset;
    % Load the h5bm data file
    model.log.log(['I/File: Opened file "' filePath '"']);
    if isempty(filePath) || ~sum(filePath)
        return
    end
    [PathName, name, extension] = fileparts(filePath);
    model.filepath = [PathName '\'];
    if ~isequal(PathName,0) && exist(filePath, 'file')
        
        model.filename = [name extension];
        file = BE_Utils.HDF5Storage.h5bmread(filePath);
        
        model.repetitionCount = getRepetitionCount(file);
        if (model.repetition >= model.repetitionCount) 
            model.repetition = model.repetitionCount - 1;
        end
        
        model.file = file;
        
        try
            delete(model.handles.plotPositions);
        catch
        end
        
        model.handles = struct( ...
            'results', NaN, ...
            'plotPositions', NaN ...
        );
        
        %% check if a corresponding results file exists
        [~, filename, ~] = fileparts(model.filename);
        if (model.repetitionCount > 1)
            defaultPath = [model.filepath '..\EvalData\' filename '_rep' num2str(model.repetition) '.mat'];
        else
            defaultPath = [model.filepath '..\EvalData\' filename '.mat'];
        end
        if exist(defaultPath, 'file') == 2
            data = load(defaultPath, 'results');
            
            parameters = data.results.parameters;
            results = data.results.results;
            displaySettings = data.results.displaySettings;
            
            % if no version field is set, file is very old, set to 0.0.0
            if ~isfield(parameters, 'programVersion')
                parameters.programVersion = struct( ...
                    'major', 0, ...
                    'minor', 0, ...
                    'patch', 0, ...
                    'preRelease', '' ...
                );
            end
            
            %% break if file to load is newer than the program
            if parameters.programVersion.major > model.programVersion.major
                disp('The file to load was created by a newer version of this program. Please update.');
                return;
            end
            
            version = sprintf('%d.%d.%d', model.programVersion.major, model.programVersion.minor, model.programVersion.patch);
            if ~strcmp('', model.programVersion.preRelease)
                version = [version '-' model.programVersion.preRelease];
            end
            
            %% migration steps for files coming from versions older than 1.0.0
            if parameters.programVersion.major < 1
                fprintf('Migrating evaluation file to version %s.\n', version);
                
                % displaySettings
                if ~isfield(displaySettings.evaluation, 'intFac')
                    displaySettings.evaluation.intFac = 1;
                end
                
                if ~isfield(displaySettings.evaluation, 'valThreshould')
                    displaySettings.evaluation.valThreshould = 25;
                end
                
                % calibrations
                if ~isfield(parameters.calibration, 'wavelength')
                    parameters.calibration.wavelength = [];
                end

                if ~isfield(parameters.calibration, 'extrapolate')
                    parameters.calibration.extrapolate = false;
                end

                if ~isfield(parameters.calibration, 'weighted')
                    parameters.calibration.weighted = true;
                end

                if ~isfield(parameters.calibration, 'correctOffset')
                    parameters.calibration.correctOffset = false;
                end

                if ~isfield(parameters.calibration, 'times')
                    parameters.calibration.times = [];
                end

                if ~isfield(parameters.calibration, 'pixels')
                    parameters.calibration.pixels = [];
                end

                %% read in all calibration measurements
                if isfield(parameters.calibration, 'values_mean')
                    parameters.calibration = rmfield(parameters.calibration, 'values_mean');
                end
                if isfield(parameters.calibration, 'values')
                    parameters.calibration = rmfield(parameters.calibration, 'values');
                end
                
                %% check if all calibration samples are present, load them if not
                oldSamples = parameters.calibration.samples;
                [allSamples, ~] = readCalibrationSamples(model);
                allSampleKeys = fields(allSamples);
                oldSampleKeys = fields(oldSamples);
                if (length(fields(oldSamples)) < length(allSampleKeys))
                    parameters.calibration.samples = allSamples;
                    for jj = 1:length(allSampleKeys)
                        sample = parameters.calibration.samples.(allSampleKeys{jj});
                        for ii = 1:length(oldSampleKeys)
                            oldSample = oldSamples.(oldSampleKeys{ii});
                            if isfield(oldSample, 'position')
                                if sample.position == oldSample.position
                                    if isfield(oldSample, 'Brillouin')
                                        parameters.calibration.samples.(allSampleKeys{jj}).indBrillouin = oldSample.Brillouin;
                                    end
                                    if isfield(oldSample, 'Rayleigh')
                                        parameters.calibration.samples.(allSampleKeys{jj}).indRayleigh = oldSample.Rayleigh;
                                    end
                                end
                            end
                        end
                    end
                end
                
                %% check all calibration samples
                sampleKeys = fields(parameters.calibration.samples);
                for jj = 1:length(sampleKeys)
                    sample = parameters.calibration.samples.(sampleKeys{jj});
                    
                    % check if calibration comes from the measurement
                    if strcmp(sampleKeys{jj}, 'measurement')
                        % set the position value to the number of calibrations
                        if ~isfield(sample, 'position')
                            sample.position = length(sampleKeys);
                        end
                        if ~isfield(sample, 'time')
                            sample.time = getPayload(model, 'date', sample.imageNr.x, sample.imageNr.y, sample.imageNr.z);
                        end
                    else
                        if ~isfield(sample, 'time')
                            sample.time = getCalibration(model, 'date', sample.position);
                        end
                        if ~isfield(sample, 'nrImages')
                            data = getCalibration(model, 'data', sample.position);
                            nrImages = size(data,3);
                            sample.nrImages = nrImages;
                            sample.active = ones(nrImages,1);
                        end
                    end

                    if ~isfield(sample, 'indRayleigh') && isfield(sample, 'Rayleigh')
                        sample.indRayleigh = sample.Rayleigh;
                        sample = rmfield(sample, 'Rayleigh');
                    end

                    if ~isfield(sample, 'indBrillouin') && isfield(sample, 'Brillouin')
                        sample.indBrillouin = sample.Brillouin;
                        sample = rmfield(sample, 'Brillouin');
                    end
                    
                    if ~isfield(sample, 'values')
                        sample.values = struct( ...   % struct with all values
                            'd',        [], ... % [m]   width of the cavity
                            'n',        [], ... % [1]   refractive index of the VIPA
                            'theta',    [], ... % [rad] angle of the VIPA
                            'x0Initial',[], ... % [m]   offset for fitting
                            'x0',       [], ... % [m]   offset for fitting, corrected for each measurement
                            'xs',       [], ... % [1]   scale factor for fitting
                            'error',    []  ... % [1]   uncertainty of the fit
                        );
                    end
                    
                    parameters.calibration.samples.(sampleKeys{jj}) = sample;
                end
                % set version to 1.0.0 to allow further migration steps
                % possibly necessary for future versions
                parameters.programVersion = struct( ...
                    'major', 1, ...
                    'minor', 0, ...
                    'patch', 0, ...
                    'preRelease', '' ...
                );
            end
            %% migration steps for files coming from versions older than 1.1.0
            if parameters.programVersion.major <= 1 && (parameters.programVersion.minor < 1 ...
                    || (parameters.programVersion.minor <= 1 && ~isempty(parameters.programVersion.preRelease)))
                if ~isfield(results, 'peaksRayleigh_int')
                    results.peaksRayleigh_int = NaN(size(results.peaksRayleigh_pos));
                end
                if ~isfield(results, 'peaksRayleigh_fwhm')
                    results.peaksRayleigh_fwhm = NaN(size(results.peaksRayleigh_pos));
                end
                if ~isfield(results, 'peaksBrillouin_fwhm_frequency')
                    results.peaksBrillouin_fwhm_frequency = NaN(size(results.peaksRayleigh_pos));
                end
                if ~isfield(results, 'peaksRayleigh_pos_exact')
                    results.peaksRayleigh_pos_exact = NaN(size(results.peaksRayleigh_pos));
                end
                if ~isfield(results, 'peaksRayleigh_pos_interp')
                    results.peaksRayleigh_pos_interp = NaN(size(results.peaksRayleigh_pos));
                end
                if ~isfield(results, 'validity_Rayleigh')
                    results.validity_Rayleigh = results.validity;
                end
                if ~isfield(results, 'validity_Brillouin')
                    results.validity_Brillouin = results.validity;
                end
                if ~isfield(results, 'masks')
                    results.masks = struct();
                end
                if ~isfield(parameters.evaluation, 'interpRayleigh')
                    parameters.evaluation.interpRayleigh = true;
                end
                if ~isfield(parameters, 'masking')
                    parameters.masking = struct( ...
                        'brushSize', 40, ...        % [micro m] size of the brush
                        'adding', 1 ...             % [logical] add or delete mask
                    );
                end
                if ~isfield(parameters.constants, 'cavitySlope')
                    parameters.constants.cavitySlope = -3840;
                end
                if ~isfield(displaySettings, 'masking')
                    displaySettings.masking = struct( ...                    
                        'autoscale', true, ...
                        'floor', 100, ...
                        'cap', 500, ...
                        'selected', '', ...
                        'showOverlay', true ...
                    );
                end
                % set version to 1.1.0 to allow further migration steps
                % possibly necessary for future versions
                parameters.programVersion = struct( ...
                    'major', 1, ...
                    'minor', 1, ...
                    'patch', 0, ...
                    'preRelease', '' ...
                );
            end
            %% migration steps for files coming from versions older than 1.2.0
            if parameters.programVersion.major <= 1 && (parameters.programVersion.minor < 2 ...
                    || (parameters.programVersion.minor <= 2 && ~isempty(parameters.programVersion.preRelease)))
                if ~isfield(parameters.calibration, 'peakProminence')
                    parameters.calibration.peakProminence = 20;
                end
                if ~isfield(parameters.calibration, 'peakTypes')
                    parameters.calibration.peakTypes = {'R', 'B', 'B', 'B' ,'B', 'R'};
                end
                if ~isfield(parameters.evaluation, 'peakTypes')
                    parameters.evaluation.minRayleighPeakHeight = 50;
                end
                if ~isfield(parameters.extraction, 'currentCalibrationNr')
                    parameters.extraction.currentCalibrationNr = 1;
                end
                if ~isfield(parameters.extraction, 'times')
                    % for previous version this is the time of the first
                    % calibration measurement
                    try
                        parameters.extraction.times = parameters.calibration.times(1);
                    catch
                    % if that doesn't work, fall back to default value (no
                    % huge difference)
                        parameters.extraction.times = 0;
                    end
                end
                if ~isfield(parameters.extraction, 'calibrations')
                    parameters.extraction.calibrations(1) = struct( ...
                        'peaks', struct( ...                        % position of the peaks for localising the spectrum
                            'x', parameters.extraction.peaks.x, ... % [pix] x-position
                            'y', parameters.extraction.peaks.y ...  % [pix] y-position
                        ), ...
                        'circleFit', parameters.extraction.circleFit ...
                    );
                    parameters.extraction = rmfield(parameters.extraction, 'peaks');
                    parameters.extraction = rmfield(parameters.extraction, 'circleFit');
                end
                if ~isfield(parameters, 'exposureTime')
                    parameters.exposureTime = 0.5;
                end
                if isfield(parameters.extraction, 'r0')
                    parameters.extraction = rmfield(parameters.extraction, 'r0');
                end
                if isfield(parameters.extraction, 'x0')
                    parameters.extraction = rmfield(parameters.extraction, 'x0');
                end
                if isfield(parameters.extraction, 'y0')
                    parameters.extraction = rmfield(parameters.extraction, 'y0');
                end
                % set version to 1.2.0 to allow further migration steps
                % possibly necessary for future versions
                parameters.programVersion = struct( ...
                    'major', 1, ...
                    'minor', 2, ...
                    'patch', 0, ...
                    'preRelease', '' ...
                );
            end
            %% migration steps for files coming from versions older than 1.3.0
            if parameters.programVersion.major <= 1 && (parameters.programVersion.minor < 3 ...
                    || (parameters.programVersion.minor <= 3 && ~isempty(parameters.programVersion.preRelease)))
                if ~isfield(parameters.data, 'rotate')
                    parameters.data = model.defaultParameters.data;
                end
                % set version to 1.3.0 to allow further migration steps
                % possibly necessary for future versions
                parameters.programVersion = struct( ...
                    'major', 1, ...
                    'minor', 3, ...
                    'patch', 0, ...
                    'preRelease', '' ...
                );
            end
            %% migration steps for files coming from versions older than 1.4.0
            if parameters.programVersion.major <= 1 && (parameters.programVersion.minor < 4 ...
                    || (parameters.programVersion.minor <= 4 && ~isempty(parameters.programVersion.preRelease)))
                
                if ~isfield(parameters, 'constants_general')
                    parameters.constants_general = model.defaultParameters.constants_general;
                end
                if ~isfield(parameters, 'constants_setup')
                    parameters.constants_setup = model.availableSetups.S0;
                end
                if isfield(parameters, 'constants')
                    parameters = rmfield(parameters, 'constants');
                end
                if isfield(parameters.calibration, 'start')
                    parameters.calibration.iterNum = parameters.calibration.start.iterNum;
                    parameters.calibration = rmfield(parameters.calibration, 'start');
                end
                
                % Migrate Brillouin calibration peak selections
                % We now fit the two peaks in one fit, so we need the whole
                % peak region and not the two peaks separately. Hence, the
                % regions are merged here.
                samples = parameters.calibration.samples;
                if isfield(parameters.calibration, 'wavelength')
                    parameters.calibration = rmfield(parameters.calibration, 'wavelength');
                    parameters.calibration.frequency = [];
                end
                sampleKeys = fields(samples);
                for jj = 1:length(sampleKeys)
                    sample = samples.(sampleKeys{jj});
                    if ~isfield(sample, 'nrBrillouinSamples')
                        if ~isempty(sample.indBrillouin)
                            sample.nrBrillouinSamples = size(sample.indBrillouin,1)/2;
                            % Merge the peak regions
                            indBrillouin = NaN(2, 2);
                            indBrillouin(1, 1) = sample.indBrillouin(1, 1);
                            indBrillouin(1, 2) = sample.indBrillouin(sample.nrBrillouinSamples, 2);
                            indBrillouin(2, 1) = sample.indBrillouin(sample.nrBrillouinSamples+1, 1);
                            indBrillouin(2, 2) = sample.indBrillouin(end, 2);
                            sample.indBrillouin = indBrillouin;
                        else
                            sample.nrBrillouinSamples = 2;
                        end
                        if isfield(sample, 'start')
                            sample = rmfield(sample, 'start');
                        end
                        if isfield(sample, 'fac')
                            sample = rmfield(sample, 'fac');
                        end
                        sample.values = struct( ...
                            'A', [], ...
                            'B', [], ...
                            'C', [], ...
                            'FSR', [], ...
                            'error', [] ...
                        );
                        if isfield(sample, 'wavelengths')
                            sample = rmfield(sample, 'wavelengths');
                            sample.frequencies = [];
                        end
                        samples.(sampleKeys{jj}) = sample;
                    end
                end
                parameters.calibration.samples = samples;
                
                % set version to 1.4.0 to allow further migration steps
                % possibly necessary for future versions
                parameters.programVersion = struct( ...
                    'major', 1, ...
                    'minor', 4, ...
                    'patch', 0, ...
                    'preRelease', '' ...
                );
            end
            % after all calibration steps, set version to program version
            parameters.programVersion = model.programVersion;
            
            %% actually load data into model
            model.parameters = parameters;
            model.results = results;
            model.displaySettings = displaySettings;
            
            model.controllers.calibration.calibrateAll(false);
            
        else
            parameters = model.parameters;
            parameters.programVersion = model.programVersion;   % set program versio key to current program version
            parameters.date = model.file.date;
            parameters.comment = model.file.comment;

            % get the resolution
            parameters.resolution.X = model.file.getResolutionX(model.mode, model.repetition);
            parameters.resolution.Y = model.file.getResolutionY(model.mode, model.repetition);
            parameters.resolution.Z = model.file.getResolutionZ(model.mode, model.repetition);

            % get the positions
            parameters.positions.X = model.file.getPositionsX(model.mode, model.repetition);
            parameters.positions.Y = model.file.getPositionsY(model.mode, model.repetition);
            parameters.positions.Z = model.file.getPositionsZ(model.mode, model.repetition);

            %% read in calibration data
            [parameters.calibration.samples, parameters.calibration.hasCalibration] = ...
                readCalibrationSamples(model);
            parameters.calibration.selectedValue = 1;
            sampleKeys = fields(parameters.calibration.samples);
            parameters.calibration.selected = sampleKeys{1};
            
            parameters.calibration.times(:) = NaN;
            parameters.calibration.frequency(:) = NaN;
            parameters.calibration.offset(:) = 0;

            %% set start values for spectrum axis fitting
            % probably a better algorithm needed
            img = getPayload(model, 'data', 1, 1, 1);
            img = img(:,:,parameters.extraction.imageNr);
            parameters.extraction.circleStart = [1, size(img,1), mean(size(img))];
            model.parameters = parameters;
            
            %% set version to program version
            parameters.programVersion = model.programVersion;
            
            %% pre-allocate results structure
            model.results = struct( ...
                'BrillouinShift',           NaN, ...    % [GHz]  the Brillouin shift
                'BrillouinShift_frequency', NaN, ...    % [GHz]  the Brillouin shift in Hz
                'peaksBrillouin_pos',       NaN, ...    % [pix]  the position of the Brillouin peak(s) in the spectrum
                'peaksBrillouin_dev',       NaN, ...    % [pix]  the deviation of the Brillouin fit
                'peaksBrillouin_int',       NaN, ...    % [a.u.] the intensity of the Brillouin peak(s)
                'peaksBrillouin_fwhm',      NaN, ...    % [pix]  the FWHM of the Brillouin peak
                'peaksBrillouin_fwhm_frequency', NaN,...% [GHz]  the FWHM of the Brillouin peak in GHz
                'peaksRayleigh_pos',        NaN, ...    % [pix]  the position of the Rayleigh peak(s) in the spectrum
                'intensity',                NaN, ...    % [a.u.] the overall intensity of the image
                'validity',                 false, ...  % [logical] the validity of the results
                'times',                    NaN, ...    % [s]    time of the measurement
                'brightfield',              NaN, ...    % [a.u.] the intensity of the brightfield image (usefull for 2D xy images)
                'brightfield_raw',          NaN, ...    % [a.u.] the complete brightfield image
                'brightfield_rot',          NaN  ...    % [a.u.] the rotated brightfield image
            );
        end
    end
end

function [samples, hasCalibration] = readCalibrationSamples(model)
    hasCalibration = false;
    jj = 1;
    testCalibration = true;
    samples = struct();
    while testCalibration
        try
            sampleType = getCalibration(model, 'sample', jj);
            if ~isempty(sampleType)
                hasCalibration = true;
            end
            sampleKey = matlab.lang.makeValidName(sampleType);
            kk = 0;
            while isfield(samples, sampleKey)
                sampleKey = [matlab.lang.makeValidName(sampleType) sprintf('_%02d', kk)];
                kk = kk + 1;
            end
            data = getCalibration(model, 'data', jj);
            nrImages = size(data,3);
            samples.(sampleKey) = struct( ...
                'sampleType', sampleType, ...
                'position', jj, ...
                'indRayleigh', [], ...
                'indBrillouin', [], ...
                'nrBrillouinSamples', 2, ...
                'shift', getCalibration(model, 'shift', jj), ...
                'peaksMeasured', [], ...
                'peaksFitted', [], ...
                'BrillouinShift', NaN(nrImages,2), ...
                'nrImages', nrImages, ...
                'active', ones(nrImages,1), ...
                'time', getCalibration(model, 'date', jj), ...
                'values', struct( ...   % struct with all values
                    'A', [], ...
                    'B', [], ...
                    'C', [], ...
                    'FSR', [], ...
                    'error', [] ...
                ) ...
            );
            jj = jj + 1;
        catch
            testCalibration = false;
        end
    end
    
    x = 1;
    y = 1;
    z = 1;
    nrSamples = length(fields(samples));
    samples.measurement = struct( ...
        'sampleType', 'measurement', ...
        'position', nrSamples + 1, ...
        'imageNr', struct( ...
            'x', x, ...
            'y', y, ...
            'z', z ...
        ), ...
        'indRayleigh', [47, 85; 255, 284], ...
        'indBrillouin', [151, 162; 206, 222], ...
        'nrBrillouinSamples', 2, ...
        'shift', 5.1, ...
        'peaksMeasured', [], ...
        'peaksFitted', [], ...
        'time', getPayload(model, 'date', x, y, z), ...
        'values', struct( ...   % struct with all values
            'A', [], ...
            'B', [], ...
            'C', [], ...
            'FSR', [], ...
            'error', [] ...
        ) ....
    );
end

function closeFile(~, ~, model)
    if ~isempty(model.filename)
        model.log.log(['I/File: Closed file "' model.filepath model.filename '"']);
        model.log.write('');
    end
    model.reset();
end

function selectSaveData(~, ~, model)
    % Save the results file
    if isempty(model.filename)
        return
    end
    [~, filename, ~] = fileparts(model.filename);
    if (model.repetitionCount > 1)
        defaultPath = [model.filepath '..\EvalData\' filename '_rep' num2str(model.repetition) '.mat'];
    else
        defaultPath = [model.filepath '..\EvalData\' filename '.mat'];
    end
    [FileName,PathName,~] = uiputfile('*.mat','Save results as', defaultPath);
    filePath = [PathName, FileName];
    saveData(model, filePath)
end

function saveData(model, filePath)
    % Save the results file
    if isempty(model.filename) || ~ischar(filePath)
        return
    end
    
    [PathName, FileName, ~] = fileparts(filePath);
    if ~isequal(FileName,0) && ~isequal(PathName,0)
        
        %% create directory if non-existent
        if ~exist(PathName, 'dir')
            mkdir(PathName);
        end
        
        %% set version to program version
        parameters = model.parameters;
        parameters.programVersion = model.programVersion;

        results = struct( ...
            'parameters', parameters, ...
            'results', model.results, ...
            'displaySettings', model.displaySettings ...
        ); %#ok<NASGU>

        save(filePath, 'results');
    end
    model.log.log(['I/File: Saved file "' filePath '"']);
end

function value = getPayload(model, type, indX, indY, indZ)
    value = model.file.readPayloadData(model.mode, model.repetition, type, indX, indY, indZ);
    if strcmp(type, 'data')
        value = adjustOrientation(model, value);
    end
end

function value = getCalibration(model, type, index)
    value = model.file.readCalibrationData(model.mode, model.repetition, type, index);
    if strcmp(type, 'data')
        value = adjustOrientation(model, value);
    end
end

function value = getBackground(model, type)
    value = model.file.readBackgroundData(model.mode, model.repetition, type);
    if strcmp(type, 'data')
        value = adjustOrientation(model, value);
    end
end

function img = adjustOrientation(model, img)
    params = model.parameters.data;
    if (params.rotate)
        img = rot90(img, params.rotate);
    end
    if (params.flipud)
        img = flipud(img);
    end
    if (params.fliplr)
        img = fliplr(img);
    end
end

function toggleVertically(~, ~, model, view)
    model.parameters.data.flipud = get(view.data.vertically, 'Value');
end

function toggleHorizontally(~, ~, model, view)
    model.parameters.data.fliplr = get(view.data.horizontally, 'Value');
end

function setRotation(~, ~, model, view)
    rotation = get(view.data.rotationGroup, 'SelectedObject');
    model.parameters.data.rotate = str2double(erase(rotation.Tag, 'rotate_'));
end

function count = getRepetitionCount(file)
    count = 0;
    e = '';
    while isempty(e)
        try
            file.getDate('Brillouin', count);
            count = count + 1;
        catch e %#ok<NASGU>
        end
    end
end

function selectRepetition(src, ~, model)
    val = get(src, 'Value');
    model.repetition = val - 1;
    
    loadData(model, [model.filepath model.filename]);
end

function selectSetup(src, ~, model)
    val = get(src, 'Value');
    model.parameters.constants_setup = model.availableSetups.(sprintf('S%d', val-1));
end