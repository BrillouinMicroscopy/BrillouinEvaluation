function Calibration(view, model)
%% CALIBRATION View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onSettings(view, e.AffectedObject));
    addlistener(model, 'displaySettings', 'PostSet', ...
        @(o,e) onDisplaySettings(view, e.AffectedObject));
    addlistener(model, 'status', 'PostSet', ...
        @(o,e) onStatus(view, e.AffectedObject));
end

function initGUI(model, view)
    parent = view.calibration.parent;

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Select sample:', 'Units', 'normalized',...
        'Position', [0.02,0.944,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');

    samples = uicontrol('Parent', parent, 'Style','popup', 'Units', 'normalized','Position',[0.02 0.889,0.18,0.055],...
        'String',{''},'FontSize', 11, 'HorizontalAlignment', 'left');

    openBrillouinShift = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/fullscreen.png']) ,'Position',[0.205,0.904,0.035,0.041],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    imageNrLabel = uicontrol('Parent', parent, 'Style', 'text', 'String', 'Image:', 'Units', 'normalized',...
        'Position', [0.02,0.862,0.08,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    imageNr = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.17,0.859,0.07,0.04], 'FontSize', 11, 'HorizontalAlignment', 'center');
    
    findPeaks = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String', 'Find peaks', 'Position',[0.15,0.810,0.09,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Brillouin peaks:', 'Units', 'normalized',...
        'Position', [0.02,0.765,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    selectBrillouin = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Select','Position',[0.19,0.762,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    clearBrillouin = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.135,0.762,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    peakTableBrillouin = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.65 0.22 0.106], ...
        'ColumnWidth', {40, 40, 75}, 'ColumnName', {'start','end','shift [GHz]'}, 'FontSize', 12, 'ColumnEditable', true);

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Rayleigh peaks:', 'Units', 'normalized',...
        'Position', [0.02,0.595,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    selectRayleigh = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Select','Position',[0.19,0.591,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    clearRayleigh = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.135,0.591,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    peakTableRayleigh = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.479 0.22 0.106], ...
        'ColumnWidth', {80, 75}, 'ColumnName', {'start','end'}, 'FontSize', 12, 'ColumnEditable', true);
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Overlay measurement', 'Units', 'normalized',...
        'Position', [0.02,0.43,0.2,0.04], 'FontSize', 11, 'HorizontalAlignment', 'left');

    overlay = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.224,0.434,0.02,0.04], 'FontSize', 11, 'HorizontalAlignment', 'left', 'tag', 'Positions');
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Fitted values:', 'Units', 'normalized',...
        'Position', [0.02,0.30,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    valuesTable = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.20 0.22 0.23], ...
        'ColumnWidth', {40, 40, 40, 60, 30, 30}, 'ColumnName', {'A', 'B', 'C', 'FSR [GHz]', ...
        '<html>&#963;</html>', 'active'}, 'FontSize', 10, 'ColumnEditable', true, ...
        'ColumnFormat',[repmat({[]},1,6),'logical']);
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Extrapolate:', 'Units', 'normalized',...
        'Position', [0.02,0.075,0.1,0.028], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    extrapolate = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.223,0.07,0.04,0.03], 'FontSize', 11, 'HorizontalAlignment', 'left');
   
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Weighting:', 'Units', 'normalized',...
        'Position', [0.02,0.045,0.1,0.028], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    weighted = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.223,0.04,0.04,0.03], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Correct offset:', 'Units', 'normalized',...
        'Position', [0.02,0.015,0.15,0.028], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    correctOffset = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.223,0.01,0.04,0.03], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    progressBar = javax.swing.JProgressBar;
    javacomponent(progressBar,[19,70,70,27.5],parent);
    progressBar.setValue(0);
    progressBar.setStringPainted(true);
    progressBar.setString('0%');
    
    clearCalibration = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.105,0.11,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    doCalibration = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Calibrate','Position',[0.16,0.11,0.08,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    zoomIn = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/zoomin.png']), 'Position',[0.33,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(zoomIn, 'UserData', 0);
    
    zoomOut = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/zoomout.png']), 'Position',[0.375,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(zoomOut, 'UserData', 0);
    
    panButton = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/pan.png']), 'Position',[0.42,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(panButton, 'UserData', 0);

    cursorButton = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/cursor.png']), 'Position',[0.465,0.92,0.0375,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    set(cursorButton, 'UserData', 0);

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Autoscale', 'Units', 'normalized',...
        'Position', [0.51,0.928,0.1,0.035], 'FontSize', 10, 'HorizontalAlignment', 'left');

    autoscale = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.58,0.93,0.017,0.034], 'FontSize', 11, 'HorizontalAlignment', 'left');

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Floor', 'Units', 'normalized',...
        'Position', [0.60,0.91,0.1,0.055], 'FontSize', 11, 'HorizontalAlignment', 'left');

    floor = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.65,0.92,0.075,0.055], 'FontSize', 11, 'HorizontalAlignment', 'center', 'Tag', 'floor');

    increaseFloor = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/up.png']), 'Position',[0.74,0.9475,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'floor');

    decreaseFloor = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/down.png']), 'Position',[0.74,0.92,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'floor');

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Cap', 'Units', 'normalized',...
        'Position', [0.79,0.91,0.1,0.055], 'FontSize', 11, 'HorizontalAlignment', 'left');

    cap = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.83,0.92,0.075,0.055], 'FontSize', 11, 'HorizontalAlignment', 'center', 'Tag', 'cap');

    increaseCap = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/up.png']), 'Position',[0.92,0.9475,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'cap');

    decreaseCap = uicontrol('Parent', parent, 'Style','pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/down.png']), 'Position',[0.92,0.92,0.0325,0.0275],...
        'FontSize', 11, 'HorizontalAlignment', 'left', 'Tag', 'cap');
    
    axesImage = axes('Parent', parent, 'Position', [0.33 .085 .65 .8]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
%     zoom(gcf,'reset');
    zoomHandle = zoom;
    panHandle = pan;
    brushHandle = brush;
    cursorHandle = datacursormode;
    
    %% Return handles
    view.calibration = struct(...
        'parent', parent, ...
        'samples', samples, ...
        'imageNrLabel', imageNrLabel, ...
        'imageNr', imageNr, ...
        'findPeaks', findPeaks, ...
        'selectBrillouin', selectBrillouin, ...
        'clearBrillouin', clearBrillouin, ...
        'peakTableBrillouin', peakTableBrillouin, ...
        'selectRayleigh', selectRayleigh, ...
        'clearRayleigh', clearRayleigh, ...
        'peakTableRayleigh', peakTableRayleigh, ...
        'overlay', overlay, ...
        'valuesTable', valuesTable, ...
        'progressBar', progressBar, ...
        'clearCalibration', clearCalibration, ...
        'calibrateButton', doCalibration, ...
        'zoomIn', zoomIn, ...
        'zoomOut', zoomOut, ...
        'panButton', panButton, ...
        'cursorButton', cursorButton, ...
        'autoscale', autoscale, ...
        'cap', cap, ...
        'floor', floor, ...
        'increaseCap', increaseCap, ...
        'decreaseCap', decreaseCap, ...
        'increaseFloor', increaseFloor, ...
        'decreaseFloor', decreaseFloor, ...
        'axesImage', axesImage, ...
        'zoomHandle', zoomHandle, ...
        'panHandle', panHandle, ...
        'brushHandle', brushHandle, ...
        'cursorHandle', cursorHandle, ...
        'openBrillouinShift', openBrillouinShift, ...
        'extrapolate', extrapolate, ...
        'weighted', weighted, ...
        'correctOffset', correctOffset ...
	);
end

function initView(view, model)
%% Initialize the view
    handles = view.calibration;
    set(handles.autoscale, 'Value', model.displaySettings.peakSelection.autoscale);
    set(handles.cap, 'String', model.displaySettings.peakSelection.cap);
    set(handles.floor, 'String', model.displaySettings.peakSelection.floor);
    set(handles.extrapolate, 'Value', model.parameters.calibration.extrapolate);
    set(handles.weighted, 'Value', model.parameters.calibration.weighted);
    set(handles.correctOffset, 'Value', model.parameters.calibration.correctOffset);
end

function onSettings(view, model)
    handles = view.calibration;
    if isempty(fields(model.parameters.calibration.samples))
        return;
    end
    set(handles.samples, 'String', fields(model.parameters.calibration.samples));
    set(handles.samples, 'Value', model.parameters.calibration.selectedValue);
    sample = model.parameters.calibration.samples.(model.parameters.calibration.selected);
    
    if strcmp(model.parameters.calibration.selected, 'measurement')
        set(handles.imageNrLabel, 'Visible', 'on');
        set(handles.imageNr, 'Visible', 'on');
    else
        set(handles.imageNrLabel, 'Visible', 'off');
        set(handles.imageNr, 'Visible', 'off');
    end
    set(handles.extrapolate, 'Value', model.parameters.calibration.extrapolate);
    set(handles.weighted, 'Value', model.parameters.calibration.weighted);
    set(handles.correctOffset, 'Value', model.parameters.calibration.correctOffset);
    set(handles.overlay, 'Value', sample.overlay);
    data = sample.indBrillouin;
    data(:,3) = sample.shift(1);
    handles.peakTableBrillouin.Data = data;
    handles.peakTableRayleigh.Data = sample.indRayleigh;

    v = sample.values;
    if ~isempty(v.A)
        leng = size(v.A,2);
        v.A = 1e6*v.A;
        v.B = 1e13*v.B;
        v.C = 1e16*v.C;
        v.FSR = 1e-9*v.FSR;
        parameters = {'A', 'B', 'C', 'FSR', 'error'};
        formats = {'%2.5f', '%2.5f', '%2.5f', '%2.3f', '%2.4f'};
        fittedValues = cell(leng,6);
        for jj = 1:length(parameters)
            for ii = 1:leng
                fittedValues{ii,jj} = sprintf(formats{jj},v.(parameters{jj})(1,ii));
            end
        end
        fittedValues(:,6) = num2cell(logical(sample.active));
    else
        fittedValues = [];
    end
    handles.valuesTable.Data = fittedValues;
    plotData(handles, model);
    updateBrillouinShifts(view, model);
end

function updateBrillouinShifts(view, model)
    if isfield(view.calibration, 'BrillouinShiftView') && ishandle(view.calibration.BrillouinShiftView)
        calibration = model.parameters.calibration;

        BrillouinShiftsS = NaN(1,2);
        BrillouinShiftsAS = BrillouinShiftsS;
        BrillouinShiftsS_mean = BrillouinShiftsS;
        BrillouinShiftsAS_mean = BrillouinShiftsAS;
        calibrationFrequency = NaN(1,1);

        sampleNames = fields(calibration.samples);
        totalImages = 0;
        for jj = 1:length(sampleNames)
            sample = calibration.samples.(sampleNames{jj});
            if isfield(sample, 'BrillouinShift')
                shift = sample.BrillouinShift;
                nrImages = size(shift,1);
                for kk = 1:length(sample.shift)
                    BrillouinShiftsS((totalImages + (1:nrImages)), kk) = shift(:,kk);
                    BrillouinShiftsAS((totalImages + (1:nrImages)), kk) = shift(:,end-kk+1);
                    BrillouinShiftsS_mean((totalImages + (1:nrImages)), kk) = repmat(nanmean(shift(:,kk),1), nrImages, 1);
                    BrillouinShiftsAS_mean((totalImages + (1:nrImages)), kk) = repmat(nanmean(shift(:,end-kk+1),1), nrImages, 1);
                end
                calibrationFrequency((totalImages + (1:nrImages)), 1:length(sample.shift)) = ones(nrImages,1) * sample.shift;
            else
                nrImages = 1;
                BrillouinShiftsS((totalImages + (1:nrImages)), :) = NaN;
                BrillouinShiftsAS((totalImages + (1:nrImages)), :) = NaN;
                BrillouinShiftsS_mean((totalImages + (1:nrImages)), :) = NaN;
                BrillouinShiftsAS_mean((totalImages + (1:nrImages)), :) = NaN;
            end
            totalImages = totalImages + nrImages;
        end

        BrillouinShiftsS(BrillouinShiftsS == 0) = NaN;
        BrillouinShiftsAS(BrillouinShiftsAS == 0) = NaN;
        BrillouinShiftsS_mean(BrillouinShiftsS_mean == 0) = NaN;
        BrillouinShiftsAS_mean(BrillouinShiftsAS_mean == 0) = NaN;
        calibrationFrequency(calibrationFrequency == 0) = NaN;
        
        ax = view.calibration.BrillouinShiftView.CurrentAxes;
        hold(ax, 'off');
        Stokes = plot(ax, BrillouinShiftsS, 'color', [0 0.4470 0.7410]);
        hold(ax, 'on');
        Stokes_m = plot(ax, BrillouinShiftsS_mean, 'LineStyle', '--', 'LineWidth', 0.8, 'color', [0 0.4470 0.7410]);
        AntiStokes = plot(ax, BrillouinShiftsAS, 'color', [0.9290 0.6940 0.1250]);
        AntiStokes_m = plot(ax, BrillouinShiftsAS_mean, 'LineStyle', '--', 'LineWidth', 0.8, 'color', [0.9290 0.6940 0.1250]);
        ax.ColorOrderIndex = 3;
        calibration = plot(ax, 1e-9*calibrationFrequency, 'color', [0.8500 0.3250 0.0980]);
        xlabel(ax, 'Calibration image #');
        ylabel(ax, '$f$ [GHz]', 'interpreter', 'latex');
        if sum(~isnan(BrillouinShiftsS(:)))
    %         leg = legend('Stokes Peak', 'AntiStokes Peak', 'Stokes Peak Mean', 'AntiStokes Peak Mean', 'Calibration Frequency');
            leg = legend(ax, [Stokes(1); Stokes_m(1); AntiStokes(1); AntiStokes_m(1); calibration(1)], ...
                'Stokes Peak', 'Stokes Peak Mean', 'AntiStokes Peak', 'AntiStokes Peak Mean', 'Calibration Frequency');
            if size(BrillouinShiftsS_mean,2) > 1
                set(leg, 'Location', 'East');
            else
                set(leg, 'Location', 'NorthEast');
            end
        end
        
    end
end

function onStatus(view, model)
    handles = view.calibration;
    buttons = {'Brillouin', 'Rayleigh'};
    for jj = 1:length(buttons)
        if model.status.calibration.(['select' buttons{jj}])
            label = 'Done';
        else
            label = 'Select';
        end
        set(handles.(['select' buttons{jj}]), 'String', label);
    end
end

function plotData(handles, model)
    %% store often used values in separate variables for convenience
    calibration = model.parameters.calibration;         % general calibration
    selectedMeasurement = calibration.selected;
    sample = calibration.samples.(selectedMeasurement); % selected sample
    
    try
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        refTime = datetime(model.file.date, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    
    mm = 1;     % selected image
    %% Plot
    ax = handles.axesImage;
    if strcmp(selectedMeasurement, 'measurement')
        imgs = model.controllers.data.getPayload('data', sample.imageNr.x, sample.imageNr.y, sample.imageNr.z);
        datestring = model.controllers.data.getPayload('date', sample.imageNr.x, sample.imageNr.y, sample.imageNr.z);
    else
        imgs = model.controllers.data.getCalibration('data', sample.position);
        datestring = model.controllers.data.getCalibration('date', sample.position);
    end
    try
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    time = etime(datevec(date),datevec(refTime));
    
    imgs = medfilt1(imgs,3);
    img = nanmean(imgs, 3);
    %% Overlay the calibration image with a measurement image if requested
    if sample.overlay
        img = BE_SharedFunctions.overlayMeasurementImage(model, img, calibration.selectedValue);
    end
    data = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction, time);
    if ~isempty(data)
        hold(ax, 'off');
        xLabelString = '$f$ [pix]';
        
        minData = min(data, [], 'all');
        maxData = max(data, [], 'all');
        deltaData = maxData - minData;
        minData = minData - 0.03 * deltaData;
        maxData = maxData + 0.03 * deltaData;
        
        peaksMeasured = [];
        peaksFitted = [];
        x = 1:length(data);
        if ~sum(isempty(sample.values.A)) && ~sum(isnan(sample.values.A))
            peaksMeasured = model.parameters.calibration.samples.(selectedMeasurement).peaksMeasured(mm,:);
            peaksFitted = model.parameters.calibration.samples.(selectedMeasurement).peaksFitted(mm,:);

            params = {'A', 'B', 'C', 'FSR'};
            VIPAparams = NaN(length(params),1);
            for jj = 1:length(params)
                VIPAparams(jj) = sample.values.(params{jj})(mm);
            end
            x = BE_SharedFunctions.getFrequency(x, VIPAparams, model.parameters.constants_setup.f_0);
            
            peaksMeasured = BE_SharedFunctions.getFrequency(peaksMeasured, VIPAparams, model.parameters.constants_setup.f_0);
            peaksFitted = BE_SharedFunctions.getFrequency(peaksFitted, VIPAparams, model.parameters.constants_setup.f_0);
            
            xLabelString = '$f$ [GHz]';
        end
        
        model.handles.calibration.plotSpectrum = plot(ax, x, data);
        hold(ax, 'on');
        ind = model.parameters.calibration.samples.(selectedMeasurement).indRayleigh;
        for jj = 1:size(ind,1)
            ix = ind(jj,1):ind(jj,2);
            if ind(jj,1) > 0 && ind(jj,2) <= length(data)
                plot(ax, x(ix), data(ix), 'color', [1, 0, 0, 0.4], 'linewidth', 5);
            end
        end
        ind = model.parameters.calibration.samples.(selectedMeasurement).indBrillouin;
        for jj = 1:size(ind,1)
            ix = ind(jj,1):ind(jj,2);
            if ind(jj,1) > 0 && ind(jj,2) <= length(data)
                plot(ax, x(ix), data(ix), 'color', [0, 0, 1, 0.4], 'linewidth', 5);
            end
        end
        if ~isempty(peaksMeasured) && ~isempty(peaksFitted)
            for jj = 1:length(peaksMeasured)
                measured = plot(ax, [peaksMeasured(jj), peaksMeasured(jj)], [minData maxData], 'color', 'Green');
            end
            for jj = 1:length(peaksFitted)
                fitted = plot(ax, [peaksFitted(jj), peaksFitted(jj)], [minData maxData], 'color', 'Red');
            end
            legend(ax, [measured, fitted], {'Measurement', 'Fit'}, 'location', 'north');
        end
        
        if model.displaySettings.calibration.autoscale
            ylim(ax, [minData maxData]);
        else
            ylim(ax, [model.displaySettings.calibration.floor model.displaySettings.calibration.cap]);
        end
        validx = x(~isnan(data));
        mi = min(validx(:));
        ma = max(validx(:));
        if mi < ma
            xlim(ax, [mi ma]);
        end
        zoom(ax, 'reset');
        xlabel(ax, xLabelString, 'interpreter', 'latex');
        ylabel(ax, '$I$ [a.u.]', 'interpreter', 'latex');
    else
        hold(ax, 'off');
        model.handles.calibration.plotSpectrum = plot(ax, NaN, NaN);
    end
end

function onDisplaySettings(view, model)
    handles = view.calibration;
    set(handles.autoscale, 'Value', model.displaySettings.calibration.autoscale);
    set(handles.cap, 'String', model.displaySettings.calibration.cap);
    set(handles.floor, 'String', model.displaySettings.calibration.floor);
    if model.displaySettings.calibration.autoscale
        if isfield(model.handles, 'calibration')
            data = model.handles.calibration.plotSpectrum.YData;
            minData = min(data, [], 'all');
            maxData = max(data, [], 'all');
            deltaData = maxData - minData;
            minData = minData - 0.03 * deltaData;
            maxData = maxData + 0.03 * deltaData;
            if minData < maxData
                ylim(handles.axesImage, [minData maxData]);
            end
        else
            ylim(handles.axesImage, 'auto');
        end
    else
        if model.displaySettings.calibration.floor < model.displaySettings.calibration.cap
            ylim(handles.axesImage, [model.displaySettings.calibration.floor model.displaySettings.calibration.cap]);
        end
    end
end
