function [BShift] = getBShift(peakPos, VIPAparams, constants, orders, correctDrift)
%% GETBSHIFT
%   this function calculates the Brillouin shifts corresponding to the
%   Brillouin peaks in ImagePeaks using the non-linear frequency axis with
%   the fitted VIPA parameters
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
%   bShift:         [Hz]    5-D array of the brillouin shifts corresponding
%                           to the peak positions 

%%
% create the indice vector
otherdims = repmat({':'},1,ndims(peakPos)-1);

% calculate wavelengths corresponding to the peak positions
if size(peakPos,ndims(peakPos)) == 1
    AntiStokes = getWavelength(peakPos(otherdims{:}, 1), VIPAparams, constants, orders(1));
elseif size(peakPos,ndims(peakPos)) == 2
    AntiStokes = getWavelength(peakPos(otherdims{:}, 1), VIPAparams, constants, orders(1));
    Stokes     = getWavelength(peakPos(otherdims{:}, 2), VIPAparams, constants, orders(2));
elseif size(peakPos,ndims(peakPos)) == 4
    AntiStokes = getWavelength(peakPos(otherdims{:}, 2), VIPAparams, constants, orders(1));
    Stokes     = getWavelength(peakPos(otherdims{:}, 3), VIPAparams, constants, orders(2));
else
    % throw an error if the size is unexpected
    ME = MException('The size of the last dimension of the array should either be 1, 2 or 4.');
    throw(ME);
end

% convert wavelengths to Brillouin frequency shifts
BShift(otherdims{:}, 1) = getFrequencyShift(AntiStokes, constants.lambda0);
if size(peakPos,ndims(peakPos)) > 1
    BShift(otherdims{:}, 2) = getFrequencyShift(Stokes, constants.lambda0);
end

% correct for laser frequency shifts is requested and possible
if correctDrift && size(peakPos,ndims(peakPos)) == 4
    Rayleigh1 = getWavelength(peakPos(otherdims{:}, 1), VIPAparams, constants, orders(1));
    Rayleigh2 = getWavelength(peakPos(otherdims{:}, 4), VIPAparams, constants, orders(2));
    Drift(otherdims{:}, 1) = getFrequencyShift(Rayleigh1, constants.lambda0);
    Drift(otherdims{:}, 2) = getFrequencyShift(Rayleigh2, constants.lambda0);

    BShift = BShift - Drift;
end

end