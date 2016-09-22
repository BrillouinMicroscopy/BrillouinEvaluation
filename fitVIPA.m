function [VIPAparams] = fitVIPA(peakPos, VIPAstart, constants, IterNum)
% this function fits the VIPA parameters to the measured peaks. To
% calculate the Parameters, 2 Rayleigh peaks and 2 Brillouin peaks within
% one FSR are required
% 
% input:
% peaks:        [m]     peak locations on the camera
% VIPAstart =
%           d:  [m]     width of the cavity
%           n:  [1]     refractive index
%       theta:  [rad]   angle of the VIPA
%           F:  [m]     focal length of the lens behind the VIPA
%          x0:  [m]     offset for fitting
%          xs:  [1]     scale factor for fitting
%       order:  [1]     observed order of the VIPA spectrum
% constants =
%           c:  [m/s]   speed of light
%   pixelSize:  [m]     pixel size of the camera
%     lambda0:  [m]     laser wavelength
%   bshiftCal:  [Hz]    calibration shift frequency
% IterNum:      [1]     number of Iterations for the Fit
% 
% output:
% params =
%           d:  [m]     width of the cavity
%           n:  [1]     refractive index
%       theta:  [rad]   angle of the VIPA
%           F:  [m]     focal length of the lens behind the VIPA
%          x0:  [m]     offset for fitting
%          xs:  [1]     scale factor for fitting

orders = VIPAstart.order:(VIPAstart.order + 1);

% peaks = peaks - peaks(1);
peakPos = sort(peakPos, 'ascend');
peakPos = constants.pixelSize * peakPos;
lambdaS  = 1/(1/constants.lambda0 - constants.bShiftCal/constants.c);
lambdaAS = 1/(1/constants.lambda0 + constants.bShiftCal/constants.c);

%% calculation

for gg = 1:1:IterNum

    if exist('ItRun', 'var')
        ItRun = ItRun + 1;
    else
        ItRun = 0;
    end

    %
    dVariation = 2.5e-5/(2^ItRun);
    if exist('dInd', 'var')
        dcenter = dRange(dInd);
    else
        dcenter = VIPAstart.d;
    end
    dRange = linspace((1-dVariation)*dcenter, (1+dVariation)*dcenter, 11);

    %
    nVariation = 2e-5/(2^ItRun);
    if exist('nInd', 'var')
        ncenter = nRange(nInd);
    else
        ncenter = VIPAstart.n;
    end
    nRange = linspace((1-nVariation)*ncenter, (1+nVariation)*ncenter, 11);

    %
    thetaVariation = 0.001/(2^ItRun);
    if exist('thetaInd', 'var')
        thetacenter = thetaRange(thetaInd);
    else
        thetacenter = VIPAstart.theta;
    end
    thetaRange = linspace((1-thetaVariation)*thetacenter, (1+thetaVariation)*thetacenter, 11);

    %
    x0Variation = 0.3/(2^ItRun);
    if exist('x0Ind', 'var')
        x0center = x0Range(x0Ind);
    else
        x0center = VIPAstart.x0;
    end
    x0Range = linspace((1-x0Variation)*x0center, (1+x0Variation)*x0center, 11);

    %
    xsVariation = 0.1/(2^ItRun);
    if exist('xsInd', 'var')
        xscenter = xsRange(xsInd);
    else
        xscenter = VIPAstart.xs;
    end
    xsRange = linspace((1-xsVariation)*xscenter, (1+xsVariation)*xscenter, 11);

    ErrorVector = NaN(length(dRange), length(nRange), length(thetaRange), length(x0Range), length(xsRange));

    for ii = 1:length(dRange)
        disp(ii);
        for jj = 1:length(nRange)
            for kk = 1:length(thetaRange)
                for ll = 1:length(x0Range)
                    for mm = 1:length(xsRange)
                        VIPAparams = {};
                        VIPAparams.d     = dRange(ii);
                        VIPAparams.n     = nRange(jj);
                        VIPAparams.theta = thetaRange(kk);
                        VIPAparams.x0    = x0Range(ll);
                        VIPAparams.xs    = xsRange(mm);
                        
                        x_F = NaN(1,4);
                        % position of the two Rayleigh peaks
                        [x_F(1,[1 4]), ~] = peakPosition(VIPAparams, constants, orders, constants.lambda0);
                        % position of the Stokes and Anti-Stokes peaks
                        [x_F(2), ~] = peakPosition(VIPAparams, constants, 1, lambdaAS);
                        [x_F(3), ~] = peakPosition(VIPAparams, constants, 2, lambdaS);
                        
                        % difference between measurement and fit
                        ErrorVector(ii,jj,kk,ll,mm) = sum((peakPos - x_F).^2);
                    end
                end
            end
        end
    end
    [~, ind] = min(ErrorVector(:));

    [dInd, nInd, thetaInd, x0Ind, xsInd] = ind2sub(size(ErrorVector),ind);

end

%% return fitted parameters
VIPAparams = {};
VIPAparams.d     = dRange(dInd);
VIPAparams.n     = nRange(nInd);
VIPAparams.theta = thetaRange(thetaInd);
VIPAparams.x0    = x0Range(x0Ind);
VIPAparams.xs    = xsRange(xsInd);


%% Plot Results
% x_F = NaN(1,4);
% % position of the two Rayleigh peaks
% [x_F(1,[1 4]), ~] = peakPosition( VIPAparams, constants, orders, constants.lambda0);
% % position of the Stokes and Anti-Stokes peaks
% [x_F(2), ~] = peakPosition(VIPAparams, constants, 1, lambdaAS);
% [x_F(3), ~] = peakPosition(VIPAparams, constants, 2, lambdaS);
% 
% figure;
% hold on
% box on
% ylim([0.7, 1.5])
% set(gca,'YTick',[])
% xlabel('distance [mm]')
% meas = plot(peakPos*1e3, ones(length(peakPos)), 'or');
% fit = plot(x_F*1e3, ones(length(x_F)), 'xb');
% legend([meas(1), fit(1)], 'Measurement', 'Fit');

end