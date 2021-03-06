function handles = Masking(parent, model)
%% MASKING View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    listener(1) = addlistener(model, 'tmp', 'PostSet', ...
        @(o,e) initView(handles, e.AffectedObject));
    listener(2) = addlistener(model, 'displaySettings', 'PostSet', ...
        @(o,e) onDisplaySettings(handles, e.AffectedObject));
    listener(3) = addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onParameters(handles, e.AffectedObject));
    
    set(parent, 'CloseRequestFcn', {@closeMasking, listener, model});    
end

function handles = initGUI(model, parent)

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Brush size [µm]:', 'Units', 'normalized',...
        'Position', [0.02,0.7,0.15,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');

    brushSize = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.18,0.698,0.06,0.04], 'FontSize', 11, 'HorizontalAlignment', 'center');
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Brush type:', 'Units', 'normalized',...
        'Position', [0.02,0.765,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    brushAdd = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String',BE_SharedFunctions.iconString([model.pp '/images/brush.png']),'Position',[0.20,0.762,0.04,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    brushRemove = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String',BE_SharedFunctions.iconString([model.pp '/images/rubber.png']),'Position',[0.155,0.762,0.04,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    masksTable = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.35 0.22 0.3], ...
        'ColumnWidth', {86, 87}, 'ColumnName', {'Mask','Transparency'}, 'FontSize', 12, 'ColumnEditable', true);
    
    deleteMask = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/delete.png']),'Position',[0.170,0.3,0.035,0.05],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    addMask = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/add.png']),'Position',[0.206,0.3,0.035,0.05],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Show as overlay:', 'Units', 'normalized',...
        'Position', [0.02,0.25,0.19,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');

    showOverlay = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.22,0.25,0.04,0.034], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
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
    hold on;
    hImage = imagesc(axesImage, NaN);
    hMask = imagesc(axesImage, NaN);
    hPointer = imagesc(axesImage, NaN);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
    colormap(axesImage, BE_Utils.Colormaps.viridis);
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
    
    handles = struct(...
        'brushSize',        brushSize, ...
        'brushAdd',         brushAdd, ...
        'brushRemove',      brushRemove, ...
        'addMask',          addMask, ...
        'deleteMask',       deleteMask, ...
        'showOverlay',      showOverlay, ...
        'masksTable',       masksTable, ...
        'parent',           parent, ...
        'zoomIn',           zoomIn, ...
        'zoomOut',          zoomOut, ...
        'panButton',        panButton, ...
        'rotate3dButton',   rotate3dButton, ...
        'autoscale',        autoscale, ...
        'cap',              cap, ...
        'floor',            floor, ...
        'increaseCap',      increaseCap, ...
        'decreaseCap',      decreaseCap, ...
        'increaseFloor',    increaseFloor, ...
        'decreaseFloor',    decreaseFloor, ...
        'axesImage',        axesImage, ...
        'hImage',           hImage, ...
        'hMask',            hMask, ...
        'hPointer',         hPointer, ...
        'zoomHandle',       zoomHandle, ...
        'panHandle',        panHandle, ...
        'rotate3dHandle',   rotate3dHandle, ...
        'ok',               ok, ...
        'cancel',           cancel ...
    );
end

function closeMasking(source, ~, listener, model)
    if isfield(model.tmp, 'masks')
        model.tmp = rmfield(model.tmp, 'masks');
    end
    delete(listener);
    delete(source);
end

function initView(handles, model) 
%% Initialize the view
    if ~isfield(model.tmp, 'masks')
        return;
    end
    set(handles.brushSize, 'String', model.parameters.masking.brushSize);
    set(handles.showOverlay, 'Value', model.displaySettings.masking.showOverlay);
    
    if model.parameters.masking.adding
        set(handles.brushAdd, 'BackgroundColor', [0.5 0.8 1]);
    else
        set(handles.brushRemove, 'BackgroundColor', [0.5 0.8 1]);
    end
    
    masks = model.tmp.masks;
    names = fields(masks);
    masksData = cell(length(names),2);
    for jj = 1:length(names)
        masksData{jj,1} = masks.(names{jj}).name;
        masksData{jj,2} = masks.(names{jj}).transparency;
    end
    
    handles.masksTable.Data = masksData;
    
    onDisplaySettings(handles, model);
end

function onParameters(handles, model) 
    if model.parameters.masking.adding
        set(handles.brushAdd, 'BackgroundColor', [0.5 0.8 1]);
        set(handles.brushRemove, 'BackgroundColor', [0.94 0.94 0.94]);
    else
        set(handles.brushAdd, 'BackgroundColor', [0.94 0.94 0.94]);
        set(handles.brushRemove, 'BackgroundColor', [0.5 0.8 1]);
    end
end

function plotBrillouinImage(handles, model)

    data = model.results.(model.displaySettings.evaluation.type);
    data = double(data);
    if ~strcmp(model.displaySettings.evaluation.type, 'brightfield')
        if model.displaySettings.evaluation.discardInvalid && ~strcmp(model.displaySettings.evaluation.type, 'validity')
            data(~model.results.validity) = NaN;
            validity = model.results.peaksBrillouin_dev./model.results.peaksBrillouin_int;
            data(validity > model.displaySettings.evaluation.valThreshould) = NaN;
        end
    end
    data = nanmean(data,5);
    data = nanmean(data,4);

    %% find non-singleton dimensions
    dimensions = struct( ...
        'count', 3, ...
        'names' , {{'X', 'Y', 'Z'}}, ...
        'orders', [2, 1, 3], ...
        'indices', {{ {1, ':', 1}, {':', 1, 1}, {1, 1, ':'} }}, ... 
        'labels', {{'$x$ [$\mu$m]', '$y$ [$\mu$m]', '$z$ [$\mu$m]'}} ...
    );

    dimLength = size(data, 1, 2, 3);
    nsdimensions = struct( ...
        'count', sum(dimLength > 1) ...
    );
    kk = 1;
    for jj = 1:dimensions.count
        if dimLength(dimensions.orders(jj)) > 1
            nsdimensions.names{kk} = dimensions.names{jj};
            nsdimensions.orders(kk) = dimensions.orders(jj);
            nsdimensions.indices{kk} = dimensions.indices{jj};
            nsdimensions.labels{kk} = dimensions.labels{jj};
            kk = kk + 1;
        end
    end
    
    labels = model.labels.evaluation.typesLabels.(model.displaySettings.evaluation.type);
    
    %% calculate zero mean positions
    for jj = 1:dimensions.count
        positions.([dimensions.names{jj} '_zm']) = model.parameters.positions.(dimensions.names{jj}) - ...
            mean(model.parameters.positions.(dimensions.names{jj})(:))*ones(size(model.parameters.positions.(dimensions.names{jj})));
    end
    %% plot
    data = squeeze(data);
    switch nsdimensions.count
        case 2
            %% Transpose the data if necessary
            if (nsdimensions.orders(1) < nsdimensions.orders(2))
                data = transpose(data);
            end
            
            %% Plot the data
            hold(handles.axesImage,'off');
            handles.hImage.XData = squeeze(positions.([nsdimensions.names{1} '_zm'])(nsdimensions.indices{1}{:}));
            handles.hImage.YData = squeeze(positions.([nsdimensions.names{2} '_zm'])(nsdimensions.indices{2}{:}));
            handles.hImage.CData = data;
            handles.hImage.AlphaData = ~isnan(data);
            title(handles.axesImage,labels.titleString);
            axis(handles.axesImage, 'equal');
            xlim(handles.axesImage, [min(handles.hImage.XData(:)), max(handles.hImage.XData(:))]);
            ylim(handles.axesImage, [min(handles.hImage.YData(:)), max(handles.hImage.YData(:))]);

            xlabel(handles.axesImage, nsdimensions.labels{1}, 'interpreter', 'latex');
            ylabel(handles.axesImage, nsdimensions.labels{2}, 'interpreter', 'latex');
            cb = colorbar(handles.axesImage);
            title(cb,labels.dataLabel, 'interpreter', 'latex');
            box(handles.axesImage, 'on');
            
            if model.displaySettings.masking.autoscale
                caxis(handles.axesImage, [min(data(:)); max(data(:))]);
            elseif model.displaySettings.masking.floor < model.displaySettings.masking.cap
                caxis(handles.axesImage, [model.displaySettings.masking.floor model.displaySettings.masking.cap]);
            end
            zoom(handles.axesImage, 'reset');
            set(handles.axesImage, 'YDir', 'normal');

            %% Plot the selected mask
            pointer = zeros(size(data));
            pointerColor = [0 0 1];
            pointerRGB = cat(3, pointerColor(1)*ones(size(pointer)), pointerColor(2)*ones(size(pointer)), pointerColor(3)*ones(size(pointer)));
            % update mask data
            handles.hMask.XData = handles.hImage.XData;
            handles.hMask.YData = handles.hImage.YData;
            % update pointer data
            handles.hPointer.XData = handles.hImage.XData;
            handles.hPointer.YData = handles.hImage.YData;
            handles.hPointer.CData = pointerRGB;
            handles.hPointer.AlphaData = 0.4*double(pointer);
            selectedMask = model.displaySettings.masking.selected;
            if isfield(model.tmp.masks, selectedMask)
                mask = model.tmp.masks.(selectedMask);
                maskData = squeeze(mask.mask);
                if (nsdimensions.orders(1) < nsdimensions.orders(2))
                    maskData = transpose(maskData);
                end
                maskRGB = cat(3, mask.color(1)*ones(size(maskData)), mask.color(2)*ones(size(maskData)), mask.color(3)*ones(size(maskData)));
                handles.hMask.CData = maskRGB;
                handles.hMask.AlphaData = 0.4*double(maskData);
            else
                handles.hMask.CData = zeros(size(data));
                handles.hMask.AlphaData = zeros(size(data));
            end
            if ~model.displaySettings.masking.showOverlay
                handles.hImage.AlphaData = zeros(size(data));
            end
    end
end

function onDisplaySettings(handles, model)
    set(handles.autoscale, 'Value', model.displaySettings.masking.autoscale);
    set(handles.cap, 'String', model.displaySettings.masking.cap);
    set(handles.floor, 'String', model.displaySettings.masking.floor);
    
    data = model.results.(model.displaySettings.evaluation.type);
    data = double(data);
    if ~strcmp(model.displaySettings.evaluation.type, 'brightfield')
        if model.displaySettings.evaluation.discardInvalid && ~strcmp(model.displaySettings.evaluation.type, 'validity')
            data(~model.results.validity) = NaN;
            validity = model.results.peaksBrillouin_dev./model.results.peaksBrillouin_int;
            data(validity > model.displaySettings.evaluation.valThreshould) = NaN;
        end
    end
    data = nanmean(data,5);
    data = squeeze(nanmean(data,4));
    
    if ~model.displaySettings.masking.showOverlay
        handles.hImage.AlphaData = zeros(size(data));
    else
        handles.hImage.AlphaData = ~isnan(data);
    end
    
    plotBrillouinImage(handles, model);
end