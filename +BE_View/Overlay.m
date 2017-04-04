function handles = Overlay(parent, model)
%% OVERLAY View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    listener = addlistener(model, 'results', 'PostSet', ...
        @(o,e) initView(handles, e.AffectedObject));
    
    set(parent, 'CloseRequestFcn', {@closeOverlay, listener});    
end

function handles = initGUI(model, parent)
    
    zoomIn = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/zoomin.png']), 'Position',[0.26,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(zoomIn, 'UserData', 0);

    zoomOut = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/zoomout.png']), 'Position',[0.305,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(zoomOut, 'UserData', 0);

    panButton = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/pan.png']), 'Position',[0.35,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(panButton, 'UserData', 0);

    rotate3dButton = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/rotate.png']), 'Position',[0.395,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(rotate3dButton, 'UserData', 0);
    
    ok = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', 'OK', 'Position',[0.1,0.92,0.06,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    cancel = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', 'Cancel', 'Position',[0.167,0.92,0.08,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    sld1 = uicontrol('Style', 'slider', 'Min',1,'Max',50,'Value',1,...
        'Position', [650 110 120 20]); 
    
    uicontrol('Style','text', 'Position',[650 135 120 20],...
        'String','Zoomslider');
    
    sld2 = uicontrol('Style', 'slider', 'Min',0,'Max',100,'Value',50,...
        'Position', [650 55 120 20]); 
    
    uicontrol('Style','text', 'Position',[650 80 120 20],...
        'String','Transparencyslider');
    
    sld3 = uicontrol('Style', 'slider', 'Min',0,'Max',720,'Value',180,...
        'Position', [650 165 120 20]); 
    
    uicontrol('Style','text', 'Position',[650 180 120 20],...
        'String','Angleslider');
    
    brillouinImage = axes('Parent', parent, 'Position', [0.1 .085 .575 .795]);
    brightfieldImage = axes('Parent', parent, 'Position', [0.1 .085 .575 .795]);
    zoomHandle = zoom;
    panHandle = pan;
    rotate3dHandle = rotate3d;
    model.handles.brightfield = brightfieldImage;
    
    set(brillouinImage, 'Visible', 'off');
    set(brightfieldImage, 'Visible', 'off');
    
    handles = struct(...
        'parent', parent, ...
        'zoomIn', zoomIn, ...
        'zoomOut', zoomOut, ...
        'panButton', panButton, ...
        'rotate3dButton', rotate3dButton, ...
        'brillouinImage', brillouinImage, ...
        'brightfieldImage', brightfieldImage, ...
        'zoomHandle', zoomHandle, ...
        'panHandle', panHandle, ...
        'rotate3dHandle', rotate3dHandle, ...
        'ok', ok, ...
        'cancel', cancel, ...
        'sld1', sld1, ...
        'sld2', sld2, ...
        'sld3', sld3 ...
    );
end

function closeOverlay(source, ~, listener)
    delete(listener);
    delete(source);
end

function initView(handles, model) 
%% Initialize the view
    bright = model.results.brightfield_rot;
    if ~isfield(model.parameters.evaluation, 'xl')
        model.parameters.evaluation.xl = NaN;
        model.parameters.evaluation.yl = NaN;
    end
    xl = model.parameters.evaluation.xl;
    yl = model.parameters.evaluation.yl;
    
    
    data = model.results.BrillouinShift;
    data = double(data);
    if model.displaySettings.evaluation.discardInvalid && ~strcmp(model.displaySettings.evaluation.type, 'validty')
        data(~model.results.validity) = NaN;
        validity = model.results.peaksBrillouin_dev./model.results.peaksBrillouin_int;
        data(validity > model.displaySettings.evaluation.valThreshould) = NaN;
    end
    
    data = nanmean(data,4);
    
    imagesc(model.parameters.positions.X(1,:), model.parameters.positions.Y(:,1), data, 'Parent', handles.brillouinImage);
    set(handles.brillouinImage,'YDir','normal');
    hold on;
    imagesc(1:size(bright,1), 1:size(bright,2), bright, 'Parent', handles.brightfieldImage);
    set(handles.brightfieldImage,'YDir','normal');
    hold off;
    
    axis(handles.brillouinImage,'equal');
    axis(handles.brightfieldImage,'equal');
    
    axis([0 size(bright,2) 0 size(bright,1)] + 0.5)
    
    zoom(gcf,'reset')
    
    if ~sum(isnan(xl)) && ~sum(isnan(yl))
       axis([xl(1) xl(2) yl(1) yl(2)]);
    end
end