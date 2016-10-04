function handles = Evaluation(parent, model)
%% EVALUATION View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'file', 'PostSet', ...
        @(o,e) onFileLoad(handles, e.AffectedObject));
end

function handles = initGUI(model, parent)
    
    %% Return handles
    handles = struct(...
	);
end

function initView(handles, model)
%% Initialize the view
    onFileLoad(handles, model)
end

function onFileLoad(handles, model)
end
