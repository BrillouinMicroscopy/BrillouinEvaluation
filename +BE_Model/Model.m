classdef Model < handle
%% MODEL

    % observable properties, listeners are notified on change
    properties (SetObservable = true)
        file;       % handle to the H5BM file
        filename;   % name of the H5BM file
        pp;         % path to the program
        parameters; % parameters of the measurement
        results;    % results of the evaluation
        displaySettings;    %settings used for displaying data
        status;             % current status of the GUI
        handles;            % structure with handles which need to be set dynamically
        labels;             % labels of the plots
    end

    methods
        function obj = Model()
            obj.file = [];
            obj.filename = [];
            obj.pp = [];
%% Parameters of the acquisition and settings used for evaluating
% Saved to evaluated data file
            obj.parameters = struct( ...
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
                'extraction', struct( ...
                    'imageNr', 1, ...
                    'width', 3, ...         % [pix] width of the extracted spectrum
                    'peaks', struct( ...    % position of the peaks for localising the spectrum
                        'x', [], ...        % [pix] x-position
                        'y', [] ...         % [pix] y-position
                    ), ...
                    'extractionAxis', 'y', ...          % {'x', 'y', 'f'} axis along which the extraction is performed
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
                'evaluation', struct( ...
                    'fwhm', 5, ...          % [pix] initial value for the FWHM of the Brillouin peak
                    'gap', 10 ...           % [pix] minimum x and y distance of maxima to the edges of the image
                ) ...
            );
%% Results of the evaluation
% Saved to evaluated data file
            obj.results = struct( ...
                'BrillouinShift', NaN, ...      % [GHz]  the Brillouin shift
                'peaksBrillouin_pos', NaN, ...  % [pix]  the position of the Brillouin peak(s) in the spectrum
                'peaksBrillouin_dev', NaN, ...  % [pix]  the deviation of the Brillouin fit
                'peaksBrillouin_int', NaN, ...  % [a.u.] the intensity of the Brillouin peak(s)
                'peaksBrillouin_fwhm', NaN, ... % [pix]  the FWHM of the Brillouin peak
                'peaksRayleigh_pos', NaN, ...   % [pix]  the position of the Rayleigh peak(s) in the spectrum
                'intensity', NaN ...            % [a.u.] the overall intensity of the image
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
                'evaluation', struct( ...
                    'preview', 0, ...
                    'type', 'BrillouinShift', ...
                    'autoscale', true, ...
                    'floor', 100, ...
                    'cap', 500 ...
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
                'evaluation', struct( ...
                    'evaluate', 0 ...
                ) ...
            );
%% Handles to plots
            obj.handles = struct( ...
                'resutls', NaN, ...
                'plotPositions', NaN ...
            );
%% Labels of plots
            obj.labels.evaluation.typesLabels = struct( ...
                'BrillouinShift', struct( ...
                    'dataLabel', '$f$ [pix]', ...
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
                'intensity', struct( ...
                    'dataLabel', '$I$ [a.u.]', ...
                    'titleString', 'Complete Intensity' ...
                ) ...
            );
            obj.labels.evaluation.types = {...
                'BrillouinShift', ...
                'peaksBrillouin_dev', ...
                'peaksBrillouin_pos', ...
                'peaksBrillouin_int', ...
                'peaksBrillouin_fwhm', ...
                'peaksRayleigh_pos', ...
                'intensity' ...
            };
        end
    end
end