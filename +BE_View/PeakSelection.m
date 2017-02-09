function handles = PeakSelection(parent, model)
%% PEAKSELECTION View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onSettings(handles, e.AffectedObject));
    addlistener(model, 'displaySettings', 'PostSet', ...
        @(o,e) onDisplaySettings(handles, e.AffectedObject));
    addlistener(model, 'status', 'PostSet', ...
        @(o,e) onStatus(handles, e.AffectedObject));
end

function handles = initGUI(model, parent)

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Brillouin peaks:', 'Units', 'normalized',...
        'Position', [0.02,0.94,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    selectBrillouin = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Select','Position',[0.02,0.885,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    clearBrillouin = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.14,0.885,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    peakTableBrillouin = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.72 0.22 0.15], ...
        'ColumnWidth', {86, 87}, 'ColumnName', {'start','end'}, 'FontSize', 12, 'ColumnEditable', true);

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Rayleigh peaks:', 'Units', 'normalized',...
        'Position', [0.02,0.67,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');

    selectRayleigh = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Select','Position',[0.02,0.615,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    clearRayleigh = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.14,0.615,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    peakTableRayleigh = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.45 0.22 0.15], ...
        'ColumnWidth', {86, 87}, 'ColumnName', {'start','end'}, 'FontSize', 12, 'ColumnEditable', true);

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

    cursorButton = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/cursor.png']), 'Position',[0.465,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(cursorButton, 'UserData', 0);

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
    brushHandle = brush;
    cursorHandle = datacursormode;
    set(cursorHandle, 'Enable', 'off');
    
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
        'cursorButton', cursorButton, ...
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
        'brushHandle', brushHandle, ...
        'cursorHandle', cursorHandle ...
	);
end

function initView(handles, model)
%% Initialize the view
    set(handles.autoscale, 'Value', model.displaySettings.peakSelection.autoscale);
    set(handles.cap, 'String', model.displaySettings.peakSelection.cap);
    set(handles.floor, 'String', model.displaySettings.peakSelection.floor);
end

function onStatus(handles, model)
    buttons = {'Brillouin', 'Rayleigh'};
    for jj = 1:length(buttons)
        if model.status.peakSelection.(['select' buttons{jj}])
            label = 'Done';
        else
            label = 'Select';
        end
        set(handles.(['select' buttons{jj}]), 'String', label);
    end
end

function onSettings(handles, model)
    handles.peakTableBrillouin.Data = model.parameters.peakSelection.Brillouin;
    handles.peakTableRayleigh.Data = model.parameters.peakSelection.Rayleigh;
    plotData(handles, model);
end

function onDisplaySettings(handles, model)
    set(handles.autoscale, 'Value', model.displaySettings.peakSelection.autoscale);
    set(handles.cap, 'String', model.displaySettings.peakSelection.cap);
    set(handles.floor, 'String', model.displaySettings.peakSelection.floor);
    if model.displaySettings.peakSelection.autoscale
        ylim(handles.axesImage,'auto');
    else
        ylim(handles.axesImage, [model.displaySettings.peakSelection.floor model.displaySettings.peakSelection.cap]);
    end
%     plotData(handles, model);
end

function plotData(handles, model)
    ax = handles.axesImage;
    imgs = model.file.readPayloadData(1, 1, 1, 'data');
    imgs = medfilt1(imgs,3);
    img = imgs(:,:,1);
    data = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction.interpolationPositions);
    data = data(~isnan(data));
    if ~isempty(data);
        hold(ax, 'off');
        xLabelString = '$f$ [pix]';
        
        x = 1:length(data);
        if ~isempty(model.parameters.calibration.values_mean.d) && ~isnan(model.parameters.calibration.values_mean.d)
            calibration = model.parameters.calibration.values_mean;
            calibration.x0 = calibration.x0(1,1,1,1);
            wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * x, calibration, model.parameters.constants, 1);
            x = 1e-9*BE_SharedFunctions.getFrequencyShift(wavelength, model.parameters.constants.lambda0);
            
            xLabelString = '$f$ [GHz]';
        end
        
        model.handles.plotSpectrum = plot(ax, x, data);
        hold(ax, 'on');
        ind = model.parameters.peakSelection.Rayleigh;
        for jj = 1:size(ind,1)
            ix = ind(jj,1):ind(jj,2);
            if ind(jj,1) > 0 && ind(jj,2) <= length(data)
                plot(ax, x(ix), data(ix), 'color', [1, 0, 0, 0.4], 'linewidth', 5);
            end
        end
        ind = model.parameters.peakSelection.Brillouin;
        for jj = 1:size(ind,1)
            ix = ind(jj,1):ind(jj,2);
            if ind(jj,1) > 0 && ind(jj,2) <= length(data)
                plot(ax, x(ix), data(ix), 'color', [0, 0, 1, 0.4], 'linewidth', 5);
            end
        end
        if model.displaySettings.peakSelection.autoscale
            ylim(ax, 'auto');
        else
            ylim(ax, [model.displaySettings.peakSelection.floor model.displaySettings.peakSelection.cap]);
        end
        xlim(ax, [min(x(:)) max(x(:))]);
        zoom(ax, 'reset');
        xlabel(ax, xLabelString, 'interpreter', 'latex');
        ylabel(ax, '$I$ [a.u.]', 'interpreter', 'latex');
    end
end