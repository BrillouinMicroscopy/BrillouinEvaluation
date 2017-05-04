function handles = Tabs(model)
%% TABS View

    % build the GUI
    handles = initGUI(model);
end

function handles = initGUI(model)
    f = figure('Visible','off','Position',[-1000,200,900,650]);
    % hide the menubar and prevent resizing
    set(f, 'menubar', 'none', 'Resize','off');
    
    % create the tabgroup for loading, calibrating and evaluating
    tabgroup = uitabgroup('Parent', f);
    data = uitab('Parent', tabgroup, 'Title', 'Data');
    extraction = uitab('Parent', tabgroup, 'Title', 'Extraction');
    calibration = uitab('Parent', tabgroup, 'Title', 'Calibration');
    peakSelection = uitab('Parent', tabgroup, 'Title', 'Peak Selection');
    evaluation = uitab('Parent', tabgroup, 'Title', 'Evaluation');
    
    data = BE_View.Data(data, model);
    calibration = BE_View.Calibration(calibration, model);
    extraction = BE_View.Extraction(extraction, model);
    peakSelection = BE_View.PeakSelection(peakSelection, model);
    evaluation = BE_View.Evaluation(evaluation, model);
                 
    % Assign the name to appear in the window title.
    f.Name = sprintf('Brillouin Evaluation v%d.%d.%d', model.programVersion.major, model.programVersion.minor, model.programVersion.patch);

    % Move the window to the center of the screen.
    movegui(f,'center')

    % Make the window visible.
    f.Visible = 'on';
    
    % return a structure of GUI handles
    handles = struct(...
        'figure', f, ...
        'data', data, ...
        'extraction', extraction, ...
        'peakSelection', peakSelection, ...
        'calibration', calibration, ...
        'evaluation', evaluation ...
    );
end