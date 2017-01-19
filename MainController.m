function MainController
%% MAINCONTROLLER  MainController

    % controller knows about model and view
    model = Model.Model();      % model is independent
    
    includePath(model);
    
    view = View.Tabs(model);    % view has a reference of the model
    
    controllers = controller(model, view);
    
    set(view.figure, 'CloseRequestFcn', {@closeGUI, model, controllers});    
end

function closeGUI(~, ~, model, controllers)
    controllers.data.close('', '', model);
    delete(gcf);
end

function controllers = controller(model, view)
    data = Controller.Data(model, view);
    extraction = Controller.Extraction(model, view);
    calibration = Controller.Calibration(model, view);
    evaluation = Controller.Evaluation(model, view);
    controllers = struct( ...
        'data', data, ...
        'extraction', extraction, ...
        'calibration', calibration, ...
        'evaluation', evaluation ...
    );
end

function includePath(model)
    fp = mfilename('fullpath');
    [model.pp,~,~] = fileparts(fp);
    addpath(model.pp);
end