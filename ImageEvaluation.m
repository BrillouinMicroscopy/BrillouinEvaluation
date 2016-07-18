
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
path = 'd:\brillouin-microscopy\Messdaten\20160718\USAF\';
file = h5bmread([path 'Testchart10.h5']);

% get the attributes and comment
version = file.version;
date = file.date;
comment = file.comment;

% get the resolution
resolution.X = file.resolutionX;
resolution.Y = file.resolutionY;
resolution.Z = file.resolutionZ;

% get the positions
positions.X = file.positionsX;
positions.Y = file.positionsY;
positions.Z = file.positionsZ;

%% calculating the brillouin shifts from the data
intensity = NaN(resolution.X, resolution.Y, resolution.Z);
for jj = 1:1:resolution.Z
    for kk = 1:1:resolution.Y
        for ll = 1:1:resolution.X
            img_data = file.readPayloadData(ll,kk,jj,'data');
            img_res.X = size(img_data, 2);
            img_res.Y = size(img_data, 1);

            for k = 1:1:size(img_data, 3)
                intensity(ll, kk, jj) = sum(img_data(:));
            end

        end
    end
end

% close the handle
h5bmclose(file);

%% show image
figure;
imagesc(positions.Y(:,1), positions.X(1,:), intensity);
set(gca,'xDir','reverse');
axis on;
xlabel('y');
ylabel('x');

