classdef Model < handle
%% MODEL

    % observable properties, listeners are notified on change
    properties (SetObservable = true)
        file;       % handle to the H5BM file
        filename;   % name of the H5BM file
        filepath;   % path to the H5BM file
        pp;         % path to the program
        parameters; % parameters of the measurement
        results;            % results of the evaluation
        displaySettings;    %settings used for displaying data
        status;             % current status of the GUI
        handles;            % structure with handles which need to be set dynamically
        labels;             % labels of the plots
        tmp;                % structure for temporary data
    end
    properties (Constant)
        programVersion = struct( ...
            'major', 1, ...
            'minor', 1, ...
            'patch', 0, ...
            'preRelease', 'alpha' ...
        );     % version of the evaluation program
    end

    methods
        function obj = Model()
            obj.file = [];
            obj.filename = [];
            obj.filepath = [];
            obj.pp = [];
%% Parameters of the acquisition and settings used for evaluating
% Saved to evaluated data file
            obj.parameters = struct( ...
                'programVersion', obj.programVersion, ...
                'data', NaN, ...
                'comment', '', ...
                'resolution', struct( ...
                    'X', NaN, ...
                    'Y', NaN, ...
                    'Z', NaN ...
                ), ...
                'positions', struct( ...
                    'X', NaN, ...
                    'Y', NaN, ...
                    'Z', NaN ...
                ), ...
                'positions_brightfield', struct( ...
                    'X', NaN, ...
                    'Y', NaN, ...
                    'Z', NaN ...
                ), ...
                'constants', struct( ...        % constants used for VIPA fit
                    'c', 299792458, ...         % [m/s] speed of light
                    'pixelSize', 6.5e-6, ...    % [m]   pixel size of the camera
                    'lambda0', 780.24e-9, ...   % [m]   laser wavelength
                    'F', 0.2 ...                % [m]   focal length of the lens behind the VIPA
                ), ...
                'extraction', struct( ...
                    'imageNr', 1, ...
                    'width', 3, ...         % [pix] width of the extracted spectrum
                    'peaks', struct( ...    % position of the peaks for localising the spectrum
                        'x', [], ...        % [pix] x-position
                        'y', [] ...         % [pix] y-position
                    ), ...
                    'extractionAxis', 'f', ...          % {'x', 'y', 'f'} axis along which the extraction is performed
                    'interpolationDirection', 'f', ...  % {'x', 'y', 'f'} direction of the interpolation
                    'circleStart', NaN, ...
                    'circleFit', NaN, ...
                    'r0', NaN, ...
                    'x0', NaN, ...
                    'y0', NaN, ...
                    'interpolationCenters', struct( ...
                        'x', [], ...        % [pix] x-position
                        'y', [] ...         % [pix] y-position
                    ), ...
                    'interpolationBorders', struct( ...
                        'x', [], ...        % [pix] x-position
                        'y', [] ...         % [pix] y-position
                    ), ...
                    'interpolationPositions', struct( ...
                        'x', [], ...        % [pix] x-position
                        'y', [] ...         % [pix] y-position
                    ) ...
                ), ...
                'peakSelection', struct( ...
                    'Rayleigh', [298, 334; 45, 75], ...
                    'Brillouin', [227, 256; 150, 180] ...
                ), ...
                'calibration', struct( ...
                    'hasCalibration', false, ...
                    'samples', struct(), ...
                    'selected', '', ...
                    'selectedValue', NaN, ...
                    'weighted', true, ...
                    'extrapolate', false, ...
                    'correctOffset', false, ...
                    'start', struct( ...            % start values for the VIPA fit
                        'd',    0.006774, ...       % [m]   width of the cavity
                        'n',    1.453683, ...       % [1]   refractive index of the VIPA
                        'theta',0.8*2*pi/360, ...   % [rad] angle of the VIPA
                        'x0',   0.0021, ...         % [m]   offset for fitting
                        'xs',   1.0000, ...         % [1]   scale factor for fitting
                        'order', 1, ...             % [1]   observed order of the VIPA spectrum
                        'iterNum', 8 ...            % [1]   number of iterations for the fit
                    ), ...
                    'wavelength', [], ...           % [m]   the wavelength corresponding to every pixel
                    'times', [], ...                % [s]   the time vector of the calibration measurements
                    'pixels', [], ...            	% [pix] the pixel value of the calibration axis
                    'offset', [] ...                % [pix] offset of the calibration
                ), ...
                'evaluation', struct( ...
                    'fwhm', 5, ...              % [pix] initial value for the FWHM of the Brillouin peak
                    'gap', 10, ...              % [pix] minimum x and y distance of maxima to the edges of the image
                    'rotationAngle', NaN, ...  % [degree]          angle of rotation
                    'centerx', 800, ...         % [pix]             x-center of the image
                    'centery', 860, ...         % [pix]             y-center of the image
                    'scaling', 0.086, ...       % [micro m / pix]   scaling factor
                    'xl', NaN, ...              %
                    'yl', NaN ...               %
                ), ...
                'masking', struct( ...
                    'brushSize', 40, ...        % [micro m] size of the brush
                    'adding', 1 ...             % [logical] add or delete mask
                ) ...
            );
%% Results of the evaluation
% Saved to evaluated data file
            obj.results = struct( ...
                'BrillouinShift',           NaN, ...    % [GHz]  the Brillouin shift
                'BrillouinShift_frequency', NaN, ...    % [GHz]  the Brillouin shift in Hz
                'peaksBrillouin_pos',       NaN, ...    % [pix]  the position of the Brillouin peak(s) in the spectrum
                'peaksBrillouin_dev',       NaN, ...    % [pix]  the deviation of the Brillouin fit
                'peaksBrillouin_int',       NaN, ...    % [a.u.] the intensity of the Brillouin peak(s)
                'peaksBrillouin_fwhm',      NaN, ...    % [pix]  the FWHM of the Brillouin peak
                'peaksRayleigh_pos',        NaN, ...    % [pix]  the position of the Rayleigh peak(s) in the spectrum
                'peaksRayleigh_int',        NaN, ...    % [a.u.] the intensity of the Rayleigh peak(s)
                'peaksRayleigh_fwhm',       NaN, ...    % [pix]  the FWHM of the Rayleigh peak(s)
                'intensity',                NaN, ...    % [a.u.] the overall intensity of the image
                'validity',                 NaN, ...    % [logical] the validity of the results
                'times',                    NaN, ...    % [s]    time of the measurement
                'brightfield',              NaN, ...    % [a.u.] the intensity of the brightfield image (usefull for 2D xy images)
                'brightfield_raw',          NaN, ...    % [a.u.] the complete brightfield image
                'brightfield_rot',          NaN, ...    % [a.u.] the rotated brightfield image
                'masks',                    struct() ...%        struct for the masks
            );
%% Display settings of the plots
            obj.displaySettings = struct( ...
                'extraction', struct( ...
                    'autoscale', false, ...
                    'floor', 100, ...
                    'cap', 500, ...
                    'showBorders', 1, ...
                    'showCenter', 1, ...
                    'showPositions', 1 ...
                ), ...
                'peakSelection', struct( ...
                    'autoscale', true, ...
                    'floor', 100, ...
                    'cap', 500 ...
                ), ...
                'calibration', struct( ...
                    'autoscale', true, ...
                    'floor', 100, ...
                    'cap', 500 ...
                ), ...
                'evaluation', struct( ...
                    'preview', 0, ...
                    'type', 'BrillouinShift', ...
                    'autoscale', true, ...
                    'floor', 100, ...
                    'cap', 500, ...
                    'discardInvalid', false, ...% [logical] discard invalid results
                    'valThreshould', 25, ...    % [1]       threshould for the validity
                    'intFac', 1 ...             % [1]       interpolation factor
                ), ...
                'masking', struct( ...
                    'autoscale', true, ...
                    'floor', 100, ...
                    'cap', 500, ...
                    'selected', '', ...
                    'showOverlay', true ...
                ) ...
            );
%% Status of the GUI
            obj.status = struct( ...
                'extraction', struct( ...
                    'selectPeaks', 0 ...
                ), ...
                'peakSelection', struct( ...
                    'selectBrillouin', 0, ...
                    'selectRayleigh', 0 ...
                ), ...
                'calibration', struct( ...
                    'selectBrillouin', 0, ...
                    'selectRayleigh', 0 ...
                ), ...
                'evaluation', struct( ...
                    'evaluate', 0, ...
                    'showSpectrum', 0 ...
                ) ...
            );
%% Handles to plots
            obj.handles = struct( ...
                'results', NaN, ...
                'plotPositions', NaN ...
            );
%% Labels of plots
            obj.labels.evaluation.typesLabels = struct( ...
                'BrillouinShift', struct( ...
                    'dataLabel', '$f$ [pix]', ...
                    'titleString', 'Corrected position of the Brillouin peaks' ...
                ), ...
                'BrillouinShift_frequency', struct( ...
                    'dataLabel', '$f$ [GHz]', ...
                    'titleString', 'Corrected position of the Brillouin peaks' ...
                ), ...
                'peaksBrillouin_dev', struct( ...
                    'dataLabel', '$f$ [pix]', ...
                    'titleString', 'Deviation of the Brillouin fit' ...
                ), ...
                'peaksBrillouin_int', struct( ...
                    'dataLabel', '$I$ [a.u.]', ...
                    'titleString', 'Intensity of the Brillouin peaks' ...
                ), ...
                'peaksBrillouin_pos', struct( ...
                    'dataLabel', '$f$ [pix]', ...
                    'titleString', 'Position of the Brillouin peaks' ...
                ), ...
                'peaksBrillouin_fwhm', struct( ...
                    'dataLabel', '$\Delta f$ [pix]', ...
                    'titleString', 'FWHM of the Brillouin peaks' ...
                ), ...
                'peaksRayleigh_pos', struct( ...
                    'dataLabel', '$f$ [pix]', ...
                    'titleString', 'Position of the Rayleigh peaks' ...
                ), ...
                'peaksRayleigh_int', struct( ...
                    'dataLabel', '$I$ [a.u.]', ...
                    'titleString', 'Intensity of the Rayleigh peaks' ...
                ), ...
                'peaksRayleigh_fwhm', struct( ...
                    'dataLabel', '$\Delta f$ [pix]', ...
                    'titleString', 'FWHM of the Rayleigh peaks' ...
                ), ...
                'intensity', struct( ...
                    'dataLabel', '$I$ [a.u.]', ...
                    'titleString', 'Complete Intensity' ...
                ), ...
                'validity', struct( ...
                    'dataLabel', 'valid [1]', ...
                    'titleString', 'Validity of the results' ...
                ), ...
                'brightfield', struct( ...
                    'dataLabel', 'brightfield', ...
                    'titleString', 'Brightfield image' ...
                ) ...
            );
            obj.labels.evaluation.types = {...
                'BrillouinShift', ...
                'BrillouinShift_frequency', ...
                'peaksBrillouin_dev', ...
                'peaksBrillouin_pos', ...
                'peaksBrillouin_int', ...
                'peaksBrillouin_fwhm', ...
                'peaksRayleigh_pos', ...
                'peaksRayleigh_int', ...
                'peaksRayleigh_fwhm', ...
                'intensity', ...
                'validity', ...
                'brightfield' ...
            };
        end
    end
end