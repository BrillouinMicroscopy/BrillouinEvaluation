function [BShift] = getBShift(peakPos, VIPAparams, constants, orders)%, lambda0, StartOrder)
% this function calculates the Brillouin shifts corresponding to the
% Brillouin peaks in ImagePeaks using the non-linear frequency axis with
% the fitted VIPA parameters
% 
% input:
% ImagePeaks    4D array of the peak positions for each pixel, multiple
%               measurements per pixel
% lambda0       wavelength of the incident laser light
% VIPAparams    fitted parameters of the VIPA conraining:
% VIPAparams = [d, n, theta, F, x0, xs]
% 
% output:
% bShift        4D array of the brillouin shifts corresponding to the peak positions

% calculate wavelengths corresponding to the peak positions
AntiStokes = getWavelength(peakPos(:, :, :, :, 2), VIPAparams, constants, orders(1));
Stokes     = getWavelength(peakPos(:, :, :, :, 3), VIPAparams, constants, orders(2));

% calculate Brillouin shifts
BShiftAS = getFrequencyShift(AntiStokes, constants.lambda0);
BShiftS  = getFrequencyShift(Stokes, constants.lambda0);

BShift = (BShiftAS - BShiftS)./2;
end