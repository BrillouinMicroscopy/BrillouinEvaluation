Data1 = im2double(imread('D:\Guck-Users\Conrad\#Data\20160728\OnlyLSM\Methanol.tif'));
Data2 = im2double(imread('D:\Guck-Users\Conrad\#Data\20160728\OnlyLSM\Water.tif'));

%% parameters for maximum search

SearchBackground_M = 0.13;
FitBackground_M = 0.115;

SearchBackground_W = 0.13;
FitBackground_W = 0.122;

cut = 10;
IntRes = 0.1;

AOIxM = [750, 1050];
columnsM = [700, 804];

AOIxW = [750,1050];
columnsW = [717, 786];

ColNum = 5;

% parameters for lorenzfit
w0 = 10;
I0 = 0.2;


%% fit peaks of the Mathanol spectrum

xData1_M = sum(Data1(AOIxM(1):AOIxM(2), columnsM(1)-ColNum:columnsM(1)+ColNum).', 1);
xData2_M = sum(Data1(AOIxM(1):AOIxM(2), columnsM(2)-ColNum:columnsM(2)+ColNum).', 1);
xData_M = xData1_M + xData2_M;

maxima_M = GetMaxima(xData_M, SearchBackground_M*2*(2*ColNum+1), cut);
maxima_M = sortrows(maxima_M.').';

xLorentzFit_M = 1:IntRes:length(xData_M);
xFitData_M = interp1(xData_M, xLorentzFit_M);

start_M = [maxima_M(1,:), w0, w0, maxima_M(3,:)];

[params_M, ~, ~, FittedCurve_M] = nfit_4peaks(xLorentzFit_M, xFitData_M, start_M, FitBackground_M*2*(2*ColNum+1));

peaks_M = (params_M(1:4) + AOIxM(1))*6.5e-6;
peaks_M = sort(peaks_M, 'ascend');

%% fit peaks for the water spectrum

xData1_W = sum(Data2(AOIxW(1):AOIxW(2), columnsW(1)-ColNum:columnsW(1)+ColNum).', 1);
xData2_W = sum(Data2(AOIxW(1):AOIxW(2), columnsW(2)-ColNum:columnsW(2)+ColNum).', 1);
xData_W = xData1_W + xData2_W;

maxima_W = GetMaxima(xData_W, SearchBackground_W*2*(2*ColNum+1), cut);
maxima_W = sortrows(maxima_W.').';

xLorentzFit_W = 1:IntRes:length(xData_W);
xFitData_W = interp1(xData_W, xLorentzFit_W);

start_W = [maxima_W(1,:), w0, 15, maxima_W(3,:)];

[params_W, ~, ~, FittedCurve_W] = nfit_4peaks(xLorentzFit_W, xFitData_W, start_W, FitBackground_W*2*(2*ColNum+1));

peaks_W = (params_W(1:4) + AOIxW(1))*6.5e-6;
peaks_W = sort(peaks_W, 'ascend');

%% plot fitted intensity distrebution

figure;
hold on
box on
ylim([2.6,6])
xlabel('pixel index')
ylabel('Intensity (pixel value)')
plot((1:1:length(xData_W)) - params_W(1), xData_W, '.')
plot(xLorentzFit_W - params_W(1), FittedCurve_W, 'r')

figure;
hold on
box on
ylim([2.5,7])
xlabel('pixel index')
ylabel('Intensity (pixel value)')
plot((1:1:length(xData_M)) - params_M(1), xData_M, '.')
plot(xLorentzFit_M - params_M(1), FittedCurve_M, 'r')

%% plot Spectra with AOI
figure;
imagesc(Data1(AOIxM(1):AOIxM(2),575:900))
hold on
axis equal
c = colorbar;
c.Label.String = 'relative intensity';
xlim([1,326])
xlabel('x pixel index')
ylabel('y pixel index')
plot(ones(2,1) * columnsM(1)-ColNum-574, AOIxM - AOIxM(1)+1, 'r')
plot(ones(2,1) * columnsM(1)+ColNum-574, AOIxM - AOIxM(1)+1, 'r')
plot(ones(2,1) * columnsM(2)-ColNum-575, AOIxM - AOIxM(1)+1, 'r')
plot(ones(2,1) * columnsM(2)+ColNum-575, AOIxM - AOIxM(1)+1, 'r')

figure;
imagesc(Data2(AOIxW(1):AOIxW(2),575:900))
hold on
axis equal
c = colorbar;
c.Label.String = 'relative intensity';
xlim([1,326])
xlabel('x pixel index')
ylabel('y pixel index')
plot(ones(2,1) * columnsW(1)-ColNum-574, AOIxW - AOIxW(1)+1, 'r')
plot(ones(2,1) * columnsW(1)+ColNum-574, AOIxW - AOIxW(1)+1, 'r')
plot(ones(2,1) * columnsW(2)-ColNum-575, AOIxW - AOIxW(1)+1, 'r')
plot(ones(2,1) * columnsW(2)+ColNum-575, AOIxW - AOIxW(1)+1, 'r')
