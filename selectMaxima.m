function [maxima] = selectMaxima(maxima, x, y, gap)
%% SELECTMAXIMA
%   the function selects the outer maxima on a diagonal plane in the image.
%
%   ##INPUT
%   maxima:         [ ]     matrix of maxima position and intensity
%       array [x, y, intensity]     [pix, pix, 1]
%   x:              [pix]   x-resolution of the image
%   y:              [pix]   y-resolution of the image
%   gap:            [pix]   minimum gap between the edges of the image and
%                           the chose maxima
%
%   ##OUTPUT
%   maxima:         [ ]     matrix of the selected maxima with their
%                           position and intensity
%       array [x, y, intensity]     [pix, pix, 1]

xmaxima = maxima(1,:);
xmaxima(xmaxima < (gap + 1) | xmaxima > (x - gap - 1)) = NaN;

ymaxima = maxima(2,:);
ymaxima(ymaxima < (gap + 1) | ymaxima > (y - gap - 1)) = NaN;

ymaxima(xmaxima < (gap + 1) | xmaxima > (x - gap - 1)) = NaN;
xmaxima(ymaxima < (gap + 1) | ymaxima > (y - gap - 1)) = NaN;

distance = xmaxima + ymaxima;

[~, ind1] = min(distance);
[~, ind2] = max(distance);

maxima = maxima(:, [ind1, ind2]);
end

