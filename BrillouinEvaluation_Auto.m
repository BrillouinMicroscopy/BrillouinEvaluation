%% script for automatically evaluating Brillouin data

% path to the file
loadFile = 'RawData\Brillouin.h5';
saveFile = 'EvalData\Brillouin.mat';

% start evaluation program
controllers = BrillouinEvaluation;

% load the data file
controllers.data.load(loadFile);

% here calls for peak detection, extraction, calibration, etc will be
% necessary in the future (once possible)
controllers.extraction.findPeaks();                 % find the Rayleigh and Brillouin peaks
% controllers.calibration.calibrateAll();             % calibrate the frequency axis using all reference measurements
% controllers.peakSelection.selectFrequencyRangeRayleigh([275 324], 'pix');       % select the frequency range which should be evaluated
% controllers.peakSelection.selectFrequencyRangeBrillouin([219 245], 'pix');      % select the frequency range which should be evaluated
% controllers.peakSelection.selectFrequencyRangeRayleigh([13.1 17.6], 'GHz');       % select the frequency range which should be evaluated
% controllers.peakSelection.selectFrequencyRangeBrillouin([8.75 10.75], 'GHz');      % select the frequency range which should be evaluated

% start the evaluation process
controllers.evaluation.startEvaluation();

% save the data file
controllers.data.save(saveFile);

% close the GUI
controllers.data.close();