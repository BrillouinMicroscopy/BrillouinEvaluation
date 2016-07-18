
%% set parameter for data analysis
backround = 0.4;        % [ ]   maximum intensity of backround
gap = 10;               % [pix] minimum x and y distance of maxima to the edges of the image
cut = 18;               % [pix] number of quadratic layers around the maxima to cut out in progress
plane_width = 5;        % [pix] width of the area to get the intensity distibution
xInterpolation = 0.5;   % [pix] x-resolution of the interpolated area
yInterpolation = 1;     % [pix] resolution of the width of the interpolated area
PR = 0.12e9;            % [Hz/Pix] frequency to pixel ratio
FSR = 15e9;             % [Hz]  free spectral range

floorb = 0.0;           % [ ]   floor of the lorenz fit
fwhm = 5;               % [pix] approx. fwhm of the lorenz peaks

%% open h5-file

% get the handle to the file
file = h5bmread('D:\brillouin-microscopy\#Software\BrillouinEvaluation\BrillouinTestData.h5');

% get the attributes and comment
version = file.version;
date = file.date;
comment = file.comment;

% get the resolution
resolution.X = file.resolutionX;
resolution.Y = file.resolutionY;

%% calculating the brillouin shifts from the data

% matrix for peak distances
PeakDistance = zeros(resolution.X, resolution.Y);

for n = 1:1:resolution.X
    for m = 1:1:resolution.Y
        img_data = file.readPayloadData(n,m,'data');
        img_res.X = size(img_data, 2);
        img_res.Y = size(img_data, 1);
        
        for k = 1:1:size(img_data, 3)
            
            % localise the maxima in the image
            maxima = GetMaxima(img_data(:, :, k), backround, cut);
        
            % error Message for too many maxima
            if size(maxima, 2) > 2
                error('too many maxima found at: x = %g y = %g', m, n)
            end

            % select the maxima for the intensity distribution
            [p1, p2] = ChooseMaxima( maxima, img_res.X, img_res.Y, gap);

            % interpolate along the planes in between the two selected maxima
            [intensity, x_interpol, y_interpol] = GetIntensity(img_data(:, :, k),...
                      p1, p2, plane_width, xInterpolation, yInterpolation);
                  
            % sum up the intensity from different planes
            intensity_sum = sum(intensity, 1, 'omitnan');

            % data for lorenz fit
            newdata2b = intensity_sum;
            newdata2b(newdata2b < floorb) = floorb;
            
            % location of the maxima for lorenz fit
            [I1, m1] = max(newdata2b(1:round(length(newdata2b)/2)));
            [I2, m2] = max(newdata2b(round(length(newdata2b)/2):end));
            % x values for fitting
            newxb = 1:1:length(newdata2b);

            % start values for lorenz fit
            start = [m1, round(length(newdata2b)/2)+m2, ...
                    fwhm/xInterpolation, I1, I2];

            % 2-peak lorenz fit
            [estimates2b, model2b, newxb, FittedCurve2b] = ...
            nfit_2peaks(newxb, newdata2b, start, floorb);

            % calculate distance between peaks
            PeakDistance(n, m, k) = (estimates2b(2)-estimates2b(1))*...
                                    xInterpolation;
        end
        
    end
end

% close the handle
h5bmclose(file);

% calculate the brillouin shift with FSR and PR
% using the mean of the datasets of each pixel
BrillouinShifts = (FSR - mean(PeakDistance, 3) * PR)/2;

% show image
imagesc(BrillouinShifts)
axis on

