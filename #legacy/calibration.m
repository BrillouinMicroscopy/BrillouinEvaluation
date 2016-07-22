%% get data from .tif file
methanolspectrum = im2double(imread('d:\Guck-Users\Conrad\#Data\measurement\methanol2.tif'));
Xm = size(methanolspectrum,2);
Ym = size(methanolspectrum,1);

waterspectrum = im2double(imread('d:\Guck-Users\Conrad\#Data\measurement\water2.tif'));
Xw = size(methanolspectrum,2);
Yw = size(methanolspectrum,1);

% plot(1:1:Y, spectrum(:, 1085))

column = 1085;
rows = 560:700;

%% evaluation for methanol

% figure(1)
% imshow(spectrum)
% hold on
% plot([column, column], [1, Y], 'r')

% mean of the 3 rows next to each other
data_m = mean(methanolspectrum(rows, column - 1:column + 1), 2);

% interpolation for better fit
xm = rows(1):0.1:rows(end);
newdata2b_m = interp1(rows, data_m, xm);

width_m = 20;
floorb_m = 0.13;

newxb_m = 1:1:length(newdata2b_m);

[Int1m, p1m] = max(newdata2b_m(1:round(length(newdata2b_m)/2)));
[Int2m, p2m] = max(newdata2b_m(round(length(newdata2b_m)/2):end));

newdata2b_m(newdata2b_m < floorb_m) = floorb_m;

start_m = [p1m, round(length(newdata2b_m)/2)+p2m, width_m, Int1m, Int2m];

[estimates2b_m, model2b_m, newxb_m, FittedCurve2b_m] = nfit_2peaks(newxb_m, newdata2b_m, start_m, floorb_m);

plot(rows, data_m, '.');
hold on;
plot(xm, FittedCurve2b_m,'r-');

%% evaluation for water

% figure(1)
% imshow(spectrum)
% hold on
% plot([column, column], [1, Y], 'r')

% mean of the 3 rows next to each other
data_w = mean(waterspectrum(rows, column - 1:column + 1), 2);

% interpolation for better fit
xw = rows(1):0.1:rows(end);
newdata2b_w = interp1(rows, data_w, xw);

width_w = 20;
floorb_w = 0.13;

newxb_w = 1:1:length(newdata2b_w);

[Int1w, p1w] = max(newdata2b_w(1:round(length(newdata2b_w)/2)));
[Int2w, p2w] = max(newdata2b_w(round(length(newdata2b_w)/2):end));

newdata2b_w(newdata2b_w < floorb_w) = floorb_w;

start_w = [p1w, round(length(newdata2b_w)/2)+p2w, width_w, Int1w, Int2w];

[estimates2b_w, model2b, newxb_w, FittedCurve2b_w] = nfit_2peaks(newxb_w, newdata2b_w, start_w, floorb_w);

plot(rows, data_w, 'b.')
plot(xw, FittedCurve2b_w, 'g-')

%% calculation of the FSR

PR = (5.0934 - 3.7979)/((estimates2b_w(1) - estimates2b_m(1)) + (-estimates2b_w(2) + estimates2b_m(2)))*2;

FSR = 2*3.7979 + PR*(estimates2b_m(2) - estimates2b_m(1));

disp('the FSR [GHz] of the optical construction is about FSR =')
disp(FSR)
