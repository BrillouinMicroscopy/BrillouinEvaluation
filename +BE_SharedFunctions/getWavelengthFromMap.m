function [ lambda ] = getWavelengthFromMap( peakPos, time, calibration)
%% GETWAVELENGTHFROMMAP
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
    
    times_valid = calibration.times(~isnan(calibration.times));
    
    inds = sum(isnan(calibration.wavelength),2) < 1;
    wavelengths_valid = calibration.wavelength(inds,:);
    
    % decide if interpolation is possible (requires at least two sample
    % points)
    if size(wavelengths_valid,1) > 1
        [pixels, times] = meshgrid(calibration.pixels, times_valid);
        
        % check if extrapolation is wanted and necessary
        if calibration.extrapolate
            maxTime = max(times_valid(:));
            time(time>maxTime) = maxTime;
        end
        
        lambda = interp2(pixels, times, wavelengths_valid, peakPos, time);
        
    elseif size(wavelengths_valid,1) > 0
    % if 2D interpolation is not possible ignore the time
        lambda = interp1(calibration.pixels, wavelengths_valid, peakPos);
    else
    % if there is no valid wavelength map at all, return NaN
        lambda = NaN(size(peakPos));
    end

end

