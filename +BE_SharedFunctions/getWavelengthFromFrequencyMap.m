function [ lambda ] = getWavelengthFromFrequencyMap( peakPos, time, calibration)
%% GETWAVELENGTHFROMFREQUENCYMAP
%   This function calculates the wavelength corresponding to the peaks at
%   location x in the spectrum of the VIPA spectrometer with the following
%   parameters:
% 
%   ##INPUT
%   peakPos:        [m]     5-D array of the peak positions on the camera
%   time:           [s]     time of the measurement point
%   calibration =
%         times:    [s]     times at which the calibration was acquired
%        pixels:    [pix]   pixel number for which the wavelengths have
%                           been calculated
%    wavelength:    [m]     wavelengths corresponding to time and pixel
%
%   ##OUTPUT
%   lambda:         [nm]    5-D array of the wavelengths

    [pixels, times] = meshgrid(calibration.pixels, calibration.times);
    
    lambda = interp2(pixels, times, calibration.wavelength, peakPos, time);

end

