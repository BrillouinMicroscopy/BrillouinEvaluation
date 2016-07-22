%% constant parameters

c = 299792458;
lambda = 780.24e-9;
bShiftM = 3.7979e9;
MlambdaS = c/(c/lambda - bShiftM);
MlambdaAS = c/(c/lambda + bShiftM);
bShiftW = 5.09e9;
WLambdaS = c/(c/lambda - bShiftW);
WLambdaAS = c/(c/lambda + bShiftW);


%% VIPA parameters from previous fit
F = 0.20;

% fitted with MinimumSearch.m
d = 0.00677383065101610;
n = 1.45372079599059;
theta = 0.0142977372323376;
x0 = 0.00600000000000000;
xs = 1.12800000000000;

%% parameters from linear fit
% calculated with linAxis.m
PR = 1.054000528604724e+13;
FSR = 1.509530586459642e+10;


%% compare linear and nonlinear axis
PeakNum = 2;
StartOrder = 1;

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
end

figure;
hold on
box on
xlim([-0.5,15.5])
% ylim([-0.11; 0.25])
set(gca, 'XMinorTick', 'on')
xlabel('frequency shift [GHz]')
ylabel('Error [GHz]')
plot(frequencies/1e9, (frequencies.' - linFreq)/1e9, '.')