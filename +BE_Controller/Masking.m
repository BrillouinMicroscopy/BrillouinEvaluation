function masking = Masking(model, view)
%% EVALUATION Controller

    %% callbacks Masking
    set(view.masking.zoomIn, 'Callback', {@zoomCallback, 'in', view});
    set(view.masking.zoomOut, 'Callback', {@zoomCallback, 'out', view});
    set(view.masking.panButton, 'Callback', {@pan, view});
    set(view.masking.rotate3dButton, 'Callback', {@rotate3d, view});
    set(view.masking.brushAdd, 'Callback', {@setMode, model, 1});
    set(view.masking.brushRemove, 'Callback', {@setMode, model, 0});
    
    set(view.masking.brushSize, 'Callback', {@setValue, model, 'brushSize'});
    
    set(view.masking.masksTable, 'CellSelectionCallback', {@selectMask, model, view});
    set(view.masking.masksTable, 'CellEditCallback', {@renameMask, model});
    
    set(view.masking.addMask, 'Callback', {@addMask, model});
    set(view.masking.deleteMask, 'Callback', {@deleteMask, model});
    
    set(view.masking.cancel, 'Callback', {@cancel, view});
    set(view.masking.ok, 'Callback', {@ok, model, view});
    
    set(view.masking.showOverlay, 'Callback', {@toggleOverlay, view, model});
    
    set(view.masking.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.masking.cap, 'Callback', {@setClim, model});
    set(view.masking.floor, 'Callback', {@setClim, model});
    
    set(view.masking.increaseFloor, 'Callback', {@changeClim, model, 1});
    set(view.masking.decreaseFloor, 'Callback', {@changeClim, model, -1});
    set(view.masking.increaseCap, 'Callback', {@changeClim, model, 1});
    set(view.masking.decreaseCap, 'Callback', {@changeClim, model, -1});
    
    %% make mask global for now to improve performance
    clear global mask;
    global mask;
    selectedMask = model.displaySettings.masking.selected;
    if isfield(model.tmp.masks, selectedMask)
        mask = model.tmp.masks.(selectedMask);
    else
        model.displaySettings.masking.selected = '';
    end
        
    
    %% Callbacks related to masking
    % Motion function
    data = model.results.(model.displaySettings.evaluation.type);
    data = double(data);
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

    for jj = 1:dimensions.count
        positions.([dimensions.names{jj} '_zm']) = model.parameters.positions.(dimensions.names{jj}) - ...
            mean(model.parameters.positions.(dimensions.names{jj})(:))*ones(size(model.parameters.positions.(dimensions.names{jj})));
    end
    
    x = squeeze(positions.([nsdimensions.names{1} '_zm']));
    y = squeeze(positions.([nsdimensions.names{2} '_zm']));
    
    global needsTranspose;
    needsTranspose = (nsdimensions.orders(1) < nsdimensions.orders(2));
    
    global brushSize;
    brushSize = model.parameters.masking.brushSize;
%     axInfo = getAxInfo(view.masking.axesImage);
    MotionFcnCallback = @(src, data) DrawPointer(src, data, view.masking.axesImage, view.masking.hPointer, x, y);
    set(view.masking.parent, 'WindowButtonMotionFcn', MotionFcnCallback);
    % ButtonDown function
    set(view.masking.parent,'WindowButtonDownFcn',{@StartDrawing, MotionFcnCallback, view.masking.hMask, model});
    % ButtonUp function
    set(view.masking.parent, 'WindowButtonUpFcn', {@EndDrawing, MotionFcnCallback, model});
    
    %%
    masking = struct( ...
    );
end

function [] = setMode(~, ~, model, mode)
    model.parameters.masking.adding = mode;
end

function setValue(src, ~, model, value)
    global brushSize
    model.parameters.masking.(value) = str2double(get(src, 'String'));
    if strcmp(value, 'brushSize')
        brushSize = str2double(get(src, 'String'));
    end
end

function [] = StartDrawing(src, ~, MotionFcnCallback, hMask, model)
    adding = model.parameters.masking.adding;
    movedraw(0, 0, MotionFcnCallback, hMask, adding);
    set(src, 'WindowButtonMotionFcn', {@movedraw, MotionFcnCallback, hMask, adding})
end

function movedraw(~, ~, MotionFcnCallback, hMask, adding)
    m = MotionFcnCallback(0,0);
    UpdateMask(hMask, m, adding);
end

function UpdateMask(hMask, m, adding)
    global mask needsTranspose;
    if ~isempty(mask)
        if needsTranspose
            m = transpose(m);
        end
        mask.mask(logical(m)) = adding;
        maskData = squeeze(mask.mask);
        if needsTranspose
            maskData = transpose(maskData);
        end
        set(hMask, 'AlphaData', 0.4*double(maskData));
    end
end

function EndDrawing(src, ~, MotionFcnCallback, model)
    set(src, 'WindowButtonMotionFcn', MotionFcnCallback);
    selectedMask = model.displaySettings.masking.selected;
    global mask;
    if isfield(model.tmp.masks, selectedMask)
        model.tmp.masks.(selectedMask) = mask;
    end
end

function pointer = DrawPointer(~, ~, axInfo, hPointer, x, y)
    cp = get(axInfo, 'currentpoint');
    cp = [cp(1, 1), cp(1, 2)];
    global brushSize needsTranspose;
    
    if ~isempty(cp)
        pointer = sqrt((x - cp(1)).^2 + (y - cp(2)).^2) <= (brushSize / 2);
        if needsTranspose
            pointer = transpose(pointer);
        end
        set(hPointer, 'AlphaData', 0.6 * pointer);
    else
        pointer = [];
    end
end

function zoomCallback(src, ~, str, view)
    switch get(src, 'UserData')
        case 0
            set(view.masking.panButton, 'UserData', 0);
            set(view.masking.panHandle, 'Enable', 'off');
            set(view.masking.rotate3dButton, 'UserData', 0);
            set(view.masking.rotate3dHandle, 'Enable', 'off');
            switch str
                case 'in'
                    set(view.masking.zoomHandle, 'Enable', 'on', 'Direction', 'in');
                    set(view.masking.zoomIn, 'UserData', 1);
                    set(view.masking.zoomOut, 'UserData', 0);
                case 'out'
                    set(view.masking.zoomHandle, 'Enable', 'on', 'Direction', 'out');
                    set(view.masking.zoomOut, 'UserData', 1);
                    set(view.masking.zoomIn, 'UserData', 0);
            end
        case 1
            set(view.masking.zoomHandle, 'Enable', 'off', 'Direction', 'in');
            set(view.masking.zoomOut, 'UserData', 0);
            set(view.masking.zoomIn, 'UserData', 0);
    end
end

function pan(src, ~, view)
    set(view.masking.zoomHandle,'Enable','off','Direction','in');
    set(view.masking.zoomOut,'UserData',0);
    set(view.masking.zoomIn,'UserData',0);
    set(view.masking.rotate3dButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.masking.panButton,'UserData',1);
            set(view.masking.panHandle,'Enable','on');
        case 1
            set(view.masking.panButton,'UserData',0);
            set(view.masking.panHandle,'Enable','off');
    end
end

function rotate3d(src, ~, view)
    set(view.masking.zoomHandle,'Enable','off','Direction','in');
    set(view.masking.zoomOut,'UserData',0);
    set(view.masking.zoomIn,'UserData',0);
    set(view.masking.panHandle,'Enable','off');
    set(view.masking.panButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.masking.rotate3dButton,'UserData',1);
            set(view.masking.rotate3dHandle,'Enable','on');
        case 1
            set(view.masking.rotate3dButton,'UserData',0);
            set(view.masking.rotate3dHandle,'Enable','off');
    end
end

function setClim(UIControl, ~, model)
    masking = model.displaySettings.masking;
    field = get(UIControl, 'Tag');
    masking.(field) = str2double(get(UIControl, 'String'));
    masking.autoscale = 0;
    model.displaySettings.masking = masking;
end

function toggleAutoscale(~, ~, model, view)
    model.displaySettings.masking.autoscale = get(view.masking.autoscale, 'Value');
end

function changeClim(UIControl, ~, model, sign)
    masking = model.displaySettings.masking;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(masking.cap - masking.floor));
    masking.autoscale = 0;
    masking.(field) = masking.(field) + sign * dif;
    model.displaySettings.masking = masking;
end

function selectMask(~, data, model, view)
    global mask needsTranspose;
    if ~isempty(data.Indices)
        masks = model.tmp.masks;
        maskFields = fieldnames(masks);
        selectedMask = maskFields{data.Indices(1)};
        model.displaySettings.masking.selected = selectedMask;
        mask = model.tmp.masks.(selectedMask);
        maskData = squeeze(mask.mask);
        if needsTranspose
            maskData = transpose(maskData);
        end
        maskRGB = cat(3, mask.color(1)*ones(size(maskData)), mask.color(2)*ones(size(maskData)), mask.color(3)*ones(size(maskData)));
        view.masking.hMask.CData = maskRGB;
        view.masking.hMask.AlphaData = 0.4*double(maskData);
    end
end

function renameMask(~, data, model)        
    masks = model.tmp.masks;
    maskFields = fieldnames(masks);
    selectedMask = maskFields{data.Indices(1)};
    switch data.Indices(2)
        case 1
            model.tmp.masks.(selectedMask).name = data.NewData;
        case 2
            model.tmp.masks.(selectedMask).transparency = data.NewData;
    end
end

function deleteMask(~, ~, model)
    masks = model.tmp.masks;
    selected = model.displaySettings.masking.selected;
    if isfield(masks, selected)
        masks = rmfield(masks, selected);
    end
    maskFields = fields(masks);
    if ~isempty(maskFields)
        model.displaySettings.masking.selected = maskFields{1};
    else
        model.displaySettings.masking.selected = '';
    end
    model.tmp.masks = masks;
end

function addMask(~, ~, model)
    masks = model.tmp.masks;
    maskFields = fields(masks);
    if isempty(maskFields)
        maskFields{1} = 'm00';
    end
    lastField = maskFields{end};
    jj = 1;
    lastNumber = str2double(lastField(2:end));
    newField = sprintf('m%01.0d', lastNumber + jj);
    while isfield(masks, newField)
        jj = jj + 1;
        newField = sprintf('m%01.0d', lastNumber + jj);
    end
    newName = 'newMask';
    
    res = model.parameters.resolution;
    masks.(newField) = struct( ...
        'name',         newName, ...
        'mask',         zeros(res.Y,res.X,res.Z), ...
        'transparency', 0.4, ...
        'color',        [1 0 0] ...
    );
    model.tmp.masks = masks;
end
 
function cancel(~, ~, view)
    close(view.masking.parent);
end
 
function ok(~, ~, model, view)
    model.results.masks = model.tmp.masks;
    close(view.masking.parent);
end

function toggleOverlay(~, ~, view, model)
    model.displaySettings.masking.showOverlay = get(view.masking.showOverlay, 'Value');
end
