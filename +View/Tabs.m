function handles = Tabs(model)
%% TABS View

    % build the GUI
    handles = initGUI(model);
end

function handles = initGUI(model)
    f = figure('Visible','off','Position',[2750,300,900,650]);
    % hide the menubar and prevent resizing
    set(f, 'menubar', 'none', 'Resize','off');
    
    % create the tabgroup for loading, calibrating and evaluating
    tabgroup = uitabgroup('Parent', f);
    data = uitab('Parent', tabgroup, 'Title', 'Data');
    calibration = uitab('Parent', tabgroup, 'Title', 'Calibration');
    evaluation = uitab('Parent', tabgroup, 'Title', 'Evaluation');
    
    data = View.Data(data, model);
    calibration = View.Calibration(calibration, model);
    evaluation = View.Evaluation(evaluation, model);
                 
    % Assign the name to appear in the window title.
    f.Name = 'Brillouin Evaluation';

    % Move the window to the center of the screen.
    movegui(f,'center')

    % Make the window visible.
    f.Visible = 'on';
    
    % return a structure of GUI handles
    handles = struct(...
        'figure', f, ...
        'data', data, ...
        'calibration', calibration, ...
        'evaluation', evaluation ...
    );
end