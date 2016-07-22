%% constant parameters

c = 299792458;
lambda = 780.24e-9;
bShiftM = 3.7979e9;     % Brillouin shift for methanol
bShiftW = 5.09e9;       % Brillouin shift for water

%% peaks of the sperctra calculated with MaximaFirstStage
peaks_M = [0.00509571136815296,0.00550633659011742,0.00621786430391508,0.00650415463091791];
% peaks from one stage first measurement
% peaks_M = 1-[0.00348146517918382,0.00376505125248156,0.00440096527673403,0.00475510959433452];
peaks_M = sort(peaks_M, 'ascend');
peaks_M = peaks_M - peaks_M(1);

peaks_W = [0.00506514672374777,0.00561613746653448,0.00608248503764085,0.00648405350079269];
% peaks from one stage first measurement
% peaks_W = 1-[0.00348235992244973,0.00387131924480853,0.00428295817795853,0.00475635914378777];
peaks_W = sort(peaks_W, 'ascend');
peaks_W = peaks_W - peaks_W(1);

%% linear fit

PR = (bShiftW - bShiftM)/(peaks_M(3)-peaks_M(2) - peaks_W(3)+peaks_W(2))*2;

PR = (bShiftW - bShiftM)/(peaks_W(2)-peaks_M(2));

FSR = 2*bShiftW + PR*(peaks_W(3) - peaks_W(2));

StokesM = FSR/2 + PR*(peaks_M(2) - (peaks_W(3) + peaks_W(2))/2);
AStokesM = FSR - (FSR/2 + PR*(peaks_M(3) - (peaks_W(3) + peaks_W(2))/2));

StokesW = FSR/2 + PR*(peaks_W(2) - (peaks_W(3) + peaks_W(2))/2);
AStokesW = FSR - (FSR/2 + PR*(peaks_W(3) - (peaks_W(3) + peaks_W(2))/2));


