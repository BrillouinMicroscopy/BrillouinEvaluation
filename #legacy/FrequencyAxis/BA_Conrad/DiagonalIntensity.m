Data1 = im2double(imread('D:\Guck-Users\Conrad\#Data\20160728\OnlyLSM\Methanol.tif'));
Data = Data1(750:1050,575:900);

plane_width = 20;
xInterpolation = 0.5;
yInterpolation = 0.5;

p1 = [52,32];
p2 = [269,251];

% interpolate along the planes in between the two selected maxima
[intensity, x_interpol, y_interpol] = GetIntensity(Data,...
p1, p2, plane_width, xInterpolation, yInterpolation);
                
% sum up the intensity from different planes
intensity_sum = sum(intensity, 1, 'omitnan');
               
%% fitting the Data

floorb = 4.95;

% data for lorenz fit
newdata2b = intensity_sum(230:630);
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
        
%% plot data

figure()
imagesc(Data)
hold on
axis equal
c = colorbar;
c.Label.String = 'relative intensity';
xlim([1,326])
xlabel('x pixel index')
ylabel('y pixel index')
plot(x_interpol(1,:), y_interpol(1,:),'r')
plot(x_interpol(end,:), y_interpol(end,:),'r')

figure;
hold on
box on
xlim([0, 275;])
ylim([4.9; 6.5])
xlabel('pixel index')
ylabel('intensity (pixel value)')
plot((1:1:length(intensity_sum(130:675)))*xInterpolation, intensity_sum(130:675), '.')
plot((newxb+100)*xInterpolation, FittedCurve2b, 'r')
