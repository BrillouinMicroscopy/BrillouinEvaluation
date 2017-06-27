function masking = Masking(model, view)
%% EVALUATION Controller

    %% callbacks Masking
    set(view.masking.zoomIn, 'Callback', {@zoomCallback, 'in', view});
    set(view.masking.zoomOut, 'Callback', {@zoomCallback, 'out', view});
    set(view.masking.panButton, 'Callback', {@pan, view});
    set(view.masking.rotate3dButton, 'Callback', {@rotate3d, view});
    set(view.masking.brushAdd, 'Callback', {@setMode, model, 1});
    set(view.masking.brushRemove, 'Callback', {@setMode, model, 0});
    
    set(view.masking.masksTable, 'CellSelectionCallback', {@selectMask, model, view});
    set(view.masking.masksTable, 'CellEditCallback', {@renameMask, model});
    
    set(view.masking.addMask, 'Callback', {@addMask, model});
    
    set(view.masking.cancel, 'Callback', {@cancel, view});
    
    set(view.masking.showOverlay, 'Callback', {@toggleOverlay, view, model});
    
    %% make mask global for now to improve performance
    global mask;
    selectedMask = model.displaySettings.masking.selected;
    if isfield(model.results.masks, selectedMask)
        mask = model.results.masks.(selectedMask);
    end
    
    %% Callbacks related to masking
    % Motion function
    dims = {'X', 'Y', 'Z'};
    for kk = 1:length(dims)
        pos.([dims{kk} '_zm']) = ...
            model.parameters.positions.(dims{kk}) - ...
            mean(model.parameters.positions.(dims{kk})(:))*ones(size(model.parameters.positions.(dims{kk})));
        pos.([dims{kk} '_zm']) = squeeze(pos.([dims{kk} '_zm']));
    end
    brushSize = model.parameters.masking.brushSize;
%     axInfo = getAxInfo(view.masking.axesImage);
    MotionFcnCallback = @(src, data) DrawPointer(src, data, view.masking.parent, view.masking.axesImage, view.masking.hPointer, pos, brushSize);
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
    global mask;
    mask.mask(logical(m)) = adding;
    set(hMask,'AlphaData',0.4*double(mask.mask));
end

function EndDrawing(src, ~, MotionFcnCallback, model)
    set(src, 'WindowButtonMotionFcn', MotionFcnCallback);
    selectedMask = model.displaySettings.masking.selected;
    global mask;
    model.results.masks.(selectedMask) = mask;
end

function pointer = DrawPointer(~, ~, fh, axInfo, hPointer, pos, brushSize)
    cp = getCurrentAxesPoint(fh, axInfo);
    
    if ~isempty(cp)
        pointer = sqrt((pos.X_zm-cp(1)).^2+(pos.Y_zm-cp(2)).^2) <= (brushSize);
        set(hPointer, 'AlphaData', 0.6*pointer);
    else
        pointer = [];
    end
end

function zoomCallback(src, ~, str, view)
    switch get(src, 'UserData')
        case 0
            set(view.masking.panButton,'UserData',0);
            set(view.masking.panHandle,'Enable','off');
            set(view.masking.rotate3dButton,'UserData',0);
            set(view.masking.rotate3dHandle,'Enable','off');
            switch str
                case 'in'
                    set(view.masking.zoomHandle,'Enable','on','Direction','in');
                    set(view.masking.zoomIn,'UserData',1);
                    set(view.masking.zoomOut,'UserData',0);
                case 'out'
                    set(view.masking.zoomHandle,'Enable','on','Direction','out');
                    set(view.masking.zoomOut,'UserData',1);
                    set(view.masking.zoomIn,'UserData',0);
            end
        case 1
            set(view.masking.zoomHandle,'Enable','off','Direction','in');
            set(view.masking.zoomOut,'UserData',0);
            set(view.masking.zoomIn,'UserData',0);
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

function selectMask(~, data, model, view)
    global mask;
    if ~isempty(data.Indices)
        type = sprintf('m%01.0d', data.Indices(1));
        model.displaySettings.masking.selected = type;
        mask = model.results.masks.(type);
        maskRGB = cat(3, mask.color(1)*ones(size(mask.mask)), mask.color(2)*ones(size(mask.mask)), mask.color(3)*ones(size(mask.mask)));
        view.masking.hMask.CData = maskRGB;
        view.masking.hMask.AlphaData = 0.4*double(mask.mask);
    end
end

function renameMask(~, data, model)
    type = sprintf('m%01.0d', data.Indices(1));
    switch data.Indices(2)
        case 1
            model.results.masks.(type).name = data.NewData;
        case 2
            model.results.masks.(type).transparency = data.NewData;
    end
end

function addMask(~, ~, model)
    masks = model.results.masks;
    maskFields = fields(masks);
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
    model.results.masks = masks;
end
 
function cancel(~, ~, view)
    close(view.masking.parent);
end

function toggleOverlay(~, ~, view, model)
    model.displaySettings.masking.showOverlay = get(view.masking.showOverlay, 'Value');
end

%% function for returning the current point
function point = getCurrentAxesPoint(fh, ax)

    axInfo = getAxInfo(ax);
    %% get the current point inside the figure
    cp = get(fh, 'currentpoint');

    %% check if current point is over axes
    tf1 = axInfo.Pos(1) <= cp(1) && cp(1) <= axInfo.Pos(1) + axInfo.Pos(3);
    tf2 = axInfo.Pos(2) <= cp(2) && cp(2) <= axInfo.Pos(2) + axInfo.Pos(4);

    if tf1 && tf2
        %% calculate the current point
        Cx = axInfo.LimX(1) + (cp(1)-axInfo.Pos(1)).*(axInfo.DifX/axInfo.Pos(3));
        Cy = axInfo.LimY(1) + (cp(2)-axInfo.Pos(2)).*(axInfo.DifY/axInfo.Pos(4));
        point = [Cx, Cy];
    else
        point = [];
    end
end

function axInfo = getAxInfo(ax)
    %% set axes units to pixels for easier calculations
    set(ax,'units','pixels');

    %% get position, x-limit and y-limit
    axInfo.Pos = get(ax, 'pos');
    axInfo.LimX = get(ax, 'xlim');
    axInfo.LimY = get(ax, 'ylim');
    axInfo.DifX = diff(axInfo.LimX);
    axInfo.DifY = diff(axInfo.LimY);

    %% reset the axes units
    set(ax, 'units', 'normalized');
end
 