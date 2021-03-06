function Extraction(view, model)
%% CALIBRATION View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'file', 'PostSet', ...
        @(o,e) onFileLoad(view, e.AffectedObject));
    addlistener(model, 'repetition', 'PostSet', ...
        @(o,e) onFileLoad(view, e.AffectedObject));
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onSettingsChange(view, e.AffectedObject));
    addlistener(model, 'displaySettings', 'PostSet', ...
        @(o,e) onDisplaySettings(view, e.AffectedObject));
    addlistener(model, 'status', 'PostSet', ...
        @(o,e) onStatus(view, e.AffectedObject));
end

function initGUI(model, view)

    parent = view.extraction.parent;

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Individual image number:', 'Units', 'normalized',...
        'Position', [0.02,0.94,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    sampleSelection = uicontrol('Parent', parent, 'Style','popup', 'Units', 'normalized','Position',[0.02,0.875,0.22,0.055],...
        'String',{''},'FontSize', 11, 'HorizontalAlignment', 'left');

    manualPeaks = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Select','Position',[0.02,0.800,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    optimizePeaks = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Optimize','Position',[0.14,0.800,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    clearPeaks = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.02,0.735,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    autoPeaks = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Autofind','Position',[0.14,0.735,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    peakTable = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.540 0.22 0.18], ...
        'ColumnWidth', {78, 77}, 'ColumnName', {'x','y'}, 'FontSize', 12);
    
    

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'General:', 'Units', 'normalized',...
        'Position', [0.02,0.49,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    clearPeaksAll = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.02,0.450,0.1,0.04],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    autoPeaksAll = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Autofind','Position',[0.14,0.450,0.1,0.04],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Overlay measurement', 'Units', 'normalized',...
        'Position', [0.02,0.395,0.2,0.04], 'FontSize', 11, 'HorizontalAlignment', 'left');

    overlay = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.224,0.399,0.02,0.04], 'FontSize', 11, 'HorizontalAlignment', 'left', 'tag', 'Positions');
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Width of the fit [pix]:', 'Units', 'normalized',...
        'Position', [0.02,0.355,0.17,0.03], 'FontSize', 11, 'HorizontalAlignment', 'left');
    width = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.17,0.345,0.07,0.05], 'FontSize', 11, 'HorizontalAlignment', 'center');
    
    % extraction axis selection
    extractionAxisGroup = uibuttongroup(parent, 'Units', 'normalized',...
        'Title','Extraction axis',...
        'Position', [0.02 0.20 0.105 0.14]);
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
        'Position', [0.135 0.20 0.105 0.14]);
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
    
    plotSelection = uipanel('Parent', parent, 'Title', 'Show graphs', 'FontSize', 11,...
             'Position', [.02 .04 .22 .16]);
    
    uicontrol('Parent', plotSelection, 'Style', 'text', 'String', 'Fit borders', 'Units', 'normalized',...
        'Position', [0.02,0.71,0.8,0.25], 'FontSize', 11, 'HorizontalAlignment', 'left');

    showBorders = uicontrol('Parent', plotSelection, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.85,0.725,0.1,0.2], 'FontSize', 11, 'HorizontalAlignment', 'left', 'tag', 'Borders');
    
    uicontrol('Parent', plotSelection, 'Style', 'text', 'String', 'Fit center', 'Units', 'normalized',...
        'Position', [0.02,0.41,0.9,0.25], 'FontSize', 11, 'HorizontalAlignment', 'left');

    showCenter = uicontrol('Parent', plotSelection, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.85,0.425,0.1,0.2], 'FontSize', 11, 'HorizontalAlignment', 'left', 'tag', 'Center');
    
    uicontrol('Parent', plotSelection, 'Style', 'text', 'String', 'Interpolation positions', 'Units', 'normalized',...
        'Position', [0.02,0.11,0.9,0.25], 'FontSize', 11, 'HorizontalAlignment', 'left');

    showPositions = uicontrol('Parent', plotSelection, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.85,0.125,0.1,0.2], 'FontSize', 11, 'HorizontalAlignment', 'left', 'tag', 'Positions');

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

    axesImage = axes('Parent', parent, 'Position', [0.33 .085 .65 .82]);
    axesImage.YDir = 'reverse';
    axis(axesImage, 'equal');
    hold(axesImage,'on');
    imageCamera = imagesc(NaN);
    
    plotCenters = plot(axesImage, NaN, 'color', 'green', 'linestyle', '--', 'linewidth', 2, 'marker', 'x');
    plotBorders = plot(axesImage, NaN(2,2), 'color', 'red', 'linestyle', '--', 'linewidth', 2);
    model.handles.plotPositions = plot(axesImage, NaN, 'color', 'yellow');
    
    plotPeaks = plot(axesImage, NaN, 'Marker', 'x', ...
        'MarkerSize', 12, 'LineStyle', 'none', 'LineWidth', 2, 'Color', 'red');
    
    set(axesImage, 'box', 'on');
    xlabel(axesImage, '$x$ [pix]', 'interpreter', 'latex');
    ylabel(axesImage, '$y$ [pix]', 'interpreter', 'latex');
    colormap(axesImage, BE_Utils.Colormaps.viridis);
    zoom(gcf,'reset');
    zoomHandle = zoom;
    panHandle = pan;
    cursorHandle = datacursormode;
    set(cursorHandle, 'Enable', 'off');
    colorbar(axesImage);
    
    %% Return handles
    view.extraction = struct( ...
        'parent', parent, ...
        'axesImage', axesImage, ...
        'imageCamera', imageCamera, ...
        'plotPeaks', plotPeaks, ...
        'plotCenters', plotCenters, ...
        'plotBorders', plotBorders, ...
        'zoomHandle', zoomHandle, ...
        'selectPeaks', manualPeaks, ...
        'optimizePeaks', optimizePeaks, ...
        'autoPeaks', autoPeaks, ...
        'autoPeaksAll', autoPeaksAll, ...
        'clearPeaks', clearPeaks, ...
        'clearPeaksAll', clearPeaksAll, ...
        'peakTable', peakTable, ...
        'sampleSelection', sampleSelection, ...
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
        'cursorButton', cursorButton, ...
        'cursorHandle', cursorHandle, ...
        'extractionAxisGroup', extractionAxisGroup, ...
        'extractionAxis', extractionAxis, ...
        'interpolationDirectionGroup', interpolationDirectionGroup, ...
        'interpolationDirection', interpolationDirection, ...
        'width', width, ...
        'overlay', overlay, ...
        'showBorders', showBorders, ...
        'showCenter', showCenter, ...
        'showPositions', showPositions ...
	);
end

function initView(view, model)
%% Initialize the view
    onFileLoad(view, model);
    onSettingsChange(view, model);
end

function onDisplaySettings(view, model)
    handles = view.extraction;
    set(handles.autoscale, 'Value', model.displaySettings.extraction.autoscale);
    set(handles.cap, 'String', model.displaySettings.extraction.cap);
    set(handles.floor, 'String', model.displaySettings.extraction.floor);
    if model.displaySettings.extraction.autoscale
        caxis(handles.axesImage,'auto');
    else
        if model.displaySettings.extraction.floor < model.displaySettings.extraction.cap
            caxis(handles.axesImage,[model.displaySettings.extraction.floor model.displaySettings.extraction.cap]);
        end
    end
    if model.displaySettings.extraction.showBorders
        set(handles.plotBorders, 'Visible', 'on');
    else
        set(handles.plotBorders, 'Visible', 'off');
    end
    if model.displaySettings.extraction.showCenter
        set(handles.plotCenters, 'Visible', 'on');
    else
        set(handles.plotCenters, 'Visible', 'off');
    end
    if model.displaySettings.extraction.showPositions
        set(model.handles.plotPositions, 'Visible', 'on');
    else
        set(model.handles.plotPositions, 'Visible', 'off');
    end
end

function onFileLoad(view, model)
    handles = view.extraction;
    if isa(model.file, 'BE_Utils.HDF5Storage.h5bm') && isvalid(model.file)
        try
            img = model.controllers.data.getCalibration('data', model.parameters.extraction.currentCalibrationNr);
        catch
            img = model.controllers.data.getPayload('data', 1, 1, 1);
        end
        img = nanmean(img, 3);
        handles.imageCamera.CData = img;
        colorbar(handles.axesImage);
        axis(handles.axesImage, [0.5 size(img,2)+0.5 0.5 size(img,1)+0.5]);

        if model.displaySettings.extraction.autoscale
            caxis(handles.axesImage,'auto');
        else
            caxis(handles.axesImage,[model.displaySettings.extraction.floor model.displaySettings.extraction.cap]);
        end
        zoom(handles.axesImage,'reset');
    end
    set(handles.showBorders, 'Value', model.displaySettings.extraction.showBorders);
    set(handles.showCenter, 'Value', model.displaySettings.extraction.showCenter);
    set(handles.showPositions, 'Value', model.displaySettings.extraction.showPositions);
end

function onStatus(view, model)
    if model.status.extraction.selectPeaks
        label = 'Done';
    else
        label = 'Select';
    end
    set(view.extraction.selectPeaks, 'String', label);
end

function onSettingsChange(view, model)
    handles = view.extraction;
    if isempty(fields(model.parameters.calibration.samples))
        return;
    end
    set(handles.sampleSelection, 'String', fields(model.parameters.calibration.samples));
    set(handles.sampleSelection, 'Value', model.parameters.extraction.currentCalibrationNr);
    
    if model.displaySettings.extraction.autoscale
        caxis(handles.axesImage,'auto');
    else
        caxis(handles.axesImage,[model.displaySettings.extraction.floor model.displaySettings.extraction.cap]);
    end
    set(handles.autoscale, 'Value', model.displaySettings.extraction.autoscale);
    set(handles.cap, 'String', model.displaySettings.extraction.cap);
    set(handles.floor, 'String', model.displaySettings.extraction.floor);
    
    extraction = model.parameters.extraction;
    set(handles.width, 'String', extraction.width);
    
    set(handles.overlay, 'Value', extraction.overlay);
    
    if isa(model.file, 'BE_Utils.HDF5Storage.h5bm') && isvalid(model.file)
        try
            img = model.controllers.data.getCalibration('data', extraction.currentCalibrationNr);
            %% Overlay the calibration image with a measurement image if requested
            if model.parameters.extraction.overlay
                img = BE_SharedFunctions.overlayMeasurementImage(model, img, extraction.currentCalibrationNr);
            end
        catch
            img = model.controllers.data.getPayload('data', 1, 1, 1);
        end
        img = nanmean(img, 3);
        handles.imageCamera.CData = img;
        axis(handles.axesImage, [0.5 size(img,2)+0.5 0.5 size(img,1)+0.5]);
    end
    
    set(handles.extractionAxisGroup,'SelectedObject',findall(handles.extractionAxis, 'String', extraction.extractionAxis));
    set(handles.interpolationDirectionGroup,'SelectedObject',findall(handles.interpolationDirection, 'String', extraction.interpolationDirection));
    
    try
        if ~sum(isnan(extraction.calibrations(extraction.currentCalibrationNr).peaks.x)) && ...
           ~sum(isnan(extraction.calibrations(extraction.currentCalibrationNr).peaks.y))
            handles.peakTable.Data = transpose([extraction.calibrations(extraction.currentCalibrationNr).peaks.x; ...
                extraction.calibrations(extraction.currentCalibrationNr).peaks.y]);
            handles.plotPeaks.XData = extraction.calibrations(extraction.currentCalibrationNr).peaks.x;
            handles.plotPeaks.YData = extraction.calibrations(extraction.currentCalibrationNr).peaks.y;
    %         fitSpectrum(model);
    %         if isa(model.file, 'BE_Utils.HDF5Storage.h5bm') && isvalid(model.file)
    %             getInterpolationPositions(handles, model);
    %         end
        else
            error('No peaks available');
        end
    catch
        handles.peakTable.Data = [];
        handles.plotPeaks.XData = [];
        handles.plotPeaks.YData = [];
    end
    showInterpolationPositions(handles, model);
end

function showInterpolationPositions(handles, model)
%% clean data for plotting to not show values outside the image
    if isa(model.file, 'BE_Utils.HDF5Storage.h5bm') && isvalid(model.file)
        try
            img = model.controllers.data.getCalibration('data', model.parameters.extraction.currentCalibrationNr);
        catch
            img = model.controllers.data.getPayload('data', 1, 1, 1);
        end
    else
        return;
    end
    centers = cleanArray(model.parameters.extraction.interpolationCenters, img);
    borders = cleanArray(model.parameters.extraction.interpolationBorders, img);
    positions = cleanArray(model.parameters.extraction.interpolationPositions, img);
    
    function arr = cleanArray(arr, img)
        arr.x(arr.x > size(img,2)) = NaN;
        arr.x(arr.x < 1) = NaN;
        arr.y(arr.y > size(img,1)) = NaN;
        arr.y(arr.y < 1) = NaN;
    end

%% plot
    try
        calNr = model.parameters.extraction.currentCalibrationNr;
        handles.plotCenters.XData = centers.x(:,:,calNr);
        handles.plotCenters.YData = centers.y(:,:,calNr);
        if ~isempty(borders.x) && ~isempty(borders.y)
            set(handles.plotBorders, {'XData'}, num2cell(borders.x(:,:,calNr),2));
            set(handles.plotBorders, {'YData'}, num2cell(borders.y(:,:,calNr),2));
        else
            set(handles.plotBorders, {'XData'}, {[];[]});
            set(handles.plotBorders, {'YData'}, {[];[]});
        end
        try
            delete(model.handles.plotPositions);
        catch
        end
        
        model.handles.plotPositions = plot(handles.axesImage, positions.x(:,:,calNr), positions.y(:,:,calNr), 'color', 'yellow');
        if model.displaySettings.extraction.showPositions
            set(model.handles.plotPositions, 'Visible', 'on');
        else
            set(model.handles.plotPositions, 'Visible', 'off');
        end
    catch
    end
end