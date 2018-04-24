%% script for automatically evaluating Brillouin data

% path to the file
        
filelist = dir('**/*.h5');

%% parameter structure
% use this configuration for new calibrations with water + methanol
peakTypes = {'R', 'B', 'B', 'B', 'B', 'R'};
% use this configuration for old calibrations with only water or methanol
% peakTypes = {'R', 'B', 'B', 'R', 'NaN'};

parameters = struct( ...
    'calibration', struct( ...          % parameters for the calibration
        'peakProminence', 15, ...       % the minimal prominence of the peaks
        'peakTypes', {peakTypes}, ...   % expected types of peaks
        'correctOffset', false, ...     % correct the calibration offset?
        'extrapolate', true, ...        % extrapolate the calibration?
        'weighted', false ...           % use weighting for calibration calculation?
    ), ...
    'evaluation', struct( ...           % parameters for the evaluation
        'interpRayleigh', true, ...     % interpolate Rayleigh peaks position?
        'minRayleighPeakHeight', 50 ... % minimum height of Rayleigh peaks
    )...
);

%%
% start evaluation program
controllers = BrillouinEvaluation;
drawnow;

for jj = 1:length(filelist)
    try
        %% construct filename
        loadFile = [filelist(jj).folder filesep filelist(jj).name];
        if ~exist(loadFile, 'file')
            continue;
        end

        [filepath,name,ext] = fileparts(filelist(jj).name);
        saveFile = [filelist(jj).folder filesep '..' filesep 'EvalData' filesep name '.mat'];

        %% load the data file
        controllers.data.setActive();
        controllers.data.load(loadFile);
        controllers.data.setParameters(parameters);

        %% extract spectrum from image
        controllers.extraction.setActive();
        controllers.extraction.findPeaks();                 % find the Rayleigh and Brillouin peaks
        drawnow;

        %% calibrate measurement
        controllers.calibration.setActive();
    %         controllers.calibration.findPeaks();
    %         controllers.calibration.updateCalibration();
        controllers.calibration.calibrateAll();             % calibrate the frequency axis using all reference measurements
        drawnow;

        %% select frequency range to evaluate
        controllers.peakSelection.setActive();
    %         controllers.peakSelection.selectFrequencyRangeRayleigh([250 330], 'pix');       % select the frequency range which should be evaluated
    %         controllers.peakSelection.selectFrequencyRangeBrillouin([190 250], 'pix');      % select the frequency range which should be evaluated
        controllers.peakSelection.selectFrequencyRangeRayleigh([12.0 18.0], 'GHz');       % select the frequency range which should be evaluated
        controllers.peakSelection.selectFrequencyRangeBrillouin([7.5 12.0], 'GHz');      % select the frequency range which should be evaluated
        drawnow;

        %% evaluate
        controllers.evaluation.setActive();
        controllers.evaluation.startEvaluation();
        drawnow;

        %% save the data file
        controllers.data.save(saveFile);

        %% close the rawdata file
        controllers.data.closeFile();
        
        controllers.closeGUI();
    catch
    end
end
