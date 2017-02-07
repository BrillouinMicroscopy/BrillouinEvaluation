function [intensity, parameters] = extractSpectrum(img, lorentzParams)
%% EXTRACTSPECTRUM
%   This function extracts the 1D intensity distribution along the diagonal 
%   plane from the acquired 2D data
% 
%   ##INPUT
%   img:            [1]     array containing the image
%   lorentzParams =
%   plane_width:    [pix]   width of the plane to cut around the intensity maxima
%           gap:    [pix]   minimum x and y distance of maxima to the edges of the image
%          fwhm:    [pix]   estimated width of the lorentz peaks for the fit
%   
%   ##OUTPUT
%   intensity:      [1]     vector containg the extracted intensity profile
%                           between the identified Rayleigh peaks
%   parameters =
%         peaks:    [pix]   array containing the positions of the found maxima

%%
% localise the maxima in the image
[maxima] = getMaxima2D(img, 4);

%     figure;
%     imagesc(img);
%     hold on;
%     for jj = 1:size(maxima,2)
%         plot(maxima(2,jj),maxima(1,jj),'r+');
%     end

% select the maxima for the intensity distribution
[maxima] = selectMaxima( maxima, size(img, 2), size(img, 1), lorentzParams.gap);
%     figure;
%     imagesc(img);
%     hold on;
%     for jj = 1:size(maxima,2)
%         plot(maxima(2,jj),maxima(1,jj),'yo');
%     end

parameters.peaks = maxima;

% interpolate along the planes in between the two selected maxima
[intensity] = getIntensity1D(img, maxima, lorentzParams.plane_width);

end