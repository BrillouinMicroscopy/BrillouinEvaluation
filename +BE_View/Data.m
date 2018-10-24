function Data(view, model)
%% DATA View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'file', 'PostSet', ...
        @(o,e) onFileLoad(view, e.AffectedObject));
end

function initGUI(~, view)
    parent = view.data.parent;

    file_panel = uipanel('Parent', parent, 'Title', 'File', 'FontSize', 11,...
                 'Position', [.02 .03 .4 .95]);

    uicontrol('Parent', file_panel, 'Style','text','String','Selected file:', 'Units', 'normalized',...
               'Position',[0.05,0.85,0.3,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
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
               'Position',[0.35,0.85,0.6,0.05], 'FontSize', 11, 'HorizontalAlignment', 'left');
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
    
    %% Return handles
    view.data = struct(...
        'parent', parent, ...
        'filename', filename, ...
        'date', date, ...
        'resolutionX', resolutionX, ...
        'resolutionY', resolutionY, ...
        'resolutionZ', resolutionZ, ...
        'calibration', calibration, ...
        'comment', comment ...
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
        set(handles.date, 'String', model.file.date);
        set(handles.resolutionX, 'String', model.file.getResolutionX(model.mode, model.repetition));
        set(handles.resolutionY, 'String', model.file.getResolutionY(model.mode, model.repetition));
        set(handles.resolutionZ, 'String', model.file.getResolutionZ(model.mode, model.repetition));
        % check for calibration
        try
            calibration = model.file.readCalibrationData(model.mode, model.repetition, 'sample', 1);
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
end
