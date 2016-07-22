%% constant parameters

c = 299792458;
lambda = 780.24e-9;
bShiftM = 3.7979e9;
MlambdaS = c/(c/lambda - bShiftM);
MlambdaAS = c/(c/lambda + bShiftM);
bShiftW = 5.09e9;
WlambdaS = c/(c/lambda - bShiftW);
WlambdaAS = c/(c/lambda + bShiftW);


%% VIPA parameters

F = 0.20;
d = 0.006774;
n = 1.4537;
theta = 0.8*2*pi/360;
x0 = 0.00600000000000000;
xs = 1.12800000000000;

PeakNum = 2;
StartOrder = 1;

%% calculate theoretical linear calibration

% calculation of the Rayleigh peaks
[x_F1, m] = VIPApeaks( d, n, theta, lambda, F, x0, xs, PeakNum, StartOrder);
m = sort(m, 'descend');

% calculation of the Brillouin peaks
xMethS = ShiftPeaks( d, n, theta, MlambdaS, F, x0, xs, m(2));
xMethAS = ShiftPeaks( d, n, theta, MlambdaAS, F, x0, xs, m(1));
xWaterS = ShiftPeaks( d, n, theta, WlambdaS, F, x0, xs, m(2));
xWaterAS = ShiftPeaks( d, n, theta, WlambdaAS, F, x0, xs, m(1));

% calculate theoretical PR and FSR
PR = (bShiftW - bShiftM)/(xMethS-xMethAS - xWaterS+xWaterAS)*2;
PR = (bShiftW - bShiftM)/(xWaterAS-xMethAS);
FSR = 2*bShiftW + PR*(xWaterS - xWaterAS);

%% compare linear and nonlinear axis


[ RPeaks, m ] = VIPApeaks(d, n, theta, lambda, F, x0, xs, PeakNum, StartOrder);
m = sort(m, 'ascend');

LinShift = (FSR - PR*(RPeaks(1) - RPeaks(2)))/2;

theta_in = asin(sin(theta)/n);
x_FSR = (RPeaks - x0)./xs;

FSR2 = c./(((2*d*n*cos(theta_in)) - ...
       (2*d*tan(theta_in)*cos(theta)*x_FSR/F) - ...
       (d*cos(theta_in)*x_FSR.^2/(n*F^2))));
   
frequencies = linspace(0, FSR2(1), 100);

linFreq = zeros(length(frequencies), 1);
for kk = 1:1:length(frequencies)
    lambdaShiftS = c/(c/lambda - frequencies(kk));
    lambdaShiftAS = c/(c/lambda + frequencies(kk));
    
    peakS = ShiftPeaks( d, n, theta, lambdaShiftS, F, x0, xs, m(1));
    peakAS = ShiftPeaks( d, n, theta, lambdaShiftAS, F, x0, xs, m(2));
    
    linFreq(kk) = (FSR - PR*(peakS - peakAS))/2; 
%     linFreqS = (FSR/2 - PR*(peakS - (xWaterAS + xWaterS)/2));
    linFreq(kk) = (FSR/2 + PR*(peakAS - (xWaterAS + xWaterS)/2));
%     linFreq(kk) = (linFreqS + linFreqAS)/2;
end

figure;
hold on
box on
xlim([-0.5,15.5])
set(gca, 'XMinorTick', 'on')
xlabel('frequency $f$ [GHz]', 'interpreter', 'LaTeX')
ylabel('$\Delta\nu$ [GHz]', 'interpreter', 'LaTeX')
plot(frequencies/1e9, (frequencies.' - linFreq)/1e9, '.')