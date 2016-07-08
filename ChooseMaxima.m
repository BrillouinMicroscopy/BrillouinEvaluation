function [ p1, p2 ] = ChooseMaxima( maxima, x, y, gap)
%ChooseMaxima selects two maxima on a diagonal plane
%   the function selects the outer maxima on a diagonal plane in the image.
%
%   input:
%   maxima: matrix of maxima position and intensity [x; y; I;]
%   x, y: x- and y-resolution of the image
%   gap: minimum gap between the edges of the Image and the coosen maxima
%
%   output:
%   p1, p2: positions and intensity of the selected maxima [x, y, I]

xmaxima = maxima(1,:);
xmaxima(xmaxima < (gap + 1) | xmaxima > (x - gap - 1)) = NaN;

ymaxima = maxima(2,:);
ymaxima(ymaxima < (gap + 1) | ymaxima > (y - gap - 1)) = NaN;

ymaxima(xmaxima < (gap + 1) | xmaxima > (x - gap - 1)) = NaN;
xmaxima(ymaxima < (gap + 1) | ymaxima > (y - gap - 1)) = NaN;

distance = xmaxima + ymaxima;

[~, ind1] = min(distance);
[~, ind2] = max(distance);

p1 = maxima(:, ind1);
p2 = maxima(:, ind2);
end

