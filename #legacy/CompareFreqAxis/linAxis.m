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

%% VIPA parameters from previous fit

d = 0.00677384758576207;
n = 1.4537178885083;
theta = 0.015066799113936;
x0 = 0.00618;
xs = 1.12896;

%% peaks of the sperctra calculated with MaximaFirstStage
peaks_M = [0.00509571136815296,0.00550633659011742,0.00621786430391508,0.00650415463091791];
peaks_M = peaks_M - peaks_M(1);
peaks_W = [0.00506514672374777,0.00561613746653448,0.00608248503764085,0.00648405350079269];
peaks_W = peaks_W - peaks_W(1);

%% linear fit

PR = (bShiftW - bShiftM)/(peaks_M(3)-peaks_M(2) - peaks_W(3)+peaks_W(2))*2;

FSR = 2*bShiftW + PR*(peaks_W(3) - peaks_W(2));

StokesM = FSR/2 + PR*(peaks_M(2) - (peaks_W(3) + peaks_W(2))/2);
AStokesM = FSR - (FSR/2 + PR*(peaks_M(3) - (peaks_W(3) + peaks_W(2))/2));

StokesW = FSR/2 + PR*(peaks_W(2) - (peaks_W(3) + peaks_W(2))/2);
AStokesW = FSR - (FSR/2 + PR*(peaks_W(3) - (peaks_W(3) + peaks_W(2))/2));


