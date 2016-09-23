%% script for calibrating the VIPA setup and evaluating the Brillouin shifts

filename = 'Solution_merged';

%% parameters calibration

% constant parameters
constants = {};                     % struct with constants
constants.c         = 299792458;    % [m/s] speed of light
constants.pixelSize = 6.5e-6;       % [m]   pixel size of the camera
constants.lambda0   = 780.24e-9;    % [m]   laser wavelength
constants.bShiftCal = 5.09e9;       % [Hz]  calibration shift frequency
constants.F         = 0.2;          % [m]   focal length of the lens behind the VIPA

% start parameters for VIPA fit
VIPAstart = {};
VIPAstart.d     = 0.006774;         % [m]   width of the cavity
VIPAstart.n     = 1.453683;         % [1]   refractive index
VIPAstart.theta = 0.8*2*pi/360;     % [rad] angle of the VIPA
VIPAstart.x0    = 0.0021;           % [m]   offset for fitting
VIPAstart.xs    = 1.1348;           % [1]   scale factor for fitting
VIPAstart.order = 1;                % [1]   observed order of the VIPA spectrum
IterNum = 4;

%%
load_path = 'RawData';
save_path = 'EvalData';
if ~exist(save_path, 'dir')
    mkdir(save_path);
end

%% calibration parameters
lorentzParams.plane_width = 30; % [pix] width of the plane to cut around the intensity maxima
lorentzParams.gap = 10;         % [pix] minimum x and y distance of maxima to the edges of the image
lorentzParams.fwhm = 5;         % [pix] estimated width of the lorentz peaks for the fit

%% calibration with non-linear frequency axis
loadFile = [load_path filesep filename '.h5'];
file = h5bmread(loadFile);

img = file.readCalibrationData('data');

% get 1D intensity didtribution
[intensity, parameters] = extractSpectrum(img(:,:,2), lorentzParams);

% fit 1D Lorenzian function to get the peak positions
[peakPos, peakFWHM, peakInt] = fitLorentzDistribution(intensity, lorentzParams.fwhm, 4, parameters.peaks);

% fit the parameters of the VIPA to the peak positions of the calibration
% data
VIPAparams = fitVIPA(peakPos, VIPAstart, constants, IterNum);

%% evaluation

% get the attributes and comment
version = file.version;
date = file.date;
comment = file.comment;

% get the resolution
resolution.X = file.resolutionX;
resolution.Y = file.resolutionY;
resolution.Z = file.resolutionZ;

% get the positions
positions = {};
% positions.X = file.positionsX;
% positions.Y = file.positionsY;
% positions.Z = file.positionsZ;

% calculating the peak positions for each pixel
ImagePeaks = NaN(resolution.X, resolution.Y, resolution.Z, 50, 4);
totalPoints = (resolution.X*resolution.Y*resolution.Z);
for ll = 1:1:resolution.X
    for kk = 1:1:resolution.Y
        for jj = 1:1:resolution.Z
            % read data from the file
            img = file.readPayloadData(ll, kk, jj, 'data');
            
            for mm = 1:size(img,3)
                try
                    % check if the image is valid
                    validateImage(img(:,:,mm));
                    
                    figure(12);
                    imagesc(img(:,:,mm));
                    caxis([100 300]);
                    drawnow;

                    % get 1D intensity distribution
                    [intensity, parameters] = extractSpectrum(img(:,:,mm), lorentzParams);

                    % fit intensity distribution
                    [peakPos, peakFWHM, peakInt] = fitLorentzDistribution(intensity, lorentzParams.fwhm, 4, parameters.peaks);

                    % get the peak positions of one pixel
                    ImagePeaks(ll, kk, jj, mm, :) = peakPos;
                catch
                    ImagePeaks(ll, kk, jj, mm, :) = NaN(1,4);
                end
            end
            finishedPoints = ((jj-1)*(resolution.X*resolution.Y) + (kk-1)*resolution.X + ll);
            fprintf('%02.0f of %02.0f done.\n',finishedPoints,totalPoints);
        end
    end
end

ImagePeaks(abs(ImagePeaks) > 1000) = NaN;

% close the handle
h5bmclose(file);

% convert pixel to meter
ImagePeaks = ImagePeaks * constants.pixelSize;

%% calculate Brillouin shifts

orders = VIPAstart.order:(VIPAstart.order + 1);

BrillouinShifts = getBShift(ImagePeaks, VIPAparams, constants, orders, false);
BrillouinShifts_corrected = getBShift(ImagePeaks, VIPAparams, constants, orders, true);

%% save Brillouin shifts to a file

save([save_path filesep filename '.mat'], 'BrillouinShifts', 'BrillouinShifts_corrected', 'positions', 'VIPAparams', 'constants');
