function [ x_F, fshifts, TickLabel ] = GetFrequencyAxisLabel( xmin, xmax, bin, scale, m, d, n, theta, F, x0, xs, lambda0)
%This function calculates the labels for the non-linear frequency axis
% 
% xmin, xmax    [m]     boundries of the axis
% bin           [Hz]    bin of the labels
% scale         [ ]     string difining the scale of the axis labels
%                       possible: 'GHz', 'MHz', 'kHz', 'Hz'
% VIPA parameters:
% m             [ ]     integer describing the order of the rayleigh peak
% d             [m]     width of the cavity of the VIPA
% n             [ ]     refractive index of the VIPA
% theta         [rad]   angle of the VIPA
% F             [m]     focal length of the lens behind the VIPA
% x0            [m]     offset
% xs            [ ]     scaling factor
% lambda0       [m]     wavelength of the incident light

c = 299792458;
theta_in = asin(sin(theta)/n);

xbound = ([xmin, xmax]-x0)/xs ;
fbound = c./(((2*d*n*cos(theta_in)) - ...
         (2*d*tan(theta_in)*cos(theta)*xbound/F) - ...
         (d*cos(theta_in)*xbound.^2/(n*F^2)))/m);

fbound = fbound - c/lambda0;
fbound = round(fbound/bin)*bin;

fshifts = (fbound(1):bin:fbound(2));

frequencies = fshifts + c/lambda0;

lambda = c./frequencies;

x_F = -n*F*tan(theta_in)*cos(theta)/(cos(theta_in)) + ...
      sqrt((n*F*tan(theta_in)*cos(theta)/(cos(theta_in)))^2 + ...
      2*n^2*F^2 - n*F^2*m*lambda/(d*cos(theta_in)));

x_F = (x_F*xs) + x0;
if strcmp(scale,'GHz') == true
    TickLabel = strtrim(cellstr(num2str((fshifts/1e9)', 2))');
elseif strcmp(scale, 'MHz') == true
    TickLabel = strtrim(cellstr(num2str((fshifts/1e6)', 2))');
elseif strcmp(scale, 'kHz') == true
    TickLabel = strtrim(cellstr(num2str((fshifts/1e3)', 2))');
elseif strcmp(scale, 'Hz') == true
    TickLabel = strtrim(cellstr(num2str((fshifts)', 2))');
else
    error('set scale to GHz, MHz, kHz or Hz to get the labels')
end

end

