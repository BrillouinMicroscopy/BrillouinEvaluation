function BrillouinEvaluation
%% MAINCONTROLLER  MainController

    % controller knows about model and view
    model = BE_Model.Model();      % model is independent
    
    includePath(model);
    
    view = BE_View.View();
    
    BE_View.Tabs(model, view);    % view has a reference of the model
    
    controllers = controller(model, view);
    
    set(view.figure, 'CloseRequestFcn', {@closeGUI, model, controllers});    
end

function closeGUI(~, ~, model, controllers)
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