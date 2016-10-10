function constants = getConstants()

% constant parameters
constants = {};                     % struct with constants
constants.c         = 299792458;    % [m/s] speed of light
constants.pixelSize = 6.5e-6;       % [m]   pixel size of the camera
constants.lambda0   = 780.24e-9;    % [m]   laser wavelength
constants.bShiftCal = 5.09e9;       % [Hz]  calibration shift frequency
constants.F         = 0.2;          % [m]   focal length of the lens behind the VIPA

end