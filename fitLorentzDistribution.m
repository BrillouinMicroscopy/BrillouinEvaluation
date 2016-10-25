function [peakPos, peakFWHM, peakInt, fittedCurve] = fitLorentzDistribution(intensity, fwhm, nrPeaks, borders)
%% FITLORENTZDISTRIBUTION
%   This function will fit a Lorentzian distribution with the requested
%   number of peaks to a given 1-D intensity distribution
% 
%   ##INPUT
%   intensity:      [1]     1D intensity distribution
%   fwhm:           [pix]   approximated fwhm
%   nrPeaks:        [1]     number of peaks: either '2' or '4'
%   borders:        [1]     position of the Rayleigh peaks (should not be necessary
%                           if the prominence of the peaks is evaluated)
%
%   ##OUTPUT
%   peakPos:        [pix]   peak positions
%   peakInt:        [1]     peak intensities
%   fwhm:           [pix]   full width at half maximum of the peaks
%   fittedCurve:    [1]     fitted intensity distribution

%%
% get the background threshold
thres = getBackground(intensity);

% clean the spectrum
% intensity(intensity<thres) = thres;

% getting the maxima in the 1D distribution
borders = [borders(1,1), borders(1,2)] + [-5, 5];
[maxima] = getMaxima1D(intensity, nrPeaks);

%% fit the data

% select fitting mode
switch nrPeaks
    case 2
        %start parameters
        start = [maxima(1, 1), maxima(1, 2), fwhm, fwhm, maxima(2, 1), maxima(2, 2)];
        x = 1:1:length(intensity);
        % fitting
        [params, ~, ~, fittedCurve]  = nfit_2peaks(x, intensity, start, thres);

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
            ind = borders + [1 -1] * round((1-0.70)/2*diff(borders));
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
            [~, fittedCurve] = lorentz4(params, x, intensity, thres);
        else
            % start parameters
            start = [maxima(1, 1:4), fwhm, fwhm, fwhm, fwhm, maxima(2, 1:4)];
            x = 1:1:length(intensity);
            [params, ~, ~, fittedCurve] = nfit_4peaks(x, intensity, start, thres);
        end
        peakPos = params(1:4);
        peakFWHM = params(5:8);
        peakInt = params(9:12);
    otherwise
        error('select fitting mode 2 or 4');
end

%% check result
% figure(3);
% hold off;
% plot(x, intensity, 'color', [0 0.4470 0.7410]);
% hold on;
% plot(x, fittedCurve, 'color', [0.8500 0.3250 0.0980]);
% plot(x, thres*ones(size(x)));
% xlim([0 500]);
% ylim([100 160]);
% xlabel('[pix]', 'interpreter', 'latex');
% ylabel('intensity [a.u.]', 'interpreter', 'latex');
% grid on;
% drawnow;
% pause(0.5);

end