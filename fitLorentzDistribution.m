function [peakPos, peakFWHM, peakInt, FittedCurve] = fitLorentzDistribution(intensity, fwhm, nrPeaks, borders)
% This function will fit a double Lorentzian distribution to the peaks in
% the 1D intensity distribution
% 
% input:
% intensity         1D intensity distribution
% fwhm              approximated fwhm
% nrPeaks           '2' or '4' select
% borders           position of the Rayleigh peaks (should not be necessary
%                   if the prominence of the peaks is evaluated)
% 
% output:
% peaks             peak positions
% peakInt           peak intensities
% fwhm              full width at half maximum of the peaks
% FittedCurve       fitted intensity distribution

% get the background threshold
thres = getBackground(intensity);

% clean the spectrum
% intensity(intensity<thres) = thres;

% getting the maxima in the 1D distribution
borders = [borders(1,1), borders(1,2)] + [-5, 5];
[maxima] = getMaxima1D(intensity, nrPeaks, borders);

%% fit the data

% select fitting mode
switch nrPeaks
    case 2
        %start parameters
        start = [maxima(1, 1), maxima(1, 2), fwhm, fwhm, maxima(2, 1), maxima(2, 2)];
        x = 1:1:length(intensity);
        % fitting
        [params, ~, ~, FittedCurve]  = nfit_2peaks(x, intensity, start, thres);

        peakPos = params(1:2);
        peakFWHM = params(3:4);
        peakInt = params(5:6);
    case 4
        if (mean(maxima(2,1:3:end)) > 5 * mean(maxima(2,[2,3])))
        % fit Rayleigh and Brillouin peaks separately
            % fit Brillouin peak
            % construct start parameter array
            start = [maxima(1, 2), maxima(1, 3), fwhm, fwhm, maxima(2, 2), maxima(2, 3)];
            x = 1:1:length(intensity);
            % limit fitted area to 75 % between Rayleigh peaks
            ind = borders + [1 -1] * round((1-0.75)/2*diff(borders));
            ind = ind(1):ind(2);
            %fit
            [params_B, ~, ~, ~]  = nfit_2peaks(x(ind), intensity(ind), start, thres);
            
            % fit Rayleigh peak
            % construct start parameter array
            start = [maxima(1, 1), maxima(1, 4), fwhm, fwhm, maxima(2, 1), maxima(2, 4)];
            x = 1:1:length(intensity);
            % fit
            [params_R, ~, ~, ~]  = nfit_2peaks(x, intensity, start, thres);
            
            % construct parameter array as 4 peak fits returns it
            params = [params_R(1), params_B(1), params_B(2), params_R(2),...
                      params_R(3), params_B(3), params_B(4), params_R(4),...
                      params_R(5), params_B(5), params_B(6), params_R(6)];
            % calculate fitte curve
            [~, FittedCurve] = lorentz4(params, x, intensity, thres);
        else
            % start parameters
            start = [maxima(1, 1:4), fwhm, fwhm, fwhm, fwhm, maxima(2, 1:4)];
            x = 1:1:length(intensity);
            [params, ~, ~, FittedCurve] = nfit_4peaks(x, intensity, start, thres);
        end
        peakPos = params(1:4);
        peakFWHM = params(5:8);
        peakInt = params(9:12);
    otherwise
        error('select fitting mode 2 or 4');
end

%% check result
% figure;
% plot(x, intensity, 'color', 'blue');
% hold on;
% plot(x, FittedCurve, 'color', 'red');
% plot(x, thres*ones(size(x)));

end