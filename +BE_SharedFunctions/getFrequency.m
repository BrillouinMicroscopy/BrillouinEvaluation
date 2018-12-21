function [frequency] = getFrequency(pixel, VIPAparams, f_0)
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

    % define theoretical frequency function
    frequency = 1 ./ (VIPAparams(1) + VIPAparams(2)*pixel + VIPAparams(3)*pixel.^2) - 1e-9*f_0;  % returns frequency in GHz

end