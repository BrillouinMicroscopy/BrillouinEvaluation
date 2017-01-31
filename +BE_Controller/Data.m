function configuration = Data(model, view)
%% DATA Controller

    %% general panel
    set(view.data.load, 'Callback', {@load, model});
    set(view.data.clear, 'Callback', {@clear, model});

    configuration = struct( ...
        'close', @close ...
    );
end

function load(~, ~, model)
% Load the h5bm data file
    [FileName,PathName,~] = uigetfile('*.h5','Select the Brillouin file to evaluate.');
    filePath = [PathName FileName];
    if ~isequal(PathName,0) && exist(filePath, 'file')
        model.filename = FileName;
        model.file = BE_Utils.HDF5Storage.h5bmread(filePath);
        
        model.parameters.date = model.file.date;
        model.parameters.comment = model.file.comment;
        
        % get the resolution
        model.parameters.resolution.X = model.file.resolutionX;
        model.parameters.resolution.Y = model.file.resolutionY;
        model.parameters.resolution.Z = model.file.resolutionZ;

        % get the positions
        model.parameters.positions.X = model.file.positionsX;
        model.parameters.positions.Y = model.file.positionsY;
        model.parameters.positions.Z = model.file.positionsZ;
        
        % set start values for spectrum axis fitting
        % probably a better algorithm needed
        img = model.file.readPayloadData(1, 1, 1, 'data');
        img = img(:,:,model.parameters.extraction.imageNr);
        model.parameters.extraction.circleStart = [1, size(img,1), mean(size(img))];
    end
end

function clear(~, ~, model)
    model.file = [];
    model.filename = [];
end