
%% get data from .tif file
spectrum = im2double(imread('BrillouinExample.tif'));
x = size(spectrum,2);
y = size(spectrum,1);

%% set parameter for data analysis
backround = 0.1;        % [ ]   maximum intensity of backround
gap = 10;               % [pix] minimum x and y distance of maxima to the edges of the image
cut = 7;                % [pix] number of quadratic layers around the maxima to cut out in progress
plane_width = 5;        % [pix] width of the area to get the intensity distibution
xResolution = 0.5;        % [pix] x-resolution of the interpolated area
zResolution = 1;        % [pix] resolution of the width of the interpolated area


%% localise the maxima in the image
maxima = GetMaxima(spectrum, backround, cut);

%% select the maxima for the intensity distribution
[p1, p2] = ChooseMaxima( maxima, x, y, gap);

%% interpolate along the planes in between the two selected maxima
[intensity, x_interpol, y_interpol] = GetIntensity(spectrum, p1, p2, plane_width, xResolution, zResolution);

%% sum up the intensity from different planes
intensity_sum = sum(intensity, 1, 'omitnan');

%% fit data with lorenz curve
floorb = 0.02;
width = 10;
newdata2b = intensity_sum;
newdata2b(newdata2b < floorb) = floorb;

[I1, m1] = max(newdata2b(1:round(length(newdata2b)/2)));
[I2, m2] = max(newdata2b(round(length(newdata2b)/2):end));
newxb = 1:1:length(newdata2b);

start = [m1, round(length(newdata2b)/2)+m2, width, I1, I2];

[estimates2b, model2b, newxb, FittedCurve2b] = nfit_2peaks(newxb, newdata2b, start, floorb);

disp((estimates2b(2)-estimates2b(1))*0.12e9*xResolution);

% x_plot = (0:1:size(intensity, 2)-1)*xResolution;
% plot(x_plot, intensity_sum, '.');
% hold on
% plot(x_plot, FittedCurve2b, 'r');


%% plot intensity distribution

figure(1)
% intensity distibution of all planes sumed up
x_plot = (0:1:size(intensity, 2)-1)*xResolution;
plot(x_plot, intensity_sum, '.')
title('intensity distribution of all planes summed up')
xlabel('distance [px]')
ylabel('intensity [counts]')

%% plot the image and analysed area

figure(2)
%plot image
imshow(spectrum, [])
title('image of the spectrum with analysed area')
hold on

%plot upper plane
plot(x_interpol(1,:), y_interpol(1,:),'r')
hold on

%plot lower plane
plot(x_interpol(plane_width/zResolution+1,:), y_interpol(plane_width/zResolution+1,:),'r')
