%% script
filenames = { ...
    '0D_01x_01y_01z', ...
    '1D_07x_01y_01z', ...
    '1D_01x_11y_01z', ...
    '1D_01x_01y_13z', ...
    '2D_07x_11y_01z', ...
    '2D_07x_01y_13z', ...
    '2D_01x_11y_13z', ...
    '3D_07x_11y_13z', ...
};

fileNr = 1;

% dataPath = 'd:\Data\#Biotec\Messungen\2017-01-12_PositioningTestData';
dataPath = 'd:\Data\#Biotec\Messungen\2017-01-10_Spheroids';
% dataPath = 'd:\Data\#Biotec\Messungen\2017-01-12_Spheroids';

filenames = { ...
    'Brillouin', ...
    'Spheroid01_xz-Scan_OutsideInside', ...
    'Spheroid02_xz-Scan_OutsideInsideHighResolution', ...
    'Spheroid03_xy-Scan_Inside', ...
    'Spheroid04_yz-Scan_InsideOutside'
};
settings = [ ...
    struct( ...
        'brillouin', 186:214, ...
        'rayleigh', 251:294, ...
        'peaks', struct( ...
            'x', [25, 144, 214, 271], ...
            'y', [12, 119, 199, 274] ...
        ) ...
    ), ...
    struct( ...
        'brillouin', 280:320, ...
        'rayleigh', 345:413, ...
        'peaks', struct( ...
            'x', [25, 144, 214, 271], ...
            'y', [12, 119, 199, 274] ...
        ) ...
    ), ...
    struct( ...
        'brillouin', 266:294, ...
        'rayleigh', 337:367, ...
        'peaks', struct( ...
            'x', [25, 144, 214, 271], ...
            'y', [12, 119, 199, 274] ...
        ) ...
    ), ...
    struct( ...
        'brillouin', 266:290, ...
        'rayleigh', 326:376, ...
        'peaks', struct( ...
            'x', [25, 144, 214, 271], ...
            'y', [12, 119, 199, 274] ...
        ) ...
    ), ...
    struct( ...
        'brillouin', 272:297, ...
        'rayleigh', 328:400, ...
        'peaks', struct( ...
            'x', [25, 144, 214, 271], ...
            'y', [12, 119, 199, 274] ...
        ) ...
    ) ...
];
filename = filenames{fileNr};


%% calibration parameters
lorentzParams.plane_width = 3;  % [pix] width of the plane to cut around the intensity maxima
lorentzParams.gap = 10;         % [pix] minimum x and y distance of maxima to the edges of the image
lorentzParams.fwhm = 5;         % [pix] estimated width of the lorentz peaks for the fit

parameters.peaks = [6 20];

nrPeaks = 1;

%%
load_path = [dataPath filesep 'RawData'];
save_path = [dataPath filesep 'EvalData'];
if ~exist(save_path, 'dir')
    mkdir(save_path);
end
loadFile = [load_path filesep filename '.h5'];
file = Utils.HDF5Storage.h5bmread(loadFile);

% get the resolution
resolution.X = file.resolutionX;
resolution.Y = file.resolutionY;
resolution.Z = file.resolutionZ;

% get the positions
positions = {};
positions.X = file.positionsX;
positions.Y = file.positionsY;
positions.Z = file.positionsZ;

% preallocate result arrays
imgs = file.readPayloadData(1, 1, 1, 'data');
intensity = NaN(resolution.Y, resolution.X, resolution.Z, size(imgs,4));
maximas = NaN(resolution.Y, resolution.X, resolution.Z, size(imgs,4));
peaks = NaN(resolution.Y, resolution.X, resolution.Z, size(imgs,4), nrPeaks);
peaks_int = NaN(resolution.Y, resolution.X, resolution.Z, size(imgs,4), nrPeaks);
peaksRayleigh = NaN(resolution.Y, resolution.X, resolution.Z, size(imgs,4), nrPeaks);

totalPoints = (resolution.X*resolution.Y*resolution.Z);

% bg = file.readPayloadData(1, 1, 1, 'data');
% bg = medfilt1(bg,3);

tic
%% this is the calibration
img = file.readPayloadData(1, 1, 1, 'data');
start = [1, size(img,1), mean(size(img))];
[params, ~, ~, ~] = fitSpectrum(settings(fileNr).peaks.x, settings(fileNr).peaks.y, start);

interpolationPositions = getInterpolationPositions(img, params, lorentzParams.plane_width, 'axis', 'f', 'averaging', 'f');

%%
for jj = 1:1:resolution.X
    for kk = 1:1:resolution.Y
        for ll = 1:1:resolution.Z
            % read data from the file
            imgs = file.readPayloadData(jj, kk, ll, 'data');
            imgs = medfilt1(imgs,3);
            
            for mm = 1:size(imgs,3)
                try 
                    img = imgs(:,:,mm);
                    spectrum = getIntensity1D(img, interpolationPositions);
%                     figure;plot(spectrum);
                    %%
                    intensity(kk, jj, ll, mm) = sum(img(:));

                    spectrumSection = spectrum(settings(fileNr).rayleigh);
                    [peakPos, ~, ~] = fitLorentzDistribution(spectrumSection, lorentzParams.fwhm, nrPeaks, parameters.peaks);
                    peaksRayleigh(kk, jj, ll, mm, :) = peakPos + min(settings(fileNr).rayleigh(:));
                    
                    shift = round((max(settings(fileNr).rayleigh(:)) - min(settings(fileNr).rayleigh(:)))/2 - peakPos);
                    
                    secInd = settings(fileNr).brillouin - shift;
                    spectrumSection = spectrum(secInd);

                    [~, ind] = max(spectrumSection);
                    maximas(kk, jj, ll, mm) = ind + min(secInd(:));

                    [peakPos, ~, int, ~, thres] = fitLorentzDistribution(spectrumSection, lorentzParams.fwhm, nrPeaks, parameters.peaks);
                    peaks(kk, jj, ll, mm, :) = peakPos + min(secInd(:));
                    peaks_int(kk, jj, ll, mm, :) = int - thres;
                catch
                end
                    
            end
            finishedPoints = ((jj-1)*(resolution.Y*resolution.Z) + (kk-1)*resolution.Z + ll);
            fprintf('%02.0f of %02.0f done.\n',finishedPoints,totalPoints);
        end
    end
end
toc

delete(file);
%%
intensity_mean = mean(intensity,4);
maximas_mean = mean(maximas,4);
peaks_mean = mean(peaks,4);
peaks_int_mean = mean(peaks_int,4);
peaksRayleigh_mean = mean(peaksRayleigh,4);

%% clean
brillouinShift = 0.0568*(peaksRayleigh_mean-peaks_mean);
brillouinShift(brillouinShift > 4.8) = NaN;
brillouinShift(brillouinShift < 3) = NaN;


peaks_int_mean(brillouinShift > 4.8) = NaN;
peaks_int_mean(brillouinShift < 3) = NaN;


%%
% 0.0568
plotData(intensity_mean, positions, '$I$ [a.u.]');
plotData(peaks_int_mean, positions, '$I$ [a.u.]');
% plotData(maximas_mean, positions, '$f$ [GHz]');
% plotData(peaks_mean, positions, '$f$ [GHz]');
% plotData(peaksRayleigh_mean, positions, '$f$ [GHz]');
plotData(brillouinShift, positions, '$f$ [GHz]');
