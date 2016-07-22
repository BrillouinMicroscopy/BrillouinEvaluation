Data3 = im2double(imread('D:\Guck-Users\Conrad\#Data\20160728\OnlyLSM\Water.tif'));
Data2 = im2double(imread('D:\Guck-Users\Conrad\#Data\20160728\OnlyLSM\Methanol.tif'));

%%
peaks = [845, 955, 783, 999, 866, 938] * 6.5e-6;

% peaks fitted in NonlinFreqAxis
peaks = [0.00506514672374777,0.00561613746653448,0.00608248503764085,0.00648405350079269];
peaks = sort(peaks, 'ascend');

peaks_M = [0.00509571136815296,0.00550633659011742,0.00621786430391508,0.00650415463091791];
peaks = [0.000241170638161125,0.000658467443473923,0.00134210852566724,0.00163693383196553];
peaks_M = peaks_M - peaks_M(1);

% waterpeaks = [866, 938] *6.5e-6; 

%% constant parameters
c = 299792458;
lambda = 780.24e-9;
bShift = 3.7979e9;
lambdaS = c/(c/lambda - bShift);
lambdaAS = c/(c/lambda + bShift);
bShiftW = 5.09e9;
lambdaSW = c/(c/lambda - bShiftW);
lambdaASW = c/(c/lambda + bShiftW);
F = 0.20;

%% VIPA parameters
d = 0.006774;
n = 1.4537;
theta = 0.8/360*2*pi;
x0 = 0.005530;
xs = 1.22;
StartOrder = 1;
PeakNumber = 2;

d = 0.00667410011;
n = 1.453700444196;
theta = 0.014465288840529;
x0 = 0.006;
xs = 1.122;
StartOrder = 1;
PeakNumber = 2;

d = 0.00677393225864520;
n = 1.45364520441644;
theta = 0.0137950824077632;
x0 = 0.00582000000000000 - peaks(1);
xs = 1.15920000000000;

d = 0.00677383065101610;
n = 1.45372079599059;
theta = 0.0142977372323376;
x0 = 0.00600000000000000 - peaks(1);
xs = 1.12800000000000;

peaks = peaks - peaks(1);

% d = 0.00677399282509200;
% n = 1.45369969413899;
% theta = 0.0140536824174980;
% x0 = 0.00596680438107500;
% xs = 1.14995749684724;

%% calculation of the Rayleigh peaks
[x_F1, m] = VIPApeaks( d, n, theta, lambda, F, x0, xs, PeakNumber, StartOrder);
m = sort(m, 'descend');

%% calculation of the Brillouin peaks

xMethS = ShiftPeaks( d, n, theta, lambdaS, F, x0, xs, m(2));
xMethAS = ShiftPeaks( d, n, theta, lambdaAS, F, x0, xs, m(1));
xWaterS = ShiftPeaks( d, n, theta, lambdaSW, F, x0, xs, m(2));
xWaterAS = ShiftPeaks( d, n, theta, lambdaASW, F, x0, xs, m(1));


%% calculate frequency shifts for water peaks

WaterShift1 = GetWavelength(peaks_M(2:3), m(1), d, n, theta, F, x0, xs);
fShift1 = c/lambda - c./WaterShift1
WaterShift2 = GetWavelength(peaks_M(2:3), m(2), d, n, theta, F, x0, xs);
fShift2 = c/lambda - c./WaterShift2

MethanolShift1 = GetWavelength(peaks(2), m(1), d, n, theta, F, x0, xs);
fShift1 = c/lambda - c./MethanolShift1
MethanolShift2 = GetWavelength(peaks(3), m(2), d, n, theta, F, x0, xs);
fShift2 = c/lambda - c./MethanolShift2

%% plot Data
figure()
hold on
title('fittet distribution vs measurement data')
xlabel('spacial resoluted spectrum')
plot(peaks, (ones(length(peaks))*0.5), 'ro')
plot(peaks_M(2:3), (ones(length(peaks_M(2:3)))*0.5), 'ro')
plot(x_F1, (ones(length(x_F1))*0.5), 'bX')
plot(xMethS, (ones(length(xMethS))*0.5), 'bX')
plot(xMethAS, (ones(length(xMethAS))*0.5), 'bX')
plot(xWaterS, (ones(length(xMethS))*0.5), 'bX')
plot(xWaterAS, (ones(length(xMethAS))*0.5), 'bX')

%%
% values fit the Data 'D:\Guck-Users\Conrad\#Data\20160728\OnlyLSM\Methanol.tif'
% d = 0.00667410011;
% n = 1.453700444196;
% theta = 0.014465288840529;
% x0 = 0.006;
% xs = 1.122;
% StartOrder = 1;
% PeakNumber = 2;