% get data from sif image
% [spectrum, X, Y] = GetSifImage('Spectrum.sif', 0);

% get data from .tif file
spectrum = im2double(imread('Spectrum.tif'));
X = size(spectrum,2);
Y = size(spectrum,1);

% figure(1)
% plot(spectrum)
% figure(2)
% plot(spectrum.')
% figure(3)
% imshow(spectrum)

% cut out area of interest
xmin = 1170;
xmax = 1420;
ymin = 950;
ymax = 1150;
smallspectrum = spectrum((ymin:ymax), (xmin:xmax));

% get resolution of the image
x = xmax - xmin +1;
y = ymax - ymin + 1;

%set parameter for data analysis
backround = 0.12;        % [counts]  maximum intensity of backround
gap = 10;               % [pix]     minimum x and y distance of maxima to the edges of the image
cut = 25;               % [pix]     number of quadratic layers around the maxima to cut out in progress
plane_width = 5;        % width of the area to get the intensity distibution
xResolution = 0.5;      % [pix]     x-Resolution of the interpolatet intensity distribution
yResolution = 0.5;      % [pix]     y-Resolution of the interpolatet intensity distribution

% localise the maxima in the image
maxima = GetMaxima(smallspectrum, backround, cut);

% select the maxima for the intensity distribution
[p1, p2] = ChooseMaxima(maxima, x, y, gap);

% interpolate along the planes in between the two selected maxima
[intensity, x_interpol, y_interpol] = GetIntensity(smallspectrum, p1, p2, plane_width, xResolution, yResolution);

% sum up the intensity from different planes
intensity_sum = sum(intensity,1,'omitnan');

%% calculate the finesse of the optical construction

floorb = 1.;
width = 10;
newdata2b = intensity_sum;
newdata2b(newdata2b < floorb) = floorb;

[I1, m1] = max(newdata2b(1:round(length(newdata2b)/2)));
[I2, m2] = max(newdata2b(round(length(newdata2b)/2):end));
newxb = 1:1:length(newdata2b);

start = [m1, round(length(newdata2b)/2)+m2, width, I1, I2];

[estimates2b, model2b, newxb, FittedCurve2b] = nfit_2peaks(newxb, newdata2b, start, floorb);

finesse = (estimates2b(2) - estimates2b(1)) / estimates2b(3);

disp('the finesse of the optical construction is f =');
disp(finesse);

%% ploting the results

% plot intensity distribution
figure(1)
x_plot = (0:1:size(intensity, 2)-1)*xResolution;
%intensity distibution of all planes sumed up
plot(x_plot, intensity_sum, '.')
hold on
plot(x_plot, FittedCurve2b)
hold off
title('intensity distribution of all planes summed up')
xlabel('distance [px]')
ylabel('intensity [counts]')

%plot the image and analysed area
figure(2)
%plot image
imshow(smallspectrum, [])
title('image of the spectrum with analysed area')
hold on
%plot analysed area
%plot upper plane
plot(x_interpol(1,:), y_interpol(1,:),'r')
hold on
%plot lower plane
plot(x_interpol(plane_width/yResolution+1,:), y_interpol(plane_width/yResolution+1,:),'r')
