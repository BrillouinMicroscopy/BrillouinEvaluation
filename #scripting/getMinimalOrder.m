function [ m ] = getMinimalOrder( VIPAparams, constants )
%GETMINIMALORDER
%

%% internal angle
theta_in = asin(sin(VIPAparams.theta)/VIPAparams.n);

%% number of wavelengths in the cavity
% solve eq. 14 in DOI 10.1109/JQE.2004.825210 for max[m]
m = VIPAparams.d*VIPAparams.n/constants.lambda0 * (2*cos(theta_in) + (tan(theta_in)^2  * cos(VIPAparams.theta)^2)/cos(theta_in));

m = floor(m);

end