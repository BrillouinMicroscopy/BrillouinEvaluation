function handles = PeakSelection(parent, model)
%% CALIBRATION View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'settings', 'PostSet', ...
        @(o,e) onSettings(handles, e.AffectedObject));
    addlistener(model, 'displaySettings', 'PostSet', ...
        @(o,e) onDisplaySettings(handles, e.AffectedObject));
end

function handles = initGUI(model, parent)

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Brillouin peaks:', 'Units', 'normalized',...
        'Position', [0.02,0.92,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    selectBrillouin = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Select','Position',[0.02,0.865,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    clearBrillouin = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.14,0.865,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    peakTableBrillouin = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.7 0.22 0.15], ...
        'ColumnWidth', {86, 87}, 'ColumnName', {'start','end'}, 'FontSize', 12);

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Rayleigh peaks:', 'Units', 'normalized',...
        'Position', [0.02,0.65,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');

    selectRayleigh = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Select','Position',[0.02,0.595,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    clearRayleigh = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.14,0.595,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    peakTableRayleigh = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.43 0.22 0.15], ...
        'ColumnWidth', {86, 87}, 'ColumnName', {'start','end'}, 'FontSize', 12);

    zoomIn = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'CData', readTransparent([model.pp '/images/zoomin.png']), 'Position',[0.33,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(zoomIn, 'UserData', 0);
    
    zoomOut = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'CData', readTransparent([model.pp '/images/zoomout.png']), 'Position',[0.375,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(zoomOut, 'UserData', 0);
    
    panButton = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'CData', readTransparent([model.pp '/images/pan.png']), 'Position',[0.42,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(panButton, 'UserData', 0);

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Autoscale', 'Units', 'normalized',...
        'Position', [0.51,0.928,0.1,0.035], 'FontSize', 10, 'HorizontalAlignment', 'left');

    autoscale = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.58,0.93,0.017,0.034], 'FontSize', 11, 'HorizontalAlignment', 'left');

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Floor', 'Units', 'normalized',...
        'Position', [0.60,0.91,0.1,0.055], 'FontSize', 11, 'HorizontalAlignment', 'left');

    floor = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.65,0.92,0.075,0.055], 'FontSize', 11, 'HorizontalAlignment', 'center', 'Tag', 'floor');

    increaseFloor = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'CData', readTransparent([model.pp '/images/up.png']), 'Position',[0.74,0.9475,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'floor');

    decreaseFloor = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'CData', readTransparent([model.pp '/images/down.png']), 'Position',[0.74,0.92,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'floor');

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Cap', 'Units', 'normalized',...
        'Position', [0.79,0.91,0.1,0.055], 'FontSize', 11, 'HorizontalAlignment', 'left');

    cap = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.83,0.92,0.075,0.055], 'FontSize', 11, 'HorizontalAlignment', 'center', 'Tag', 'cap');

    increaseCap = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'CData', readTransparent([model.pp '/images/up.png']), 'Position',[0.92,0.9475,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'cap');

    decreaseCap = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'CData', readTransparent([model.pp '/images/down.png']), 'Position',[0.92,0.92,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'cap');
    
    axesImage = axes('Parent', parent, 'Position', [0.33 .085 .65 .8]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
%     zoom(gcf,'reset');
    zoomHandle = zoom;
    panHandle = pan;
    brushHandle = brush;
    
    %% Return handles
    handles = struct(...
        'selectBrillouin', selectBrillouin, ...
        'clearBrillouin', clearBrillouin, ...
        'peakTableBrillouin', peakTableBrillouin, ...
        'selectRayleigh', selectRayleigh, ...
        'clearRayleigh', clearRayleigh, ...
        'peakTableRayleigh', peakTableRayleigh, ...
        'zoomIn', zoomIn, ...
        'zoomOut', zoomOut, ...
        'panButton', panButton, ...
        'autoscale', autoscale, ...
        'cap', cap, ...
        'floor', floor, ...
        'increaseCap', increaseCap, ...
        'decreaseCap', decreaseCap, ...
        'increaseFloor', increaseFloor, ...
        'decreaseFloor', decreaseFloor, ...
        'axesImage', axesImage, ...
        'zoomHandle', zoomHandle, ...
        'panHandle', panHandle, ...
        'brushHandle', brushHandle ...
	);
end

function initView(handles, model)
%% Initialize the view
    set(handles.autoscale, 'Value', model.displaySettings.peakSelection.autoscale);
    set(handles.cap, 'String', model.displaySettings.peakSelection.cap);
    set(handles.floor, 'String', model.displaySettings.peakSelection.floor);
end

function onSettings(handles, model)
    handles.peakTableBrillouin.Data = model.settings.peakSelection.brillouin;
    handles.peakTableRayleigh.Data = model.settings.peakSelection.rayleigh;
    plotData(handles, model);
end

function onDisplaySettings(handles, model)
    set(handles.autoscale, 'Value', model.displaySettings.peakSelection.autoscale);
    set(handles.cap, 'String', model.displaySettings.peakSelection.cap);
    set(handles.floor, 'String', model.displaySettings.peakSelection.floor);
    plotData(handles, model);
end

function plotData(handles, model)
    ax = handles.axesImage;
    imgs = model.file.readPayloadData(1, 1, 1, 'data');
    imgs = medfilt1(imgs,3);
    img = imgs(:,:,1);
    data = getIntensity1D(img, model.settings.extraction.interpolationPositions);
    hold(ax, 'off');
    model.handles.plotSpectrum = plot(ax, data);
    hold(ax, 'on');
    ind = model.settings.peakSelection.rayleigh;
    for jj = 1:size(ind,1)
        ix = ind(jj,1):ind(jj,2);
        plot(ax, ix, data(ix), 'color', [1, 0, 0, 0.4], 'linewidth', 5);
    end
    ind = model.settings.peakSelection.brillouin;
    for jj = 1:size(ind,1)
        ix = ind(jj,1):ind(jj,2);
        plot(ax, ix, data(ix), 'color', [0, 0, 1, 0.4], 'linewidth', 5);
    end
    if model.displaySettings.peakSelection.autoscale
        model.displaySettings.peakSelection.floor = min(data(:));
        model.displaySettings.peakSelection.cap = max(data(:));
    end
    ylim(ax, [model.displaySettings.peakSelection.floor model.displaySettings.peakSelection.cap]);
    xlim(ax, [1 size(data,2)]);
    zoom(ax, 'reset');
end

function img = readTransparent(file)
	img = imread(file);
    img = double(img)/255;
    index1 = img(:,:,1) == 1;
    index2 = img(:,:,2) == 1;
    index3 = img(:,:,3) == 1;
    
    indexWhite = index1+index2+index3==3;
    for idx = 1 : 3
       rgb = img(:,:,idx);     % extract part of the image
       rgb(indexWhite) = NaN;  % set the white portion of the image to NaN
       img(:,:,idx) = rgb;     % substitute the update values
    end
end