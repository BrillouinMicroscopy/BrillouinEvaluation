function handles = Data(parent, model)
%% DATA View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'file', 'PostSet', ...
        @(o,e) onFileLoad(handles, e.AffectedObject));
end

function handles = initGUI(~, parent)

file_panel = uipanel('Parent', parent, 'Title', 'File', 'FontSize', 11,...
             'Position', [.02 .03 .4 .95]);

clear = uicontrol('Parent', file_panel, 'Style','pushbutton', 'Units', 'normalized',...
             'String','Clear','Position',[0.53,0.94,0.2,0.05],...
             'FontSize', 11, 'HorizontalAlignment', 'left');
load = uicontrol('Parent', file_panel, 'Style','pushbutton', 'Units', 'normalized',...
             'String','Load file','Position',[0.76,0.94,0.2,0.05],...
             'FontSize', 11, 'HorizontalAlignment', 'left');
         
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
    handles = struct(...
        'load', load, ...
        'clear', clear, ...
        'filename', filename, ...
        'date', date, ...
        'resolutionX', resolutionX, ...
        'resolutionY', resolutionY, ...
        'resolutionZ', resolutionZ, ...
        'calibration', calibration, ...
        'comment', comment ...
	);
end

function initView(handles, model)
%% Initialize the view
    onFileLoad(handles, model)
end

function onFileLoad(handles, model)
    if isa(model.file,'BE_Utils.HDF5Storage.h5bm') && isvalid(model.file)
        set(handles.filename, 'String', model.filename);
        set(handles.date, 'String', model.file.date);
        set(handles.resolutionX, 'String', model.file.resolutionX);
        set(handles.resolutionY, 'String', model.file.resolutionY);
        set(handles.resolutionZ, 'String', model.file.resolutionZ);
        % check for calibration
        try
            calibration = model.file.readCalibrationData(1,'sample');
            if ~isempty(calibration)
                set(handles.calibration, 'String', 'true');
            end
        catch
            set(handles.calibration, 'String', 'false');
        end
        set(handles.comment,  'String', model.file.comment);
        delete(model.handles.plotPositions);
%         delete(model.handles.results);
        model.handles = struct( ...
            'resutls', NaN, ...
            'plotPositions', NaN ...
        );
        model.results = struct( ...
            'BrillouinShift', NaN, ...              % [GHz]  the Brillouin shift
            'BrillouinShift_frequency', NaN, ...    % [GHz]  the Brillouin shift in Hz
            'peaksBrillouin_pos', NaN, ...          % [pix]  the position of the Brillouin peak(s) in the spectrum
            'peaksBrillouin_dev', NaN, ...          % [pix]  the deviation of the Brillouin fit
            'peaksBrillouin_int', NaN, ...          % [a.u.] the intensity of the Brillouin peak(s)
            'peaksBrillouin_fwhm', NaN, ...         % [pix]  the FWHM of the Brillouin peak
            'peaksRayleigh_pos', NaN, ...           % [pix]  the position of the Rayleigh peak(s) in the spectrum
            'intensity', NaN ...                    % [a.u.] the overall intensity of the image
        );
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
