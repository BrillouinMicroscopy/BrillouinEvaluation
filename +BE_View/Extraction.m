function handles = Extraction(parent, model)
%% CALIBRATION View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'file', 'PostSet', ...
        @(o,e) onFileLoad(handles, e.AffectedObject));
    addlistener(model, 'settings', 'PostSet', ...
        @(o,e) onSettingsChange(handles, e.AffectedObject));
end

function handles = initGUI(model, parent)

    manualPeaks = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Manually','Position',[0.02,0.92,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    autoPeaks = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Automatically','Position',[0.14,0.92,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Enable', 'off');
    
    optimizePeaks = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Optimize','Position',[0.02,0.85,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    clearPeaks = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.14,0.85,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    peakTable = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.5 0.22 0.3], ...
        'ColumnWidth', {86, 87}, 'ColumnName', {'x','y'}, 'FontSize', 12);
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Width of the Fit:', 'Units', 'normalized',...
        'Position', [0.02,0.42,0.14,0.03], 'FontSize', 11, 'HorizontalAlignment', 'left');
    width = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.14,0.41,0.1,0.05], 'FontSize', 11, 'HorizontalAlignment', 'center');
    
    % extraction axis selection
    extractionAxisGroup = uibuttongroup(parent, 'Units', 'normalized',...
        'Title','Extraction axis',...
        'Position', [0.02 0.22 0.105 0.14]);
    % Create three radio buttons in the button group.
    extractionAxis(1) = uicontrol(extractionAxisGroup,'Style','radiobutton',...
        'String','x',...
        'Position',[10 53 70 15]);
    extractionAxis(2) = uicontrol(extractionAxisGroup,'Style','radiobutton',...
        'String','y',...
        'Position',[10 31 70 15]);
    extractionAxis(3) = uicontrol(extractionAxisGroup,'Style','radiobutton',...
        'String','f',...
        'Position',[10 8 70 15]);
    
    % interpolation direction
    interpolationDirectionGroup = uibuttongroup(parent, 'Units', 'normalized',...
        'Title','Interpol. direction',...
        'Position', [0.135 0.22 0.105 0.14]);
    % Create three radio buttons in the button group.
    interpolationDirection(1) = uicontrol(interpolationDirectionGroup,'Style','radiobutton',...
        'String','x',...
        'Position',[10 53 70 15]);
    interpolationDirection(2) = uicontrol(interpolationDirectionGroup,'Style','radiobutton',...
        'String','y',...
        'Position',[10 31 70 15]);
    interpolationDirection(3) = uicontrol(interpolationDirectionGroup,'Style','radiobutton',...
        'String','f',...
        'Position',[10 8 70 15]);

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
        'Position', [0.48,0.928,0.1,0.035], 'FontSize', 10, 'HorizontalAlignment', 'left');

    autoscale = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.55,0.93,0.017,0.034], 'FontSize', 11, 'HorizontalAlignment', 'left');

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

    axesImage = axes('Parent', parent, 'Position', [0.33 .085 .65 .82]);
    axesImage.YDir = 'reverse';
    axis(axesImage, 'equal');
    hold(axesImage,'on');
    imageCamera = imagesc(axesImage, NaN);
    
    plotCenters = plot(axesImage, NaN, 'color', 'green', 'linestyle', '--', 'linewidth', 2, 'marker', 'x');
    plotBorders = plot(axesImage, NaN(2,2), 'color', 'red', 'linestyle', '--', 'linewidth', 2);
    model.handles.plotPositions = plot(axesImage, NaN, 'color', 'yellow');
    
    plotPeaks = plot(axesImage, NaN, 'Marker', 'x', ...
        'MarkerSize', 12, 'LineStyle', 'none', 'LineWidth', 2, 'Color', 'red');
    
    set(axesImage, 'box', 'on');
    xlabel(axesImage, '$x$ [pix]', 'interpreter', 'latex');
    ylabel(axesImage, '$y$ [pix]', 'interpreter', 'latex');
    zoom(gcf,'reset');
    zoomHandle = zoom;
    panHandle = pan;
    colorbar(axesImage);
    
    %% Return handles
    handles = struct( ...
        'axesImage', axesImage, ...
        'imageCamera', imageCamera, ...
        'plotPeaks', plotPeaks, ...
        'plotCenters', plotCenters, ...
        'plotBorders', plotBorders, ...
        'zoomHandle', zoomHandle, ...
        'selectPeaks', manualPeaks, ...
        'optimizePeaks', optimizePeaks, ...
        'clearPeaks', clearPeaks, ...
        'autoPeaks', autoPeaks, ...
        'peakTable', peakTable, ...
        'autoscale', autoscale, ...
        'cap', cap, ...
        'floor', floor, ...
        'increaseCap', increaseCap, ...
        'decreaseCap', decreaseCap, ...
        'increaseFloor', increaseFloor, ...
        'decreaseFloor', decreaseFloor, ...
        'zoomIn', zoomIn, ...
        'zoomOut', zoomOut, ...
        'panButton', panButton, ...
        'panHandle', panHandle, ...
        'extractionAxisGroup', extractionAxisGroup, ...
        'extractionAxis', extractionAxis, ...
        'interpolationDirectionGroup', interpolationDirectionGroup, ...
        'interpolationDirection', interpolationDirection, ...
        'width', width ...
	);
end

function initView(handles, model)
%% Initialize the view
    onFileLoad(handles, model);
    onSettingsChange(handles, model);
end

function onFileLoad(handles, model)
    if isa(model.file, 'Utils.HDF5Storage.h5bm') && isvalid(model.file)
        img = model.file.readPayloadData(1, 1, 1, 'data');
        img = img(:,:,model.settings.extraction.imageNr);
        handles.imageCamera.CData = img;
        colorbar(handles.axesImage);
        axis(handles.axesImage, [0.5 size(img,2)+0.5 0.5 size(img,1)+0.5]);
        
        % set start values for spectrum axis fitting
        % probably a better algorithm needed
        model.settings.extraction.circleStart = [1, size(img,1), mean(size(img))];

        if model.settings.extraction.autoscale
            caxis(handles.axesImage,'auto');
        else
            caxis(handles.axesImage,[model.settings.extraction.floor model.settings.extraction.cap]);
        end
        zoom(handles.axesImage,'reset');
    end
end

function onSettingsChange(handles, model)
    if model.settings.extraction.autoscale
        caxis(handles.axesImage,'auto');
    else
        caxis(handles.axesImage,[model.settings.extraction.floor model.settings.extraction.cap]);
    end
    set(handles.autoscale, 'Value', model.settings.extraction.autoscale);
    set(handles.cap, 'String', model.settings.extraction.cap);
    set(handles.floor, 'String', model.settings.extraction.floor);
    
    set(handles.width, 'String', model.settings.extraction.width);
    
    set(handles.extractionAxisGroup,'SelectedObject',findall(handles.extractionAxis, 'String', model.settings.extraction.extractionAxis));
    set(handles.interpolationDirectionGroup,'SelectedObject',findall(handles.interpolationDirection, 'String', model.settings.extraction.interpolationDirection));
    
    if ~sum(isnan(model.settings.extraction.peaks.x)) && ~sum(isnan(model.settings.extraction.peaks.y))
        handles.peakTable.Data = transpose([model.settings.extraction.peaks.x; model.settings.extraction.peaks.y]);
        handles.plotPeaks.XData = model.settings.extraction.peaks.x;
        handles.plotPeaks.YData = model.settings.extraction.peaks.y;
%         fitSpectrum(model);
%         if isa(model.file, 'Utils.HDF5Storage.h5bm') && isvalid(model.file)
%             getInterpolationPositions(handles, model);
%         end
    else
        handles.peakTable.Data = [];
    end
    showInterpolationPositions(handles, model);
end

function showInterpolationPositions(handles, model)
%% clean data for plotting to not show values outside the image
    if isa(model.file, 'Utils.HDF5Storage.h5bm') && isvalid(model.file)
        img = model.file.readPayloadData(1, 1, 1, 'data');
    else
        return;
    end
    centers = cleanArray(model.settings.extraction.interpolationCenters, img);
    borders = cleanArray(model.settings.extraction.interpolationBorders, img);
    positions = cleanArray(model.settings.extraction.interpolationPositions, img);
    
    function arr = cleanArray(arr, img)
        arr.x(arr.x > size(img,2)) = NaN;
        arr.x(arr.x < 1) = NaN;
        arr.y(arr.y > size(img,1)) = NaN;
        arr.y(arr.y < 1) = NaN;
    end

%% plot
    handles.plotCenters.XData = centers.x;
    handles.plotCenters.YData = centers.y;
    if ~isempty(borders.x) && ~isempty(borders.y)
        set(handles.plotBorders, {'XData'}, num2cell(borders.x,2));
        set(handles.plotBorders, {'YData'}, num2cell(borders.y,2));
    else
        set(handles.plotBorders, {'XData'}, {[];[]});
        set(handles.plotBorders, {'YData'}, {[];[]});
    end
    delete(model.handles.plotPositions);
    model.handles.plotPositions = plot(handles.axesImage, positions.x, positions.y, 'color', 'yellow');
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