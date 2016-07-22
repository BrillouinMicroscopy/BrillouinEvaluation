%% open data file
Data = imread('D:\Guck-Users\Conrad\#Data\measurement\background2.tif');
% Data = imread('D:\Guck-Users\Conrad\#Data\measurement\methanol2.tif');

%% set parameters

% parameters for peak finding
background = 0.15;
column_nr = 1080;

% constant parameters
StartOrder = 1;
c = 299792458;
d = 0.0067743;
theta = 1.95/360*2*pi;
% theta = 1.6/360*2*pi;
lambda = 780.24e-9;
F = 0.20;
xs = 1.22;

d = 0.006774;
n = 1.4536539;
x0 = 9.92e-3;
theta = 1.6/360*2*pi;
lambda = 780.24e-9;
F = 0.20;
xs = 1.22;

% start parameters for VIPA fitting
n_start = 1.453654;
x0_start = 0.012099;

% plot parameters
orderNum = 2;
bin = 5e8;

MethanolPeaks = sort((2048 - [576, 674])*6.5e-6, 'ascend');

%% locate maxima and intensities

cutspectrum = im2double(Data(:, column_nr));
maxima = GetMaxima(cutspectrum, background, 25);

maxima(2,:) = (2048 - maxima(2,:)) * 6.5e-6;
maxima = maxima(2:3,:).';
maxima = sortrows(maxima, 1);

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
peaks = (2048 - [102, 234, 375, 533, 728, 1093]) * 6.5e-6;
peaks = sort(peaks, 'ascend');
maxima(:,1) = peaks.';


%% fit VIPA parameters

[ params_fit, fun1 ] = VIPAFit( maxima, n_start, d, theta, lambda, F, x0_start, xs, StartOrder );

n = params_fit(1);
x0 = params_fit(2);

% n = 1.4536539;
% x0 = 12.099e-3;

%% calculate therorethical data
MaxNum = size(maxima, 1);

[x_F, m] = VIPApeaks( d, n, theta, lambda, F, x0, xs, MaxNum, StartOrder);
m = sort(m, 'descend');

% calculate FSR between second and third order
LambdaTest = GetWavelength( maxima(:,1), m(2), d, n, theta, F, x0, xs );
fTest = c./LambdaTest;
FSR = fTest(3) - fTest(2);

%% calculate brillouin shift

MethanolShift1 = GetWavelength(MethanolPeaks, m(2), d, n, theta, F, x0, xs);
fShift1 = c/lambda - c./MethanolShift1;
MethanolShift2 = GetWavelength(MethanolPeaks, m(3), d, n, theta, F, x0, xs);
fShift2 = c/lambda - c./MethanolShift2;

disp(fShift1);
disp(fShift2);


%% get frequency axis
xmin = min(maxima(:,1));
xmax = max(maxima(:,1));
[xLabels, ~, fLabels] = GetFrequencyAxisLabel(xmin, xmax, m(orderNum), bin, d, n, theta, F, x0, xs, lambda);

%% plot data

FreqPeaks = GetWavelength( x_F, m(1), d, n, theta, F, x0, xs );

figure()
plot(maxima(:, 1), (ones(length(maxima(:, 1)))*0.5), 'ro')
hold on
plot(x_F, (ones(length(x_F))*0.5), 'bX')

% set frequency axis
set(gca, 'XTick', xLabels)
set(gca, 'XTickLabel', fLabels)

% plot methanol peaks
plot(MethanolPeaks, (ones(length(MethanolPeaks))*0.5),'.')


%% parameters fit the first 3 peaks:
% d = 0.006774;
% n = 1.4536675;
% theta = 1.6/360*2*pi;
% lambda = 780.e-9;
% F = 0.20;
% x0 = 9.908e-3;
% xs = 1.22;
% k = 3;

% d = 0.006774;
% n = 1.4536539;
% x0 = 9.92e-3;
% theta = 1.6/360*2*pi;
% lambda = 780.24e-9;
% F = 0.20;
% xs = 1.22;
% k = 5;

% d = 0.006774;
% n = 1.4536997;
% theta = 1.6/360*2*pi;
% lambda = 781.1e-9;
% F = 0.20;
% x0 = 9.92e-3;
% xs = 1.22;
% k = 5;
