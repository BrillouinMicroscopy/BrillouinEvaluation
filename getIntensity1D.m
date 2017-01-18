function [intensity] = getIntensity1D(img, params, width, varargin)
%% parse input values
    p = inputParser;

    addRequired(p,'img',@isnumeric);
    addRequired(p,'params',@isnumeric);
    addRequired(p,'width',@isnumeric);
    addParameter(p,'axis',@ischar);
    addParameter(p,'averaging',@ischar);
    
    parse(p, img, params, width, varargin{:});

%% calculate positions of the interpolation positions
    switch p.Results.axis
        case 'x'
            centers.x = 1:size(img,2);
            centers.y = 1:size(img,1);
            [~, centers.y] = circle(params, centers.x, NaN, -1);
        case 'y'
            centers.x = 1:size(img,2);
            centers.y = 1:size(img,1);
            n(1) = params(2);
            n(2) = params(1);
            n(3) = params(3);
            [~, centers.x] = circle(n, centers.y, NaN, 1);
        case 'f'
            ex = MException('MATLAB:notImplemented', ...
                'Not possible to use the axis %s. This option is not implemented yet.', p.Results.axis);
            throw(ex)
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
    
    switch p.Results.averaging
        case 'f'
            %% correct way to average the spectrum
            borders.x = [1; 1] * centers.x + [-1; 1] .* width/2 * cos(alpha);
            borders.y = [1; 1] * centers.y + [-1; 1] .* width/2 * sin(alpha);
        case 'x'
            %% "wrong" way to average the spectrum
            % corresponds to the old way of averaging
            borders.x = [1; 1] * centers.x + [-1; 1] .* width/2 * sin(alpha);
            borders.y = [1; 1] * centers.y;
        case 'y'
            %%
            borders.x = [1; 1] * centers.x;
            borders.y = [1; 1] * centers.y + [-1; 1] .* width/2 * cos(alpha);
        otherwise
            ex = MException('MATLAB:noSuchAveraging', ...
                'Not possible to average in direction %s. Chose either x, y or f.', p.Results.averaging);
            throw(ex)
    end

    % create positions array for interpolating
    steps = repmat(transpose(0:(width-1)),1,size(borders.y,2));
    positions.x = repmat(borders.x(1,:),width,1) + repmat(diff(borders.x,1,1),width,1)./(width-1) .* steps;
    positions.y = repmat(borders.y(1,:),width,1) + repmat(diff(borders.y,1,1),width,1)./(width-1) .* steps;
    
    [X, Y] = meshgrid(1:size(img,2),1:size(img,1));
    intensity = interp2(X,Y,img,positions.x,positions.y);
    
    intensity = nanmean(intensity, 1);
    
%% calculate the borders (just for visualisation)
%     paramsInner = params;
%     paramsInner(3) = paramsInner(3) - width/2;
%     [~, centers.yInner] = circle(paramsInner, centers.x, NaN, -1);
%     paramsOuter = params;
%     paramsOuter(3) = paramsOuter(3) + width/2;
%     [~, centers.yOuter] = circle(paramsOuter, centers.x, NaN, -1);

%% plot
%     figure;
%     plot(diff(centers.x), 'color', 'blue');
%     hold on;
%     plot(diff(centers.y), 'color', 'red');
%     
%     figure;
%     imagesc(img);
%     hold on;
%     plot(centers.x, centers.y, 'color', 'green', 'linestyle', '--', 'linewidth', 2, 'marker', 'x');
%     plot(centers.x, centers.yInner, 'color', 'red', 'linestyle', '--', 'linewidth', 2);
%     plot(centers.x, centers.yOuter, 'color', 'red', 'linestyle', '--', 'linewidth', 2);
%     plot(borders.x, borders.y, 'color', 'yellow');
%     axis equal
%     axis([1, size(img,2), 1, size(img,1)])
end