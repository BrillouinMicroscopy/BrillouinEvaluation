function [ lambda ] = getWavelength( peakPos, VIPAparams, constants, order)
%This function calculates the wavelength corresponding to the peaks at
%location x in the spectrum of the VIPA spectrometer with the following
%parameters:

% x             [m]     position of the peak
% VIPA parameters:
% m             [1]     integer describing the order of the rayleigh peak
% d             [m]     width of the cavity of the VIPA
% n             [1]     refractive index of the VIPA
% theta         [rad]   angle of the VIPA
% F             [m]     focal length of the lens behind the VIPA
% x0            [m]     offset
% xs            [1]     scaling factor

d     = VIPAparams.d;
n     = VIPAparams.n;
theta = VIPAparams.theta;
F     = constants.F;

[~, m] = peakPosition(VIPAparams, constants, order, constants.lambda0);

theta_in = asin(sin(theta)/n);
peakPos = (peakPos - VIPAparams.x0)./VIPAparams.xs;

lambda = ((2*d*n*cos(theta_in)) - ...
         (2*d*tan(theta_in)*cos(theta)*peakPos/F) - ...
         (d*cos(theta_in)*peakPos.^2/(n*F^2)))/(m);

end

