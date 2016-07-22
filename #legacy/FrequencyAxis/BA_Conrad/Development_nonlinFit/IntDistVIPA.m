function [I_out] = IntDistVIPA(f, F, W, R, r, t, Lambda, n, theta_vipa, x)
% the function calculates the lateral intensity distribution of the light
% behind a VIPA

% parameters:
% f, F:         [m]     focal lengths of the first and second lens
% W             [m]     beam width of the collimated beam
% R, r          [ ]     reflectivitysof the front-/back-mirror in the VIPA
% t             [m]     width of the cavity of the VIPA
% Lambda        [m]     wavelength of the incident light
% n             [ ]     refractive index of the VIPA
% theta_vipa    [rad]   angle of the VIPA
% x             [m]     x-values

theta_in = asin(sin(theta_vipa)/n);

delta = (2*t*n*cos(theta_in)) - (2*t*tan(theta_in)*cos(theta_vipa)*x/F) - (t*cos(theta_in)*x.^2/(n*F^2));
    
I_out = 1./((1-r*R)^2 + 4*r*R*(sin(pi*delta/Lambda)).^2);

% exp(-2*f^2*x.^2/(F^2*W^2))

end