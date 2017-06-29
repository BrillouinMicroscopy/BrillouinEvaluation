function varargout = BrillouinEvaluation
%% MAINCONTROLLER  MainController

    % controller knows about model and view
    model = BE_Model.Model();      % model is independent
    
    includePath(model);
    
    view = BE_View.View();
    
    BE_View.Tabs(model, view);    % view has a reference of the model
    
    controllers = controller(model, view);
    
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
    controllers.data.close('', '', model);
    delete(gcf);
end

function controllers = controller(model, view)
    data = BE_Controller.Data(model, view);
    extraction = BE_Controller.Extraction(model, view);
    peakSelection = BE_Controller.PeakSelection(model, view);
    calibration = BE_Controller.Calibration(model, view);
    evaluation = BE_Controller.Evaluation(model, view);
    controllers = struct( ...
        'data', data, ...
        'extraction', extraction, ...
        'calibration', calibration, ...
        'peakSelection', peakSelection, ...
        'evaluation', evaluation ...
    );
end

function includePath(model)
    fp = mfilename('fullpath');
    [model.pp,~,~] = fileparts(fp);
    addpath(model.pp);
end