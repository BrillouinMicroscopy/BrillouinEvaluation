function Tabs(model, view)
%% TABS View

    % build the GUI
    initGUI(model, view);
end

function initGUI(model, view)
    f = figure('Visible','off','Position',[-1000,200,900,650]);
    % hide the menubar and prevent resizing
    set(f, 'menubar', 'none', 'Resize','off');
    
    % set menubar
    menubar.file = uimenu(f,'Label','File');
    menubar.fileOpen   = uimenu(menubar.file,'Label','Open','Accelerator','O');
    menubar.fileClose  = uimenu(menubar.file,'Label','Close','Accelerator','W');                 
    menubar.fileSave   = uimenu(menubar.file,'Label','Save','Accelerator','S');
    
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
    version = sprintf('%d.%d.%d', model.programVersion.major, model.programVersion.minor, model.programVersion.patch);
    if ~strcmp('', model.programVersion.preRelease)
        version = [version '-' model.programVersion.preRelease];
    end
    f.Name = sprintf('Brillouin Evaluation v%s', version);

    % Move the window to the center of the screen.
    movegui(f,'center')

    % Make the window visible.
    f.Visible = 'on';
    
    % return a structure of GUI handles
    view.figure = f;
    view.menubar = menubar;
    view.data = data;
    view.extraction = extraction;
    view.peakSelection = peakSelection;
    view.calibration = calibration;
    view.evaluation = evaluation;
end