function [ maxima ] = getMaxima2D( img, limit )
%% GETMAXIMA localises maxima in an image
%   input:
%   img: image
%   limit: maximum number of maximas
%
%   output:
%   maxima: array [x, y, intensity]

%   idea of the function was adapted form FastPeakFind:
%   https://de.mathworks.com/matlabcentral/fileexchange/37388-fast-2d-peak-finder

%   first filter all hot pixels and smooth with Gaussian filter
%   find all non-zero pixels and check if they are local maxima
%   sort local maxima by intensity limit count of maxima to the value of
%   limit

% number of pixels to ignore at the image border
border = 3;

% get the background threshold
thres = getBackground(img);

% remove salt and pepper pixels by a median filter
img = medfilt2(img,[3,3]);

% set all values smaller than the threshold to zero
img = img.*double(img>thres);

% smooth image
filt = (fspecial('gaussian', 7,1));
img = conv2(double(img),filt,'same');

% again apply the threshold
img = img.*(img>0.9*thres);

% find all non-zero values
sizeImg = size(img);
[x, y, I] = find(img(border:sizeImg(1)-border, border:sizeImg(2)-border));

% correct for ignored image border
x = x+border-1;
y = y+border-1;

% iterate over all non-zero pixels and check if they are a local maxima
posX = [];
posY = [];
int = [];
for j=1:length(y)
    if (img(x(j),y(j))>=img(x(j)-1,y(j)-1 )) && ...
       (img(x(j),y(j))> img(x(j)-1,y(j)))    && ...
       (img(x(j),y(j))>=img(x(j)-1,y(j)+1))  && ...
       (img(x(j),y(j))> img(x(j),  y(j)-1))  && ...
       (img(x(j),y(j))> img(x(j),  y(j)+1))  && ...
       (img(x(j),y(j))>=img(x(j)+1,y(j)-1))  && ...
       (img(x(j),y(j))> img(x(j)+1,y(j)))    && ...
       (img(x(j),y(j))>=img(x(j)+1,y(j)+1));
    
        posX = [posX; x(j)]; %#ok<*AGROW>
        posY = [posY; y(j)];
        int = [int; I(j)];
    end
end

[int,ind] = sort(int,'descend');
posX = posX(ind);
posY = posY(ind);

maxima = [transpose(posX); transpose(posY); transpose(int)];
maxima = maxima(:,1:limit);

end

