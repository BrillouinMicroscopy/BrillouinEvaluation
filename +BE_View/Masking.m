function handles = Masking(parent, model)
%% MASKING View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    listener = addlistener(model, 'results', 'PostSet', ...
        @(o,e) initView(handles, e.AffectedObject));
    
    set(parent, 'CloseRequestFcn', {@closeMasking, listener});    
end

function handles = initGUI(model, parent)

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Brush size [�m]:', 'Units', 'normalized',...
        'Position', [0.02,0.7,0.15,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');

    brushSize = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.18,0.698,0.06,0.04], 'FontSize', 11, 'HorizontalAlignment', 'center');
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Brush type:', 'Units', 'normalized',...
        'Position', [0.02,0.765,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    brushAdd = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Add','Position',[0.19,0.762,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    brushRemove = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Remove','Position',[0.135,0.762,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    addMask = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/add.png']),'Position',[0.206,0.3,0.035,0.05],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    masksTable = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.35 0.22 0.3], ...
        'ColumnWidth', {86, 87}, 'ColumnName', {'Mask',''}, 'FontSize', 12, 'ColumnEditable', true);
    
    zoomIn = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/zoomin.png']), 'Position',[0.33,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(zoomIn, 'UserData', 0);

    zoomOut = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/zoomout.png']), 'Position',[0.375,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(zoomOut, 'UserData', 0);

    panButton = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/pan.png']), 'Position',[0.42,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(panButton, 'UserData', 0);

    rotate3dButton = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/rotate.png']), 'Position',[0.465,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(rotate3dButton, 'UserData', 0);

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Autoscale', 'Units', 'normalized',...
        'Position', [0.51,0.928,0.1,0.035], 'FontSize', 10, 'HorizontalAlignment', 'left');

    autoscale = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.58,0.93,0.017,0.034], 'FontSize', 11, 'HorizontalAlignment', 'left');

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Floor', 'Units', 'normalized',...
        'Position', [0.60,0.91,0.1,0.055], 'FontSize', 11, 'HorizontalAlignment', 'left');

    floor = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.65,0.92,0.075,0.055], 'FontSize', 11, 'HorizontalAlignment', 'center', 'Tag', 'floor');

    increaseFloor = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/up.png']), 'Position',[0.74,0.9475,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'floor');

    decreaseFloor = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/down.png']), 'Position',[0.74,0.92,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'floor');

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Cap', 'Units', 'normalized',...
        'Position', [0.79,0.91,0.1,0.055], 'FontSize', 11, 'HorizontalAlignment', 'left');

    cap = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.83,0.92,0.075,0.055], 'FontSize', 11, 'HorizontalAlignment', 'center', 'Tag', 'cap');

    increaseCap = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/up.png']), 'Position',[0.92,0.9475,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'cap');

    decreaseCap = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/down.png']), 'Position',[0.92,0.92,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'cap');

    axesImage = axes('Parent', parent, 'Position', [0.33 .085 .65 .8]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
%     zoom(gcf,'reset');
    zoomHandle = zoom;
    panHandle = pan;
    rotate3dHandle = rotate3d;
    
    ok = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','OK','Position',[0.02,0.03,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    cancel = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Cancel','Position',[0.14,0.03,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
%     set(brillouinImage, 'Visible', 'off');
    
    handles = struct(...
        'brushSize', brushSize, ...
        'brushAdd', brushAdd, ...
        'brushRemove', brushRemove, ...
        'addMask', addMask, ...
        'masksTable', masksTable, ...
        'parent', parent, ...
        'zoomIn', zoomIn, ...
        'zoomOut', zoomOut, ...
        'panButton', panButton, ...
        'rotate3dButton', rotate3dButton, ...
        'autoscale', autoscale, ...
        'cap', cap, ...
        'floor', floor, ...
        'increaseCap', increaseCap, ...
        'decreaseCap', decreaseCap, ...
        'increaseFloor', increaseFloor, ...
        'decreaseFloor', decreaseFloor, ...
        'zoomHandle', zoomHandle, ...
        'panHandle', panHandle, ...
        'rotate3dHandle', rotate3dHandle, ...
        'ok', ok, ...
        'cancel', cancel ...
    );
end

function closeMasking(source, ~, listener)
    delete(listener);
    delete(source);
end

function initView(handles, model) 
%% Initialize the view
%     bright = model.results.brightfield_rot;
%     if ~isfield(model.parameters.evaluation, 'xl')
%         model.parameters.evaluation.xl = NaN;
%         model.parameters.evaluation.yl = NaN;
%     end
%     xl = model.parameters.evaluation.xl;
%     yl = model.parameters.evaluation.yl;
%     
%     
%     data = model.results.BrillouinShift;
%     data = double(data);
%     if model.displaySettings.evaluation.discardInvalid && ~strcmp(model.displaySettings.evaluation.type, 'validty')
%         data(~model.results.validity) = NaN;
%         validity = model.results.peaksBrillouin_dev./model.results.peaksBrillouin_int;
%         data(validity > model.displaySettings.evaluation.valThreshould) = NaN;
%     end
%     
%     data = nanmean(data,4);
%     
%     imagesc(model.parameters.positions.X(1,:), model.parameters.positions.Y(:,1), data, 'Parent', handles.brillouinImage);
%     set(handles.brillouinImage,'YDir','normal');
%     hold on;
%     imagesc(1:size(bright,1), 1:size(bright,2), bright, 'Parent', handles.brightfieldImage);
%     set(handles.brightfieldImage,'YDir','normal');
%     
%     axis(handles.brillouinImage,'equal');
%     axis(handles.brightfieldImage,'equal');
%     
%     axis([0 size(bright,2) 0 size(bright,1)] + 0.5)
%     
%     zoom(gcf,'reset')
%     
%     if ~sum(isnan(xl)) && ~sum(isnan(yl))
%         axis([xl(1) xl(2) yl(1) yl(2)]);
%     end
end