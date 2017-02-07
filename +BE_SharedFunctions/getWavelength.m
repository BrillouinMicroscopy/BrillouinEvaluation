function [ lambda ] = getWavelength( peakPos, VIPAparams, constants, order)
%% GETWAVELENGTH
%   This function calculates the wavelength corresponding to the peaks at
%   location x in the spectrum of the VIPA spectrometer with the following
%   parameters:
% 
%   ##INPUT
%   peakPos:        [m]     5-D array of the peak positions on the camera
%   VIPAparams =
%             d:    [m]     width of the cavity
%             n:    [1]     refractive index
%         theta:    [rad]   angle of the VIPA
%             F:    [m]     focal length of the lens behind the VIPA
%            x0:    [m]     offset for fitting
%            xs:    [1]     scale factor for fitting
%   constants =
%             c:    [m/s]   speed of light
%     pixelSize:    [m]     pixel size of the camera
%       lambda0:    [m]     laser wavelength
%     bshiftCal:    [Hz]    calibration shift frequency
%   order:          [1]     orders of the peaks
%
%   ##OUTPUT
%   lambda:         [nm]    wavelength

d     = VIPAparams.d;
n     = VIPAparams.n;
theta = VIPAparams.theta;
F     = constants.F;

[~, m] = BE_SharedFunctions.peakPosition(VIPAparams, constants, order, constants.lambda0);

theta_in = asin(sin(theta)/n);
peakPos = (peakPos - VIPAparams.x0)./VIPAparams.xs;

lambda = ((2*d*n*cos(theta_in)) - ...
         (2*d*tan(theta_in)*cos(theta)*peakPos/F) - ...
         (d*cos(theta_in)*peakPos.^2/(n*F^2)))/(m);

end

