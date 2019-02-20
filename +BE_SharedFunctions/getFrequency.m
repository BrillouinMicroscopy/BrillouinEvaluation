function [frequency] = getFrequency(x, params, f_0)
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
    frequency = params(1) * (x-params(6)) + params(2) * (x-params(6)).^2 + params(3) * (x-params(6)).^3 + params(4) * (x-params(6)).^4 + params(5) * (x-params(6)).^5;  % returns frequency in GHz

end