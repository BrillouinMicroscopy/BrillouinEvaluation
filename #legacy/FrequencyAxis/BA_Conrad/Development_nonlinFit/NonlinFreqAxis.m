%% get Data
Data3 = im2double(imread('D:\Guck-Users\Conrad\#Data\20160728\OnlyLSM\Water.tif'));
Data = im2double(imread('D:\Guck-Users\Conrad\#Data\20160728\OnlyLSM\Methanol.tif'));
Data1 = im2double(imread('D:\Guck-Users\Conrad\#Data\20160728\OnlyLSM\WithoutSample.tif'));
Data2 = Data - Data1;
%% constant parameters

c = 299792458;
lambda = 780.24e-9;
bShiftM = 3.7979e9;
MlambdaS = c/(c/lambda - bShiftM);
MlambdaAS = c/(c/lambda + bShiftM);
bShiftW = 5.09e9;
WLambdaS = c/(c/lambda - bShiftW);
WLambdaAS = c/(c/lambda + bShiftW);
F = 0.20;

%% parameters for maximum search

SearchBackground = 0.02;
FitBackground = 0.0;
cut = 10;
IntRes = 0.1;

AOIx = [750, 1050];
columns = [700, 804];
ColNum = 5;

% parameters for lorenzfit
w0 = 10;
I0 = 0.2;

%% start parameters for fit
StartOrder = 1;
RpeakNum = 2;

dStart = 0.0067739;
dMax = 0.0067741;
dMin = 0.0067738;
nStart = 1.45371;
nMax = 1.4537200;
nMin = 1.4537;
thetaStart = 0.8 *2*pi/360;
thetaMax = 0.9 *2*pi/360;
thetaMin = 0.7 *2*pi/360;
x0Start = 0.006;
x0Max = 0.01;
x0Min = 0.004;
xsStart = 1.12;
xsMax = 1.3;
xsMin = 1.0;

VIPAstart = [dStart, nStart, thetaStart, x0Start, xsStart];
ub = [dMax, nMax, thetaMax, x0Max, xsMax];
lb = [dMin, nMin, thetaMin, x0Min, xsMin];

%% fit peaks of the spectrum


xData1 = sum(Data2(AOIx(1):AOIx(2), columns(1)-ColNum:columns(1)+ColNum).', 1);
xData2 = sum(Data2(AOIx(1):AOIx(2), columns(2)-ColNum:columns(2)+ColNum).', 1);
xData = xData1 + xData2;

maxima = GetMaxima(xData, SearchBackground*2*(2*ColNum+1), cut);
maxima = sortrows(maxima.').';

xLorentzFit = 1:IntRes:length(xData);
xData = interp1(xData, xLorentzFit);

start = [maxima(1,:), w0, w0, maxima(3,:)];

[params, ~, ~, FittedCurve] = nfit_4peaks(xLorentzFit, xData, start, FitBackground*2*(2*ColNum+1));

peaks = (params(1:4) + AOIx(1)) * 6.5e-6;
peaks = sort(peaks, 'ascend');

%% fit VIPA parameters

[fitParams, fun1] = VIPABrillouinFit(peaks, VIPAstart, ub, lb, lambda, MlambdaS, MlambdaAS, F, StartOrder, RpeakNum);

dFit = fitParams(1);
nFit = fitParams(2);
thetaFit = fitParams(3);
x0Fit = fitParams(4);
xsFit = fitParams(5);

%% calculation of the Rayleigh peaks
[xR, m] = VIPApeaks( dFit, nFit, thetaFit, lambda, F, x0Fit, xsFit, RpeakNum, StartOrder);
m = sort(m, 'descend');

%% calculation of the Brillouin peaks

xMethS = ShiftPeaks(dFit, nFit, thetaFit, MlambdaS, F, x0Fit, xsFit, m(2));
xMethAS = ShiftPeaks(dFit, nFit, thetaFit, MlambdaAS, F, x0Fit, xsFit, m(1));


%% plot Data

figure;
hold on
plot(peaks, (ones(length(peaks))*0.5), 'ro')
plot(xR, (ones(length(xR))*0.5), 'bX')
plot(xMethS, (ones(length(xMethS))*0.5), 'bX')
plot(xMethAS, (ones(length(xMethAS))*0.5), 'bX')