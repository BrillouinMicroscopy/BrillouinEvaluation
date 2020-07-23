function [peakPos, peakFWHM, peakInt, fittedCurve, thres, deviation, peakIntReal] = ...
    fitLorentzDistribution(intensity, fwhm, nrPeaks, borders, debug, constraints)
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
        %% Start parameters
        start = [maxima(1, 1), fwhm, maxima(2, 1)];
        x = 1:1:length(intensity);

        %% Fitting
        [params, ~, ~, fittedCurve, deviation]  = BE_Utils.FittingScripts.nfit_1peaks(x, intensity, start, thres);

        peakPos = params(1);
        peakFWHM = params(2);
        peakInt = params(3); 
    case 2
        x = 1:1:length(intensity);

        %% Construct default constraints if none are given
        if nargin < 6
            constraints.sa.Lower = 0;
            constraints.sa.Upper = length(intensity);

            constraints.sb.Lower = 0;
            constraints.sb.Upper = length(intensity);

            constraints.wa.Lower = 3;
            constraints.wa.Upper = Inf;

            constraints.wb.Lower = 3;
            constraints.wb.Upper = Inf;

            constraints.Ba.Lower = 0;
            constraints.Ba.Upper = Inf;

            constraints.Bb.Lower = 0;
            constraints.Bb.Upper = Inf;

            %% Start parameters
            % If there are no constraints, we use the two peaks with the
            % highest prominence as start points
            StartPoint.sa = maxima(1, 1);
            StartPoint.sb = maxima(1, 2);
            StartPoint.wa = fwhm;
            StartPoint.wb = fwhm;
            StartPoint.Ba = maxima(2, 1) - thres;
            StartPoint.Bb = maxima(2, 2) - thres;
        else
            %% Start parameters
            % If there are constraints, we use the highest peak in the
            % given range
            s_keys = [{'a'}, {'b'}];
            % Calculate Brillouin shift range
            for s_ind = 1:length(s_keys)
                left = round(constraints.(['s' s_keys{s_ind}]).Lower);
                if isinf(left)
                    left = 1;
                end
                right = round(constraints.(['s' s_keys{s_ind}]).Upper);
                if isinf(right)
                    right = length(intensity);
                end
                % We pad the selected region, so first and last sample can
                % be peaks too.
                section = [thres, intensity(left:right), thres];
                if right - left > 1
                    [maxima] = BE_SharedFunctions.getMaxima1D(section, 1);
                    StartPoint.(['s' s_keys{s_ind}]) = maxima(1, 1) + left - 2;
                    StartPoint.(['B' s_keys{s_ind}]) = maxima(2, 1);
                else
                    [B, s] = max(section);
                    StartPoint.(['s' s_keys{s_ind}]) = s + left - 2;
                    StartPoint.(['B' s_keys{s_ind}]) = B;
                end
            end
            StartPoint.wa = fwhm;
            StartPoint.wb = fwhm;
        end

        %% Fitting
        ft = fittype(@(sa, sb, wa, wb, Ba, Bb, x ) BE_Utils.FittingScripts.lorentz2(x, sa, sb, wa, wb, Ba, Bb));
        opts = fitoptions('Method', 'NonlinearLeastSquares');
        names = coeffnames(ft);
        for jj = 1:length(names)
            opts.StartPoint(jj) = StartPoint.(names{jj});
            opts.Lower(jj) = constraints.(names{jj}).Lower;
            opts.Upper(jj) = constraints.(names{jj}).Upper;
        end
        opts.Display = 'Off';
        xtmp = x.';
        ytmp = intensity.' - thres;
        [fitresult, gof] = fit(xtmp, ytmp, ft, opts);

        fittedCurve = fitresult.Ba * ((fitresult.wa/2).^2) ./ ((x - fitresult.sa).^2 + (fitresult.wa/2).^2) ...
            + fitresult.Bb * ((fitresult.wb/2).^2) ./ ((x - fitresult.sb).^2 + (fitresult.wb/2).^2) + thres;
        deviation = gof.sse;

        peakPos = [fitresult.sa, fitresult.sb];
        peakFWHM = [fitresult.wa, fitresult.wb];
        peakInt = [fitresult.Ba + thres, fitresult.Bb + thres];
    case 4
        if (mean(maxima(2,1:3:end)) > 5 * mean(maxima(2,[2,3])))
            % Fit Rayleigh and Brillouin peaks separately
            % Fit Brillouin peak
            % Construct start parameter array
            start = [maxima(1, 2), maxima(1, 3), fwhm, fwhm, maxima(2, 2), maxima(2, 3)];
            x = 1:1:length(intensity);
            % Limit fitted area to 75 % between Rayleigh peaks
            ind = borders + [1 -1] * round((1-0.70)/2*diff(borders));
            ind = ind(1):ind(2);
            % Fit
            [params_B, ~, ~, ~, deviation]  = BE_Utils.FittingScripts.nfit_2peaks(x(ind), intensity(ind), start, thres);
            
            % Fit Rayleigh peak
            % Construct start parameter array
            start = [maxima(1, 1), maxima(1, 4), fwhm, fwhm, maxima(2, 1), maxima(2, 4)];
            x = 1:1:length(intensity);
            % Fit
            [params_R, ~, ~, ~, ~]  = BE_Utils.FittingScripts.nfit_2peaks(x, intensity, start, thres);
            
            % Construct parameter array as 4 peak fits returns it
            params = [params_R(1), params_B(1), params_B(2), params_R(2),...
                      params_R(3), params_B(3), params_B(4), params_R(4),...
                      params_R(5), params_B(5), params_B(6), params_R(6)];
            % Calculate fitted curve
            [~, fittedCurve] = BE_Utils.FittingScripts.lorentz4(params, x, intensity, thres);
        else
            % Start parameters
            start = [maxima(1, 1:4), fwhm, fwhm, fwhm, fwhm, maxima(2, 1:4)];
            x = 1:1:length(intensity);
            [params, ~, ~, fittedCurve, deviation] = BE_Utils.FittingScripts.nfit_4peaks(x, intensity, start, thres);
        end
        peakPos = params(1:4);
        peakFWHM = params(5:8);
        peakInt = params(9:12);
    otherwise
        error('Select fitting mode 2 or 4.');
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

%% Plot result
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
end

end