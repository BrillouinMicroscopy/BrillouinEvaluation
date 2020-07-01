function BrillouinEvaluation_Auto(filelist, parameters)
% function for automatically evaluating Brillouin data

%% start evaluation program
[controllers, model] = BrillouinEvaluation;
drawnow;

for jj = 1:length(filelist)
    try
        %% construct filename
        loadFile = [filelist(jj).folder filesep filelist(jj).name];
        if ~exist(loadFile, 'file')
            continue;
        end

        %% load the data file
        controllers.data.setActive();
        model.repetition = 0;
        controllers.data.load(loadFile);
        
        for ii = 0:(model.repetitionCount-1)
            try
                %% set current repetition
                controllers.data.setActive();
                model.repetition = ii;
                controllers.data.load([model.filepath model.filename]);
                controllers.data.setParameters(parameters);
                
                %% construct filename of save file
                [~, name, ~] = fileparts(filelist(jj).name);
                if (model.repetitionCount > 1)                    
                    saveFile = [filelist(jj).folder filesep '..' filesep 'EvalData' filesep name '_rep' num2str(model.repetition) '.mat'];
                else
                    saveFile = [filelist(jj).folder filesep '..' filesep 'EvalData' filesep name '.mat'];
                end

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
                
                    % calibrate the frequency axis using all reference measurements
                    controllers.calibration.calibrateAll(parameters.calibration.findPeaks);
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
                try
                    if parameters.evaluation.do
                        controllers.evaluation.setActive();
                        controllers.evaluation.startEvaluation();
                        drawnow;
                    end
                catch
                end

                %% save the data file
                controllers.data.save(saveFile);
            catch e
                disp(e);
            end
        end

        %% close the rawdata file
        controllers.data.closeFile();
    catch e
        disp(e);
    end
end
        
controllers.closeGUI();
