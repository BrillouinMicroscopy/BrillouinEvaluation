function VIPAstart = getStartparameters()

% start parameters for VIPA fit
VIPAstart = {};
VIPAstart.d       = 0.006774;       % [m]   width of the cavity
VIPAstart.n       = 1.453683;       % [1]   refractive index
VIPAstart.theta   = 0.8*2*pi/360;   % [rad] angle of the VIPA
VIPAstart.x0      = 0.0021;         % [m]   offset for fitting
VIPAstart.xs      = 1.1348;         % [1]   scale factor for fitting
VIPAstart.order   = 1;              % [1]   observed order of the VIPA spectrum
VIPAstart.iterNum = 4;              % [1]   number of iterations for the fit

end