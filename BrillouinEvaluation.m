function BrillouinEvaluation
%% MAINCONTROLLER  MainController

    % controller knows about model and view
    model = BE_Model.Model();      % model is independent
    
    includePath(model);
    sharedFunctions(model);
    
    view = BE_View.Tabs(model);    % view has a reference of the model
    
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

function sharedFunctions(model)
    model.sharedFunctions.iconString = @iconString;
end

function str = iconString(filepath)
    iconFile = urlencode(fullfile(filepath));
    iconUrl1 = strrep(['file:/' iconFile],'\','/');
    scale = getScalingValue();
    width = scale*20;
    height = scale*20;
    str = ['<html><img src="' iconUrl1 '" height="' sprintf('%1.0f', height) '" width="' sprintf('%1.0f', width) '"/></html>'];
end

function scale = getScalingValue()
    screenSize = get(0,'ScreenSize');
    jScreenSize = java.awt.Toolkit.getDefaultToolkit.getScreenSize;
    scale = jScreenSize.width/screenSize(3);
end