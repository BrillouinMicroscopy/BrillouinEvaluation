%% script for calibrating the VIPA setup and evaluating the Brillouin shifts


filename = 'Solution01_00';

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
IterNum = 1;

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

%% calibration non-lin frequency axis
loadFile = [load_path filesep filename '.h5'];
file = h5bmread(loadFile);

img = file.readPayloadData(1, 1, 1, 'data');

% get 1D intensity didtribution
[intensity, parameters] = extractSpectrum(img, lorentzParams);

% fit 1D Lorenzian function to get the peak positions
[peakPos, peakFWHM, peakInt] = fitLorentzDistribution(intensity, lorentzParams.fwhm, 4, parameters.peaks);

% fit the parameters of the VIPA to the peak positions of the calibration
% data
VIPAparams = fitVIPA(peakPos, VIPAstart, constants, IterNum);


%% evaluation

% get the handle to the file
file = h5bmread(loadFile);

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

% calculating the peak positions for each pixel
ImagePeaks = NaN(resolution.X, resolution.Y, resolution.Z, 1, 4);
for nn = 1:1:resolution.X
    for mm = 1:1:resolution.Y
        for ll = 1:1:resolution.Z
            % read data from the file
            img = file.readPayloadData(nn, mm, ll, 'data');
            % resolution of the image
            img_res.X = size(img, 2);
            img_res.Y = size(img, 1);
            img_res.ImNum = size(img, 3);
            
            for kk = 1:1:img_res.ImNum
                try
                    img = img(:, :, kk);

                    % get 1D intensity distribution
                    [intensity, parameters] = extractSpectrum(img, lorentzParams);

                    % fit intensity distribution
                    [peakPos, peakFWHM, peakInt] = fitLorentzDistribution(intensity, lorentzParams.fwhm, 4, parameters.peaks);

                    % get the peak positions of one pixel
                    ImagePeaks(nn, mm, ll, kk, :) = peakPos;
                catch
                end
            end
        end
    end
end

% convert pixel to meter
ImagePeaks = ImagePeaks * constants.pixelSize;

%% calculate Brillouin shifts

orders = VIPAstart.order:(VIPAstart.order + 1);
[ImageShifts] = getBShift(ImagePeaks, VIPAparams, constants, orders);

tmp = squeeze(ImageShifts);tmp(49) = NaN; nanmean(tmp)

