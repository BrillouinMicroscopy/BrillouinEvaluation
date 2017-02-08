function handles = Evaluation(parent, model)
%% EVALUATION View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values
    handles.functions.plotData = @plotData;

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'results', 'PostSet', ...
        @(o,e) onResults(handles, e.AffectedObject));
    addlistener(model, 'displaySettings', 'PostSet', ...
        @(o,e) onDisplaySettings(handles, e.AffectedObject));
    addlistener(model, 'status', 'PostSet', ...
        @(o,e) onStatus(handles, e.AffectedObject));
end

function handles = initGUI(model, parent)

    evaluate = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Evaluate','Position',[0.02,0.92,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    newFig = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Open figure','Position',[0.14,0.92,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    plotTypes = uicontrol('Parent', parent, 'Style','popup', 'Units', 'normalized','Position',[0.02 0.85,0.22,0.055],...
        'String',model.labels.evaluation.types,'FontSize', 11, 'HorizontalAlignment', 'left');

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Live preview (2x slower)', 'Units', 'normalized',...
        'Position', [0.02,0.8,0.19,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');

    livePreview = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.22,0.8,0.04,0.034], 'FontSize', 11, 'HorizontalAlignment', 'left');

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

    progressBar = javax.swing.JProgressBar;
    javacomponent(progressBar,[19,20,208,30],parent);
    progressBar.setValue(0);
    progressBar.setStringPainted(true);
    progressBar.setString('0%');

    %% Return handles
    handles = struct(...
        'evaluate', evaluate, ...
        'newFig', newFig, ...
        'plotTypes', plotTypes, ...
        'livePreview', livePreview, ...
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
        'axesImage', axesImage, ...
        'zoomHandle', zoomHandle, ...
        'panHandle', panHandle, ...
        'rotate3dHandle', rotate3dHandle, ...
        'progressBar', progressBar ...
	);
end

function initView(handles, model)
%% Initialize the view
    onDisplaySettings(handles, model)
end

function onResults(handles, model)
    plotData(handles, model, 'int', 0);
end

function onStatus(handles, model)
    if model.status.evaluation.evaluate
        label = 'Stop';
    else
        label = 'Evaluate';
    end
    set(handles.evaluate, 'String', label);
end

function onDisplaySettings(handles, model)
    set(handles.autoscale, 'Value', model.displaySettings.evaluation.autoscale);
    set(handles.cap, 'String', model.displaySettings.evaluation.cap);
    set(handles.floor, 'String', model.displaySettings.evaluation.floor);
    if model.displaySettings.evaluation.autoscale
        caxis(handles.axesImage,'auto');
    else
        caxis(handles.axesImage,[model.displaySettings.evaluation.floor model.displaySettings.evaluation.cap]);
    end
    plotData(handles, model, 'int', 1);
end

function plotData (handles, model, location, full)

    data = model.results.(model.displaySettings.evaluation.type);
    data = mean(data,4);

    %% find non-singleton dimensions
    dimensions = size(data);
    dimension = sum(dimensions > 1);

    %% only update cdata for live preview
    if model.displaySettings.evaluation.preview && model.status.evaluation.evaluate && ~full
        try
            switch dimension
                case 1
                    set(model.handles.results, 'YData', data);
                case 2
                    set(model.handles.results, 'CData', data);
                case 3
                    for jj = 1:size(data,3)
                        set(model.handles.results(jj), 'CData', data(:,:,jj));
                    end
            end
            return;
        catch
        end
    end

    switch location
        case 'int'
            ax = handles.axesImage;
            [az, el] = view(handles.axesImage);
        case 'ext'
            fig = figure;
            ax = axes(fig);
            [az, el] = view(handles.evaluation.axesImage);
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
            nsdimslabel{ind} = dimslabel{jj};
        end
    end

    %% calculate zero mean positions
    for jj = 1:length(dims)
        positions.([dims{jj} '_zm']) = ...
            model.parameters.positions.(dims{jj}) - mean(model.parameters.positions.(dims{jj})(:))*ones(size(model.parameters.positions.(dims{jj})));
    end

    %% plot data for different dimensions
    switch dimension
        case 0
            %% 0D data
            model.handles.results = plot(ax,data);
%             disp(data(1,1,1));
        case 1
            %% 1D data
            d = squeeze(data);
            p = squeeze(positions.([nsdims{1} '_zm']));
            hold(ax,'off');
            model.handles.results = plot(ax,p,d);
            title(ax,labels.titleString);
            xlim(ax, [min(p(:)), max(p(:))]);
            xlabel(ax, ['$' nsdimslabel{1} '$ [$\mu$m]'], 'interpreter', 'latex');
            ylabel(ax, labels.dataLabel, 'interpreter', 'latex');
            box(ax, 'on');
            if model.displaySettings.evaluation.autoscale
%                 model.displaySettings.evaluation.floor = min(data(:));
%                 model.displaySettings.evaluation.cap = max(data(:));
                ylim(ax, 'auto');
            else
                ylim(ax, [model.displaySettings.evaluation.floor model.displaySettings.evaluation.cap]);
            end
            zoom(ax, 'reset');
        case 2
            %% 2D data
            d = squeeze(data);
            px = squeeze(positions.X_zm);
            py = squeeze(positions.Y_zm);
            pz = squeeze(positions.Z_zm);
            hold(ax,'off');
            model.handles.results = surf(ax,px, py, pz, d);
            title(ax,labels.titleString);
            shading(ax, 'flat');
            axis(ax, 'equal');
%             xlim([min(px(:)), max(px(:))]);
%             ylim([min(py(:)), max(py(:))]);
%             zlim([min(pz(:)), max(pz(:))]);
            xlabel(ax, '$x$ [$\mu$m]', 'interpreter', 'latex');
            ylabel(ax, '$y$ [$\mu$m]', 'interpreter', 'latex');
            zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
            cb = colorbar(ax);
            title(cb,labels.dataLabel, 'interpreter', 'latex');
            box(ax, 'on');
            if model.displaySettings.evaluation.autoscale
%                 [floor, cap] = checkCaxis(min(data(:)), max(data(:)));
%                 model.displaySettings.evaluation.floor = floor;
%                 model.displaySettings.evaluation.cap = cap;
                caxis(ax, 'auto');
            else
                caxis(ax, [model.displaySettings.evaluation.floor model.displaySettings.evaluation.cap]);
            end
            zoom(ax, 'reset');
            view(ax, [az el]);
        case 3
            %% 3D data
            hold(ax,'off');
            hndls = NaN(size(data,3),1);
            for jj = 1:size(data,3)
                hndls(jj) = surf(ax,positions.X_zm(:,:,jj),positions.Y_zm(:,:,jj),positions.Z_zm(:,:,jj),data(:,:,jj));
                hold(ax,'on');
            end
            model.handles.results = hndls;
            title(ax,labels.titleString);
            shading(ax, 'flat');
            axis(ax, 'equal');
            xlim([min(positions.X_zm(:)), max(positions.X_zm(:))]);
            ylim([min(positions.Y_zm(:)), max(positions.Y_zm(:))]);
            zlim([min(positions.Z_zm(:)), max(positions.Z_zm(:))]);
            xlabel(ax, '$x$ [$\mu$m]', 'interpreter', 'latex');
            ylabel(ax, '$y$ [$\mu$m]', 'interpreter', 'latex');
            zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
            cb = colorbar(ax);
            title(cb,labels.dataLabel, 'interpreter', 'latex');
            box(ax, 'on');
            if model.displaySettings.evaluation.autoscale
%                 [floor, cap] = checkCaxis(min(data(:)), max(data(:)));
%                 model.displaySettings.evaluation.floor = floor;
%                 model.displaySettings.evaluation.cap = cap;
                caxis(ax, 'auto');
            else
                caxis(ax, [model.displaySettings.evaluation.floor model.displaySettings.evaluation.cap]);
            end
            zoom(ax, 'reset');
            view(ax, [az el]);
    end
end

% function [floor, cap] = checkCaxis(floor, cap)
%     if floor >= cap
%         floor = floor - 0.05*abs(floor);
%         cap = cap + 0.05*abs(cap);
%     end
% end