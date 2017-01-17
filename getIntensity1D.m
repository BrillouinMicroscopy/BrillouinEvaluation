function [intensity] = getIntensity1D(img, model, params, width, varargin)
%% parse input values
    p = inputParser;

    addRequired(p,'img',@isnumeric);
    addRequired(p,'model',@(model) isa(model, 'function_handle'));
    addRequired(p,'params',@isnumeric);
    addRequired(p,'width',@isnumeric);
    addParameter(p,'axis',@ischar);
    addParameter(p,'averaging',@ischar);
    
    parse(p, img, model, params, width, varargin{:});

%% calculate positions of the interpolation positions
    switch p.Results.axis
        case 'x'
            centers.x = 1:size(img,2);
            centers.y = 1:size(img,1);
            [~, centers.y] = model(params, centers.x, NaN, -1);
        case 'y'
            centers.x = 1:size(img,2);
            centers.y = 1:size(img,1);
            n(1) = params(2);
            n(2) = params(1);
            n(3) = params(3);
            [~, centers.x] = model(n, centers.y, NaN, 1);
        case 'f'
            ex = MException('MATLAB:notImplemented', ...
                'Not possible to use the axis %s. This option is not implemented yet.', p.Results.axis);
            throw(ex)
        otherwise
            ex = MException('MATLAB:noSuchAxis', ...
                'Not possible to use the axis %s. Chose either x, y or f.', p.Results.axis);
            throw(ex)
    end
%% calculate the borders (just for visualisation)
%     paramsInner = n;
%     paramsInner(3) = paramsInner(3) - width/2;
%     [~, centers.xInner] = model(paramsInner, centers.y, NaN, -1);
%     paramsOuter = n;
%     paramsOuter(3) = paramsOuter(3) + width/2;
%     [~, centers.xOuter] = model(paramsOuter, centers.y, NaN, -1);
    
    x0 = params(1);
    y0 = params(2);
    
    m = (centers.y - y0) ./ (centers.x - x0);
    alpha = atan(m);
    
    % preallocate borders arrays
    borders = struct();
    borders.xInner = NaN(1,length(centers.x));
    borders.yInner = NaN(1,length(centers.x));
    borders.xOuter = NaN(1,length(centers.x));
    borders.yOuter = NaN(1,length(centers.x));
    
    switch p.Results.averaging
        case 'f'
            %% correct way to average the spectrum
            borders.xInner = centers.x - width/2 * cos(alpha);
            borders.yInner = centers.y - width/2 * sin(alpha);
            borders.xOuter = centers.x + width/2 * cos(alpha);
            borders.yOuter = centers.y + width/2 * sin(alpha);
        case 'x'
            %% "wrong" way to average the spectrum
            % corresponds to the old way of averaging
            borders.xInner = centers.x - width * sin(alpha);
            borders.yInner = centers.y;
            borders.xOuter = centers.x + width * sin(alpha);
            borders.yOuter = centers.y;
        case 'y'
            %% 
            borders.xInner = centers.x;
            borders.yInner = centers.y - width * cos(alpha);
            borders.xOuter = centers.x;
            borders.yOuter = centers.y + width * cos(alpha);
        otherwise
            ex = MException('MATLAB:noSuchAveraging', ...
                'Not possible to average in direction %s. Chose either x, y or f.', p.Results.averaging);
            throw(ex)
    end
    
    % create positions array for interpolating
    for jj = 1:length(centers.x)
        positions.x(:,jj) = linspace(borders.xInner(jj), borders.xOuter(jj), width);
        positions.y(:,jj) = linspace(borders.yInner(jj), borders.yOuter(jj), width);
    end
    
    [X, Y] = meshgrid(1:size(img,2),1:size(img,1));
    intensity = interp2(X,Y,img,positions.x,positions.y);
    
    intensity = nanmean(intensity, 1);
    
    %%
%     figure;
%     plot(diff(centers.x), 'color', 'blue');
%     hold on;
%     plot(diff(centers.y), 'color', 'red');
%     
%     figure;
%     imagesc(img);
%     hold on;
%     plot(centers.x, centers.y, 'color', 'green', 'linestyle', '--', 'linewidth', 2, 'marker', 'x');
% %     plot(centers.xInner, centers.y, 'color', 'red', 'linestyle', '--', 'linewidth', 2);
% %     plot(centers.xOuter, centers.y, 'color', 'red', 'linestyle', '--', 'linewidth', 2);
%     plot([borders.xInner; borders.xOuter], [borders.yInner; borders.yOuter], 'color', 'yellow');
%     axis equal
%     axis([1, size(img,2), 1, size(img,1)])
end