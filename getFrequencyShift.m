function [ frequencyShift ] = getFrequencyShift( wavelength, reference )
%GETFREQUENCYSHIFT
%
c = 299792458;  % [m/s] speed of light

frequencyShift = c./wavelength - c/reference;

end