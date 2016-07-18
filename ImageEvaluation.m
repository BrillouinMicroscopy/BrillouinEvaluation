
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
path = 'd:\user\Raimund\#Biotec\Messungen\20160715\';
file = h5bmread([path 'Methanol.h5']);

% get the attributes and comment
version = file.version;
date = file.date;
comment = file.comment;

% get the resolution
resolution.X = file.resolutionX;
resolution.Y = file.resolutionY;

%% calculating the brillouin shifts from the data
intensity = NaN(resolution.X, resolution.Y);
for n = 1:1:resolution.X
    for m = 1:1:resolution.Y
        img_data = file.readPayloadData(n,m,'data');
        img_res.X = size(img_data, 2);
        img_res.Y = size(img_data, 1);
        
        for k = 1:1:size(img_data, 3)
            intensity(n, m) = sum(img_data(:));
        end
        
    end
end

% close the handle
h5bmclose(file);

%% show image
intensity_aligned = rot90(intensity,2);

figure;
imagesc(intensity_aligned);
set(gca,'yDir','normal');
axis on

