
Data1 = im2double(imread('d:\Guck-Users\Conrad\#Data\measurement\Methanol2.tif'));
Data2 = im2double(imread('d:\Guck-Users\Conrad\#Data\measurement\Water2.tif'));

%% parameters for maximum search

SearchBackground_M = 0.18;
FitBackground_M = 0.13;

SearchBackground_W = 0.17;
FitBackground_W = 0.123;

cut = 25;
IntRes = 0.1;

AOIxM = [510, 760];
columnM = 1080;

AOIxW = [510, 760];
columnW = 1080;

ColNum = 2;

% parameters for lorenzfit
w0 = 10;
I0 = 0.2;


%% fit peaks of the Mathanol spectrum

xData_M = sum(Data1(AOIxM(1):AOIxM(2), columnM-ColNum:columnM+ColNum).', 1);

maxima_M = GetMaxima(xData_M, SearchBackground_M*(2*ColNum+1), cut);
maxima_M = sortrows(maxima_M.').';

xLorentzFit_M = 1:IntRes:length(xData_M);
xData_M = interp1(xData_M, xLorentzFit_M);

start_M = [maxima_M(1,:), w0, w0, maxima_M(3,:)];

[params, ~, ~, FittedCurve_M] = nfit_4peaks(xLorentzFit_M, xData_M, start_M, FitBackground_M*(2*ColNum+1));

peaks_M = (params(1:4) + AOIxM(1))*6.5e-6;
peaks_M = sort(peaks_M, 'ascend');

%% fit peaks for the water spectrum

xData_W = sum(Data2(AOIxW(1):AOIxW(2), columnW-ColNum:columnW+ColNum).', 1);

maxima_W = GetMaxima(xData_W, SearchBackground_W*(2*ColNum+1), cut);
maxima_W = sortrows(maxima_W.').';

xLorentzFit_W = 1:IntRes:length(xData_W);
xData_W = interp1(xData_W, xLorentzFit_W);

start_W = [maxima_W(1,:), w0, 15, maxima_W(3,:)];

[params_W, ~, ~, FittedCurve_W] = nfit_4peaks(xLorentzFit_W, xData_W, start_W, FitBackground_W*(2*ColNum+1));

peaks_W = (params_W(1:4) + AOIxW(1))*6.5e-6;
peaks_W = sort(peaks_W, 'ascend');
