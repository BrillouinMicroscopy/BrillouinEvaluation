function varargout = BrillouinEvaluation
%% MAINCONTROLLER  MainController

    % controller knows about model and view
    clear model;
    model = BE_Model.Model();      % model is independent
    
    includePath(model);
    
    clear view;
    view = BE_View.View();
    
    BE_View.Tabs(model, view);    % view has a reference of the model
    
    controllers = controller(model, view);
    
    % add logging class
    model.log = BE_Utils.Logging.Logging([model.pp filesep 'log.log']);
    model.log.write('');
    model.log.write('#####################################################');
    model.log.log('V/BrillouinEvaluation: Opened program.');
    model.log.write('=====================================================');
    
    set(view.figure, 'CloseRequestFcn', {@closeGUI, model, view, controllers});
    
    if nargout
        varargout{1} = controllers;
    end
end

function closeGUI(~, ~, model, view, controllers)
    if isfield(view.masking, 'parent') && ishandle(view.masking.parent)
        close(view.masking.parent);
        delete(view.masking.parent);
    end
    if isfield(view.help, 'parent') && ishandle(view.help.parent)
        close(view.help.parent);
        delete(view.help.parent);
    end
    controllers.data.closeFile();
    model.log.write('=====================================================');
    model.log.log('V/BrillouinEvaluation: Closed program.');
    delete(gcf);
end

function controllers = controller(model, view)
    data = BE_Controller.Data(model, view);
    extraction = BE_Controller.Extraction(model, view);
    peakSelection = BE_Controller.PeakSelection(model, view);
    calibration = BE_Controller.Calibration(model, view);
    evaluation = BE_Controller.Evaluation(model, view);
    help = BE_Controller.Help(model, view);
    controllers = struct( ...
        'data', data, ...
        'extraction', extraction, ...
        'calibration', calibration, ...
        'peakSelection', peakSelection, ...
        'evaluation', evaluation, ...
        'help', help ...
    );
end

function includePath(model)
    fp = mfilename('fullpath');
    [model.pp,~,~] = fileparts(fp);
    addpath(model.pp);
end