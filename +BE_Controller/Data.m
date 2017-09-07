function configuration = Data(model, view)
%% DATA Controller

    %% general panel
    set(view.menubar.fileOpen, 'Callback', {@selectLoadData, model});
    set(view.menubar.fileClose, 'Callback', {@closeFile, model});
    set(view.menubar.fileSave, 'Callback', {@selectSaveData, model});

    configuration = struct( ...
        'setActive', @()setActive(view), ...
        'closeFile', @()closeFile('', '', model), ...
        'load', @(filePath)loadData(model, filePath), ...
        'save', @(filePath)saveData(model, filePath)...
    );
end

function setActive(view)
    tabgroup = get(view.data.parent, 'parent');
    tabgroup.SelectedTab = view.data.parent;
end

function selectLoadData(~, ~, model)
    [FileName,PathName,~] = uigetfile('*.h5','Select the Brillouin file to evaluate.');
    filePath = [PathName FileName];
    loadData(model, filePath);
end

function loadData(model, filePath)
% Load the h5bm data file
    model.log.log(['[File] Opened file ' filePath]);
    if ~filePath
        return
    end
    [PathName, name, extension] = fileparts(filePath);
    model.filepath = [PathName '\'];
    if ~isequal(PathName,0) && exist(filePath, 'file')
        
        model.filename = [name extension];
        model.file = BE_Utils.HDF5Storage.h5bmread(filePath);
        
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
        defaultPath = [model.filepath '..\EvalData\' filename '.mat'];
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
                            sample.time = model.file.readPayloadData(sample.imageNr.x, sample.imageNr.y, sample.imageNr.z, 'date');
                        end
                    else
                        if ~isfield(sample, 'time')
                            sample.time = model.file.readCalibrationData(sample.position,'date');
                        end
                        if ~isfield(sample, 'nrImages')
                            data = model.file.readCalibrationData(sample.position,'data');
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
                    parameters.evaluation.interpRayleigh = false;
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
            % after all calibration steps, set version to program version
            parameters.programVersion = model.programVersion;
            
            %% actually load data into model
            model.parameters = parameters;
            model.results = results;
            model.displaySettings = displaySettings;
            
        else
            parameters = model.parameters;
            parameters.programVersion = model.programVersion;   % set program versio key to current program version
            parameters.date = model.file.date;
            parameters.comment = model.file.comment;

            % get the resolution
            parameters.resolution.X = model.file.resolutionX;
            parameters.resolution.Y = model.file.resolutionY;
            parameters.resolution.Z = model.file.resolutionZ;

            % get the positions
            parameters.positions.X = model.file.positionsX;
            parameters.positions.Y = model.file.positionsY;
            parameters.positions.Z = model.file.positionsZ;

            %% read in calibration data
            [parameters.calibration.samples, parameters.calibration.hasCalibration] = ...
                readCalibrationSamples(model);
            parameters.calibration.selectedValue = 1;
            sampleKeys = fields(parameters.calibration.samples);
            parameters.calibration.selected = sampleKeys{1};
            
            parameters.calibration.times(:) = NaN;
            parameters.calibration.wavelength(:) = NaN;
            parameters.calibration.offset(:) = 0;

            %% set start values for spectrum axis fitting
            % probably a better algorithm needed
            img = model.file.readPayloadData(1, 1, 1, 'data');
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
            sampleType = model.file.readCalibrationData(jj,'sample');
            if ~isempty(sampleType)
                hasCalibration = true;
            end
            sampleKey = sampleType;
            kk = 0;
            while isfield(samples, sampleKey)
                sampleKey = [sampleType sprintf('_%02d', kk)];
                kk = kk + 1;
            end
            data = model.file.readCalibrationData(jj,'data');
            nrImages = size(data,3);
            samples.(sampleKey) = struct( ...
                'sampleType', sampleType, ...
                'position', jj, ...
                'indRayleigh', [], ...
                'indBrillouin', [], ...
                'shift', model.file.readCalibrationData(jj,'shift'), ...
                'peaksMeasured', [], ...
                'peaksFitted', [], ...
                'BrillouinShift', NaN(nrImages,2), ...
                'nrImages', nrImages, ...
                'active', ones(nrImages,1), ...
                'time', model.file.readCalibrationData(jj,'date'), ...
                'values', struct( ...   % struct with all values
                    'd',        [], ... % [m]   width of the cavity
                    'n',        [], ... % [1]   refractive index of the VIPA
                    'theta',    [], ... % [rad] angle of the VIPA
                    'x0Initial',[], ... % [m]   offset for fitting
                    'x0',       [], ... % [m]   offset for fitting, corrected for each measurement
                    'xs',       [], ... % [1]   scale factor for fitting
                    'error',    []  ... % [1]   uncertainty of the fit
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
        'shift', 5.1, ...
        'peaksMeasured', [], ...
        'peaksFitted', [], ...
        'time', model.file.readPayloadData(x, y, z, 'date'), ...
        'values', struct( ...   % struct with all values
            'd',        [], ... % [m]   width of the cavity
            'n',        [], ... % [1]   refractive index of the VIPA
            'theta',    [], ... % [rad] angle of the VIPA
            'x0Initial',[], ... % [m]   offset for fitting
            'x0',       [], ... % [m]   offset for fitting, corrected for each measurement
            'xs',       [], ... % [1]   scale factor for fitting
            'error',    []  ... % [1]   uncertainty of the fit
        ) ....
    );
end

function closeFile(~, ~, model)
    if ~isempty(model.filename)
        model.log.log(['[File] Closed file ' model.filepath model.filename]);
        model.log.write('');
    end
    model.file = [];
    model.filename = [];
end

function selectSaveData(~, ~, model)
    % Save the results file
    if isempty(model.filename)
        return
    end
    [~, filename, ~] = fileparts(model.filename);
    defaultPath = [model.filepath '..\EvalData\' filename '.mat'];
    [FileName,PathName,~] = uiputfile('*.mat','Save results as', defaultPath);
    filePath = [PathName, FileName];
    saveData(model, filePath)
end

function saveData(model, filePath)
    % Save the results file
    if isempty(model.filename)
        return
    end
    
    [PathName, FileName, ~] = fileparts(filePath);
    if ~isequal(FileName,0) && ~isequal(PathName,0)
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
    model.log.log(['[File] Saved file ' filePath]);
end