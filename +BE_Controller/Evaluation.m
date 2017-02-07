function acquisition = Evaluation(model, view)
%% EVALUATION Controller

    %% callbacks Calibration
    set(view.evaluation.evaluate, 'Callback', {@startEvaluation, view, model});
    set(view.evaluation.newFig, 'Callback', {@openNewFig, view, model});
    
    set(view.evaluation.livePreview, 'Callback', {@toggleLivePreview, view, model});
    
    set(view.evaluation.zoomIn, 'Callback', {@zoom, 'in', view});
    set(view.evaluation.zoomOut, 'Callback', {@zoom, 'out', view});
    set(view.evaluation.panButton, 'Callback', {@pan, view});
    set(view.evaluation.rotate3dButton, 'Callback', {@rotate3d, view});
    
    set(view.evaluation.plotTypes, 'Callback', {@selectPlotType, model});
    
    set(view.evaluation.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.evaluation.cap, 'Callback', {@setClim, model});
    set(view.evaluation.floor, 'Callback', {@setClim, model});
    
    set(view.evaluation.increaseFloor, 'Callback', {@changeClim, model, 1});
    set(view.evaluation.decreaseFloor, 'Callback', {@changeClim, model, -1});
    set(view.evaluation.increaseCap, 'Callback', {@changeClim, model, 1});
    set(view.evaluation.decreaseCap, 'Callback', {@changeClim, model, -1});
        
    acquisition = struct( ...
    ); 
end

function startEvaluation(~, ~, view, model)
    model.status.evaluation.evaluate = ~model.status.evaluation.evaluate;
    if model.status.evaluation.evaluate
        evaluate(view, model);
        model.status.evaluation.evaluate = 0;
    end
end

function evaluate(view, model)
    
    totalPoints = (model.parameters.resolution.X*model.parameters.resolution.Y*model.parameters.resolution.Z);
    
    ind_Rayleigh = model.parameters.peakSelection.Rayleigh(1,1):model.parameters.peakSelection.Rayleigh(1,2);
    ind_Brillouin = model.parameters.peakSelection.Brillouin(1,1):model.parameters.peakSelection.Brillouin(1,2);
    
    nrPeaks = 1;
    parameters.peaks = [6 20];
    
    imgs = model.file.readPayloadData(1, 1, 1, 'data');
    img = imgs(:,:,1);
    spectrum = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction.interpolationPositions);
    spectrumSection = spectrum(ind_Rayleigh);
    [initRayleighPos, ~, ~] = BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
    intensity = NaN(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3));
    peaksBrillouin_pos = NaN(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3), nrPeaks);
    peaksBrillouin_dev = peaksBrillouin_pos;
    peaksBrillouin_fwhm = peaksBrillouin_pos;
    peaksBrillouin_max = peaksBrillouin_pos;
    peaksBrillouin_int = peaksBrillouin_pos;
    peaksRayleigh_pos = peaksBrillouin_pos;
    
    uu = 0;
    for jj = 1:1:model.parameters.resolution.X
        if ~model.status.evaluation.evaluate
            break
        end
        for kk = 1:1:model.parameters.resolution.Y
            if ~model.status.evaluation.evaluate
                break
            end
            for ll = 1:1:model.parameters.resolution.Z
                if ~model.status.evaluation.evaluate
                    break
                end
                % read data from the file
                imgs = model.file.readPayloadData(jj, kk, ll, 'data');
                imgs = medfilt1(imgs,3);

                for mm = 1:size(imgs,3)
                    if ~model.status.evaluation.evaluate
                        break
                    end
                    uu = uu + 1;
                    try 
                        img = imgs(:,:,mm);
                        spectrum = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction.interpolationPositions);
                        %%
                        intensity(kk, jj, ll, mm) = sum(img(:));

                        spectrumSection = spectrum(ind_Rayleigh);
                        [peakPos, ~, ~] = BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
                        peaksRayleigh_pos(kk, jj, ll, mm, :) = peakPos + min(ind_Rayleigh(:)) - 1;

                        shift = round(peakPos - initRayleighPos);

                        secInd = ind_Brillouin + shift;
                        spectrumSection = spectrum(secInd);

                        [~, ind] = max(spectrumSection);
                        peaksBrillouin_max(kk, jj, ll, mm) = ind + min(secInd(:));

                        [peakPos, fwhm, int, ~, thres, deviation] = BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
                        peaksBrillouin_fwhm(kk, jj, ll, mm, :) = fwhm;
                        peaksBrillouin_dev(kk, jj, ll, mm, :) = deviation;
                        peaksBrillouin_pos(kk, jj, ll, mm, :) = peakPos + min(secInd(:)) - 1;
                        peaksBrillouin_int(kk, jj, ll, mm, :) = int - thres;
                        

                    catch e
                        disp(e);
                    end
                end
                if model.displaySettings.evaluation.preview
                    
                    wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * peaksRayleigh_pos, model.parameters.calibration.values_mean, model.parameters.constants, 1);
                    peaksRayleigh_pos_frequency = 1e-9*BE_SharedFunctions.getFrequencyShift(wavelength, model.parameters.constants.lambda0);
                    
                    wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * peaksBrillouin_pos, model.parameters.calibration.values_mean, model.parameters.constants, 1);
                    peaksBrillouin_pos_frequency = 1e-9*BE_SharedFunctions.getFrequencyShift(wavelength, model.parameters.constants.lambda0);
                    
                    brillouinShift = (peaksRayleigh_pos-peaksBrillouin_pos);
                    brillouinShift_frequency = (peaksRayleigh_pos_frequency-peaksBrillouin_pos_frequency);
                    model.results = struct( ...
                        'BrillouinShift',           brillouinShift, ...             % [pix]  the Brillouin shift in pixels
                        'BrillouinShift_frequency', brillouinShift_frequency, ...   % [GHz]  the Brillouin shift in Hz
                        'peaksBrillouin_pos',       peaksBrillouin_pos, ...         % [pix]  the position of the Brillouin peak(s) in the spectrum
                        'peaksBrillouin_dev',       peaksBrillouin_dev, ...         % [pix]  the deviation of the Brillouin fit
                        'peaksBrillouin_int',       peaksBrillouin_int, ...         % [a.u.] the intensity of the Brillouin peak(s)
                        'peaksBrillouin_fwhm',      peaksBrillouin_fwhm, ...        % [pix]  the FWHM of the Brillouin peak
                        'peaksRayleigh_pos',        peaksRayleigh_pos, ...          % [pix]  the position of the Rayleigh peak(s) in the spectrum
                        'intensity',                intensity ...                   % [a.u.] the overall intensity of the image
                    );
                end
                drawnow;
                
                finishedPoints = ((jj-1)*(model.parameters.resolution.Y*model.parameters.resolution.Z) + (kk-1)*model.parameters.resolution.Z + ll);
                prog = 100*finishedPoints/totalPoints;
                view.evaluation.progressBar.setValue(prog);
                view.evaluation.progressBar.setString(sprintf('%01.1f%%',prog));
            end
        end
    end
    
    if ~model.displaySettings.evaluation.preview
        wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * peaksRayleigh_pos, model.parameters.calibration.values_mean, model.parameters.constants, 1);
        peaksRayleigh_pos_frequency = 1e-9*BE_SharedFunctions.getFrequencyShift(wavelength, model.parameters.constants.lambda0);

        wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * peaksBrillouin_pos, model.parameters.calibration.values_mean, model.parameters.constants, 1);
        peaksBrillouin_pos_frequency = 1e-9*BE_SharedFunctions.getFrequencyShift(wavelength, model.parameters.constants.lambda0);

        brillouinShift = (peaksRayleigh_pos-peaksBrillouin_pos);
        brillouinShift_frequency = (peaksRayleigh_pos_frequency-peaksBrillouin_pos_frequency);
        model.results = struct( ...
            'BrillouinShift',           brillouinShift, ...             % [pix]  the Brillouin shift in pixels
            'BrillouinShift_frequency', brillouinShift_frequency, ...   % [GHz]  the Brillouin shift in GHz
            'peaksBrillouin_pos',       peaksBrillouin_pos, ...         % [pix]  the position of the Brillouin peak(s) in the spectrum
            'peaksBrillouin_dev',       peaksBrillouin_dev, ...         % [pix]  the deviation of the Brillouin fit
            'peaksBrillouin_int',       peaksBrillouin_int, ...         % [a.u.] the intensity of the Brillouin peak(s)
            'peaksBrillouin_fwhm',      peaksBrillouin_fwhm, ...        % [pix]  the FWHM of the Brillouin peak
            'peaksRayleigh_pos',        peaksRayleigh_pos, ...          % [pix]  the position of the Rayleigh peak(s) in the spectrum
            'intensity',                intensity ...                   % [a.u.] the overall intensity of the image
        );
    end
end

function zoom(src, ~, str, view)
switch get(src, 'UserData')
    case 0
        set(view.evaluation.panButton,'UserData',0);
        set(view.evaluation.panHandle,'Enable','off');
        set(view.evaluation.rotate3dButton,'UserData',0);
        set(view.evaluation.rotate3dHandle,'Enable','off');
        switch str
            case 'in'
                set(view.evaluation.zoomHandle,'Enable','on','Direction','in');
                set(view.evaluation.zoomIn,'UserData',1);
                set(view.evaluation.zoomOut,'UserData',0);
            case 'out'
                set(view.evaluation.zoomHandle,'Enable','on','Direction','out');
                set(view.evaluation.zoomOut,'UserData',1);
                set(view.evaluation.zoomIn,'UserData',0);
        end
    case 1
        set(view.evaluation.zoomHandle,'Enable','off','Direction','in');
        set(view.evaluation.zoomOut,'UserData',0);
        set(view.evaluation.zoomIn,'UserData',0);
end
        
end

function pan(src, ~, view)
    set(view.evaluation.zoomHandle,'Enable','off','Direction','in');
    set(view.evaluation.zoomOut,'UserData',0);
    set(view.evaluation.zoomIn,'UserData',0);
    set(view.evaluation.rotate3dButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.evaluation.panButton,'UserData',1);
            set(view.evaluation.panHandle,'Enable','on');
        case 1
            set(view.evaluation.panButton,'UserData',0);
            set(view.evaluation.panHandle,'Enable','off');
    end
end

function rotate3d(src, ~, view)
    set(view.evaluation.zoomHandle,'Enable','off','Direction','in');
    set(view.evaluation.zoomOut,'UserData',0);
    set(view.evaluation.zoomIn,'UserData',0);
    set(view.evaluation.panHandle,'Enable','off');
    set(view.evaluation.panButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.evaluation.rotate3dButton,'UserData',1);
            set(view.evaluation.rotate3dHandle,'Enable','on');
        case 1
            set(view.evaluation.rotate3dButton,'UserData',0);
            set(view.evaluation.rotate3dHandle,'Enable','off');
    end
end

function setClim(UIControl, ~, model)
    evaluation = model.displaySettings.evaluation;
    field = get(UIControl, 'Tag');
    evaluation.(field) = str2double(get(UIControl, 'String'));
    evaluation.autoscale = 0;
    model.displaySettings.evaluation = evaluation;
end

function toggleAutoscale(~, ~, model, view)
    model.displaySettings.evaluation.autoscale = get(view.evaluation.autoscale, 'Value');
end

function changeClim(UIControl, ~, model, sign)
    evaluation = model.displaySettings.evaluation;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(evaluation.cap - evaluation.floor));
    evaluation.autoscale = 0;
    evaluation.(field) = evaluation.(field) + sign * dif;
    model.displaySettings.evaluation = evaluation;
end

function selectPlotType(src, ~, model)
    val = get(src,'Value');
    types = get(src,'String');
    model.displaySettings.evaluation.type = types{val};
end

function toggleLivePreview(~, ~, view, model)
    model.displaySettings.evaluation.preview = get(view.evaluation.livePreview, 'Value');
end

function openNewFig(~, ~, view, model)
    view.evaluation.functions.plotData(view, model, 'ext');
end