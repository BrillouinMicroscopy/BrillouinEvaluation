classdef Model < handle
%% MODEL

    % observable properties, listeners are notified on change
    properties (SetObservable = true)
        file = [];          % handle to the H5BM file
        filename = [];      % name of the H5BM file
        filepath = [];      % path to the H5BM file
        mode = 'Brillouin'; % mode
        repetition = 0;     % repetition number
        repetitionCount = 0;% number of repetitions
        pp = [];            % path to the program
        log;                % logging object
        parameters;         % parameters of the measurement
        results;            % results of the evaluation
        displaySettings;    % settings used for displaying data
        status;             % current status of the GUI
        handles;            % structure with handles which need to be set dynamically
        tmp;                % structure for temporary data
        controllers;        % handle to all controllers
    end
    properties (Constant)
        programVersion = getProgramVersion();
        %% Results of the evaluation
        % Saved to evaluated data file
        defaultResults = struct( ...
            'BrillouinShift',           NaN, ...    % [GHz]  the Brillouin shift
            'BrillouinShift_frequency', NaN, ...    % [GHz]  the Brillouin shift in Hz
            'peaksBrillouin_pos',       NaN, ...    % [pix]  the position of the Brillouin peak(s) in the spectrum
            'peaksBrillouin_dev',       NaN, ...    % [pix]  the deviation of the Brillouin fit
            'peaksBrillouin_int',       NaN, ...    % [a.u.] the fitted intensity of the Brillouin peak(s)
            'peaksBrillouin_int_real',  NaN, ...    % [a.u.] the real intensity of the Brillouin peak(s)
            'peaksBrillouin_nrFittedPeaks', NaN, ...% [1]    the number of Brillouin peaks fitted
            'peaksBrillouin_fwhm',      NaN, ...    % [pix]  the FWHM of the Brillouin peak
            'peaksBrillouin_fwhm_frequency', NaN,...% [GHz]  the FWHM of the Brillouin peak in GHz
            'peaksRayleigh_pos_interp', NaN, ...    % [pix]  the position of the Rayleigh peak(s) in the spectrum (interpoalted)
            'peaksRayleigh_pos_exact',  NaN, ...    % [pix]  the position of the Rayleigh peak(s) in the spectrum (exact)
            'peaksRayleigh_pos',        NaN, ...    % [pix]  the position of the Rayleigh peak(s) in the spectrum
            'peaksRayleigh_int',        NaN, ...    % [a.u.] the intensity of the Rayleigh peak(s)
            'peaksRayleigh_fwhm',       NaN, ...    % [pix]  the FWHM of the Rayleigh peak(s)
            'intensity',                NaN, ...    % [a.u.] the overall intensity of the image
            'validity_Rayleigh',        NaN, ...    % [logical] the validity of the Rayleigh peaks
            'validity_Brillouin',       NaN, ...    % [logical] the validity of the Brillouin peaks
            'validity',                 NaN, ...    % [logical] the validity of the general results
            'times',                    NaN, ...    % [s]    time of the measurement
            'masks',                    struct() ...%        struct for the masks
        );
        %% Parameters of the acquisition and settings used for evaluating
        % Available setups
        availableSetups = struct( ...
            'S0', struct( ...                   % constants for the 780 nm setup
                'name', '780 nm @ Biotec R340', ... %   name of the setup
                'pixelSize', 6.5e-6, ...        % [m]   pixel size of the camera
                'lambda0', 780.24e-9, ...       % [m]   laser wavelength
                'F', 0.2, ...                   % [m]   focal length of the lens behind the VIPA
                'VIPA', struct( ...             % start values for the VIPA fit
                    'd',     0.006743, ...      % [m]   width of the cavity
                    'n',     1.45367, ...       % [1]   refractive index of the VIPA
                    'theta', 0.8*2*pi/360, ...  % [rad] angle of the VIPA
                    'order', 0 ...              % [1]   observed order of the VIPA spectrum
                ), ...
                'calibration' , struct( ...
                    'nrBrillouinSamples', 2, ...
                    'shifts', [ ...
                        3.78e9, ...             % [Hz]  Brillouin shift of methanol
                        5.066e9 ...             % [Hz]  Brillouin shift of water
                    ] ...
                ) ...
            ), ...
            'S1', struct( ...                   % constants for the 780 nm setup
                'name', '780 nm @ Biotec R340 old', ... %   name of the setup
                'pixelSize', 6.5e-6, ...        % [m]   pixel size of the camera
                'lambda0', 780.24e-9, ...       % [m]   laser wavelength
                'F', 0.2, ...                   % [m]   focal length of the lens behind the VIPA
                'VIPA', struct( ...             % start values for the VIPA fit
                    'd',     0.006743, ...      % [m]   width of the cavity
                    'n',     1.45367, ...       % [1]   refractive index of the VIPA
                    'theta', 0.8*2*pi/360, ...  % [rad] angle of the VIPA
                    'order', 0 ...              % [1]   observed order of the VIPA spectrum
                ), ...
                'calibration' , struct( ...
                    'nrBrillouinSamples', 1, ...
                    'shifts', [ ...
                        3.78e9 ...             % [Hz]  Brillouin shift of methanol
                    ] ...
                ) ...
            ), ...
            'S2', struct( ...                   % constants for the 532 nm setup
                'name', '532 nm @ Biotec R314', ... %   name of the setup
                'pixelSize', 6.5e-6, ...        % [m]   pixel size of the camera
                'lambda0', 532e-9, ...          % [m]   laser wavelength
                'F', 0.2, ...                   % [m]   focal length of the lens behind the VIPA
                'VIPA', struct( ...             % start values for the VIPA fit
                    'd',     0.003371, ...      % [m]   width of the cavity
                    'n',     1.46071, ...       % [1]   refractive index of the VIPA
                    'theta', 0.8*2*pi/360, ...  % [rad] angle of the VIPA
                    'order', 0 ...              % [1]   observed order of the VIPA spectrum
                ), ...
                'calibration' , struct( ...
                    'nrBrillouinSamples', 2, ...
                    'shifts', [ ...
                        5.54e9, ...             % [Hz]  Brillouin shift of methanol
                        7.43e9 ...              % [Hz]  Brillouin shift of water
                    ] ...
                ) ...
            ) ...
        );
        
        % Saved to evaluated data file
        defaultParameters = struct( ...
            'programVersion', BE_Model.Model.programVersion, ...
            'data', struct( ...
                'rotate', -1, ...           % {-1 , 0, 1} rotate the image by k*90 degrees
                'flipud', false, ...        % flip the image up-down
                'fliplr', false ...         % flip the image left-right
            ), ...
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
            'constants_general', struct( ...        % constants used for VIPA fit
                'c', 299792458 ...         % [m/s] speed of light
            ), ...
            'constants_setup', struct( ...                   % constants for the 780 nm setup
                'name', '780 nm @ Biotec R340', ... %   name of the setup
                'pixelSize', 6.5e-6, ...        % [m]   pixel size of the camera
                'lambda0', 780.24e-9, ...       % [m]   laser wavelength
                'F', 0.2, ...                   % [m]   focal length of the lens behind the VIPA
                'VIPA', struct( ...             % start values for the VIPA fit
                    'd',     0.006743, ...      % [m]   width of the cavity
                    'n',     1.45367, ...       % [1]   refractive index of the VIPA
                    'theta', 0.8*2*pi/360, ...  % [rad] angle of the VIPA
                    'order', 0 ...              % [1]   observed order of the VIPA spectrum
                ), ...
                'calibration' , struct( ...
                    'nrBrillouinSamples', 2, ...
                    'shifts', [ ...
                        3.78e9, ...             % [Hz]  Brillouin shift of methanol
                        5.066e9 ...             % [Hz]  Brillouin shift of water
                    ] ...
                ) ...
            ), ...
            'extraction', struct( ...
                'imageNr', 1, ...
                'currentCalibrationNr', 1, ...
                'overlay', false, ...           % [bool]  should a measurement image be overlayed to the calibration (helps for weak Rayleigh signals)
                'width', 3, ...         % [pix] width of the extracted spectrum
                'extractionAxis', 'f', ...          % {'x', 'y', 'f'} axis along which the extraction is performed
                'interpolationDirection', 'f', ...  % {'x', 'y', 'f'} direction of the interpolation
                'circleStart', NaN, ...
                'times', [], ...
                'calibrations', struct( ...
                    'peaks', struct( ...% position of the peaks for localising the spectrum
                        'x', [], ...    % [pix] x-position
                        'y', [] ...     % [pix] y-position
                    ), ...
                    'circleFit', [] ...
                ), ...
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
                'peakTypes', {{'R', 'B', 'B', 'B' ,'B', 'R'}}, ... % expected types of peaks
                'peakProminence', 15, ...       % the minimal prominence of the peaks (used for finding peaks)
                'frequency', [], ...            % [GHz] the wavelength corresponding to every pixel
                'times', [], ...                % [s]   the time vector of the calibration measurements
                'pixels', [], ...            	% [pix] the pixel value of the calibration axis
                'offset', [] ...               % [pix] offset of the calibration
            ), ...
            'evaluation', struct( ...
                'fwhm', 5, ...              % [pix] initial value for the FWHM of the Brillouin peak
                'gap', 10, ...              % [pix] minimum x and y distance of maxima to the edges of the image
                'interpRayleigh', true, ... % [bool] whether or not invalid Rayleigh peak positions (e.g. due to saturation) should be interpolated
                'minRayleighPeakHeight', 50, ... % [1] minimum Rayleigh peak height
                'rotationAngle', NaN, ...   % [degree]          angle of rotation
                'centerx', 800, ...         % [pix]             x-center of the image
                'centery', 860, ...         % [pix]             y-center of the image
                'scaling', 0.086, ...       % [micro m / pix]   scaling factor
                'xl', NaN, ...              %
                'yl', NaN, ...              %
                'nrBrillouinPeaks', 1, ...  % [1]   number of Brillouin peaks to fit
                'constraints', struct( ...
                    'sa', struct( ...
                        'Lower', 'min', ...
                        'Upper', 'max' ...
                    ), ...
                    'wa', struct( ...
                        'Lower', 3, ...
                        'Upper', Inf ...
                    ), ...
                    'Ba', struct( ...
                        'Lower', 0, ...
                        'Upper', Inf ...
                    ), ...
                    'sb', struct( ...
                        'Lower', 'min', ...
                        'Upper', 'max' ...
                    ), ...
                    'wb', struct( ...
                        'Lower', 3, ...
                        'Upper', Inf ...
                    ), ...
                    'Bb', struct( ...
                        'Lower', 0, ...
                        'Upper', Inf ...
                    ) ...
                ) ...
            ), ...
            'masking', struct( ...
                'brushSize', 40, ...        % [micro m] size of the brush
                'adding', 1 ...             % [logical] add or delete mask
            ), ...
            'date', NaN, ...
            'exposureTime', 0.5 ... % This is the default exposure time for files in which the time was not
                                ... % saved. For newer files, the exposure time is read from the file. The
                                ... % time is only used for interpolating the Rayleigh peak position, so
                                ... % +- 0.5 s have no significant influence.
        );
        %% Display settings of the plots
        % Saved to evaluated data file
        defaultDisplaySettings = struct( ...
            'extraction', struct( ...
                'autoscale', false, ...
                'floor', 90, ...
                'cap', 500, ...
                'showBorders', false, ...
                'showCenter', false, ...
                'showPositions', true ...
            ), ...
            'peakSelection', struct( ...
                'autoscale', true, ...
                'floor', 90, ...
                'cap', 500 ...
            ), ...
            'calibration', struct( ...
                'autoscale', true, ...
                'floor', 90, ...
                'cap', 500 ...
            ), ...
            'evaluation', struct( ...
                'preview', 0, ...
                'type', 'BrillouinShift', ...
                'autoscale', true, ...
                'floor', 90, ...
                'cap', 500, ...
                'discardInvalid', false, ...% [logical] discard invalid results
                'valThreshould', 25, ...    % [1]       threshould for the validity
                'intFac', 1, ...            % [1]       interpolation factor
                'peakNumber', 1 ...         % [1]       the peak to show
            ), ...
            'masking', struct( ...
                'autoscale', true, ...
                'floor', 90, ...
                'cap', 500, ...
                'selected', '', ...
                'showOverlay', true ...
            ) ...
        );
        %% Labels of plots
        labels = struct( ...
            'evaluation', struct( ...
                'typesLabels', struct( ...
                    'BrillouinShift', struct( ...
                        'dataLabel', '$\nu_\mathrm{B}$ [pix]', ...
                        'titleString', 'Brillouin shift' ...
                    ), ...
                    'BrillouinShift_frequency', struct( ...
                        'dataLabel', '$\nu_\mathrm{B}$ [GHz]', ...
                        'titleString', 'Brillouin shift' ...
                    ), ...
                    'peaksBrillouin_dev', struct( ...
                        'dataLabel', '$\nu_\mathrm{B}$ [pix]', ...
                        'titleString', 'Deviation of the Brillouin fit' ...
                    ), ...
                    'peaksBrillouin_int', struct( ...
                        'dataLabel', '$I$ [a.u.]', ...
                        'titleString', 'Intensity of the Brillouin peaks' ...
                    ), ...
                    'peaksBrillouin_pos', struct( ...
                        'dataLabel', '$\nu_\mathrm{B}$ [pix]', ...
                        'titleString', 'Position of the Brillouin peaks' ...
                    ), ...
                    'peaksBrillouin_fwhm', struct( ...
                        'dataLabel', '$\Delta \nu_\mathrm{B}$ [pix]', ...
                        'titleString', 'FWHM of the Brillouin peaks' ...
                    ), ...
                    'peaksBrillouin_fwhm_frequency', struct( ...
                        'dataLabel', '$\Delta \nu_\mathrm{B}$ [GHz]', ...
                        'titleString', 'FWHM of the Brillouin peaks' ...
                    ), ...
                    'peaksBrillouin_nrFittedPeaks', struct( ...
                        'dataLabel', '[1]', ...
                        'titleString', 'Number of Brillouin peaks' ...
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
                    'times', struct( ...
                        'dataLabel', '$t$ [s]', ...
                        'titleString', 'Time' ...
                    ), ...
                    'intensity', struct( ...
                        'dataLabel', '$I$ [a.u.]', ...
                        'titleString', 'Complete Intensity' ...
                    ), ...
                    'validity', struct( ...
                        'dataLabel', 'valid [1]', ...
                        'titleString', 'Validity of the results' ...
                    ) ...
                ), ...
                'types', {{...
                    'BrillouinShift', ...
                    'BrillouinShift_frequency', ...
                    'peaksBrillouin_dev', ...
                    'peaksBrillouin_pos', ...
                    'peaksBrillouin_int', ...
                    'peaksBrillouin_fwhm', ...
                    'peaksBrillouin_fwhm_frequency', ...
                    'peaksBrillouin_nrFittedPeaks', ...
                    'peaksRayleigh_pos', ...
                    'peaksRayleigh_int', ...
                    'peaksRayleigh_fwhm', ...
                    'times', ...
                    'intensity', ...
                    'validity' ...
                }} ...
            ) ...
        );
        %% Status of the GUI
        defaultStatus = struct( ...
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
    end

    methods
        function obj = Model()            
            %% Parameters of the acquisition and settings used for evaluating
            % Saved to evaluated data file
            obj.parameters = obj.defaultParameters;
            %% Results of the evaluation
            % Saved to evaluated data file
            obj.results = obj.defaultResults;
            %% Display settings of the plots
            % Saved to evaluated data file
            obj.displaySettings = obj.defaultDisplaySettings;
            %% Status of the GUI
            obj.status = obj.defaultStatus;
            %% Handles to plots
            obj.handles = struct( ...
                'results', NaN, ...
                'plotPositions', NaN ...
            );
        end
        %% function to reset the model
        function reset(obj)
            obj.file = [];
            obj.filepath = [];
            obj.filename = [];
            obj.parameters = obj.defaultParameters;
            obj.results = obj.defaultResults;
            obj.displaySettings = obj.defaultDisplaySettings;
            obj.status = obj.defaultStatus;
        end
    end
end

function programVersion = getProgramVersion()
    %% check if git commit can be found
    commit = '';
    cleanRepo = 'False';
    fp = mfilename('fullpath');
    [path,~,~] = fileparts(fp);
    try
        if ispc
            [status,com] = system(['git -C "' path '" log -n 1 --format=format:%H']);
            if ~status
                commit = com;
            end
            [status,clean] = system(['git -C "' path '" ls-files --exclude-standard -d -m -o -k']);
            if ~status
                cleanRepo = isempty(clean);
            end
        else
            commit = 'Could not determine commit.';
            cleanRepo = 'unknown';
        end
    catch
        commit = 'Could not determine commit.';
        cleanRepo = 'unknown';
        % program folder does not contain git folder
    end

    programVersion = struct( ...
        'name', 'BrillouinEvaluation', ...
        'major', 1, ...
        'minor', 5, ...
        'patch', 2, ...
        'preRelease', '', ...
        'commit', commit, ...
        'cleanRepo', cleanRepo, ...
        'website', 'https://github.com/BrillouinMicroscopy/BrillouinEvaluation', ...
        'author', 'Raimund Schl��ler', ...
        'email', 'raimund.schluessler@tu-dresden.de', ...
        'link', ['https://github.com/BrillouinMicroscopy/BrillouinEvaluation/commit/' commit] ...
    );     % version of the evaluation program
end