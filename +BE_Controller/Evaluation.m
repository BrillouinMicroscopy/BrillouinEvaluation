function acquisition = Evaluation(model, view)
%% EVALUATION Controller

    %% callbacks Calibration
    set(view.evaluation.evaluate, 'Callback', {@evaluate, view, model});
    set(view.evaluation.newFig, 'Callback', {@openNewFig, view, model});
    
    set(view.evaluation.zoomIn, 'Callback', {@zoom, 'in', view});
    set(view.evaluation.zoomOut, 'Callback', {@zoom, 'out', view});
    set(view.evaluation.panButton, 'Callback', {@pan, view});
    set(view.evaluation.rotate3dButton, 'Callback', {@rotate3d, view});
    
    set(view.evaluation.plotTypes, 'Callback', {@selectPlotType, model});
    
    set(view.evaluation.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.evaluation.cap, 'Callback', {@setCameraParameters, model});
    set(view.evaluation.floor, 'Callback', {@setCameraParameters, model});
    
    set(view.evaluation.increaseFloor, 'Callback', {@increaseClim, model});
    set(view.evaluation.decreaseFloor, 'Callback', {@decreaseClim, model});
    set(view.evaluation.increaseCap, 'Callback', {@increaseClim, model});
    set(view.evaluation.decreaseCap, 'Callback', {@decreaseClim, model});
        
    acquisition = struct( ...
    ); 
end


function evaluate(~, ~, view, model)
    model.displaySettings.evaluation.preview = 0;
    totalPoints = (model.parameters.resolution.X*model.parameters.resolution.Y*model.parameters.resolution.Z);
    
    ind_Rayleigh = model.settings.peakSelection.Rayleigh(1,1):model.settings.peakSelection.Rayleigh(1,2);
    ind_Brillouin = model.settings.peakSelection.Brillouin(1,1):model.settings.peakSelection.Brillouin(1,2);
    
    nrPeaks = 1;
    parameters.peaks = [6 20];
    
    imgs = model.file.readPayloadData(1, 1, 1, 'data');
    img = imgs(:,:,1);
    spectrum = getIntensity1D(img, model.settings.extraction.interpolationPositions);
    spectrumSection = spectrum(ind_Rayleigh);
    [initRayleighPos, ~, ~] = fitLorentzDistribution(spectrumSection, model.settings.fitting.fwhm, nrPeaks, parameters.peaks, 0);
    intensity = NaN(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3));
    peaksBrillouin_pos = NaN(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3), nrPeaks);
    peaksBrillouin_fwhm = peaksBrillouin_pos;
    peaksBrillouin_max = peaksBrillouin_pos;
    peaksBrillouin_int = peaksBrillouin_pos;
    peaksRayleigh_pos = peaksBrillouin_pos;
    
    uu = 0;
    for jj = 1:1:model.parameters.resolution.X
        for kk = 1:1:model.parameters.resolution.Y
            for ll = 1:1:model.parameters.resolution.Z
                % read data from the file
                imgs = model.file.readPayloadData(jj, kk, ll, 'data');
                imgs = medfilt1(imgs,3);

                for mm = 1:size(imgs,3)
                    uu = uu + 1;
                    try 
                        img = imgs(:,:,mm);
                        spectrum = getIntensity1D(img, model.settings.extraction.interpolationPositions);
                        %%
                        intensity(kk, jj, ll, mm) = sum(img(:));

                        spectrumSection = spectrum(ind_Rayleigh);
                        [peakPos, ~, ~] = fitLorentzDistribution(spectrumSection, model.settings.fitting.fwhm, nrPeaks, parameters.peaks, 0);
                        peaksRayleigh_pos(kk, jj, ll, mm, :) = peakPos + min(ind_Rayleigh(:));

                        shift = round(peakPos - initRayleighPos);

                        secInd = ind_Brillouin + shift;
                        spectrumSection = spectrum(secInd);

                        [~, ind] = max(spectrumSection);
                        peaksBrillouin_max(kk, jj, ll, mm) = ind + min(secInd(:));

                        [peakPos, fwhm, int, ~, thres] = fitLorentzDistribution(spectrumSection, model.settings.fitting.fwhm, nrPeaks, parameters.peaks, 1);
                        peaksBrillouin_fwhm(kk, jj, ll, mm, :) = fwhm;
                        peaksBrillouin_pos(kk, jj, ll, mm, :) = peakPos + min(secInd(:));
                        peaksBrillouin_int(kk, jj, ll, mm, :) = int - thres;
                    catch e
                        disp(e);
                    end

                end
                finishedPoints = ((jj-1)*(model.parameters.resolution.Y*model.parameters.resolution.Z) + (kk-1)*model.parameters.resolution.Z + ll);
                prog = 100*finishedPoints/totalPoints;
                view.evaluation.progressBar.setValue(prog);
                view.evaluation.progressBar.setString(sprintf('%01.1f%%',prog));
            end
        end
    end
    
    if ~model.displaySettings.evaluation.preview
        brillouinShift = (peaksRayleigh_pos-peaksBrillouin_pos);
        model.results = struct( ...
            'BrillouinShift',       brillouinShift, ...      % [GHz]  the Brillouin shift
            'peaksBrillouin_pos',   peaksBrillouin_pos, ...  % [pix]  the position of the Brillouin peak(s) in the spectrum
            'peaksBrillouin_int',   peaksBrillouin_int, ...  % [a.u.] the intensity of the Brillouin peak(s)
            'peaksBrillouin_fwhm',  peaksBrillouin_fwhm, ... % [pix]  the FWHM of the Brillouin peak
            'peaksRayleigh_pos',    peaksRayleigh_pos, ...   % [pix]  the position of the Rayleigh peak(s) in the spectrum
            'intensity',            intensity ...            % [a.u.] the overall intensity of the image
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

function setCameraParameters(UIControl, ~, model)
    field = get(UIControl, 'Tag');
    model.displaySettings.evaluation.(field) = str2double(get(UIControl, 'String'));
end

function toggleAutoscale(~, ~, model, view)
    model.displaySettings.evaluation.autoscale = get(view.evaluation.autoscale, 'Value');
end

function decreaseClim(UIControl, ~, model)
    model.displaySettings.evaluation.autoscale = 0;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(model.displaySettings.evaluation.cap - model.displaySettings.evaluation.floor));
    model.displaySettings.evaluation.(field) = model.displaySettings.evaluation.(field) - dif;
end

function increaseClim(UIControl, ~, model)
    model.displaySettings.evaluation.autoscale = 0;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(model.displaySettings.evaluation.cap - model.displaySettings.evaluation.floor));
    model.displaySettings.evaluation.(field) = model.displaySettings.evaluation.(field) + dif;
end

function selectPlotType(src, ~, model)
    val = get(src,'Value');
    types = get(src,'String');
    model.displaySettings.evaluation.type = types{val};
end

function openNewFig(~, ~, view, model)
    view.evaluation.functions.plotData(view, model, 'ext');
end