function acquisition = Evaluation(model, view)
%% EVALUATION Controller

    %% callbacks Calibration
    set(view.evaluation.evaluate, 'Callback', {@startEvaluation, view, model});
    set(view.evaluation.newFig, 'Callback', {@openNewFig, view, model});
    
    set(view.evaluation.livePreview, 'Callback', {@toggleLivePreview, view, model});
    set(view.evaluation.discardInvalid, 'Callback', {@toggleDiscardInvalid, view, model});
    
    set(view.evaluation.intFac, 'Callback', {@setValue, model, 'intFac'});
    set(view.evaluation.validity, 'Callback', {@setValue, model, 'valThreshould'});
    
    set(view.evaluation.showSpectrum, 'Callback', {@showSpectrum, view, model});
    set(view.evaluation.selectbright, 'Callback', {@selectbright, view, model});
    
    
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
    imgs = medfilt1(imgs,3);
    img = imgs(:,:,1);
    spectrum = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction.interpolationPositions);
    spectrumSection = spectrum(ind_Rayleigh);
    [initRayleighPos, ~, ~] = BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
    intensity = NaN(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3));
    peaksBrillouin_pos = NaN(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3), nrPeaks);
    peaksBrillouin_dev = peaksBrillouin_pos;
    peaksBrillouin_fwhm = peaksBrillouin_pos;
    peaksBrillouin_int = peaksBrillouin_pos;
    peaksRayleigh_pos = peaksBrillouin_pos;
    validity = true(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3));
    
    %% Calculate the initial value of which the shift of x0 has to be corrected
    initx0Shift = (initRayleighPos + min(ind_Rayleigh(:)) - 1) * model.parameters.constants.pixelSize;
    
    x0Shift = zeros(size(peaksBrillouin_pos));
    
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
                try
                    % read data from the file
                    imgs = model.file.readPayloadData(jj, kk, ll, 'data');
                    imgs = medfilt1(imgs,3);

                    for mm = 1:size(imgs,3)
                        if ~model.status.evaluation.evaluate
                            break
                        end
                        img = imgs(:,:,mm);
                        
                        spectrum = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction.interpolationPositions);
                        %%
                        intensity(kk, jj, ll, mm) = sum(img(:));

                        spectrumSection = spectrum(ind_Rayleigh);
                        [peakPos, ~, ~] = ...
                            BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
                        peaksRayleigh_pos(kk, jj, ll, mm, :) = peakPos + min(ind_Rayleigh(:)) - 1;
                        shift = round(peakPos - initRayleighPos);
                        
                        %% check if peak position is valid
                        if peakPos <= 0 || peakPos >= length(ind_Rayleigh)
                            validity(kk, jj, ll, mm) = false;
                        end


                        secInd = ind_Brillouin + shift;
                        spectrumSection = spectrum(secInd);

                        [peakPos, fwhm, int, ~, thres, deviation] = ...
                            BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
                        
                        
                        %% check if peak position is valid
                        if peakPos <= 0 || peakPos >= length(secInd)
                            validity(kk, jj, ll, mm) = false;
                        end
                        
                        peaksBrillouin_fwhm(kk, jj, ll, mm, :) = fwhm;
                        peaksBrillouin_dev(kk, jj, ll, mm, :) = deviation;
                        peaksBrillouin_pos(kk, jj, ll, mm, :) = peakPos + min(secInd(:)) - 1;
                        peaksBrillouin_int(kk, jj, ll, mm, :) = int - thres;
                        
                        %% calculate the value of which x0 has to be shifted for each measurement point
                        x0Shift(kk, jj, ll, mm) = peaksRayleigh_pos(kk, jj, ll, mm) * model.parameters.constants.pixelSize - initx0Shift;

                    end
                    if model.displaySettings.evaluation.preview

                        %% adjust calibration accordingly to the shift of x0
                        calibration = model.parameters.calibration.values_mean;
                        calibration.x0Shift = x0Shift;
                        calibration.x0 = calibration.x0Initial + calibration.x0Shift;

                        %% calculate the frequency of the Rayleigh and Brillouin peak
                        wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * peaksRayleigh_pos, ...
                            calibration, model.parameters.constants, 1);
                        peaksRayleigh_pos_frequency = 1e-9*BE_SharedFunctions.getFrequencyShift(wavelength, model.parameters.constants.lambda0);

                        wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * peaksBrillouin_pos, ...
                            calibration, model.parameters.constants, 1);
                        peaksBrillouin_pos_frequency = 1e-9*BE_SharedFunctions.getFrequencyShift(wavelength, model.parameters.constants.lambda0);

                        brillouinShift = abs(peaksRayleigh_pos-peaksBrillouin_pos);
                        brillouinShift_frequency = abs(peaksRayleigh_pos_frequency-peaksBrillouin_pos_frequency);
                        model.results = struct( ...
                            'BrillouinShift',           brillouinShift, ...             % [pix]  the Brillouin shift in pixels
                            'BrillouinShift_frequency', brillouinShift_frequency, ...   % [GHz]  the Brillouin shift in Hz
                            'peaksBrillouin_pos',       peaksBrillouin_pos, ...         % [pix]  the position of the Brillouin peak(s) in the spectrum
                            'peaksBrillouin_dev',       peaksBrillouin_dev, ...         % [pix]  the deviation of the Brillouin fit
                            'peaksBrillouin_int',       peaksBrillouin_int, ...         % [a.u.] the intensity of the Brillouin peak(s)
                            'peaksBrillouin_fwhm',      peaksBrillouin_fwhm, ...        % [pix]  the FWHM of the Brillouin peak
                            'peaksRayleigh_pos',        peaksRayleigh_pos, ...          % [pix]  the position of the Rayleigh peak(s) in the spectrum
                            'intensity',                intensity, ...                  % [a.u.] the overall intensity of the image
                            'validity',                 validity ...                    % [logical] the validity of the results
                        );
                    end
                    drawnow;

                    finishedPoints = ((jj-1)*(model.parameters.resolution.Y*model.parameters.resolution.Z) + (kk-1)*model.parameters.resolution.Z + ll);
                    prog = 100*finishedPoints/totalPoints;
                    view.evaluation.progressBar.setValue(prog);
                    view.evaluation.progressBar.setString(sprintf('%01.1f%%',prog));
                catch e
                    disp(e);
                end
            end
        end
    end
    
    %% save corrected calibration
    calibration = model.parameters.calibration.values_mean;
    calibration.x0Shift = x0Shift;
    calibration.x0 = calibration.x0Initial + calibration.x0Shift;
    model.parameters.calibration.values_mean = calibration;
    
    %% calculate and save the Brillouin shift
    if ~model.displaySettings.evaluation.preview
        wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * peaksRayleigh_pos, ...
            model.parameters.calibration.values_mean, model.parameters.constants, 1);
        peaksRayleigh_pos_frequency = 1e-9*BE_SharedFunctions.getFrequencyShift(wavelength, model.parameters.constants.lambda0);

        wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * peaksBrillouin_pos, ...
            model.parameters.calibration.values_mean, model.parameters.constants, 1);
        peaksBrillouin_pos_frequency = 1e-9*BE_SharedFunctions.getFrequencyShift(wavelength, model.parameters.constants.lambda0);

        brillouinShift = abs(peaksRayleigh_pos-peaksBrillouin_pos);
        brillouinShift_frequency = abs(peaksRayleigh_pos_frequency-peaksBrillouin_pos_frequency);
        model.results = struct( ...
            'BrillouinShift',           brillouinShift, ...             % [pix]  the Brillouin shift in pixels
            'BrillouinShift_frequency', brillouinShift_frequency, ...   % [GHz]  the Brillouin shift in GHz
            'peaksBrillouin_pos',       peaksBrillouin_pos, ...         % [pix]  the position of the Brillouin peak(s) in the spectrum
            'peaksBrillouin_dev',       peaksBrillouin_dev, ...         % [pix]  the deviation of the Brillouin fit
            'peaksBrillouin_int',       peaksBrillouin_int, ...         % [a.u.] the intensity of the Brillouin peak(s)
            'peaksBrillouin_fwhm',      peaksBrillouin_fwhm, ...        % [pix]  the FWHM of the Brillouin peak
            'peaksRayleigh_pos',        peaksRayleigh_pos, ...          % [pix]  the position of the Rayleigh peak(s) in the spectrum
            'intensity',                intensity, ...                  % [a.u.] the overall intensity of the image
            'validity',                 validity ...                    % [logical] the validity of the results
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

function toggleDiscardInvalid(~, ~, view, model)
    model.displaySettings.evaluation.discardInvalid = get(view.evaluation.discardInvalid, 'Value');
end

function setValue(src, ~, model, value)
    model.displaySettings.evaluation.(value) = str2double(get(src, 'String'));
end

function openNewFig(~, ~, view, model)
    view.evaluation.functions.plotData(view, model, 'ext');
end

function showSpectrum(~, ~, view, model)
     model.status.evaluation.showSpectrum = ~model.status.evaluation.showSpectrum;
     if model.status.evaluation.showSpectrum
            set(model.handles.results,'ButtonDownFcn',{@ImageClickCallback model});
            set(view.evaluation.axesImage,'ButtonDownFcn',{@ImageClickCallback model});
     else
            set(model.handles.results,'ButtonDownFcn',[]);
            set(view.evaluation.axesImage,'ButtonDownFcn',[]);
    end
end

function ImageClickCallback(~, event, model)

    x = event.IntersectionPoint(1);
    y = event.IntersectionPoint(2);
    z = event.IntersectionPoint(3);
    
    positions.X = ...
            model.parameters.positions.X - mean(model.parameters.positions.X(:));
    positions.Y = ...
            model.parameters.positions.Y - mean(model.parameters.positions.Y(:));
    positions.Z = ...
            model.parameters.positions.Z - mean(model.parameters.positions.Z(:));
    
    x_min = min(positions.X(:));
    x_max = max(positions.X(:));

    x_lin = linspace(x_min,x_max,model.parameters.resolution.X);
    
    y_min = min(positions.Y(:));
    y_max = max(positions.Y(:));

    y_lin = linspace(y_min,y_max,model.parameters.resolution.Y);
    
    z_min = min(positions.Z(:));
    z_max = max(positions.Z(:));

    z_lin = linspace(z_min,z_max,model.parameters.resolution.Z);

    [~, jj] = min(abs(x_lin-x));
    
    [~, kk] = min(abs(y_lin-y));
    
    [~, ll] = min(abs(z_lin-z));
    
    imgs = model.file.readPayloadData(jj, kk, ll, 'data');
    
    spectrum = BE_SharedFunctions.getIntensity1D(imgs(:,:,1), model.parameters.extraction.interpolationPositions);
    
    figure(123);
    imagesc(imgs(:,:,1));
    caxis([100 500]);
    
    figure(124);
    plot(spectrum);
    ylim([100 500]);
end

function selectbright(~, ~, ~, model)

    defaultFileName = fullfile(pwd, '*.png');
    [baseFileName, folder] = uigetfile(defaultFileName, 'Select a file');
    if baseFileName == 0
        return;
    end
    
    fullFileName = fullfile(folder, baseFileName);

    I = imread(fullFileName);
    I = I(:,:,1);
    I = imcrop(I, [600 500 1500 1500]);
    model.results.brightfield_raw = I;

%     brillouin = model.results.BrillouinShift_frequency;
%     figure1 = figure(372);
%     t = uitoolbar(figure1);
%     
%     ax1 = axes('Parent', figure1);
%     ax2 = axes('Parent', figure1);
%     
%     set(ax1,'Visible', 'off');
%     set(ax2,'Visible', 'on');
%     
%     a = imread(brillouin);
%     imshow(a, 'Parent',ax1);
%     hold on;
%     imshow(I, 'Parent',ax2);
%     hold off;
%     alpha(0.5);
%     
%     [img, map] = imread(fullfile(matlabroot,...
%                     'toolbox','matlab','icons','matlabicon.gif'));
%     
%     icon = ind2rgb(img,map);
%     
%     p = uipushtool(t,'TooltipString', 'Toolbar push button',...
%                     'ClickedCallback', {@getpopstn,view,model});
%     p.CData = icon;
    
    overlayBrightfield(model);
end
    
function overlayBrightfield(model)

    model.parameters.evaluation.scaling = 0.086;
    model.parameters.evaluation.centerx = 800;
    model.parameters.evaluation.centery = 860;
    model.parameters.evaluation.rotationAngle = -135;

    scaling = model.parameters.evaluation.scaling;   % [micro m / pix]   scaling factor
    
    dims = {'Y', 'X', 'Z'};
    for jj = 1:length(dims)
        positions.([dims{jj} '_zm']) = ...
            model.parameters.positions.(dims{jj}) - mean(model.parameters.positions.(dims{jj})(:))*ones(size(model.parameters.positions.(dims{jj})));
    end
    
    maxx = max(max(positions.X_zm));
    minx = min(min(positions.X_zm));
    maxy = max(max(positions.Y_zm));
    miny = min(min(positions.Y_zm));
    
    width = (maxx - minx)/(scaling);
    height = (maxy - miny)/(scaling);
    
    startx = model.parameters.evaluation.centerx - width/2;
    starty = model.parameters.evaluation.centery - height/2;

    I = imrotate(model.results.brightfield_raw, model.parameters.evaluation.rotationAngle);
    
    I = imcrop(I, [startx starty width height]);
    
    x = linspace(minx, maxx, size(I,2));
    y = linspace(miny, maxy, size(I,1));
    [X,Y,Z] = meshgrid(x, y, 1);
    
    parameters = model.parameters;
    parameters.positions_brightfield.X = X;
    parameters.positions_brightfield.Y = Y;
    parameters.positions_brightfield.Z = Z;
    model.parameters = parameters;
    
    model.results.brightfield = I;
end

