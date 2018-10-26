function BrillouinEvaluation_Auto(filelist, parameters)
% function for automatically evaluating Brillouin data

%% start evaluation program
controllers = BrillouinEvaluation;
drawnow;

for jj = 1:length(filelist)
    try
        %% construct filename
        loadFile = [filelist(jj).folder filesep filelist(jj).name];
        if ~exist(loadFile, 'file')
            continue;
        end

        [~, name, ~] = fileparts(filelist(jj).name);
        saveFile = [filelist(jj).folder filesep '..' filesep 'EvalData' filesep name '.mat'];

        %% load the data file
        controllers.data.setActive();
        controllers.data.load(loadFile);
        controllers.data.setParameters(parameters);

        %% extract spectrum from image
        if parameters.extraction.do
            controllers.extraction.setActive();
            controllers.extraction.findPeaksAll();              % find the Rayleigh and Brillouin peaks
            drawnow;
        end

        %% calibrate measurement
        if parameters.calibration.do
            controllers.calibration.setActive();
        %         controllers.calibration.findPeaks();
        %         controllers.calibration.updateCalibration();
            controllers.calibration.calibrateAll();             % calibrate the frequency axis using all reference measurements
            drawnow;
        end

        %% select frequency range to evaluate
        if parameters.peakSelection.do
            controllers.peakSelection.setActive();
            if any(strcmp(parameters.peakSelection.unit, {'GHz', 'pix'}))
                 % select the frequency range which should be evaluated
                controllers.peakSelection.selectFrequencyRangeRayleigh(parameters.peakSelection.valuesRayleigh, parameters.peakSelection.unit);
                controllers.peakSelection.selectFrequencyRangeBrillouin(parameters.peakSelection.valuesBrillouin, parameters.peakSelection.unit);
            end
            drawnow;
        end

        %% evaluate
        if parameters.evaluation.do
            controllers.evaluation.setActive();
            controllers.evaluation.startEvaluation();
            drawnow;
        end

        %% save the data file
        controllers.data.save(saveFile);

        %% close the rawdata file
        controllers.data.closeFile();
    catch e
        disp(e);
    end
end
        
controllers.closeGUI();
