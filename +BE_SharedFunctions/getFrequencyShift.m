function [frequencyShift] = getFrequencyShift(wavelength, reference)
%% GETFREQUENCYSHIFT
%   This function calculates the frequency shift of wavelength compared to
%   reference
% 
%   ##INPUT
%   wavelength:     [nm]    shifted wavelength
%   reference:      [nm]    reference wavelength
%
%   ##OUTPUT
%   frequencyShift: [Hz]    frequency shift

%%
c = 299792458;    % [m/s]   speed of light

frequencyShift = c./reference - c./wavelength;

end