%% open data file
Data = imread('D:\Guck-Users\Conrad\#Data\measurement\background2.tif');
Data2 = imread('D:\Guck-Users\Conrad\#Data\20160803\Spectrum_WithoutSample.tif');
Data3 = im2double(imread('D:\Guck-Users\Conrad\#Data\20160728\OnlyLSM\Methanol.tif'));
% Data = imread('D:\Guck-Users\Conrad\#Data\measurement\methanol2.tif');

%% set parameters

% parameters for peak finding
background = 0.15;
column_nr = 1080;

% constant parameters
c = 299792458;
d = 0.0067740;
theta = 0.8/360*2*pi;
% theta = 1.6/360*2*pi;
lambda = 780.24e-9;
F = 0.20;
xs = 1.;

% start parameters for VIPA fitting
n_start = 1.4537;
x0_start = 0.012099;

% plot parameters
orderNum = 2;
bin = 5e8;


%% locate maxima and intensities

% cutspectrum = im2double(Data(:, column_nr));
% maxima = GetMaxima(cutspectrum, background, 25);
% 
% maxima(2,:) = (2048 - maxima(2,:)) * 6.5e-6;
% maxima = maxima(2:3,:).';
% maxima = sortrows(maxima, 1);

% points = zeros(size(maxima, 2), 1);
% for kk = 1:1:size(maxima, 2)
%     data = spectrum((maxima(1,kk)-30):(maxima(1,kk)+30)).';
%     newx = (1:1:size(data, 2)) + (maxima(1, kk)-30);
%     start = [maxima(1,kk), 10, maxima(2, kk)];
%     
%     [FittedParams, FittedCurve] = LorentzFit(start, 0.125, newx, data);
%     points(kk) = FittedParams(1);
% end

% change location of maxima because of bad data (camera overload)
% peaks = (2048 - [110, 236, 376, 534, 729.5, 1094]) * 6.5e-6;

peaksStart = (2048 - [102, 234, 375, 533, 728, 1093]) * 6.5e-6;
peaksStart = sort(peaksStart, 'ascend');

MethanolPeaks = sort((2048 - [576, 674])*6.5e-6, 'ascend');

peaks = peaksStart(2:3);
peaks(3:4) = MethanolPeaks;

% peaks = [845, 955, 783, 999] * 6.5e-6;

peaks = sort(peaks, 'ascend');

%% fit VIPA parameters
StartOrder = 1;

bShift = 3.7979e9;
lambdaS = c/(c/lambda - bShift);
lambdaAS = c/(c/lambda + bShift);

[ params_fit, fun1, x_F ] = VIPAFitTest( peaks, n_start, d, theta, lambda, lambdaS, lambdaAS, F, x0_start, xs, StartOrder  );

n = params_fit(1);
x0 = params_fit(2);

% n = 1.4536539;
% x0 = 12.099e-3;

%% calculate therorethical data
% d = 0.006864471607500;
% d = 0.006774;
% n = 1.453651741200000;
% theta = 0.028260371248292;
% x0 = 0.01219300000000000;
% xs = 1.202000000000000;
% StartOrder = 1;
% 
% 
% [x_F1, m] = VIPApeaks( d, n, theta, lambda, F, x0, xs, 6, 1);
% m = sort(m, 'descend');
% 
% xMethS = ShiftPeaks( d, n, theta, lambdaS, F, x0, xs, m(3));
% xMethAS = ShiftPeaks( d, n, theta, lambdaAS, F, x0, xs, m(2));


%% calculate FSR
theta_in = asin(sin(theta)/n);
x_FSR = (x_F - x0)./xs;

FSR2 = c./(((2*d*n*cos(theta_in)) - ...
       (2*d*tan(theta_in)*cos(theta)*x_FSR/F) - ...
       (d*cos(theta_in)*x_FSR.^2/(n*F^2))));

%% calculate brillouin shift

% MethanolShift1 = GetWavelength(MethanolPeaks, m(2), d, n, theta, F, x0, xs);
% fShift1 = c/lambda - c./MethanolShift1;
% MethanolShift2 = GetWavelength(MethanolPeaks, m(3), d, n, theta, F, x0, xs);
% fShift2 = c/lambda - c./MethanolShift2;
% 
% disp(fShift1);
% disp(fShift2);


%% get frequency axis
xmin = min(maxima(:,1));
xmax = max(maxima(:,1));
[xLabels, ~, fLabels] = GetFrequencyAxisLabel(xmin, xmax, m(orderNum), bin, d, n, theta, F, x0, xs, lambda);

%% plot data

figure()
plot(peaks, (ones(length(peaks))*0.5), 'ro')
hold on
% plot(peaksStart, (ones(length(peaksStart))*0.5), 'ro')
plot(x_F, (ones(length(x_F))*0.5), 'kX')
% plot(x_F1, (ones(length(x_F1))*0.5), 'bX')
% plot(xMethS, (ones(length(xMethS))*0.5), 'bX')
% plot(xMethAS, (ones(length(xMethAS))*0.5), 'bX')
% xlim([8.4e-3 10e-3]);

% set frequency axis
set(gca, 'XTick', xLabels)
set(gca, 'XTickLabel', fLabels)

% plot methanol peaks
% plot(MethanolPeaks, (ones(length(MethanolPeaks))*0.5),'.')