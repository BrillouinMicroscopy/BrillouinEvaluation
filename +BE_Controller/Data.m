function configuration = Data(model, view)
%% DATA Controller

    %% general panel
    set(view.data.load, 'Callback', {@loadData, model});
    set(view.data.clear, 'Callback', {@clear, model});
    set(view.data.save, 'Callback', {@saveData, model});

    configuration = struct( ...
        'close', @close ...
    );
end

function loadData(~, ~, model)
% Load the h5bm data file
    [FileName,PathName,~] = uigetfile('*.h5','Select the Brillouin file to evaluate.');
    model.filepath = PathName;
    filePath = [PathName FileName];
    if ~isequal(PathName,0) && exist(filePath, 'file')
        
        model.filename = FileName;
        model.file = BE_Utils.HDF5Storage.h5bmread(filePath);
    
        delete(model.handles.plotPositions);
        
        model.handles = struct( ...
            'results', NaN, ...
            'plotPositions', NaN ...
        );
        
        %% check if a corresponding results file exists
        [~, filename, ~] = fileparts(model.filename);
        defaultPath = [model.filepath '..\EvalData\' filename '.mat'];
        if exist(defaultPath, 'file') == 2
            results = load(defaultPath, 'results');
            model.parameters = results.results.parameters;
            model.results = results.results.results;
            model.displaySettings = results.results.displaySettings;
        else        
            parameters = model.parameters;
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

            % check for calibration
            parameters.calibration.hasCalibration = false;
            jj = 1;
            testCalibration = true;
            parameters.calibration.samples = struct();
            while testCalibration
                try
                    sampleType = model.file.readCalibrationData(jj,'sample');
                    if ~isempty(sampleType)
                        parameters.calibration.hasCalibration = true;
                    end
                    sampleKey = sampleType;
                    kk = 0;
                    while isfield(parameters.calibration.samples, sampleKey)
                        sampleKey = [sampleType sprintf('_%02d', kk)];
                        kk = kk + 1;
                    end
                    data = model.file.readCalibrationData(jj,'data');
                    nrImages = size(data,1);
                    parameters.calibration.samples.(sampleKey) = struct( ...
                        'sampleType', sampleType, ...
                        'position', jj, ...
                        'indRayleigh', [], ...
                        'indBrillouin', [], ...
                        'shift', model.file.readCalibrationData(jj,'shift'), ...
                        'peaksMeasured', [], ...
                        'peaksFitted', [], ...
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
            parameters.calibration.samples.measurement = struct( ...
                'sampleType', 'measurement', ...
                'position', jj, ...
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
            samples = fields(parameters.calibration.samples);
            parameters.calibration.selectedValue = 1;
            parameters.calibration.selected = samples{1};

            % set start values for spectrum axis fitting
            % probably a better algorithm needed
            img = model.file.readPayloadData(1, 1, 1, 'data');
            img = img(:,:,parameters.extraction.imageNr);
            parameters.extraction.circleStart = [1, size(img,1), mean(size(img))];
            model.parameters = parameters;
            
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

function clear(~, ~, model)
    model.file = [];
    model.filename = [];
end

function saveData(~, ~, model)
    % Save the results file
    [~, filename, ~] = fileparts(model.filename);
    defaultPath = [model.filepath '..\EvalData\' filename '.mat'];
    [FileName,PathName,~] = uiputfile('*.mat','Save results as', defaultPath);
    if ~isequal(FileName,0) && ~isequal(PathName,0)
        filePath = [PathName FileName];

        results = struct( ...
            'parameters', model.parameters, ...
            'results', model.results, ...
            'displaySettings', model.displaySettings ...
        ); %#ok<NASGU>

        save(filePath, 'results');
    end
end