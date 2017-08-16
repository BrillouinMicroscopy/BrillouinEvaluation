function handles = Calibration(parent, model)
%% CALIBRATION View

    % build the GUI
    handles = initGUI(model, parent);
    initView(handles, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onSettings(handles, e.AffectedObject));
    addlistener(model, 'displaySettings', 'PostSet', ...
        @(o,e) onDisplaySettings(handles, e.AffectedObject));
    addlistener(model, 'status', 'PostSet', ...
        @(o,e) onStatus(handles, e.AffectedObject));
end

function handles = initGUI(model, parent)

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Select sample:', 'Units', 'normalized',...
        'Position', [0.02,0.94,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');

    samples = uicontrol('Parent', parent, 'Style','popup', 'Units', 'normalized','Position',[0.02 0.885,0.18,0.055],...
        'String',{''},'FontSize', 11, 'HorizontalAlignment', 'left');

    openBrillouinShift = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String', BE_SharedFunctions.iconString([model.pp '/images/fullscreen.png']) ,'Position',[0.205,0.90,0.035,0.041],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    imageNrLabel = uicontrol('Parent', parent, 'Style', 'text', 'String', 'Image:', 'Units', 'normalized',...
        'Position', [0.02,0.858,0.08,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    imageNr = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.17,0.855,0.07,0.04], 'FontSize', 11, 'HorizontalAlignment', 'center');

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Brillouin shift [GHz]:', 'Units', 'normalized',...
        'Position', [0.02,0.815,0.15,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');

    BrillouinShift = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.17,0.812,0.07,0.04], 'FontSize', 11, 'HorizontalAlignment', 'center');

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Brillouin peaks:', 'Units', 'normalized',...
        'Position', [0.02,0.765,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    selectBrillouin = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Select','Position',[0.19,0.762,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    clearBrillouin = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.135,0.762,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    peakTableBrillouin = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.65 0.22 0.106], ...
        'ColumnWidth', {86, 87}, 'ColumnName', {'start','end'}, 'FontSize', 12, 'ColumnEditable', true);

    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Rayleigh peaks:', 'Units', 'normalized',...
        'Position', [0.02,0.595,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    selectRayleigh = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Select','Position',[0.19,0.591,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    clearRayleigh = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Clear','Position',[0.135,0.591,0.05,0.045],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    peakTableRayleigh = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.479 0.22 0.106], ...
        'ColumnWidth', {86, 87}, 'ColumnName', {'start','end'}, 'FontSize', 12, 'ColumnEditable', true);
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Start values:', 'Units', 'normalized',...
        'Position', [0.02,0.44,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    startTable = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.34 0.22 0.10], ...
        'ColumnWidth', {50, 50, 50, 50, 50, 50, 50}, 'ColumnName', {'d / m', 'n', '<html>&#920;</html>', '<html>x<sub>0</sub> / m</html>', ...
        '<html>x<sub>s</sub> / m </html>', 'order', 'iterNum'}, 'FontSize', 10, 'ColumnEditable', true);
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Fitted values:', 'Units', 'normalized',...
        'Position', [0.02,0.30,0.2,0.035], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    valuesTable = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.17 0.22 0.13], ...
        'ColumnWidth', {50, 50, 50, 50, 50, 50, 40}, 'ColumnName', {'d / m', 'n', '<html>&#920;</html>', '<html>x<sub>0</sub> / m</html>', ...
        '<html>x<sub>s</sub> / m</html>', '<html>&#963;</html>', 'active'}, 'FontSize', 10, 'ColumnEditable', true, ...
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
    handles = struct(...
        'parent', parent, ...
        'samples', samples, ...
        'imageNrLabel', imageNrLabel, ...
        'imageNr', imageNr, ...
        'BrillouinShift', BrillouinShift, ...
        'selectBrillouin', selectBrillouin, ...
        'clearBrillouin', clearBrillouin, ...
        'peakTableBrillouin', peakTableBrillouin, ...
        'selectRayleigh', selectRayleigh, ...
        'clearRayleigh', clearRayleigh, ...
        'peakTableRayleigh', peakTableRayleigh, ...
        'startTable', startTable, ...
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

function initView(handles, model)
%% Initialize the view
    set(handles.autoscale, 'Value', model.displaySettings.peakSelection.autoscale);
    set(handles.cap, 'String', model.displaySettings.peakSelection.cap);
    set(handles.floor, 'String', model.displaySettings.peakSelection.floor);
    set(handles.extrapolate, 'Value', model.parameters.calibration.extrapolate);
    set(handles.weighted, 'Value', model.parameters.calibration.weighted);
    set(handles.correctOffset, 'Value', model.parameters.calibration.correctOffset);
end

function onSettings(handles, model)
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
    set(handles.BrillouinShift, 'String', sample.shift);
    set(handles.extrapolate, 'Value', model.parameters.calibration.extrapolate);
    set(handles.weighted, 'Value', model.parameters.calibration.weighted);
    set(handles.correctOffset, 'Value', model.parameters.calibration.correctOffset);
    handles.peakTableBrillouin.Data = sample.indBrillouin;
    handles.peakTableRayleigh.Data = sample.indRayleigh;
    
    if isfield(model.parameters.calibration.samples.(model.parameters.calibration.selected), 'start')
        s = model.parameters.calibration.samples.(model.parameters.calibration.selected).start;
    else
        s = model.parameters.calibration.start;
    end
    startValues = {sprintf('%2.10f',s.d), sprintf('%2.7f',s.n), sprintf('%2.10f',s.theta), ...
        sprintf('%2.5f',s.x0), sprintf('%2.3f',s.xs), sprintf('%2.0f',s.order), sprintf('%2.0f',s.iterNum)};
    handles.startTable.Data = startValues;

    v = sample.values;
    if ~isempty(v.d)
        leng = size(v.d,2);
        v.error = 1e10 * v.error;
        parameters = {'d', 'n', 'theta', 'x0', 'xs', 'error'};
        formats = {'%2.10f', '%2.7f', '%2.10f', '%2.5f', '%2.4f', '%d'};
        fittedValues = cell(leng,7);
        for jj = 1:length(parameters)
            for ii = 1:leng
                fittedValues{ii,jj} = sprintf(formats{jj},v.(parameters{jj})(1,ii));
            end
        end
        fittedValues(:,7) = num2cell(logical(sample.active));
    else
        fittedValues = [];
    end
    handles.valuesTable.Data = fittedValues;
    plotData(handles, model);
end

function onStatus(handles, model)
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
    
    mm = 1;     % selected image
    %% Plot
    ax = handles.axesImage;
    if strcmp(selectedMeasurement, 'measurement')
        imgs = model.file.readPayloadData(sample.imageNr.x, sample.imageNr.y, sample.imageNr.z, 'data');
    else
        imgs = model.file.readCalibrationData(sample.position, 'data');
    end
    imgs = medfilt1(imgs,3);
    img = imgs(:,:,mm);
    data = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction.interpolationPositions);
    if ~isempty(data);
        hold(ax, 'off');
        xLabelString = '$f$ [pix]';
        
        peaksMeasured = [];
        peaksFitted = [];
        x = 1:length(data);
        if ~sum(isempty(sample.values.d)) && ~sum(isnan(sample.values.d))
            peaksMeasured = model.parameters.calibration.samples.(selectedMeasurement).peaksMeasured(mm,:);
            peaksFitted = model.parameters.calibration.samples.(selectedMeasurement).peaksFitted(mm,:);

            params = {'d', 'n', 'theta', 'x0Initial', 'x0', 'xs', 'error'};
            for jj = 1:length(params)
                VIPAparams.(params{jj}) = sample.values.(params{jj})(mm);
            end
            
            wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * x, ...
                VIPAparams, model.parameters.constants, 1);
            x = 1e-9*BE_SharedFunctions.getFrequencyShift(model.parameters.constants.lambda0, wavelength);

            wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * peaksMeasured, ...
                VIPAparams, model.parameters.constants, 1);
            peaksMeasured = 1e-9*BE_SharedFunctions.getFrequencyShift(model.parameters.constants.lambda0, wavelength);
            
            wavelength = BE_SharedFunctions.getWavelength(model.parameters.constants.pixelSize * peaksFitted, ...
                VIPAparams, model.parameters.constants, 1);
            peaksFitted = 1e-9*BE_SharedFunctions.getFrequencyShift(model.parameters.constants.lambda0, wavelength);
            
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
                measured = plot(ax, [peaksMeasured(jj), peaksMeasured(jj)], [min(data(:)) max(data(:))], 'color', 'Green');
            end
            for jj = 1:length(peaksFitted)
                fitted = plot(ax, [peaksFitted(jj), peaksFitted(jj)], [min(data(:)) max(data(:))], 'color', 'Red');
            end
            legend(ax, [measured, fitted], {'Measurement', 'Fit'}, 'location', 'north');
        end
        
        if model.displaySettings.calibration.autoscale
            ylim(ax, 'auto');
        else
            ylim(ax, [model.displaySettings.calibration.floor model.displaySettings.calibration.cap]);
        end
        validx = x(~isnan(data));
        xlim(ax, [min(validx(:)) max(validx(:))]);
        zoom(ax, 'reset');
        xlabel(ax, xLabelString, 'interpreter', 'latex');
        ylabel(ax, '$I$ [a.u.]', 'interpreter', 'latex');
    end
end

function onDisplaySettings(handles, model)
    set(handles.autoscale, 'Value', model.displaySettings.calibration.autoscale);
    set(handles.cap, 'String', model.displaySettings.calibration.cap);
    set(handles.floor, 'String', model.displaySettings.calibration.floor);
    if model.displaySettings.calibration.autoscale
        ylim(handles.axesImage,'auto');
    else
        if model.displaySettings.calibration.floor < model.displaySettings.calibration.cap
            ylim(handles.axesImage, [model.displaySettings.calibration.floor model.displaySettings.calibration.cap]);
        end
    end
end
