%% script for automatically evaluating Brillouin data

%% paths for loading and saving data
loadFile = 'RawData\Brillouin.h5';
saveFile = 'EvalData\Brillouin.mat';

%% parameter structure
% use this configuration for new calibrations with water + methanol
% peakTypes = {'R', 'B', 'B', 'B', 'B', 'R', 'NaN'};
% use this configuration for old calibrations with only water or methanol
peakTypes = {'R', 'B', 'B', 'R', 'NaN'};

parameters = struct( ...
    'calibration', struct( ...          % parameters for the calibration
        'peakProminence', 15, ...       % the minimal prominence of the peaks
        'peakTypes', {peakTypes}, ...   % expected types of peaks
        'correctOffset', false, ...     % correct the calibration offset?
        'extrapolate', true, ...        % extrapolate the calibration?
        'weighted', false ...           % use weighting for calibration calculation?
    ), ...
    'evaluation', struct( ...           % parameters for the evaluation
        'interpRayleigh', true ...      % interpolate Rayleigh peaks position?
    )...
);

%% evaluate
% start evaluation program
controllers = BrillouinEvaluation;
drawnow;

% load the data file
controllers.data.setActive();
controllers.data.load(loadFile);
controllers.data.setParameters(parameters);

% here calls for peak detection, extraction, calibration, etc will be
% necessary in the future (once possible)
controllers.extraction.setActive();
controllers.extraction.findPeaks();                 % find the Rayleigh and Brillouin peaks

controllers.calibration.setActive();
% controllers.calibration.updateCalibration();    % allow to update the calibration after setting 'extrapolate' or 'correctOffset'
controllers.calibration.calibrateAll();         % calibrate the frequency axis using all reference measurements

controllers.peakSelection.setActive();
% controllers.peakSelection.selectFrequencyRangeRayleigh([275 324], 'pix');       % select the frequency range which should be evaluated
% controllers.peakSelection.selectFrequencyRangeBrillouin([219 245], 'pix');      % select the frequency range which should be evaluated
controllers.peakSelection.selectFrequencyRangeRayleigh([13.1 17.6], 'GHz');     % select the frequency range which should be evaluated
controllers.peakSelection.selectFrequencyRangeBrillouin([8.75 10.75], 'GHz');   % select the frequency range which should be evaluated

% start the evaluation process
controllers.evaluation.setActive();
controllers.evaluation.startEvaluation();

% save the data file
controllers.data.save(saveFile);

% close the GUI
controllers.data.closeFile();