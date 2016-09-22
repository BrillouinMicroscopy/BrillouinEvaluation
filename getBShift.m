function [BShift] = getBShift(peakPos, VIPAparams, constants, orders, correctDrift)
% this function calculates the Brillouin shifts corresponding to the
% Brillouin peaks in ImagePeaks using the non-linear frequency axis with
% the fitted VIPA parameters
% 
% input:
% ImagePeaks    5-D array of the peak positions for each pixel, multiple
%               measurements per pixel
% lambda0       wavelength of the incident laser light
% VIPAparams    fitted parameters of the VIPA conraining:
% VIPAparams = [d, n, theta, F, x0, xs]
% 
% output:
% bShift        5-D array of the brillouin shifts corresponding to the peak positions

% calculate wavelengths corresponding to the peak positions

otherdims = repmat({':'},1,ndims(peakPos)-1);

AntiStokes = getWavelength(peakPos(otherdims{:}, 2), VIPAparams, constants, orders(1));
Stokes     = getWavelength(peakPos(otherdims{:}, 3), VIPAparams, constants, orders(2));

% calculate Brillouin shifts
BShift(otherdims{:}, 1) = getFrequencyShift(AntiStokes, constants.lambda0);
BShift(otherdims{:}, 2) = getFrequencyShift(Stokes, constants.lambda0);
% tmp = squeeze(BShift);

if correctDrift && size(peakPos,ndims(peakPos)) > 2
    Rayleigh1 = getWavelength(peakPos(otherdims{:}, 1), VIPAparams, constants, orders(1));
    Rayleigh2 = getWavelength(peakPos(otherdims{:}, 4), VIPAparams, constants, orders(2));
    Drift(otherdims{:}, 1) = getFrequencyShift(Rayleigh1, constants.lambda0);
    Drift(otherdims{:}, 2) = getFrequencyShift(Rayleigh2, constants.lambda0);
    
    tmp1 = squeeze(Rayleigh1);
    
    tmp2 = squeeze(BShift);
    BShift = BShift - Drift;
    tmp3 = squeeze(Drift);
    tmp4 = squeeze(BShift);
end
% BShift(otherdims{:}, 1) = BShiftAS;
% BShift(otherdims{:}, 2) = BShiftS;
% BShift = (BShiftAS - BShiftS)./2;
end