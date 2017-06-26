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
    set(view.evaluation.getbrightposition, 'Callback', {@getpstn, view, model});
    set(view.evaluation.startMasking, 'Callback', {@startMasking, view, model});
    
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
        'startEvaluation', @()startEvaluation(0, 0, view, model) ...
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
    
    if isempty(model.parameters.peakSelection.Rayleigh) || isempty(model.parameters.peakSelection.Brillouin)
        disp('Please select at least one Rayleigh and one Brillouin peak.');
        return;
    end
    
    ind_Rayleigh = model.parameters.peakSelection.Rayleigh(1,1):model.parameters.peakSelection.Rayleigh(1,2);
    ind_Brillouin = model.parameters.peakSelection.Brillouin(1,1):model.parameters.peakSelection.Brillouin(1,2);
    
    startTime = model.file.date;
    refTime = datetime(startTime, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    
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
    peaksRayleigh_fwhm = peaksBrillouin_pos;
    peaksRayleigh_int = peaksBrillouin_pos;
    times = peaksBrillouin_pos;
    validity = true(model.parameters.resolution.Y, model.parameters.resolution.X, model.parameters.resolution.Z, size(imgs,3));
    
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
                    
                    datestring = model.file.readPayloadData(jj, kk, ll, 'date');
                    date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
                    times(kk, jj, ll, :) = etime(datevec(date),datevec(refTime));

                    for mm = 1:size(imgs,3)
                        if ~model.status.evaluation.evaluate
                            break
                        end
                        img = imgs(:,:,mm);
                        
                        spectrum = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction.interpolationPositions);
                        %%
                        intensity(kk, jj, ll, mm) = sum(img(:));

                        spectrumSection = spectrum(ind_Rayleigh);
                        [peakPos, fwhm, int] = ...
                            BE_SharedFunctions.fitLorentzDistribution(spectrumSection, model.parameters.evaluation.fwhm, nrPeaks, parameters.peaks, 0);
                        peaksRayleigh_pos(kk, jj, ll, mm, :) = peakPos + min(ind_Rayleigh(:)) - 1;
                        peaksRayleigh_fwhm(kk, jj, ll, mm, :) = fwhm;
                        peaksRayleigh_int(kk, jj, ll, mm, :) = int;
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

                    end
                    if model.displaySettings.evaluation.preview

                        %% calculate the Brillouin shift in [pix]
                        brillouinShift = abs(peaksRayleigh_pos-peaksBrillouin_pos);
                        
                        %% calculate the Brillouin shift in [GHz]
                        calibration = model.parameters.calibration;
                        
                        wavelengthRayleigh = BE_SharedFunctions.getWavelengthFromMap(peaksRayleigh_pos, times, calibration);
                        wavelengthBrillouin = BE_SharedFunctions.getWavelengthFromMap(peaksBrillouin_pos, times, calibration);
                        
                        brillouinShift_frequency = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(wavelengthBrillouin, wavelengthRayleigh));
                        
                        %% save the results
                        results = model.results;
                        results.BrillouinShift            = brillouinShift;           % [pix]  the Brillouin shift in pixels
                        results.BrillouinShift_frequency  = brillouinShift_frequency; % [GHz]  the Brillouin shift in GHz
                        results.peaksBrillouin_pos        = peaksBrillouin_pos;       % [pix]  the position of the Brillouin peak(s) in the spectrum
                        results.peaksBrillouin_dev        = peaksBrillouin_dev;       % [pix]  the deviation of the Brillouin fit
                        results.peaksBrillouin_int        = peaksBrillouin_int;       % [a.u.] the intensity of the Brillouin peak(s)
                        results.peaksBrillouin_fwhm       = peaksBrillouin_fwhm;      % [pix]  the FWHM of the Brillouin peak
                        results.peaksRayleigh_pos         = peaksRayleigh_pos;        % [pix]  the position of the Rayleigh peak(s) in the spectrum
                        results.peaksRayleigh_int         = peaksRayleigh_int;        % [a.u.] the intensity of the Rayleigh peak(s)
                        results.peaksRayleigh_fwhm        = peaksRayleigh_fwhm;       % [pix]  the FWHM of the Rayleigh peak(s)
                        results.intensity                 = intensity;                % [a.u.] the overall intensity of the image
                        results.validity                  = validity;                 % [logical] the validity of the results
                        results.times                     = times;                    % [s]    time of the measurement
                        model.results = results;
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
    
    
    %% calculate the Brillouin shift in [pix]
    brillouinShift = abs(peaksRayleigh_pos-peaksBrillouin_pos);

    %% calculate the Brillouin shift in [GHz]
    calibration = model.parameters.calibration;
    
    wavelengthRayleigh = BE_SharedFunctions.getWavelengthFromMap(peaksRayleigh_pos, times, calibration);
    wavelengthBrillouin = BE_SharedFunctions.getWavelengthFromMap(peaksBrillouin_pos, times, calibration);
    
    brillouinShift_frequency = 1e-9*abs(BE_SharedFunctions.getFrequencyShift(wavelengthBrillouin, wavelengthRayleigh));
    
    %% save the results
    results = model.results;
    results.BrillouinShift            = brillouinShift;           % [pix]  the Brillouin shift in pixels
    results.BrillouinShift_frequency  = brillouinShift_frequency; % [GHz]  the Brillouin shift in GHz
    results.peaksBrillouin_pos        = peaksBrillouin_pos;       % [pix]  the position of the Brillouin peak(s) in the spectrum
    results.peaksBrillouin_dev        = peaksBrillouin_dev;       % [pix]  the deviation of the Brillouin fit
    results.peaksBrillouin_int        = peaksBrillouin_int;       % [a.u.] the intensity of the Brillouin peak(s)
    results.peaksBrillouin_fwhm       = peaksBrillouin_fwhm;      % [pix]  the FWHM of the Brillouin peak
    results.peaksRayleigh_pos         = peaksRayleigh_pos;        % [pix]  the position of the Rayleigh peak(s) in the spectrum
    results.peaksRayleigh_int         = peaksRayleigh_int;        % [a.u.] the intensity of the Rayleigh peak(s)
    results.peaksRayleigh_fwhm        = peaksRayleigh_fwhm;       % [pix]  the FWHM of the Rayleigh peak(s)
    results.intensity                 = intensity;                % [a.u.] the overall intensity of the image
    results.validity                  = validity;                 % [logical] the validity of the results
    results.times                     = times;                    % [s]    time of the measurement
    model.results = results;
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
    evaluation = model.displaySettings.evaluation;
    evaluation.preview = get(view.evaluation.livePreview, 'Value');
    if evaluation.preview
        evaluation.intFac = 1;
    end
    model.displaySettings.evaluation = evaluation;
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

    data = model.results.(model.displaySettings.evaluation.type);
    data = double(data);
    data = nanmean(data,4);
    %% find non-singleton dimensions
    dimensions = size(data);
    dimension = sum(dimensions > 1);
    
    %% define possible dimensions and their labels
    dims = {'Y', 'X', 'Z'};
    dimslabel = {'y', 'x', 'z'};

    nsdims = cell(dimension,1);
    otherdims = cell(dimension,1);
    nsdimslabel = cell(dimension,1);
    ind = 0;
    ind2 = 0;
    for jj = 1:length(dimensions)
        if dimensions(jj) > 1
            ind = ind + 1;
            nsdims{ind} = dims{jj};
            nsdimslabel{ind} = dimslabel{jj};
        else
            ind2 = ind2 + 1;
            otherdims{ind2} = dims{jj};
        end
    end
    
    if (dimension > 1)
        position.X = event.IntersectionPoint(1);
        position.Y = event.IntersectionPoint(2);
        position.Z = event.IntersectionPoint(3);
    else
        position.([nsdims{1}]) = event.IntersectionPoint(1);
        position.([otherdims{1}]) = 0;
        position.([otherdims{2}]) = 0;
    end
    
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

    [~, jj] = min(abs(x_lin-position.X));
    
    [~, kk] = min(abs(y_lin-position.Y));
    
    [~, ll] = min(abs(z_lin-position.Z));
    
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
    model.results.brightfield_rot = I;
    
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

function getpstn(~, ~, view, model)
    valids = ~isnan(model.results.brightfield_rot);
    if isempty(model.results.brightfield_rot) || sum(valids(:)) == 0
        disp('Please load a brightfield image first.');
        return;
    end
    if isempty(model.file)
        disp('Please load a Brillouin file first.');
        return;
    end
    if isfield(view.overlay, 'parent') && ishandle(view.overlay.parent)
        return;
    else
        parent = figure('Position',[500,200,900,650]);
        % hide the menubar and prevent resizing
        set(parent, 'menubar', 'none', 'Resize','off');
    end

    view.overlay = BE_View.Overlay(parent, model);

    BE_Controller.Overlay(model, view);
end

function startMasking(~, ~, view, model)
    if isfield(view.masking, 'parent') && ishandle(view.masking.parent)
        return;
    else
        parent = figure('Position',[500,200,900,650]);
        % hide the menubar and prevent resizing
        set(parent, 'menubar', 'none', 'Resize','off', 'units', 'pixels');
    end

    view.masking = BE_View.Masking(parent, model);

    BE_Controller.Masking(model, view);
end

