function handles = Masking(parent, model)
%% MASKING View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    listener(1) = addlistener(model, 'results', 'PostSet', ...
        @(o,e) initView(handles, e.AffectedObject));
    listener(2) = addlistener(model, 'displaySettings', 'PostSet', ...
        @(o,e) toggleOverlay(handles, e.AffectedObject));
    
    set(parent, 'CloseRequestFcn', {@closeMasking, listener});    
end

function handles = initGUI(model, parent)

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Brush size [µm]:', 'Units', 'normalized',...
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

function closeMasking(source, ~, listener)
    delete(listener);
    delete(source);
end

function initView(handles, model) 
%% Initialize the view
    set(handles.brushSize, 'String', model.parameters.masking.brushSize);
    set(handles.showOverlay, 'Value', model.displaySettings.masking.showOverlay);
    
    masks = model.results.masks;
    names = fields(masks);
    masksData = cell(length(names),2);
    for jj = 1:length(names)
        masksData{jj,1} = masks.(names{jj}).name;
        masksData{jj,2} = masks.(names{jj}).transparency;
    end
    
    handles.masksTable.Data = masksData;
    
    plotBrillouinImage(handles, model);
end

function plotBrillouinImage(handles, model)

    data = model.results.(model.displaySettings.evaluation.type);
    data = double(data);
    if ~strcmp(model.displaySettings.evaluation.type, 'brightfield') && ~strcmp(model.displaySettings.evaluation.type, 'calibrationFrequency')
        if model.displaySettings.evaluation.discardInvalid && ~strcmp(model.displaySettings.evaluation.type, 'validity')
            data(~model.results.validity) = NaN;
            validity = model.results.peaksBrillouin_dev./model.results.peaksBrillouin_int;
            data(validity > model.displaySettings.evaluation.valThreshould) = NaN;
        end
    end
    data = nanmean(data,4);

    %% find non-singleton dimensions
    dimensions = size(data);
    dimension = sum(dimensions > 1);
    if strcmp(model.displaySettings.evaluation.type, 'calibrationFrequency')
        dimension = 1;
    end
    
    labels = model.labels.evaluation.typesLabels.(model.displaySettings.evaluation.type);
    
    %% define possible dimensions and their labels
    dims = {'Y', 'X', 'Z'};
    dimslabel = {'y', 'x', 'z'};

    nsdims = cell(dimension,1);
    nsdimslabel = cell(dimension,1);
    ind = 0;
    for jj = 1:length(dimensions)
        if dimensions(jj) > 1
            ind = ind + 1;
            nsdims{ind} = dims{jj};
            nsdimslabel{ind} = ['$' dimslabel{jj} '$ [$\mu$m]'];
        end
    end
    
    %% calculate zero mean positions
    for jj = 1:length(dims)
        positions.([dims{jj} '_zm']) = ...
            model.parameters.positions.(dims{jj}) - mean(model.parameters.positions.(dims{jj})(:))*ones(size(model.parameters.positions.(dims{jj})));
    end
    
    d = squeeze(data);
    pos.X_zm = squeeze(positions.X_zm);
    pos.Y_zm = squeeze(positions.Y_zm);
    pos.Z_zm = squeeze(positions.Z_zm);
    
    dimensions = size(d);
    dimension = sum(dimensions > 1);

    %% plot
    switch dimension
        case 2
            hold(handles.axesImage,'off');
            handles.hImage.XData = pos.X_zm(1,:);
            handles.hImage.YData = pos.Y_zm(:,1);
            handles.hImage.CData = d;
            handles.hImage.AlphaData = ~isnan(d);
            title(handles.axesImage,labels.titleString);
            axis(handles.axesImage, 'equal');
        %             xlim([min(px(:)), max(px(:))]);
        %             ylim([min(py(:)), max(py(:))]);
        %             zlim([min(pz(:)), max(pz(:))]);
            xlabel(handles.axesImage, '$x$ [$\mu$m]', 'interpreter', 'latex');
            ylabel(handles.axesImage, '$y$ [$\mu$m]', 'interpreter', 'latex');
            zlabel(handles.axesImage, '$z$ [$\mu$m]', 'interpreter', 'latex');
            cb = colorbar(handles.axesImage);
            title(cb,labels.dataLabel, 'interpreter', 'latex');
            box(handles.axesImage, 'on');
            if model.displaySettings.evaluation.autoscale
        %                 [floor, cap] = checkCaxis(min(data(:)), max(data(:)));
        %                 model.displaySettings.evaluation.floor = floor;
        %                 model.displaySettings.evaluation.cap = cap;
                caxis(handles.axesImage, 'auto');
            elseif model.displaySettings.evaluation.floor < model.displaySettings.evaluation.cap
                caxis(handles.axesImage, [model.displaySettings.evaluation.floor model.displaySettings.evaluation.cap]);
            end
            zoom(handles.axesImage, 'reset');
            set(handles.axesImage, 'YDir', 'normal');

            %% plot the selected mask
            pointer = zeros(size(d));
            pointerColor = [0 0 1];
            pointerRGB = cat(3, pointerColor(1)*ones(size(pointer)), pointerColor(2)*ones(size(pointer)), pointerColor(3)*ones(size(pointer)));
            % update mask data
            handles.hMask.XData = pos.X_zm(1,:);
            handles.hMask.YData = pos.Y_zm(:,1);
            % update pointer data
            handles.hPointer.XData = pos.X_zm(1,:);
            handles.hPointer.YData = pos.Y_zm(:,1);
            handles.hPointer.CData = pointerRGB;
            handles.hPointer.AlphaData = 0.4*double(pointer);
            selectedMask = model.displaySettings.masking.selected;
            if isfield(model.results.masks, selectedMask)
                mask = model.results.masks.(selectedMask);
                maskRGB = cat(3, mask.color(1)*ones(size(mask.mask)), mask.color(2)*ones(size(mask.mask)), mask.color(3)*ones(size(mask.mask)));
                handles.hMask.CData = maskRGB;
                handles.hMask.AlphaData = 0.4*double(mask.mask);
            else
                handles.hMask.CData = zeros(size(d));
                handles.hMask.AlphaData = zeros(size(d));
            end
            if ~model.displaySettings.masking.showOverlay
                handles.hImage.AlphaData = zeros(size(d));
            end
    end
end

function toggleOverlay(handles, model)
    data = model.results.(model.displaySettings.evaluation.type);
    data = double(data);
    if ~strcmp(model.displaySettings.evaluation.type, 'brightfield') && ~strcmp(model.displaySettings.evaluation.type, 'calibrationFrequency')
        if model.displaySettings.evaluation.discardInvalid && ~strcmp(model.displaySettings.evaluation.type, 'validity')
            data(~model.results.validity) = NaN;
            validity = model.results.peaksBrillouin_dev./model.results.peaksBrillouin_int;
            data(validity > model.displaySettings.evaluation.valThreshould) = NaN;
        end
    end
    data = squeeze(nanmean(data,4));
    
    if ~model.displaySettings.masking.showOverlay
        handles.hImage.AlphaData = zeros(size(data));
    else
        handles.hImage.AlphaData = ~isnan(data);
    end
end