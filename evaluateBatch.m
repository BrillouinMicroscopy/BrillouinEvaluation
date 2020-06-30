% script for automatically evaluating Brillouin data
% copy this file to the folder with the data you want to evaluate and
% adjust the parameters below if necessary

%% path to the files
filelist = dir('**/*.h5');

%% parameter structure
% use this configuration for new calibrations with water + methanol
peakTypes = {'R', 'B', 'B', 'B', 'B', 'R'};
% use this configuration for old calibrations with only water or methanol
% peakTypes = {'R', 'B', 'B', 'R', 'NaN'};

parameters = struct( ...
    'data', struct( ...
        'rotate', -1, ...               % {-1 , 0, 1} rotate the image by k*90 degrees
        'flipud', false, ...            % flip the image up-down
        'fliplr', false ...             % flip the image left-right
    ), ...
    'extraction', struct( ...           % parameters for the extraction
        'do', true ...                  % execute extraction?
    ), ...
    'calibration', struct( ...          % parameters for the calibration
        'do', true, ...                 % execute calibration?
        'peakProminence', 15, ...       % the minimal prominence of the peaks
        'peakTypes', {peakTypes}, ...   % expected types of peaks
        'correctOffset', false, ...     % correct the calibration offset?
        'extrapolate', true, ...        % extrapolate the calibration?
        'weighted', false ...           % use weighting for calibration calculation?
    ), ...
    'peakSelection', struct( ...        % parameters for the peak selection
        'do', true, ...                 % execute peak selection?
        'unit', 'GHz', ...              % unit to use {'GHz' or 'pix'}
        'valuesRayleigh', [12.0 18.0], ...  % frequency range for Rayleigh peaks
        'valuesBrillouin', [7.5 12.0]  ...  % frequency range for Brillouin peaks
    ), ...
    'evaluation', struct( ...           % parameters for the evaluation
        'do', true, ...                 % execute evaluation?
        'interpRayleigh', true, ...     % interpolate Rayleigh peaks position?
        'minRayleighPeakHeight', 50 ... % minimum height of Rayleigh peaks
    )...
);

BrillouinEvaluation_Auto(filelist, parameters);
