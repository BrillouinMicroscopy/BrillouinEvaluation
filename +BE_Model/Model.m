classdef Model < handle
%% MODEL

    % observable properties, listeners are notified on change
    properties (SetObservable = true)
        file = [];          % handle to the H5BM file
        filename = [];      % name of the H5BM file
        filepath = [];      % path to the H5BM file
        pp = [];            % path to the program
        log;                % logging object
        parameters;         % parameters of the measurement
        results;            % results of the evaluation
        displaySettings;    % settings used for displaying data
        status;             % current status of the GUI
        handles;            % structure with handles which need to be set dynamically
        tmp;                % structure for temporary data
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
            'peaksBrillouin_int',       NaN, ...    % [a.u.] the intensity of the Brillouin peak(s)
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
            'brightfield',              NaN, ...    % [a.u.] the intensity of the brightfield image (usefull for 2D xy images)
            'brightfield_raw',          NaN, ...    % [a.u.] the complete brightfield image
            'brightfield_rot',          NaN, ...    % [a.u.] the rotated brightfield image
            'masks',                    struct() ...%        struct for the masks
        );
        %% Parameters of the acquisition and settings used for evaluating
        % Saved to evaluated data file
        defaultParameters = struct( ...
            'programVersion', BE_Model.Model.programVersion, ...
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
                'F', 0.2, ...               % [m]   focal length of the lens behind the VIPA
                'cavitySlope', -3840, ...   % [pix/m] empirically determinded factor between the
                ...                         %         difference of measured and fitted peak positions
                ...                         %         (calculated in +BE_Controller\Calibration.m lines 275 ff.)
                ...                         %         and the VIPA cavity width [see +BE_Controller\Calibration.m:testCavitySlope()]
                'cavitySlope2', -5830 ...   % same as cavitySlope, but for two pairs of Brillouin peaks
            ), ...
            'extraction', struct( ...
                'imageNr', 1, ...
                'currentCalibrationNr', 1, ...
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
                'peakTypes', {{'R', 'B', 'B', 'B' ,'B', 'R'}}, ... % expected types of peaks
                'peakProminence', 20, ...       % the minimal prominence of the peaks (used for finding peaks)
                'start', struct( ...            % start values for the VIPA fit
                    'd',    0.006743, ...       % [m]   width of the cavity
                    'n',    1.4607, ...         % [1]   refractive index of the VIPA
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
                'interpRayleigh', true, ... % [bool] whether or not invalid Rayleigh peak positions (e.g. due to saturation) should be interpolated
                'minRayleighPeakHeight', 50, ... % [1] minimum Rayleigh peak height
                'rotationAngle', NaN, ...   % [degree]          angle of rotation
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
        %% Display settings of the plots
        % Saved to evaluated data file
        defaultDisplaySettings = struct( ...
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
        %% Labels of plots
        labels = struct( ...
            'evaluation', struct( ...
                'typesLabels', struct( ...
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
                    'peaksBrillouin_fwhm_frequency', struct( ...
                        'dataLabel', '$\Delta f$ [GHz]', ...
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
                ), ...
                'types', {{...
                    'BrillouinShift', ...
                    'BrillouinShift_frequency', ...
                    'peaksBrillouin_dev', ...
                    'peaksBrillouin_pos', ...
                    'peaksBrillouin_int', ...
                    'peaksBrillouin_fwhm', ...
                    'peaksBrillouin_fwhm_frequency', ...
                    'peaksRayleigh_pos', ...
                    'peaksRayleigh_int', ...
                    'peaksRayleigh_fwhm', ...
                    'intensity', ...
                    'validity', ...
                    'brightfield' ...
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
        [status,com] = system(['git -C "' path '" log -n 1 --format=format:%H']);
        if ~status
            commit = com;
        end
        [status,clean] = system(['git -C "' path '" ls-files --exclude-standard -d -m -o -k']);
        if ~status
            cleanRepo = isempty(clean);
        end
    catch
        % program folder does not contain git folder
    end

    programVersion = struct( ...
        'major', 1, ...
        'minor', 2, ...
        'patch', 0, ...
        'preRelease', 'alpha', ...
        'commit', commit, ...
        'cleanRepo', cleanRepo, ...
        'website', 'https://gitlab.rschluessler.com/BrillouinMicroscopy/BrillouinEvaluation', ...
        'author', 'Raimund Schl��ler', ...
        'email', 'raimund.schluessler@tu-dresden.de', ...
        'link', ['https://gitlab.rschluessler.com/BrillouinMicroscopy/BrillouinEvaluation/commit/' commit] ...
    );     % version of the evaluation program
end