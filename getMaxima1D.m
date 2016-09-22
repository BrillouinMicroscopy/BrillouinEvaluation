function [maxima] = getMaxima1D(img, limit)
%% GETMAXIMA
%   localises maxima in an image
%
%   idea of the function was adapted form FastPeakFind:
%   https://de.mathworks.com/matlabcentral/fileexchange/37388-fast-2d-peak-finder

%   first filter all hot pixels and smooth with Gaussian filter
%   find all non-zero pixels and check if they are local maxima
%   sort local maxima by intensity limit count of maxima to the value of
%   limit
%
%   ##INPUT
%   img:            [1]     array containing the image
%   limit:          [1]     maximum number of maximas
% 
%   ##OUTPUT
%   maxima:         [1]     2-D array containing the found maxima
%       array [x, intensity]     [pix, 1]

%%
% remove salt and pepper pixels by a median filter
img = medfilt1(img,3);

% find all local peaks
[intensity,position,width,prominence] = findpeaks(img);

% sort the peaks by their prominence
[prominence,ind] = sort(prominence,'descend');
intensity = intensity(ind);
position = position(ind);
width = width(ind);

% check intermediate result
% figure(15);
% findpeaks(img, 'Annotate', 'extents');
% ylim([100 300]);
% text(position(1:limit)+.02,intensity(1:limit),num2str((1:limit)'));
% drawnow;

% limit number of peaks
prominence = prominence(1:limit);
intensity = intensity(1:limit);
position = position(1:limit);
width = width(1:limit);

% sort the peaks by their position
[position,ind] = sort(position,'ascend');
prominence = prominence(ind);
intensity = intensity(ind);
width = width(ind);

% construct array with position and intensity
maxima = [position; intensity; prominence; width];

%% Check result
% figure(16);
% plot(img);
% hold on;
% plot(maxima(1,:), maxima(2,:), 'linestyle', 'none', 'Marker', 'x', 'color', 'red');

end

