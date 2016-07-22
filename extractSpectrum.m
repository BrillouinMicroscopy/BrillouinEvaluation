function [intensity, parameters] = extractSpectrum(img, lorentzParams)
% This function extracts the 1D intensity distribution along the diagonal 
% plane from the acquired 2D data
% input:
% img           2D data
% gap           minimum distance between the edges of the image and the
%               choosen maxima in ChooseMaxima
% plane_width   width of the plane summed up creating the 1D spectrum

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