function MainController
%% MAINCONTROLLER  MainController

    % controller knows about model and view
    model = Model.Model();      % model is independent
    view = View.Tabs(model);    % view has a reference of the model
    
    controllers = controller(model, view);
    
    includePath();
    
    set(view.figure, 'CloseRequestFcn', {@closeGUI, model, controllers});    
end

function closeGUI(~, ~, model, controllers)
    controllers.data.close('', '', model);
    delete(gcf);
end

function controllers = controller(model, view)
    data = Controller.Data(model, view);
    calibration = Controller.Calibration(model, view);
    evaluation = Controller.Evaluation(model, view);
    controllers = struct( ...
        'data', data, ...
        'calibration', calibration, ...
        'evaluation', evaluation ...
    );
end

function includePath()
    fp = mfilename('fullpath');
    [pathstr,~,~] = fileparts(fp);
    addpath(pathstr);
end