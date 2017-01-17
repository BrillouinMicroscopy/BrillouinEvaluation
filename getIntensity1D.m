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
    for jj = 1:length(centers.(p.Results.axis))
        positions.x(:,jj) = linspace(borders.x(1,jj), borders.x(2,jj), width);
        positions.y(:,jj) = linspace(borders.y(1,jj), borders.y(2,jj), width);
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
%     plot(borders.x, borders.y, 'color', 'yellow');
%     axis equal
%     axis([1, size(img,2), 1, size(img,1)])
end