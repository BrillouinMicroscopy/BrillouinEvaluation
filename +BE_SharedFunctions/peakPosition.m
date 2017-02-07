function [ x_F, m ] = peakPosition( VIPAparams, constants, orders, lambda )
%PEAKPOSITION 
% Uses the non-linear description from DOI 10.1109/JQE.2004.825210

% create shortcuts for often used values
n = VIPAparams.n;
theta = VIPAparams.theta;
F = constants.F;

%% internal angle
theta_in = asin(sin(theta)/n);

%% number of wavelengths in the cavity
% solve eq. 14 in the above mentioned paper for max[m]
m_max = BE_SharedFunctions.getMinimalOrder(VIPAparams, constants);

%% interesting number of wavelengths
% (given by startOrder and number of requested peaks)
m = m_max - orders + 1;

%% position of the peaks
% solve eq. 14 by x_F
x_F =      -n*F*tan(theta_in)*cos(theta)/(cos(theta_in)) + ...
      sqrt((n*F*tan(theta_in)*cos(theta)/(cos(theta_in)))^2 + ...
      2*n^2*F^2 - n*F^2*m*lambda/(VIPAparams.d*cos(theta_in)));

x_F = (x_F * VIPAparams.xs) + VIPAparams.x0;
end