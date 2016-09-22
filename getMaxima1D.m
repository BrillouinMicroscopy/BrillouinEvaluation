function [maxima] = getMaxima1D(img, limit, borders)
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
%   borders:        [pix]   borders outside of which all found maximas are
%                           discarded
% 
%   ##OUTPUT
%   maxima:         [1]     2-D array containing the found maxima
%       array [x, y, intensity]     [pix, pix, 1]

%%
% number of pixels to ignore at the image border
border = 3;

% get the background threshold
thres = getBackground(img);

% remove salt and pepper pixels by a median filter
if size(img,1) > 1
    img = medfilt2(img,[3,3]);
else
    img = medfilt1(img,3);
end

% set all values smaller than the threshold to zero
img = img.*double(img>thres);

% smooth image
filt = [1 1 1 1]/4;
img = conv(double(img),filt,'same');

% again apply the threshold
img = img.*(img>0.9*thres);

% find all non-zero values
sizeImg = length(img);
[~, x, I] = find(img(border:sizeImg(1)-border));

% correct for ignored image border
x = x+border-1;

% iterate over all non-zero pixels and check if they are a local maxima
posX = [];
int = [];
for j=1:length(x)
    if (img(x(j))>=img(x(j)-1)) && ...
       (img(x(j))>=img(x(j)+1));
    
        posX = [posX; x(j)]; %#ok<*AGROW>
        int = [int; I(j)];
    end
end

% discard all values with positions outside the specified borders (usually
% the positions of the Rayleigh peaks
borders = sort(borders, 'ascend');
posX(posX < borders(1) | posX > borders(2)) = NaN;
int = int(~isnan(posX));
posX = posX(~isnan(posX));

% sort the peaks by intensity and limit to 'limit' highest peaks
[int,ind] = sort(int,'descend');
posX = posX(ind);
posX = posX(1:limit);
int = int(1:limit);

% sort the peaks by position
[posX,ind] = sort(posX,'ascend');
int = int(ind);

% construct array with position and intensity
maxima = [transpose(posX); transpose(int)];

%% Check result
% figure;
% plot(img);
% hold on;
% plot(maxima(1,:), maxima(2,:), 'linestyle', 'none', 'Marker', 'x', 'color', 'red');

end

