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
    
    menubar.help = uimenu(f,'Label','Help');
    menubar.helpAbout  = uimenu(menubar.help,'Label','About','Accelerator','A');
    
    % create the tabgroup for loading, calibrating and evaluating
    tabgroup = uitabgroup('Parent', f);
    view.data.parent = uitab('Parent', tabgroup, 'Title', 'Data');
    view.extraction.parent = uitab('Parent', tabgroup, 'Title', 'Extraction');
    view.calibration.parent = uitab('Parent', tabgroup, 'Title', 'Calibration');
    view.peakSelection.parent = uitab('Parent', tabgroup, 'Title', 'Peak Selection');
    view.evaluation.parent = uitab('Parent', tabgroup, 'Title', 'Evaluation');
    
    BE_View.Data(view, model);
    BE_View.Calibration(view, model);
    BE_View.Extraction(view, model);
    BE_View.PeakSelection(view, model);
    BE_View.Evaluation(view, model);
                 
    % Assign the name to appear in the window title.
    version = sprintf('%d.%d.%d', model.programVersion.major, model.programVersion.minor, model.programVersion.patch);
    if ~strcmp('', model.programVersion.preRelease)
        version = [version '-' model.programVersion.preRelease];
    end
    f.Name = sprintf('%s v%s', model.programVersion.name, version);

    % Move the window to the center of the screen.
    movegui(f,'center')

    % Make the window visible.
    f.Visible = 'on';
    
    % return a structure of GUI handles
    view.figure = f;
    view.menubar = menubar;
end