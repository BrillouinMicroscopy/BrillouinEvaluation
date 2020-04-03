function [peakPos, peakFWHM, peakInt, fittedCurve, thres, deviation, peakIntReal] = fitLorentzDistribution(intensity, fwhm, nrPeaks, borders, debug)
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
%   peakInt:        [1]     fitted peak intensities
%   peakIntReal:    [1]     real peak intensities
%   fwhm:           [pix]   full width at half maximum of the peaks
%   fittedCurve:    [1]     fitted intensity distribution

%%
% get the background threshold
thres = BE_SharedFunctions.getBackground(intensity);

% clean the spectrum
% intensity(intensity<thres) = thres;

% getting the maxima in the 1D distribution
[maxima] = BE_SharedFunctions.getMaxima1D(intensity, nrPeaks);

borders = [borders(1,1), borders(1,2)] + [-5, 5];

%% fit the data

% select fitting mode
switch nrPeaks
    case 1
        %start parameters
        start = [maxima(1, 1), fwhm, maxima(2, 1)];
        x = 1:1:length(intensity);
        % fitting
        [params, ~, ~, fittedCurve, deviation]  = BE_Utils.FittingScripts.nfit_1peaks(x, intensity, start, thres);

        peakPos = params(1);
        peakFWHM = params(2);
        peakInt = params(3); 
    case 2

        %start = [maxima(1, 1), maxima(1, 2), fwhm, maxima(2, 1), maxima(2, 2)];
        x = 1:1:length(intensity);
        %start parameters
        start = [maxima(1, 1), maxima(1, 2), fwhm, fwhm, maxima(2, 1), maxima(2, 2)];
        
        % fitting
        if  true
            %identify left peak
            %fit with constrains if debug active
            [params, ~, ~, fittedCurve, deviation]  = BE_Utils.FittingScripts.nfit_2peakscon(x, intensity, start, thres);
        else

            [params, ~, ~, fittedCurve, deviation]  = BE_Utils.FittingScripts.nfit_2peaks(x, intensity, start, thres);
        end
        
        peakPos = params(1:2);
        peakFWHM = params(3:4);
        %peakFWHM = [11.6 params(3)];
        peakInt = params(5:6);
        %peakInt = params(4:5);
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
            [params_B, ~, ~, ~, deviation]  = BE_Utils.FittingScripts.nfit_2peaks(x(ind), intensity(ind), start, thres);
            
            % fit Rayleigh peak
            % construct start parameter array
            start = [maxima(1, 1), maxima(1, 4), fwhm, fwhm, maxima(2, 1), maxima(2, 4)];
            x = 1:1:length(intensity);
            % fit
            [params_R, ~, ~, ~, ~]  = BE_Utils.FittingScripts.nfit_2peaks(x, intensity, start, thres);
            
            % construct parameter array as 4 peak fits returns it
            params = [params_R(1), params_B(1), params_B(2), params_R(2),...
                      params_R(3), params_B(3), params_B(4), params_R(4),...
                      params_R(5), params_B(5), params_B(6), params_R(6)];
            % calculate fitte curve
            [~, fittedCurve] = BE_Utils.FittingScripts.lorentz4(params, x, intensity, thres);
        else
            % start parameters
            start = [maxima(1, 1:4), fwhm, fwhm, fwhm, fwhm, maxima(2, 1:4)];
            x = 1:1:length(intensity);
            [params, ~, ~, fittedCurve, deviation] = BE_Utils.FittingScripts.nfit_4peaks(x, intensity, start, thres);
        end
        peakPos = params(1:4);
        peakFWHM = params(5:8);
        peakInt = params(9:12);
    otherwise
        error('select fitting mode 2 or 4');
end

%% Get the peak intensity based on the measurement data (not fitted)
centers = round(peakPos);
peakIntReal = NaN(size(peakPos));
for jj = 1:length(peakPos)
    ind = [-1 1] + centers(jj);
    ind(ind < 1) = 1;
    ind(ind > length(intensity)) = length(intensity);
    try
        peakIntReal(jj) = max(intensity(ind(1):ind(2)));
    catch
        peakIntReal(jj) = NaN;
    end
end

%% check result
if debug
    lim.x = [min(x(:)) max(x(:))];
    tmp = max(fittedCurve(:));
    lim.y = [thres, tmp] + 0.05*(tmp-thres)*[-1 1];
    figure(3);
    hold off;
    plot(x, intensity, 'color', [0 0.4470 0.7410]);
    hold on;
    plot(x, fittedCurve, 'color', [0.8500 0.3250 0.0980]);
    plot(x, thres*ones(size(x)));
    xlim(lim.x);
    ylim(lim.y);
    xlabel('[pix]', 'interpreter', 'latex');
    ylabel('intensity [a.u.]', 'interpreter', 'latex');
    grid on;
    drawnow;
    pause(0.02);
end

end