%% Paramters from fit:
% [d, n, theta, x0, xs] =
% fitted with methanopl peaks
% [0.00677393225864520,1.45364520441644,0.0137950824077632,0.00582000000000000,1.15920000000000]
% for the classification:
% [0.00677377137910882,1.45367573148033,0.0148042202760559,0.00103700800000000,1.10555280000000]
% Fitted with water peaks
% [0.00677383065101610,1.45372079599059,0.0142977372323376,0.00600000000000000,1.12800000000000]

%% calculation

% peaks fitted in MaximaFirstStage
% peaks methanol spectrum
peaks = [0.00509571136815296,0.00550633659011742,0.00621786430391508,0.00650415463091791];
peaks = [0.000241170638161125,0.000658467443473923,0.00134210852566724,0.00163693383196553];
% first calibration measurement only 1 VIPA
peaks = 1-[0.00348146517918382,0.00376505125248156,0.00440096527673403,0.00475510959433452];



% peaks water spectrum
% peaks = [0.00506514672374777,0.00561613746653448,0.00608248503764085,0.00648405350079269];

peaks = sort(peaks, 'ascend');
peaks = peaks - peaks(1);

RPeakNumber = 2;
StartOrder = 2;

c = 299792458;
lambda = 780.24e-9;
bShift = 3.7979e9; % methanol
% bShift = 5.09e9;   % water
lambdaS = c/(c/lambda - bShift);
lambdaAS = c/(c/lambda + bShift);
F = 0.20;

if exist('run', 'var')
    run = run + 1;
else
    run = 0;
end

%
dVariation = 2.5e-5/(2^run);
if exist('dInd', 'var')
    dcenter = dRange(dInd);
else
    dcenter = 0.006774;
end
dRange = linspace((1-dVariation)*dcenter, (1+dVariation)*dcenter, 11);

%
thetaVariation = 0.06/(2^run);
if exist('thetaInd', 'var')
    thetacenter = thetaRange(thetaInd)*360/2/pi;
else
    thetacenter = 0.8;
end
thetaRange = linspace((1-thetaVariation)*thetacenter, (1+thetaVariation)*thetacenter, 11);
thetaRange = thetaRange / 360*2*pi;

%
xsVariation = 0.1/(2^run);
if exist('xsInd', 'var')
    xscenter = xsRange(xsInd);
else
    xscenter = 1.2;
end
xsRange = linspace((1-xsVariation)*xscenter, (1+xsVariation)*xscenter, 11);

%
nVariation = 2e-5/(2^run);
if exist('nInd', 'var')
    ncenter = nRange(nInd);
else
    ncenter = 1.453683;
end
nRange = linspace((1-nVariation)*ncenter, (1+nVariation)*ncenter, 11);

%
x0Variation = 0.3/(2^run);
if exist('x0Ind', 'var')
    x0center = x0Range(x0Ind);
else
    x0center = 0.0001;
end
x0Range = linspace((1-x0Variation)*x0center, (1+x0Variation)*x0center, 11);

ErrorVector = zeros(length(dRange), length(thetaRange), length(xsRange), length(nRange), length(x0Range));

for ii = 1:length(dRange)
    disp(ii);
    for jj = 1:length(thetaRange)
        for kk = 1:length(xsRange)
            for ll = 1:length(nRange)
                for mm = 1:length(x0Range)
                    [x_F, m] = VIPApeaks( dRange(ii), nRange(ll), thetaRange(jj), lambda, F, x0Range(mm), xsRange(kk), RPeakNumber, StartOrder);
                    m = sort(m, 'descend');
                    xTheoS = ShiftPeaks( dRange(ii), nRange(ll), thetaRange(jj), lambdaS, F, x0Range(mm), xsRange(kk), m(2));
                    xTheoAS = ShiftPeaks( dRange(ii), nRange(ll), thetaRange(jj), lambdaAS, F, x0Range(mm), xsRange(kk), m(1));
                    
                    x_F(RPeakNumber + 1:RPeakNumber + 2) = [xTheoS, xTheoAS];
                    x_F = sort(x_F, 'ascend');
                    err = (peaks - x_F); % .* [0.1 0.99 0.99 0.5 0.3 0.1];
                    ErrorVector(ii,jj,kk,ll,mm) = sum(err.^2);
                end
            end
        end
    end
end

%%
% peaks = (2048 - [102, 234, 375, 533, 728, 1093]) * 6.5e-6;
% peaks = sort(peaks, 'ascend');

[minimum, ind] = min(ErrorVector(:));

[dInd, thetaInd, xsInd, nInd, x0Ind] = ind2sub(size(ErrorVector),ind);

Parameter = [dRange(dInd), nRange(nInd), thetaRange(thetaInd), x0Range(x0Ind), xsRange(xsInd)];
% dRange(dInd)
% nRange(nInd)
% thetaRange(thetaInd)
% x0Range(x0Ind)
% xsRange(xsInd)

[x_Min, m] = VIPApeaks( dRange(dInd), nRange(nInd), thetaRange(thetaInd), lambda, F, x0Range(x0Ind), xsRange(xsInd), RPeakNumber, StartOrder);
m = sort(m, 'descend');
x_MinS = ShiftPeaks( dRange(dInd), nRange(nInd), thetaRange(thetaInd), lambdaS, F, x0Range(x0Ind), xsRange(xsInd), m(2));
x_MinAS = ShiftPeaks( dRange(dInd), nRange(nInd), thetaRange(thetaInd), lambdaAS, F, x0Range(x0Ind), xsRange(xsInd), m(1));

%% MethanolPeaks

% m = sort(m, 'descend');
% MethanolShift1 = GetWavelength(MethanolPeaks, m(2), dRange(dInd), nRange(nInd), thetaRange(thetaInd), F, x0Range(x0Ind), xsRange(xsInd));
% fShift1 = c/lambda - c./MethanolShift1;
% MethanolShift2 = GetWavelength(MethanolPeaks, m(3), dRange(dInd), nRange(nInd), thetaRange(thetaInd), F, x0Range(x0Ind), xsRange(xsInd));
% fShift2 = c/lambda - c./MethanolShift2;
% 
% disp(fShift1);
% disp(fShift2);
% 
% FSR = fShift2 - fShift1;
% disp(FSR);
disp(minimum);

%% plot

figure;
plot(peaks, ones(length(peaks)), 'or');
hold on
plot(x_Min, ones(length(x_Min)), 'xb');
plot(x_MinS, 1, 'xb');
plot(x_MinAS, 1, 'xb');

