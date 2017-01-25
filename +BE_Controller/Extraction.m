function extraction = Extraction(model, view)
%% CALIBRATION Controller

    %% callbacks Calibration
    set(view.extraction.selectPeaks, 'Callback', {@selectPeaks, view, model});
    set(view.extraction.optimizePeaks, 'Callback', {@optimizePeaks, model});
    set(view.extraction.clearPeaks, 'Callback', {@clearPeaks, model});
    
    set(view.extraction.extractionAxis, 'Callback', {@changeSettings, view, model});
    set(view.extraction.interpolationDirection, 'Callback', {@changeSettings, view, model});
    
    set(view.extraction.width, 'Callback', {@changeSettings, view, model});
    
    set(view.extraction.zoomIn, 'Callback', {@zoom, 'in', view});
    set(view.extraction.zoomOut, 'Callback', {@zoom, 'out', view});
    set(view.extraction.panButton, 'Callback', {@pan, view});
    
    set(view.extraction.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.extraction.cap, 'Callback', {@setCameraParameters, model});
    set(view.extraction.floor, 'Callback', {@setCameraParameters, model});
    
    set(view.extraction.increaseFloor, 'Callback', {@increaseClim, model});
    set(view.extraction.decreaseFloor, 'Callback', {@decreaseClim, model});
    set(view.extraction.increaseCap, 'Callback', {@increaseClim, model});
    set(view.extraction.decreaseCap, 'Callback', {@decreaseClim, model});
    
    extraction = struct( ...
    );
end

function selectPeaks(~, ~, view, model)
    model.status.extraction.selectPeaks = ~model.status.extraction.selectPeaks;
    if model.status.extraction.selectPeaks
        set(view.figure,'KeyPressFcn',{@finishPeaks, view, model});
        set(view.figure,'WindowButtonMotionFcn',{@changepointer, view});
        set(view.extraction.selectPeaks, 'KeyPressFcn', {@finishPeaks, view, model});
        set(view.extraction.axesImage,'ButtonDownFcn',{@getpoints, view, model});
        set(view.extraction.imageCamera,'ButtonDownFcn',{@getpoints, view, model});
    else
        set(view.figure,'KeyPressFcn',[]);
        set(view.figure,'WindowButtonMotionFcn',[]);
        set(view.extraction.selectPeaks, 'KeyPressFcn', []);
        set(view.extraction.axesImage,'ButtonDownFcn',[]);
        set(view.extraction.imageCamera,'ButtonDownFcn',[]);
        set(view.figure,'Pointer','arrow');
        
    end
end

function changepointer(~, ~, view)
    view.extraction.axesImage.Units = 'pixels';
    view.figure.Units = 'pixels';
    axlim = get(view.extraction.axesImage,'Position');
    fglim = get(view.figure,'Position');
    x1 = fglim(1) + axlim(1);
    x2 = x1 + axlim(3);
    y1 = fglim(2) + axlim(2);
    y2 = y1 + axlim(4);
    pntr = get(0,'PointerLocation');
    if pntr(2)>y1 && pntr(2)<y2 && pntr(1)>x1 && pntr(1)<x2
        set(view.figure,'Pointer','crosshair');
    else
        set(view.figure,'Pointer','arrow');
    end
end

function finishPeaks(~, ~, view, model)
    val=double(get(view.figure,'CurrentCharacter'));
    if val == 13 || val == 27
        model.status.extraction.selectPeaks = 0;
        set(view.figure,'KeyPressFcn',[]);
        set(view.figure,'WindowButtonMotionFcn',[]);
        set(view.extraction.selectPeaks, 'KeyPressFcn', []);
        set(view.extraction.axesImage,'ButtonDownFcn',[]);
        set(view.extraction.imageCamera,'ButtonDownFcn',[]);
        set(view.figure,'Pointer','arrow');
    end
end

function getpoints(~, ~, view, model)
    % manually select the peaks of the spectrum
    cp = get(view.extraction.axesImage,'CurrentPoint');
    x = model.settings.extraction.peaks.x;
    x = [x cp(1,1)];
    y = model.settings.extraction.peaks.y;
    y = [y cp(1,2)];
    model.settings.extraction.peaks = struct( ...
        'x', x, ...
        'y', y ...
    );
    fitSpectrum(model);
end

function clearPeaks(~, ~, model)
    model.settings.extraction.peaks = struct( ...
        'x', [], ...
        'y', [] ...
    );
    model.settings.extraction.interpolationCenters = struct( ...
        'x', [], ...        % [pix] x-position
        'y', [] ...         % [pix] y-position
    );
    model.settings.extraction.interpolationBorders = struct( ...
        'x', [], ...        % [pix] x-position
        'y', [] ...         % [pix] y-position
    );
    model.settings.extraction.interpolationPositions = struct( ...
        'x', [], ...        % [pix] x-position
        'y', [] ...         % [pix] y-position
    );
end

function optimizePeaks(~, ~, model)
    if isa(model.file, 'Utils.HDF5Storage.h5bm') && isvalid(model.file)
        img = model.file.readPayloadData(1, 1, 1, 'data');
        img = img(:,:,model.settings.extraction.imageNr);
        r=10;
        % do a median filtering to prevent finding maxixums which are none,
        % reduce radius if medfilt2 is not possible (license checkout
        % failure)
        try
            img = medfilt2(img);
        catch
            r = 4;
        end
        peaks = model.settings.extraction.peaks;
        siz=size(img);
        for jj = 1:length(peaks.x)
            cx=peaks.x(jj);
            cy=peaks.y(jj);
            [x,y]=meshgrid(-(cx-1):(siz(2)-cx),-(cy-1):(siz(1)-cy));
            mask=((x.^2+y.^2)<=r^2);
            tmp = img;
            tmp(~mask) = NaN;
            [~, ind] = max(tmp(:));
            [peaks.y(jj),peaks.x(jj)] = ind2sub(siz,ind);
        end
        model.settings.extraction.peaks = peaks;
    end
    fitSpectrum(model);
end

function changeSettings(~, ~, view, model)
    % create a copy of the struct, otherwise model is reset after first
    % value has been changed
    extraction = model.settings.extraction;
    
    % set new values
    extractionAxis = get(view.extraction.extractionAxisGroup,'SelectedObject');
    extraction.extractionAxis = extractionAxis.String;

    interpolationDirection = get(view.extraction.interpolationDirectionGroup,'SelectedObject');
    extraction.interpolationDirection = interpolationDirection.String;
    
    extraction.width = str2double(get(view.extraction.width, 'String'));
    
    model.settings.extraction = extraction;
    getInterpolationPositions(model);
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
    
    getInterpolationPositions(model);

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

function getInterpolationPositions(model)

%% calculate positions of the interpolation positions
    if isa(model.file, 'Utils.HDF5Storage.h5bm') && isvalid(model.file)
        img = model.file.readPayloadData(1, 1, 1, 'data');
        img = img(:,:,model.settings.extraction.imageNr);
    else
        return;
    end
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
    
    model.settings.extraction.interpolationCenters = centers;
    model.settings.extraction.interpolationBorders = borders;
    model.settings.extraction.interpolationPositions = positions;
end

function setCameraParameters(UIControl, ~, model)
    field = get(UIControl, 'Tag');
    model.settings.extraction.(field) = str2double(get(UIControl, 'String'));
end

function toggleAutoscale(~, ~, model, view)
    model.settings.extraction.autoscale = get(view.extraction.autoscale, 'Value');
end

function zoom(src, ~, str, view)
switch get(src, 'UserData')
    case 0
        set(view.extraction.panButton,'UserData',0);
        set(view.extraction.panHandle,'Enable','off');
        switch str
            case 'in'
                set(view.extraction.zoomHandle,'Enable','on','Direction','in');
                set(view.extraction.zoomIn,'UserData',1);
                set(view.extraction.zoomOut,'UserData',0);
            case 'out'
                set(view.extraction.zoomHandle,'Enable','on','Direction','out');
                set(view.extraction.zoomOut,'UserData',1);
                set(view.extraction.zoomIn,'UserData',0);
        end
    case 1
        set(view.extraction.zoomHandle,'Enable','off','Direction','in');
        set(view.extraction.zoomOut,'UserData',0);
        set(view.extraction.zoomIn,'UserData',0);
end
        
end

function pan(src, ~, view)
    set(view.extraction.zoomOut,'UserData',0);
    set(view.extraction.zoomIn,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.extraction.panButton,'UserData',1);
            set(view.extraction.panHandle,'Enable','on');
        case 1
            set(view.extraction.panButton,'UserData',0);
            set(view.extraction.panHandle,'Enable','off');
    end
end

function decreaseClim(UIControl, ~, model)
    model.settings.extraction.autoscale = 0;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(model.settings.extraction.cap - model.settings.extraction.floor));
    model.settings.extraction.(field) = model.settings.extraction.(field) - dif;
end

function increaseClim(UIControl, ~, model)
    model.settings.extraction.autoscale = 0;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(model.settings.extraction.cap - model.settings.extraction.floor));
    model.settings.extraction.(field) = model.settings.extraction.(field) + dif;
end