function [intensity, x_interpol, y_interpol] = getIntensity(spectrum, p1, p2, width, xResolution, yResolution)
%GetIntensity interpolates the intensity distribution between two points
%   The function gets the linear equation through the points p1 and p2.
%   To cover a larger area the function creates "plane_nr" lines parallel
%   to the linear equation in the area "width" around the line.
%   The intensity distibution of the "spectrum" is interpolated along these
%   Lines.
%
%   input:
%   spectrum:               matrix with intensity data
%   p1, p2:         [ ]     points [x, y] (location of the maxima)
%   width:          [pix]   width of the covered area
%   xResolution:    [pix]   x-Resolution of the Interpolation
%   yResolution:    [pix]   Resolution of the width of the covered area
%
%   output:
%   intensity:              intensity-distributions along the parallel lines
%   x_interpol:             x-coordinates of the parallel lines
%   y_interpol:             y-coordinates of the parallel lines

% resolution of the spectrum
X = size(spectrum, 2);
Y = size(spectrum, 1);
% length of the diagonal line
diagonal = round(sqrt(X^2 + Y^2));

%linear equation for sectional plane
m1 = (p1(2) - p2(2))/(p1(1) - p2(1));
n1 = p1(2) - m1*p1(1);
x0 = -n1/m1;
% angle of the linear equation
theta = atan(m1);

% creating grid for interpolation
[x, y] = meshgrid(1:xResolution:diagonal, (-width/2):yResolution:(width/2));

% turning grid by the angle of the linear equation
x_interpol = x*cos(theta) - y*sin(theta);
y_interpol = x*sin(theta) + y*cos(theta);

if n1<0
    x_interpol = x_interpol + x0;
elseif n1>0
    y_interpol = y_interpol + n1;
end

% interpolate along the turned grid
intensity = interp2(spectrum, x_interpol, y_interpol);

end

