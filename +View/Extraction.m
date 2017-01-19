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

    selectPeaks = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Select','Position',[0.02,0.92,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    optimizePeaks = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String','Optimize','Position',[0.14,0.92,0.1,0.055],...
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
        'selectPeaks', selectPeaks, ...
        'optimizePeaks', optimizePeaks, ...
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
        handles.imageCamera.CData = img;
        colorbar(handles.axesImage);
        axis(handles.axesImage, [0.5 size(img,2)+0.5 0.5 size(img,1)+0.5]);
        model.settings.extraction.circleStart = [1, size(img,1), mean(size(img))];

        if model.settings.extraction.autoscale
            caxis(handles.axesImage,'auto');
        else
            caxis(handles.axesImage,[model.settings.extraction.floor model.settings.extraction.cap]);
        end
        zoom reset;
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
    
    tmp(:,1) = model.settings.extraction.peaks.x;
    tmp(:,2) = model.settings.extraction.peaks.y;
    if ~isnan(tmp)
        handles.peakTable.Data = tmp;
        handles.plotPeaks.XData = tmp(:,1);
        handles.plotPeaks.YData = tmp(:,2);
        fitSpectrum(model);
        if isa(model.file, 'Utils.HDF5Storage.h5bm') && isvalid(model.file)
            getInterpolationPositions(handles, model);
        end
    end
end

function fitSpectrum(model)

    newxb = model.settings.extraction.peaks.x;
    newdata2b = model.settings.extraction.peaks.y;
    circleStart = model.settings.extraction.circleStart;
    
    if ~sum(isnan(newxb)) && ~sum(isnan(newdata2b)) && ~sum(isnan(circleStart))

        model2b = @(params) circleError(params, newxb, newdata2b, -1);
        [estimates2b, ~, ~, ~] = fitCircle(model2b, newxb, circleStart);

        model.settings.extraction.circleFit = estimates2b;
    end

    function [estimates2b, model2b, newxb, FittedCurve2b] = fitCircle(model2b, newxb, start)

        options = optimset('MaxFunEvals', 100000, 'MaxIter', 100000);
        estimates2b = fminsearch(model2b, start, options);

        [~, FittedCurve2b] = model2b(estimates2b);
    end
    
end

function [error, y] = circleError(params, x, yTarget, sign)
% CIRCLEERROR

    y = circle(params, x, sign);

    errorVec = y - yTarget;

    error = sum(errorVec.^2);
end

function [y] = circle(params, x, sign)
% CIRCLE model for a circle
    y = params(2) + sign * sqrt(params(3).^2 - (x-params(1)).^2);
    y(imag(y) ~=0) = NaN;
end

function getInterpolationPositions(handles, model)

%% calculate positions of the interpolation positions
    img = model.file.readPayloadData(1, 1, 1, 'data');
    params = model.settings.extraction.circleFit;
    width = model.settings.extraction.width;
    
    centers.x = 1:size(img,2);
    centers.y = 1:size(img,1);
    switch model.settings.extraction.extractionAxis
        case 'x'
            centers.y = circle(params, centers.x, -1);
        case 'y'
            n(1) = params(2);
            n(2) = params(1);
            n(3) = params(3);
            centers.x = circle(n, centers.y, 1);
        case 'f'
            centers.y = circle(params, centers.x, -1);
            centers.y(~isreal(centers.y)) = NaN;
            [yMax, ind] = max(centers.y);
            xMax = centers.x(ind);
            [yMin, ind] = min(centers.y);
            xMin = centers.x(ind);
            aMax = atan2((yMax - params(2)),(xMax - params(1)));
            aMin = atan2((yMin - params(2)),(xMin - params(1)));
            a = linspace(aMin, aMax, round(mean(size(img))));
            centers.x = params(1) + params(3) * cos(a);
            centers.y = params(2) + params(3) * sin(a);
        otherwise
            ex = MException('MATLAB:noSuchAxis', ...
                'Not possible to use the axis %s. Chose either x, y or f.', p.Results.axis);
            throw(ex)
    end
    
    x0 = params(1);
    y0 = params(2);
    
    m = (centers.y - y0) ./ (centers.x - x0);
    alpha = atan(m);
    
    % preallocate borders arrays
    borders = struct();
    borders.x = NaN(2,length(centers.x));
    borders.y = NaN(2,length(centers.x));
    
    switch model.settings.extraction.interpolationDirection
        case 'f'
            %% correct way to average the spectrum
            borders.x = [1; 1] * centers.x + [-1; 1] .* width/2 * cos(alpha);
            borders.y = [1; 1] * centers.y + [-1; 1] .* width/2 * sin(alpha);
        case 'x'
            %% "wrong" way to average the spectrum
            % corresponds to the old way of averaging
            borders.x = [1; 1] * centers.x + [-1; 1] .* width * sin(alpha);
            borders.y = [1; 1] * centers.y;
        case 'y'
            %%
            borders.x = [1; 1] * centers.x;
            borders.y = [1; 1] * centers.y + [-1; 1] .* width * cos(alpha);
        otherwise
            ex = MException('MATLAB:noSuchAveraging', ...
                'Not possible to average in direction %s. Chose either x, y or f.', p.Results.averaging);
            throw(ex)
    end

    % create positions array for interpolating
    steps = repmat(transpose(0:(width-1)),1,size(borders.y,2));
    positions.x = repmat(borders.x(1,:),width,1) + repmat(diff(borders.x,1,1),width,1)./(width-1) .* steps;
    positions.y = repmat(borders.y(1,:),width,1) + repmat(diff(borders.y,1,1),width,1)./(width-1) .* steps;
    
    model.settings.extraction.interpolationPositions = positions;
    
%% clean data for plotting to not show values outside the image
    centers = cleanArray(centers, img);
    borders = cleanArray(borders, img);
    positions = cleanArray(positions, img);
    
    function arr = cleanArray(arr, img)
        arr.x(arr.x > size(img,2)) = NaN;
        arr.x(arr.x < 1) = NaN;
        arr.y(arr.y > size(img,1)) = NaN;
        arr.y(arr.y < 1) = NaN;
    end

%% plot
    handles.plotCenters.XData = centers.x;
    handles.plotCenters.YData = centers.y;
    set(handles.plotBorders, {'XData'}, num2cell(borders.x,2));
    set(handles.plotBorders, {'YData'}, num2cell(borders.y,2));
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