function callbacks = Extraction(model, view)
%% CALIBRATION Controller

    %% callbacks Calibration
    set(view.extraction.selectPeaks, 'Callback', {@selectPeaks, view, model});
    set(view.extraction.optimizePeaks, 'Callback', {@optimizePeaksCallback, model});
    set(view.extraction.clearPeaks, 'Callback', {@clearPeaks, model});
    set(view.extraction.autoPeaks, 'Callback', {@findPeaksSingle, model});
    
    set(view.extraction.calibrationSlider, 'StateChangedCallback', {@selectCalibration, model});
    
    set(view.extraction.clearPeaksAll, 'Callback', {@clearPeaksAll, model});
    set(view.extraction.autoPeaksAll, 'Callback', {@findPeaksAll, model});
    
    set(view.extraction.extractionAxis, 'Callback', {@changeSettings, view, model});
    set(view.extraction.interpolationDirection, 'Callback', {@changeSettings, view, model});
    
    set(view.extraction.width, 'Callback', {@changeSettings, view, model});
    set(view.extraction.overlay, 'Callback', {@setOverlay, model});
    
    set(view.extraction.zoomIn, 'Callback', {@zoom, 'in', view, model});
    set(view.extraction.zoomOut, 'Callback', {@zoom, 'out', view, model});
    set(view.extraction.panButton, 'Callback', {@pan, view, model});
    set(view.extraction.cursorButton, 'Callback', {@cursor, view});
    
    set(view.extraction.showBorders, 'Callback', {@showGraphs, model});
    set(view.extraction.showCenter, 'Callback', {@showGraphs, model});
    set(view.extraction.showPositions, 'Callback', {@showGraphs, model});
    
    set(view.extraction.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.extraction.cap, 'Callback', {@setClim, model});
    set(view.extraction.floor, 'Callback', {@setClim, model});
    
    set(view.extraction.increaseFloor, 'Callback', {@changeClim, model, 1});
    set(view.extraction.decreaseFloor, 'Callback', {@changeClim, model, -1});
    set(view.extraction.increaseCap, 'Callback', {@changeClim, model, 1});
    set(view.extraction.decreaseCap, 'Callback', {@changeClim, model, -1});
    
    callbacks = struct( ...
        'setActive', @()setActive(view), ...
        'findPeaks', @()findPeaksSingle(0, 0, model), ...
        'findPeaksAll', @()findPeaksAll(0, 0, model) ...
    );
end

function setActive(view)
    tabgroup = get(view.extraction.parent, 'parent');
    tabgroup.SelectedTab = view.extraction.parent;
end

function selectCalibration(src, ~, model)
    model.parameters.extraction.currentCalibrationNr = get(src, 'Value');
end

function findPeaksSingle(~, ~, model)
    findPeaks(model);
end

function findPeaks(varargin)
    model = varargin{1};
    if nargin < 2
        currentCalibrationNr = model.parameters.extraction.currentCalibrationNr;
    else
        currentCalibrationNr = varargin{2};
    end
    
    if isa(model.file, 'BE_Utils.HDF5Storage.h5bm') && isvalid(model.file)
        if currentCalibrationNr == 1
            try
                peaks = model.parameters.extraction.calibrations(currentCalibrationNr).peaks;
            catch
                peaks.x = [];
                peaks.y = [];
            end
        end
        
        if (currentCalibrationNr == 1) && (isempty(peaks.x) || isempty(peaks.y))
            % found peaks
            peaks.x = [];
            peaks.y = [];
            % get the image
            try
                img = model.controllers.data.getCalibration('data', currentCalibrationNr);
                %% Overlay the calibration image with a measurement image if requested
                if model.parameters.extraction.overlay
                    img = BE_SharedFunctions.overlayMeasurementImage(model, img, currentCalibrationNr);
                end
            catch
                img = model.controllers.data.getPayload('data', 1, 1, 1);
            end
            img = nanmean(img, 3);
            r=70;
            siz=size(img);
            % do a median filtering to prevent finding maxixums which are none,
            % reduce radius if medfilt2 is not possible (license checkout
            % failure)
            try
                img = medfilt2(img, 'symmetric');
            catch
            end

            %% find the (hopefully) four Rayleigh peaks
            % assumes that Rayleigh peaks are stronger than Brillouin peaks
            % this might become a problem later on :(
%             
            %consider prelocating the memory
            peak_info_x_scan = [];

%             peak_prominece_ii_kk = 0
      
            for ii = 1:siz(1) 
                [height,locs_y, width_x, proms_x] = findpeaks(img(ii,:), ...
                'MinPeakProminence',20, ...
                'MinPeakDistance', 50);%, ...
%                'SortStr','descend');
                if ~ isempty(height) 
                    for kk = 1:size(height,2)
                        peak_info_x_scan = [peak_info_x_scan; ...
                        [ii, height(kk), locs_y(kk), ...
                        width_x(kk), proms_x(kk)]];
                        %disp([ii,kk]);
                        %disp(peak_info);
                    end
                end
                % if found 1D peak is next to the previous and prominence
                % is higher: add the located peak to the peak list
%                 if ~ isempty(peak_info) && (peak_info(ii-1,0) == ...
%                         peak_info(ii,0))
%                 end
%                 
%                 else
%                     peak_prominece_ii_kk = 0
%                 end   
            end
            
%             peak_info_y_scan = []
%             for kk = 1:size(peak_info_x_scan, 1)
%                 %scan all the y locations where peaks were found
%                 [pks_y,locs_y, width_y, proms_y] = findpeaks(img(:,peak_info_x_scan(kk,3)), ...
%                 'MinPeakProminence',10, ...
%                 'MinPeakDistance', 50);
%                 if ~ isempty(pks_y) 
%                     for ii = 1:size(pks_y,2)
%                         peak_info_y_scan = [peak_info_y_scan; ...
%                         [kk, pks_y(ii), locs_y(ii), width_y(ii), proms_y(ii)]];
%                     end
%                 end
%             end
            

            peak_index_x = 1;
            peak_index_y = 1;
            peak_index = 1;
            peak_list = [];
            peak_group =[];        
% peak_group [peak_index_x, peak_index_y, peak info];
% peak info [ii, height(kk), locs_y(kk), width_x(kk), proms_x(kk)]];            
            
            for ii = 1 : (size(peak_info_x_scan, 1)-1)
                %if peaks connected x is either equal or 
               if abs(peak_info_x_scan(ii+1,1) - peak_info_x_scan(ii,1)) <= 1 
                    peak_group = [peak_group; [peak_index_x,  nan, nan,...
                       peak_info_x_scan(ii,:)]];          
               else
                   peak_index_x = peak_index_x +1;
                   peak_group = [peak_group; ...
                                [peak_index_x,  nan, nan,...
                                 peak_info_x_scan(ii,:)]];     
               end             
            end
            
            peak_info_x_scan = sortrows(peak_info_x_scan, 3);
            for kk = 1 : (size(peak_info_x_scan, 1)-1)
                %if peaks connected (2 as border is arbitrary) 
               if abs(peak_info_x_scan(kk+1,3) - peak_info_x_scan(kk,3)) <= 2
                    %disp(kk);
                    peak_group(kk, 2) = peak_index_y;
               else
                   peak_index_y = peak_index_y +1;
                   peak_group(kk, 2) = peak_index_y;
               end             
            end
            
            
            for ll = 1 : (size(peak_info_x_scan, 1)-1)
                peak_group(ll,3) = peak_index;
                %if peak_index_x or peak_index_y is grater than the
                %previous, the new peak is not connected and therefore gets
                % a new index
                if (peak_group(ll+1,1) + peak_group(ll+1,2) > ...
                    peak_group(ll,1) + peak_group(ll,2))
                
                    peak_index = peak_index + 1;
                end
                
            end
                

            tmpImg = img;
            for jj = 1:4
                % find highest value in the image
                [~, ind] = max(tmpImg(:));
                [cy,cx] = ind2sub(siz,ind);
                % set peak region to zero for finding new peak
                [x,y]=meshgrid(-(cx-1):(siz(2)-cx),-(cy-1):(siz(1)-cy));
                mask=((x.^2+y.^2)<=r^2);
                tmpImg(mask) = 0;
                % select Rayleigh peaks in upper left and lower right corner
                if ((cy < siz(2)/2) && (cx < siz(1)/2)) || ((cy > siz(2)/2) && (cx > siz(1)/2))
                    peaks.x = [peaks.x cx];
                    peaks.y = [peaks.y cy];
                end
            end

            %% Select only the area between the Rayleigh peaks
            m = (peaks.y(1) - peaks.y(2))/(peaks.x(1) - peaks.x(2));
            n = peaks.y(1) - m*peaks.x(1);

            [~,order] = sort(peaks.x);
            peaks.x = peaks.x(order);
            peaks.y = peaks.y(order);

            mask = zeros(size(img));
            width = 50;
            % only select point inbetween the Rayleigh peaks
            for jj = peaks.y(1):peaks.y(2)
                for kk = peaks.x(1):peaks.x(2)
                    if (jj > (m * kk) + n - width) && (jj < (m * kk) + n + width/2)
                        mask(jj,kk) = 1;
                    end
                end
            end

            tmpImg(mask == 0) = NaN;

            %% find two Brillouin peaks
            for jj = 1:2
                % find highest value in the image
                [~, ind] = max(tmpImg(:));
                [cy,cx] = ind2sub(siz,ind);
                % set peak region to zero for finding new peak
                [x,y]=meshgrid(-(cx-1):(siz(2)-cx),-(cy-1):(siz(1)-cy));
                mask=((x.^2+y.^2)<=r^2);
                tmpImg(mask) = 0;
                % add peaks
                peaks.x = [peaks.x cx];
                peaks.y = [peaks.y cy];
            end

            % sort the peaks (just nice to have)
            [~,order] = sort(peaks.x);
            peaks.x = peaks.x(order);
            peaks.y = peaks.y(order);
        elseif currentCalibrationNr > 1
            peaks = model.parameters.extraction.calibrations(currentCalibrationNr-1).peaks;
        end
        
        % store new peak positions
        model.parameters.extraction.calibrations(currentCalibrationNr).peaks = peaks;
        % optimize the peak position
        optimizePeaks(model, currentCalibrationNr);
        model.log.log('I/Extraction: Extraction successful.');
    end
end

function findPeaksAll(~, ~, model)
    % number of calibrations
    f = fields(model.parameters.calibration.samples);
    nrs = max([length(f)-1, 1]);
    for currentCalibrationNr = 1:nrs
        findPeaks(model, currentCalibrationNr);
    end
end

function selectPeaks(~, ~, view, model)
    model.status.extraction.selectPeaks = ~model.status.extraction.selectPeaks;
    set(view.extraction.panButton,'UserData',0);
    set(view.extraction.panHandle,'Enable','off');
    set(view.extraction.cursorButton,'UserData',0);
    set(view.extraction.cursorHandle,'Enable','off');
    set(view.extraction.zoomHandle,'Enable','off','Direction','in');
    set(view.extraction.zoomOut,'UserData',0);
    set(view.extraction.zoomIn,'UserData',0);
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
    x = model.parameters.extraction.calibrations(model.parameters.extraction.currentCalibrationNr).peaks.x;
    x = [x cp(1,1)];
    y = model.parameters.extraction.calibrations(model.parameters.extraction.currentCalibrationNr).peaks.y;
    y = [y cp(1,2)];
    model.parameters.extraction.calibrations(model.parameters.extraction.currentCalibrationNr).peaks = struct( ...
        'x', x, ...
        'y', y ...
    );
    fitSpectrum(model);
end

function clearPeaks(~, ~, model)
    extraction = model.parameters.extraction;
    extraction.calibrations(extraction.currentCalibrationNr).peaks = struct( ...
        'x', [], ...
        'y', [] ...
    );
    extraction.calibrations(extraction.currentCalibrationNr).circleFit = [];
    extraction.interpolationCenters.x(:,:,extraction.currentCalibrationNr) = NaN;
    extraction.interpolationCenters.y(:,:,extraction.currentCalibrationNr) = NaN;
    extraction.interpolationBorders.x(:,:,extraction.currentCalibrationNr) = NaN;
    extraction.interpolationBorders.y(:,:,extraction.currentCalibrationNr) = NaN;
    extraction.interpolationPositions.x(:,:,extraction.currentCalibrationNr) = NaN;
    extraction.interpolationPositions.y(:,:,extraction.currentCalibrationNr) = NaN;
    model.parameters.extraction = extraction;
end

function clearPeaksAll(~, ~, model)
    extraction = model.parameters.extraction;
    extraction.calibrations = struct( ...
        'peaks', struct( ...% position of the peaks for localising the spectrum
            'x', [], ...    % [pix] x-position
            'y', [] ...     % [pix] y-position
        ), ...
        'circleFit', [] ...
    );
    extraction.interpolationCenters = struct( ...
        'x', [], ...        % [pix] x-position
        'y', [] ...         % [pix] y-position
    );
    extraction.interpolationBorders = struct( ...
        'x', [], ...        % [pix] x-position
        'y', [] ...         % [pix] y-position
    );
    extraction.interpolationPositions = struct( ...
        'x', [], ...        % [pix] x-position
        'y', [] ...         % [pix] y-position
    );
    extraction.times = [];
    model.parameters.extraction = extraction;
end

function optimizePeaksCallback(~, ~, model)
    optimizePeaks(model);
end

function optimizePeaks(varargin)
    model = varargin{1};
    if nargin < 2
        currentCalibrationNr = model.parameters.extraction.currentCalibrationNr;
    else
        currentCalibrationNr = varargin{2};
    end
    
    if isa(model.file, 'BE_Utils.HDF5Storage.h5bm') && isvalid(model.file)
        try
            img = model.controllers.data.getCalibration('data', currentCalibrationNr);
            img = nanmean(img, 3);
            %% Overlay the calibration image with a measurement image if requested
            if model.parameters.extraction.overlay
                img = BE_SharedFunctions.overlayMeasurementImage(model, img, currentCalibrationNr);
            end
        catch
            img = model.controllers.data.getPayload('data', 1, 1, 1);
            img = nanmean(img, 3);
        end
        
        r=10;
        % do a median filtering to prevent finding maxixums which are none,
        % reduce radius if medfilt2 is not possible (license checkout
        % failure)
        try
            img = medfilt2(img);
        catch
            r = 4;
        end
        peaks = model.parameters.extraction.calibrations(currentCalibrationNr).peaks;
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
        model.parameters.extraction.calibrations(currentCalibrationNr).peaks = peaks;
    end
    fitSpectrum(model, currentCalibrationNr);
end

function changeSettings(~, ~, view, model)
    % create a copy of the struct, otherwise model is reset after first
    % value has been changed
    extraction = model.parameters.extraction;
    
    % set new values
    extractionAxis = get(view.extraction.extractionAxisGroup,'SelectedObject');
    extraction.extractionAxis = extractionAxis.String;

    interpolationDirection = get(view.extraction.interpolationDirectionGroup,'SelectedObject');
    extraction.interpolationDirection = interpolationDirection.String;
    
    extraction.width = str2double(get(view.extraction.width, 'String'));
    
    %% clear interpolation variables and recalculate them
    extraction.interpolationCenters = struct( ...
        'x', [], ...        % [pix] x-position
        'y', [] ...         % [pix] y-position
    );
    extraction.interpolationBorders = struct( ...
        'x', [], ...        % [pix] x-position
        'y', [] ...         % [pix] y-position
    );
    extraction.interpolationPositions = struct( ...
        'x', [], ...        % [pix] x-position
        'y', [] ...         % [pix] y-position
    );
    model.parameters.extraction = extraction;
    
    % number of calibrations
    f = fields(model.parameters.calibration.samples);
    nrs = max([length(f)-1, 1]);
    for currentCalibrationNr = 1:nrs
        getInterpolationPositions(model, currentCalibrationNr);
    end
end

function fitSpectrum(varargin)
    model = varargin{1};
    if nargin < 2
        currentCalibrationNr = model.parameters.extraction.currentCalibrationNr;
    else
        currentCalibrationNr = varargin{2};
    end

    newxb = model.parameters.extraction.calibrations(currentCalibrationNr).peaks.x;
    newdata2b = model.parameters.extraction.calibrations(currentCalibrationNr).peaks.y;
    circleStart = model.parameters.extraction.circleStart;
    
    if ~sum(isnan(newxb)) && ~sum(isnan(newdata2b)) && ~sum(isnan(circleStart))

        model2b = @(params) circleError(params, newxb, newdata2b, -1);
        [estimates2b, ~, ~, ~] = fitCircle(model2b, newxb, circleStart);

        model.parameters.extraction.calibrations(currentCalibrationNr).circleFit = estimates2b;
    end
    
    getInterpolationPositions(model, currentCalibrationNr);

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

function getInterpolationPositions(varargin)
    model = varargin{1};
    if nargin < 2
        currentCalibrationNr = model.parameters.extraction.currentCalibrationNr;
    else
        currentCalibrationNr = varargin{2};
    end

%% calculate positions of the interpolation positions
    if isa(model.file, 'BE_Utils.HDF5Storage.h5bm') && isvalid(model.file)
        try
            refTime = datetime(model.parameters.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
        catch
            refTime = datetime(model.parameters.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
        end
        try
            img = model.controllers.data.getCalibration('data', currentCalibrationNr);
            datestring = model.controllers.data.getCalibration('date', currentCalibrationNr);
        catch
            img = model.controllers.data.getPayload('data', 1, 1, 1);
            datestring = model.controllers.data.getPayload('date', 1, 1, 1);
        end
        img = nanmean(img, 3);
        try
            date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
        catch
            date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
        end
    else
        return;
    end
    params = model.parameters.extraction.calibrations(currentCalibrationNr).circleFit;
    width = model.parameters.extraction.width;
    
    centers.x = 1:size(img,2);
    centers.y = 1:size(img,1);
    switch model.parameters.extraction.extractionAxis
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
    
    switch model.parameters.extraction.interpolationDirection
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
    
    extraction = model.parameters.extraction;
    extraction.interpolationCenters.x(:,:,currentCalibrationNr) = centers.x;
    extraction.interpolationCenters.y(:,:,currentCalibrationNr) = centers.y;
    extraction.interpolationBorders.x(:,:,currentCalibrationNr) = borders.x;
    extraction.interpolationBorders.y(:,:,currentCalibrationNr) = borders.y;
    extraction.interpolationPositions.x(:,:,currentCalibrationNr) = positions.x;
    extraction.interpolationPositions.y(:,:,currentCalibrationNr) = positions.y;
    extraction.times(currentCalibrationNr) = etime(datevec(date),datevec(refTime));
    model.parameters.extraction = extraction;
end

function zoom(src, ~, str, view, model)
    switch get(src, 'UserData')
        case 0
            model.status.extraction.selectPeaks = 0;
            set(view.figure,'KeyPressFcn',[]);
            set(view.figure,'WindowButtonMotionFcn',[]);
            set(view.extraction.selectPeaks, 'KeyPressFcn', []);
            set(view.extraction.axesImage,'ButtonDownFcn',[]);
            set(view.extraction.imageCamera,'ButtonDownFcn',[]);
            set(view.figure,'Pointer','arrow');
            set(view.extraction.panButton,'UserData',0);
            set(view.extraction.panHandle,'Enable','off');
            set(view.extraction.cursorButton,'UserData',0);
            set(view.extraction.cursorHandle,'Enable','off');
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

function pan(src, ~, view, model)
    set(view.extraction.zoomHandle,'Enable','off','Direction','in');
    set(view.extraction.cursorHandle,'Enable','off');
    set(view.extraction.zoomOut,'UserData',0);
    set(view.extraction.zoomIn,'UserData',0);
    set(view.extraction.cursorButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            model.status.extraction.selectPeaks = 0;
            set(view.figure,'KeyPressFcn',[]);
            set(view.figure,'WindowButtonMotionFcn',[]);
            set(view.extraction.selectPeaks, 'KeyPressFcn', []);
            set(view.extraction.axesImage,'ButtonDownFcn',[]);
            set(view.extraction.imageCamera,'ButtonDownFcn',[]);
            set(view.figure,'Pointer','arrow');
            set(view.extraction.panButton,'UserData',1);
            set(view.extraction.panHandle,'Enable','on');
        case 1
            set(view.extraction.panButton,'UserData',0);
            set(view.extraction.panHandle,'Enable','off');
    end
end

function cursor(src, ~, view)
    set(view.extraction.zoomHandle,'Enable','off','Direction','in');
    set(view.extraction.panHandle,'Enable','off');
    set(view.extraction.zoomOut,'UserData',0);
    set(view.extraction.zoomIn,'UserData',0);
    set(view.extraction.panButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.extraction.cursorButton,'UserData',1);
            set(view.extraction.cursorHandle,'Enable','on');
        case 1
            set(view.extraction.cursorButton,'UserData',0);
            set(view.extraction.cursorHandle,'Enable','off');
    end
end

function showGraphs(src, ~, model)
    tag = get(src, 'Tag');
    model.displaySettings.extraction.(['show' tag]) = get(src, 'Value');
end

function setOverlay(src, ~, model)
    model.parameters.extraction.overlay = get(src, 'Value');
end

function setClim(UIControl, ~, model)
    extraction = model.displaySettings.extraction;
    field = get(UIControl, 'Tag');
    extraction.(field) = str2double(get(UIControl, 'String'));
    extraction.autoscale = 0;
    model.displaySettings.extraction = extraction;
end

function toggleAutoscale(~, ~, model, view)
    model.displaySettings.extraction.autoscale = get(view.extraction.autoscale, 'Value');
end

function changeClim(UIControl, ~, model, sign)
    extraction = model.displaySettings.extraction;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(extraction.cap - extraction.floor));
    extraction.autoscale = 0;
    extraction.(field) = extraction.(field) + sign * dif;
    model.displaySettings.extraction = extraction;
end