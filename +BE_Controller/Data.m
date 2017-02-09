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
        jj = 0;
        testCalibration = true;
        parameters.calibration.samples = struct();
        while testCalibration
            try
                jj = jj + 1;
                sample = model.file.readCalibrationData(jj,'sample');
                if ~isempty(sample)
                    parameters.calibration.hasCalibration = true;
                end
                parameters.calibration.samples.(sample) = struct( ...
                    'position', jj, ...
                    'Rayleigh', [], ...
                    'Brillouin', [], ...
                    'shift', model.file.readCalibrationData(jj,'shift'), ...
                    'peaksMeasured', [], ...
                    'peaksFitted', [] ...
                );
            catch
                testCalibration = false;
            end
        end
        
        parameters.calibration.samples.measurement = struct( ...
            'imageNr', struct( ...
                'x', 1, ...
                'y', 1, ...
                'z', 1 ...
            ), ...
            'Rayleigh', [47, 85; 255, 284], ...
            'Brillouin', [151, 162; 206, 222], ...
            'shift', 5.1, ...
            'peaksMeasured', [], ...
            'peaksFitted', [] ...
        );
        samples = fields(parameters.calibration.samples);
        parameters.calibration.selectedValue = 1;
        parameters.calibration.selected = samples{1};
        
        % set start values for spectrum axis fitting
        % probably a better algorithm needed
        img = model.file.readPayloadData(1, 1, 1, 'data');
        img = img(:,:,model.parameters.extraction.imageNr);
        parameters.extraction.circleStart = [1, size(img,1), mean(size(img))];
        model.parameters = parameters;
        
        %% check if a corresponding results file exists
        [~, filename, ~] = fileparts(model.filename);
        defaultPath = [model.filepath '..\EvalData\' filename '.mat'];
        if exist(defaultPath, 'file') == 2
            tmp = model;
            results = load(defaultPath, 'results');
            tmp.parameters = results.results.parameters;
            tmp.results = results.results.results;
            tmp.displaySettings = results.results.displaySettings;
            model = tmp; %#ok<NASGU>
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