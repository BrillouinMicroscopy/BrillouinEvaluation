function [intensity] = getIntensity1D(img, maxima, width)
%% GETINTENSITY1D
%   The function extracts an intensity profile with a given width between
%   two given points from an image
% 
%   ##INPUT
%   img:            [1]     array containing the image
%   maxima:         [1]     2-D array containing the maxima positions
%       array [x, y, intensity]     [pix, pix, 1]
%   width:          [pix]   width of the profile
% 
%   ##OUTPUT
%   intensity:      [1]     extracted intensity profile

%%
mask = NaN(size(img));

m = (maxima(1,1) - maxima(1,2))/(maxima(2,1) - maxima(2,2));
n = maxima(1,1) - m*maxima(2,1);

% x = 1:size(img,2);
% 
% figure;
% imagesc(img);
% hold on;
% for jj = 1:size(maxima,2)
%     plot(maxima(2,jj),maxima(1,jj),'r+');
% end
% plot(x, m * x + n + width/2, 'color', 'red');
% plot(x, m * x + n - width, 'color', 'red');

for jj = 1:size(img,1)
    for kk = 1:size(img,2)
        if (jj > (m * kk) + n - width) && (jj < (m * kk) + n + width/2)
            mask(jj,kk) = 1;
        end
    end
end

masked = img.*mask;

intensity = transpose(nanmean(masked,2));

end

