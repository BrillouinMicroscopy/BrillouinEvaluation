%% set file path

FilePath = 'd:\brillouin-microscopy\Messdaten\20160715\Methanol_new.h5';

%% set operation

% options:
singleImage = true;
plotSpectrum = true;
plotIntDist = true;

BrillouinShifts = true;


% for 'singleImage' set x, y, z and image-number value
spec.x = 1;
spec.y = 1;
spec.z = 1;
spec.ImNum = 1;

% set area of interest of the spectrum
AOIx = [110, 270];

%% set parameter for data analysis

SearchBackground = 130;       % [ ]   maximum background intensity
gap = 10;               % [pix] minimum x and y distance of maxima to the edges of the image
cut = 20;               % [pix] number of quadratic layers around the maxima to cut out in maxima searching progress
ExpMaxima = 4;          % [ ]   expected maxima in each spectrum image

plane1 = [30, 45];
plane2 = [135,150];

PlaneNum = plane1(2)-plane1(1) + plane2(2)-plane2(1);

PR = 1.054000528604721e+13;            % [Hz/Pix] frequency to pixel ratio
FSR = 1.509530586459642e+10;             % [Hz]  free spectral range

PixelSize = 6.5e-6;

IntRes = 0.1;
floorb = 115*(PlaneNum);           % [ ]   floor of the lorenz fit
fwhm = 5;               % [pix] approx. fwhm of the lorenz peaks

%% VIPA parapeters from prvious fit

d = 0.00677377137910882;
n = 1.45367573148033;
theta = 0.0148042202760559;
x0 = 0.00103700800000000;
xs = 1.10555280000000;

% constant parameters
c = 299792458;
lambda = 780.24e-9;
F = 0.2;
PeakNumber = 2;
StartOrder = 1;

%% open h5-file

% get the handle to the file
file = h5bmread(FilePath);

% get the attributes and comment
version = file.version;
date = file.date;
comment = file.comment;

% get the resolution
resolution.X = file.resolutionX;
resolution.Y = file.resolutionY;
resolution.Z = file.resolutionZ;

% get the positions
% positions.X = file.positionsX;
% positions.Y = file.positionsY;
% positions.Z = file.positionsZ;

%% getting the spectrum 

if singleImage == true
    AOIdata = file.readPayloadData(spec.x, spec.y, spec.z, 'data');
    img_res.X = size(AOIdata, 2);
    img_res.Y = size(AOIdata, 1);
    % get AOI
    AOIdata = AOIdata(:, AOIx(1):AOIx(2), :);
   
    intensity_sum = sum(AOIdata(:, plane1(1):plane1(2)), 2) ...
                    + sum(AOIdata(:, plane2(1):plane2(2)), 2);
                
    maxima = GetMaxima(intensity_sum, SearchBackground*PlaneNum, cut);
    maxima = sortrows(maxima.').';

    xLorentzFit = 1:IntRes:length(intensity_sum);
    xData = interp1(intensity_sum, xLorentzFit);

    start = [maxima(2,:), fwhm, fwhm, maxima(3,:)];

    [params, ~, ~, FittedCurve] = nfit_4peaks(xLorentzFit, xData, start, floorb);

    peaks = params(1:4)*PixelSize;
    peaks = sort(peaks, 'ascend');
    
    x0 = x0 + peaks(1);
    
    % fit offset for nonlin Frequency axis
    
    
    % plot
    if plotIntDist == true
        figure(1)
%         title('Intensity distribution with lorentz fit of the analysed area')
%         xlabel('Distance [pix]')
        xlabel('frequency shift [GHz]')
        ylabel('Intensity (pixel value)')
        x_plot = (1:1:size(intensity_sum, 1));
        plot(x_plot, intensity_sum/1000,'.')
        hold on
        plot(xLorentzFit, FittedCurve/1000)
    end
    
    if plotSpectrum == true
        figure()
        imagesc(AOIdata)
        hold on
        axis on
        title('Scpectrum and analysed area')
        xlabel('x')
        ylabel('y')
        plot(ones(size(AOIdata, 1))*plane1(1), 1:1:size(AOIdata, 1),'r')
        plot(ones(size(AOIdata, 1))*plane1(2), 1:1:size(AOIdata, 1),'r')
        plot(ones(size(AOIdata, 1))*plane2(1), 1:1:size(AOIdata, 1),'r')
        plot(ones(size(AOIdata, 1))*plane2(2), 1:1:size(AOIdata, 1),'r')
    end
end
    
% calculating the brillouin shifts from the data
if BrillouinShifts == true

    % matrix for peak distances
    ImagePeaks = zeros(resolution.X, resolution.Y, resolution.Z, 4);
    finesse = zeros(resolution.X, resolution.Y, resolution.Z);

    % calculating the peak distances for each pixel
    for nn = 1:1:resolution.X
        for mm = 1:1:resolution.Y
            for ll = 1:1:resolution.Z
                AOIdata = file.readPayloadData(nn, mm, ll, 'data');
                AOIdata = AOIdata(:, AOIx(1):AOIx(2), :);
                img_res.X = size(AOIdata, 2);
                img_res.Y = size(AOIdata, 1);
                
                for kk = 1:1:size(AOIdata, 3)
                    AOIdata = AOIdata(:, :, kk);
                    intensity_sum = sum(AOIdata(:, plane1(1):plane1(2)), 2) ...
                                    + sum(AOIdata(:, plane2(1):plane2(2)), 2);
                    if max(intensity_sum) < SearchBackground*PlaneNum
                        fprintf('no maxima at x=%d, y=%d, z=%d\n', nn, mm, ll);
                        ImagePeaks(nn, mm, ll, :) = NaN;
                        finesse(nn,mm,ll) = NaN;
                    else
                        maxima = GetMaxima(intensity_sum, SearchBackground*PlaneNum, cut);
                        maxima = sortrows(maxima.').';
                        if size(maxima, 2) > ExpMaxima
                            fprintf('too many maxima found at x=%d, y=%d, z=%d\n', nn, mm, ll);
                            ImagePeaks(nn, mm, ll, :) = NaN;
                            finesse(nn,mm,ll) = NaN;
                        else
                            xLorentzFit = 1:IntRes:length(intensity_sum);
                            xData = interp1(intensity_sum, xLorentzFit);
                    
                            start = [maxima(2,:), fwhm, fwhm, maxima(3,:)];
                    
                            [params, ~, ~, FittedCurve] = nfit_4peaks(xLorentzFit, xData, start, floorb);
                    
                            peaks = params(1:4)*PixelSize;
                            peaks = sort(peaks, 'ascend');
%                             peaks = peaks - peaks(1);
                    
                            ImagePeaks(nn, mm, ll, :) = peaks;
                            finesse(nn, mm, ll) = (params(4)-params(1))/params(5);
                        end
                    end
                end
            end
        end
    end
end
% close the handle
h5bmclose(file);

%% calculate shifts with linear axis

linShifts = (FSR - PR*(ImagePeaks(:, :, :, 3) - ImagePeaks(:, :, :, 2)))/2;

%% calculate shifts with nonlinear axis

[~, m] = VIPApeaks( d, n, theta, lambda, F, x0, xs, PeakNumber, StartOrder);
m = sort(m, 'descend');

% calculate Rayleigh-peaks
RPeaks1 = ImagePeaks(:, :, :, 1);
RPeaks2 = ImagePeaks(:, :, :, 4);

lambda1 = GetWavelength(RPeaks1, m(1), d, n, theta, F, x0, xs);
lambda2 = GetWavelength(RPeaks2, m(2), d, n, theta, F, x0, xs);

diff1 = c/lambda - c./lambda1;
diff2 = c/lambda - c./lambda2;

% calculate Brillouin-shifts
AntiStokesPeaks = ImagePeaks(:, :, :, 2);
StokesPeaks = ImagePeaks(:, :, :, 3);

AntiStokes = GetWavelength(AntiStokesPeaks, m(1), d, n, theta, F, x0, xs);
AntiStokes = c./AntiStokes;

Stokes = GetWavelength(StokesPeaks, m(2), d, n, theta, F, x0, xs);
Stokes = c./Stokes;

%% check linearity of drift
% RP1 = RPeaks1(:).';
% x = 1:1:length(RP1);
% x = x(isnan(RP1)==false);
% RP1 = RP1(isnan(RP1)==false);
% start1 = [0, 2.42e-4];
% [params1, line1] = LinEqFit(x, RP1, start1);
% 
% RP2 = RPeaks2(:).';
% RP2 = RP2(isnan(RP2)==false);
% start2 = [0, 1.64e-3];
% [params2, line2] = LinEqFit(x, RP2, start2);
% 
% ASP = AntiStokesPeaks(:).';
% ASP = ASP(isnan(ASP)==false);
% start3 = [0, 6.59e-4];
% [params3, line3] = LinEqFit(x, ASP, start3);
% 
% SP = StokesPeaks(:).';
% SP = SP(isnan(SP)==false);
% start4 = [0, 6.59e-4];
% [params4, line4] = LinEqFit(x, SP, start4);

%% calculate and compensate drift
% anti-stokes
AS = AntiStokes(:).';
xAS = 1:1:length(AS);
xAS = xAS(isnan(AS) == false);
AS = AS(isnan(AS) == false);

startAS = [1, 3.8423e14];
[paramsAS, lineAS] = LinEqFit(xAS, AS, startAS);
driftASerror = sqrt(1/(length(AS)-1)*sum((lineAS-AS).^2));


%% Stokes
St = Stokes(:).';
xSt = 1:1:length(St);
xSt = xSt(isnan(St) == false);
St = St(isnan(St) == false);

startSt = [1, 3.8423e14];
[paramsSt, lineSt] = LinEqFit(xSt, St, startSt);

drift = (paramsAS(1) + paramsSt(1))/2;

ASCorrected = AS - drift*xAS;
ShiftAS = ASCorrected - c/lambda;

StCorrected = St - drift*xSt;
ShiftSt = StCorrected - c/lambda;

%% add nonlin frequency axis to plot
xmin = 0 * 6.5e-6;
xmax = x_plot(end)*6.5e-6;
bin = 2e9;

[ xTick, ~, TickLabel ] = GetFrequencyAxisLabel( xmin, xmax, bin, 'GHz', m(1), d, n, theta, F, x0, xs, lambda);
xTick = xTick/6.5e-6;



figure(1)
hold on
box on
xlim([0,300])
set(gca, 'XTick', xTick)
set(gca, 'XTickLabel', TickLabel)
%% plot data

% figure;
% hold on
% box on
% xlabel('time [s]')
% ylabel('frequency shift [GHz]')
% plot(xAS,(AS - c/lambda)/1e9, '.')
% plot(xAS, (lineAS - c/lambda)/1e9,'r')
% 
% figure;
% hold on
% box on
% xlabel('time [s]')
% ylabel('frequency shift [GHz]')
% plot(xSt,(St - c/lambda)/1e9, '.')
% plot(xSt, (lineSt - c/lambda)/1e9,'r')

figure;
hold on
box on
ylim([3.75, 3.85])
xlabel('time [s]')
ylabel('frequency shift [GHz]')
plot(xAS, (ASCorrected-c/lambda)/1e9, '.')

figure;
hold on
box on
ylim([-3.85, -3.75])
xlabel('time [s]')
ylabel('frequency shift [GHz]')
plot(xSt, (StCorrected-c/lambda)/1e9, '.')
