function Data(view, model)
%% DATA View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'file', 'PostSet', ...
        @(o,e) onFileLoad(view, e.AffectedObject));
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onFileLoad(view, e.AffectedObject));
    addlistener(model, 'repetition', 'PostSet', ...
        @(o,e) onFileLoad(view, e.AffectedObject));
end

function initGUI(~, view)
    parent = view.data.parent;

    file_panel = uipanel('Parent', parent, 'Title', 'File', 'FontSize', 11,...
                 'Position', [.02 .03 .4 .95]);

    uicontrol('Parent', file_panel, 'Style','text','String','Selected file:', 'Units', 'normalized',...
               'Position',[0.05,0.9,0.3,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    uicontrol('Parent', file_panel, 'Style','text','String','Repetition:', 'Units', 'normalized',...
               'Position',[0.05,0.85,0.4,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    uicontrol('Parent', file_panel, 'Style','text','String','Date:', 'Units', 'normalized',...
               'Position',[0.05,0.8,0.3,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    uicontrol('Parent', file_panel, 'Style','text','String','Resolution x:', 'Units', 'normalized',...
               'Position',[0.05,0.75,0.3,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    uicontrol('Parent', file_panel, 'Style','text','String','Resolution y:', 'Units', 'normalized',...
               'Position',[0.05,0.7,0.3,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    uicontrol('Parent', file_panel, 'Style','text','String','Resolution z:', 'Units', 'normalized',...
               'Position',[0.05,0.65,0.3,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    uicontrol('Parent', file_panel, 'Style','text','String','Calibration:', 'Units', 'normalized',...
               'Position',[0.05,0.6,0.3,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    uicontrol('Parent', file_panel, 'Style','text','String','Comment:', 'Units', 'normalized',...
               'Position',[0.05,0.55,0.3,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');

    filename = uicontrol('Parent', file_panel, 'Style','text', 'Units', 'normalized',...
               'Position',[0.35,0.9,0.6,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    repetition = uicontrol('Parent', file_panel, 'Style','popup', 'Units', 'normalized',...
               'Position',[0.35,0.85,0.6,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left', 'String', {''});
    date = uicontrol('Parent', file_panel, 'Style','text', 'Units', 'normalized',...
               'Position',[0.35,0.8,0.6,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    resolutionX = uicontrol('Parent', file_panel, 'Style','text', 'Units', 'normalized',...
               'Position',[0.35,0.75,0.6,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    resolutionY = uicontrol('Parent', file_panel, 'Style','text', 'Units', 'normalized',...
               'Position',[0.35,0.7,0.6,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    resolutionZ = uicontrol('Parent', file_panel, 'Style','text', 'Units', 'normalized',...
               'Position',[0.35,0.65,0.6,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    calibration = uicontrol('Parent', file_panel, 'Style','text', 'Units', 'normalized',...
               'Position',[0.35,0.6,0.6,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
    comment = uicontrol('Parent', file_panel, 'Style','edit','Max',2, 'Units', 'normalized',...
           'Position',[0.05,0.20,0.9,0.35], 'FontSize', 11, 'HorizontalAlignment', 'left', 'Enable', 'inactive');

    orientation_panel = uipanel('Parent', parent, 'Title', 'Image orientation', 'FontSize', 11,...
                 'Position', [.44 .78 .3 .20]);
             
    % extraction axis selection
    rotationGroup = uibuttongroup(orientation_panel, 'Units', 'normalized', 'FontSize', 11, ...
        'Title', 'Rotate by 90 °',...
        'Position', [0.02 0.03 0.55 0.96]);
    % Create three radio buttons in the button group.
    rotation(1) = uicontrol(rotationGroup, 'Style', 'radiobutton', 'FontSize', 11, ...
        'String', 'None', 'Tag', 'rotate_0', ...
        'Position', [10 59 150 15]);
    rotation(2) = uicontrol(rotationGroup, 'Style', 'radiobutton', 'FontSize', 11, ...
        'String', 'Clockwise', 'Tag', 'rotate_-1', ...
        'Position', [10 35 150 15]);
    rotation(3) = uicontrol(rotationGroup, 'Style', 'radiobutton', 'FontSize', 11, ...
        'String','Counterclockwise', 'Tag', 'rotate_1', ...
        'Position', [10 10 150 15]);
    
    mirrorGroup = uipanel('Parent', orientation_panel, 'Title', 'Mirror', 'FontSize', 11,...
             'Position', [.59 .03 .39 .96]);

    vertically = uicontrol('Parent', mirrorGroup, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.02,0.725,0.14,0.22], 'FontSize', 11, 'HorizontalAlignment', 'left', 'tag', 'Borders');
    
    uicontrol('Parent', mirrorGroup, 'Style', 'text', 'String', 'Vertically', 'Units', 'normalized',...
        'Position', [0.18,0.75,0.8,0.22], 'FontSize', 11, 'HorizontalAlignment', 'left');

    horizontally = uicontrol('Parent', mirrorGroup, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.02,0.425,0.14,0.22], 'FontSize', 11, 'HorizontalAlignment', 'left', 'tag', 'Center');
    
    uicontrol('Parent', mirrorGroup, 'Style', 'text', 'String', 'Horizontally', 'Units', 'normalized',...
        'Position', [0.18,0.45,0.9,0.22], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    setup_panel = uipanel('Parent', parent, 'Title', 'Setup selection', 'FontSize', 11,...
                 'Position', [.44 .68 .3 .10]);
    
    uicontrol('Parent', setup_panel, 'Style','text','String','Selected setup:', 'Units', 'normalized',...
               'Position',[0.02,0.03,0.4,0.8], 'FontSize', 11, 'HorizontalAlignment', 'left');   
    setup = uicontrol('Parent', setup_panel, 'Style','popup', 'Units', 'normalized',...
               'Position',[0.42,0.1,0.55,0.8], 'FontSize', 11, 'HorizontalAlignment', 'left', 'String', {''});
    
    %% Return handles
    view.data = struct(...
        'parent', parent, ...
        'filename', filename, ...
        'repetition', repetition, ...
        'date', date, ...
        'resolutionX', resolutionX, ...
        'resolutionY', resolutionY, ...
        'resolutionZ', resolutionZ, ...
        'calibration', calibration, ...
        'comment', comment, ...
        'rotationGroup', rotationGroup, ...
        'rotation', rotation, ...
        'vertically', vertically, ...
        'horizontally', horizontally, ...
        'setup', setup ...
	);
end

function initView(view, model)
    %% Initialize the view
    onFileLoad(view, model)
end

function onFileLoad(view, model)
    handles = view.data;
    if isa(model.file,'BE_Utils.HDF5Storage.h5bm') && isvalid(model.file)
        set(handles.filename, 'String', model.filename);
        set(handles.date, 'String', model.parameters.date);
        set(handles.resolutionX, 'String', model.parameters.resolution.X);
        set(handles.resolutionY, 'String', model.parameters.resolution.Y);
        set(handles.resolutionZ, 'String', model.parameters.resolution.Z);
        % check for calibration
        try
            calibration = model.controllers.data.getCalibration('sample', 1);
            if ~isempty(calibration)
                set(handles.calibration, 'String', 'true');
            end
        catch
            set(handles.calibration, 'String', 'false');
        end
        set(handles.comment,  'String', model.file.comment);
    else
        set(handles.filename, 'String', '');
        set(handles.date, 'String', '');
        set(handles.resolutionX, 'String', '');
        set(handles.resolutionY, 'String', '');
        set(handles.resolutionZ, 'String', '');
        set(handles.calibration, 'String', '');
        set(handles.comment,  'String', '');
    end
    params = model.parameters.data;
    if isfield(params, 'flipud')
        set(handles.vertically, 'Value', params.flipud);
    end
    if isfield(params, 'fliplr')
        set(handles.horizontally, 'Value', params.fliplr);
    end
    set(handles.rotationGroup, 'SelectedObject', findobj('Tag', ['rotate_' num2str(params.rotate)]));
    
    reps = num2str((0:(model.repetitionCount-1)).');
    if (isempty(reps))
        reps = {''};
    end
    
    set(handles.repetition, 'String', reps);
    set(handles.repetition, 'Value', model.repetition+1);
    
    setups = fields(model.availableSetups);
    setup_names = cell(length(setups), 1);
    selectedSetup = NaN;
    for jj = 1:length(setups)
       setup_names{jj} = model.availableSetups.(setups{jj}).name;
       if strcmp(model.availableSetups.(setups{jj}).name, model.parameters.constants_setup.name)
           selectedSetup = jj;
       end
    end
    
    set(handles.setup, 'String', setup_names);
    set(handles.setup, 'Value', selectedSetup);
end
