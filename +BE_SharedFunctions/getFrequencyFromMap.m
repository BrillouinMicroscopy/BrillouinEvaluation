function [ f ] = getFrequencyFromMap( peakPos, time, calibration)
%% GETFREQUENCYFROMMAP
%   This function calculates the frequency corresponding to the peaks at
%   location x in the spectrum of the VIPA spectrometer with the following
%   parameters:
% 
%   ##INPUT
%   peakPos:        [m]     5-D array of the peak positions on the camera
%   time:           [s]     time of the measurement point
%   calibration =
%         times:    [s]     times at which the calibration was acquired
%        pixels:    [pix]   pixel number for which the frequencies have
%                           been calculated
%    frequency:     [GHz]     frequencies corresponding to time and pixel
%
%   ##OUTPUT
%   f:              [GHz]    5-D array of the frequencies

    %% discard all invalid frequencies and corresponding times
    frequency = calibration.frequency;
    frequency(frequency == 0) = NaN;
    
    inds = sum(isnan(frequency),2) < 1;
    frequency_valid = frequency(inds,:);
    times_valid = calibration.times(inds);
    
    %% correct the offset
    if calibration.correctOffset
        
        offset = calibration.offset;
        offset = offset(inds,:);
        
        if size(offset,1) > 3
            [peaksOffset, times] = meshgrid(calibration.pixels, times_valid);

            % check if extrapolation is wanted and necessary
            if calibration.extrapolate
                peakPos_offset = interp2(peaksOffset, times, offset, peakPos, time, 'spline');
            else
                peakPos_offset = interp2(peaksOffset, times, offset, peakPos, time, 'linear', NaN);
            end
        elseif size(offset,1) > 1
            [peaksOffset, times] = meshgrid(calibration.pixels, times_valid.');

            % check if extrapolation is wanted and necessary
            if calibration.extrapolate
                maxTime = max(times_valid(:));
                time(time>maxTime) = maxTime;
            end
            peakPos_offset = interp2(peaksOffset, times, offset, peakPos, time, 'spline');

        elseif size(offset,1) > 0
        % if 2D interpolation is not possible ignore the time
            peakPos_offset = interp1(calibration.pixels, offset, peakPos, 'spline');
        else
        % if there is no valid wavelength map at all, return NaN
            peakPos_offset = NaN(size(peakPos));
        end
        
        peakPos = peakPos - peakPos_offset;
    end
    
    %% calculate the frequency
    % decide if interpolation is possible (requires at least two sample
    % points)
    if size(frequency_valid,1) > 3
        [pixels, times] = meshgrid(calibration.pixels, times_valid);
        
        % check if extrapolation is wanted and necessary
        if calibration.extrapolate
            f = interp2(pixels, times, frequency_valid, peakPos, time, 'spline');
        else
            f = interp2(pixels, times, frequency_valid, peakPos, time, 'linear', NaN);
        end
    elseif size(frequency_valid,1) > 1
        [pixels, times] = meshgrid(calibration.pixels, times_valid);
        
        % check if extrapolation is wanted and necessary
        if calibration.extrapolate
            maxTime = max(times_valid(:));
            time(time>maxTime) = maxTime;
        end
        f = interp2(pixels, times, frequency_valid, peakPos, time);
        
    elseif size(frequency_valid,1) > 0
    % if 2D interpolation is not possible ignore the time
        f = interp1(calibration.pixels, frequency_valid, peakPos);
    else
    % if there is no valid frequency map at all, return NaN
        f = NaN(size(peakPos));
    end
end

