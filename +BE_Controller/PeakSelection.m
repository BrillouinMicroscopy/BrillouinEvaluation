function callbacks = PeakSelection(model, view)
%% CALIBRATION Controller

    %% callbacks PeakSelection
    set(view.peakSelection.selectBrillouin, 'Callback', {@selectPeaks, view, model, 'Brillouin'});
    set(view.peakSelection.selectRayleigh, 'Callback', {@selectPeaks, view, model, 'Rayleigh'});
    
    set(view.peakSelection.peakTableBrillouin, 'CellEditCallback', {@editPeaks, model, 'Brillouin'});
    set(view.peakSelection.peakTableRayleigh, 'CellEditCallback', {@editPeaks, model, 'Rayleigh'});
    
    set(view.peakSelection.clearBrillouin, 'Callback', {@clearPeaks, model, 'Brillouin'});
    set(view.peakSelection.clearRayleigh, 'Callback', {@clearPeaks, model, 'Rayleigh'});
    
    set(view.peakSelection.zoomIn, 'Callback', {@zoom, 'in', view});
    set(view.peakSelection.zoomOut, 'Callback', {@zoom, 'out', view});
    set(view.peakSelection.panButton, 'Callback', {@pan, view});
    set(view.peakSelection.cursorButton, 'Callback', {@cursor, view});
    
    set(view.peakSelection.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.peakSelection.cap, 'Callback', {@setClim, model});
    set(view.peakSelection.floor, 'Callback', {@setClim, model});
    
    set(view.peakSelection.increaseFloor, 'Callback', {@changeClim, model, 1});
    set(view.peakSelection.decreaseFloor, 'Callback', {@changeClim, model, -1});
    set(view.peakSelection.increaseCap, 'Callback', {@changeClim, model, 1});
    set(view.peakSelection.decreaseCap, 'Callback', {@changeClim, model, -1});
    
    callbacks = struct( ...
        'setActive', @()setActive(view), ...
        'selectFrequencyRangeRayleigh', @(range, units)selectFrequencyRange(model, 'Rayleigh', range, units), ...
        'selectFrequencyRangeBrillouin', @(range, units)selectFrequencyRange(model, 'Brillouin', range, units) ...
    );
end

function setActive(view)
    tabgroup = get(view.peakSelection.parent, 'parent');
    tabgroup.SelectedTab = view.peakSelection.parent;
end

function selectFrequencyRange(model, type, range, units)
    imgs = model.file.readPayloadData(model.mode, model.repetition, 'data', 1, 1, 1);
    imgs = medfilt1(imgs,3);
    img = imgs(:,:,1);

    startTime = model.file.date;
    datestring = model.file.readPayloadData(model.mode, model.repetition , 'date', 1, 1, 1);
    try
        refTime = datetime(startTime, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        refTime = datetime(startTime, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
        date = datetime(datestring, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'UTC');
    end
    time = etime(datevec(date),datevec(refTime));

    data = BE_SharedFunctions.getIntensity1D(img, model.parameters.extraction, time);
    if ~isempty(data)
        % if units is GHz then calculate the indices from the calibrated
        % frequency axis
        if strcmp(units, 'GHz')
            x = 1:length(data);
            calibration = model.parameters.calibration;
            valid = ~isnan(calibration.wavelength);
            if ~isempty(calibration.wavelength) && sum(valid(:))
                wavelength = BE_SharedFunctions.getWavelengthFromMap(x, time, calibration);
                x = 1e-9*BE_SharedFunctions.getFrequencyShift(model.parameters.constants.lambda0, wavelength);

                [~, ind1] = min(abs(x - range(1)));
                [~, ind2] = min(abs(x - range(2)));
                range = [ind1 ind2];
            else
                errorStr = 'Error: No calibration available, please set this parameter in [pix].';
                disp(errorStr);
                model.log.log('E', errorStr);
                return;
            end
        end
        model.parameters.peakSelection.(type) = range;
        model.log.log(['I/PeakSelection: Selection of the ' type ' peaks successful.']);
    else
        errorStr = 'Error: Cannot set this parameter, no data was loaded.';
        disp(errorStr);
        model.log.log('E', errorStr);
        return;
    end
end

function selectPeaks(~, ~, view, model, type)
    model.status.peakSelection.(['select' type]) = ~model.status.peakSelection.(['select' type]);
    if model.status.peakSelection.(['select' type])
        switch type
            case 'Brillouin'
                model.status.peakSelection.selectRayleigh = 0;
                color = [0 0 1];
            case 'Rayleigh'
                model.status.peakSelection.selectBrillouin = 0;
                color = [1 0 0];
        end
        set(view.peakSelection.brushHandle, 'Enable', 'on', 'color', color);
    else
        if ~isfield(model.handles, 'plotSpectrum')
            return;
        end
        brushed = logical(get(model.handles.plotSpectrum, 'BrushData'));
        set(view.peakSelection.brushHandle, 'Enable', 'off');
        
        xd = 1:length(brushed);
        ind = xd(brushed);
        model.parameters.peakSelection.(type) = vertcat(model.parameters.peakSelection.(type), findBorders(ind));
    end
end

function borders = findBorders(ind)
    try
        borderPosition = diff(ind);

        t = find((borderPosition>1));

        borders = NaN((length(t)+1),2);
        for jj = 1:(length(t)+1)
            if jj == 1
                start = ind(1);
            else
                start = ind(t(jj-1)+1);
            end
            if jj == (length(t)+1)
                stop = ind(end);
            else
                stop = ind(t(jj));
            end
            borders(jj,:) = [start stop];
        end
    catch
        borders = [];
    end
end

function clearPeaks(~, ~, model, type)
    model.parameters.peakSelection.(type) = [];
end

function editPeaks(~, table, model, type)
    model.parameters.peakSelection.(type)(table.Indices(1), table.Indices(2)) = table.NewData;
end

function zoom(src, ~, str, view)
    switch get(src, 'UserData')
        case 0
            set(view.peakSelection.panButton,'UserData',0);
            set(view.peakSelection.panHandle,'Enable','off');
            set(view.peakSelection.cursorButton,'UserData',0);
            set(view.peakSelection.cursorHandle,'Enable','off');
            switch str
                case 'in'
                    set(view.peakSelection.zoomHandle,'Enable','on','Direction','in');
                    set(view.peakSelection.zoomIn,'UserData',1);
                    set(view.peakSelection.zoomOut,'UserData',0);
                case 'out'
                    set(view.peakSelection.zoomHandle,'Enable','on','Direction','out');
                    set(view.peakSelection.zoomOut,'UserData',1);
                    set(view.peakSelection.zoomIn,'UserData',0);
            end
        case 1
            set(view.peakSelection.zoomHandle,'Enable','off','Direction','in');
            set(view.peakSelection.zoomOut,'UserData',0);
            set(view.peakSelection.zoomIn,'UserData',0);
    end
end

function pan(src, ~, view)
    set(view.peakSelection.zoomHandle,'Enable','off','Direction','in');
    set(view.peakSelection.cursorHandle,'Enable','off');
    set(view.peakSelection.zoomOut,'UserData',0);
    set(view.peakSelection.zoomIn,'UserData',0);
    set(view.peakSelection.cursorButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.peakSelection.panButton,'UserData',1);
            set(view.peakSelection.panHandle,'Enable','on');
        case 1
            set(view.peakSelection.panButton,'UserData',0);
            set(view.peakSelection.panHandle,'Enable','off');
    end
end

function cursor(src, ~, view)
    set(view.peakSelection.zoomHandle,'Enable','off','Direction','in');
    set(view.peakSelection.panHandle,'Enable','off');
    set(view.peakSelection.zoomOut,'UserData',0);
    set(view.peakSelection.zoomIn,'UserData',0);
    set(view.peakSelection.panButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.peakSelection.cursorButton,'UserData',1);
            set(view.peakSelection.cursorHandle,'Enable','on');
        case 1
            set(view.peakSelection.cursorButton,'UserData',0);
            set(view.peakSelection.cursorHandle,'Enable','off');
    end
end

function setClim(UIControl, ~, model)
    peakSelection = model.displaySettings.peakSelection;
    field = get(UIControl, 'Tag');
    peakSelection.(field) = str2double(get(UIControl, 'String'));
    peakSelection.autoscale = 0;
    model.displaySettings.peakSelection = peakSelection;
end

function toggleAutoscale(~, ~, model, view)
    model.displaySettings.peakSelection.autoscale = get(view.peakSelection.autoscale, 'Value');
end

function changeClim(UIControl, ~, model, sign)
    peakSelection = model.displaySettings.peakSelection;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(peakSelection.cap - peakSelection.floor));
    peakSelection.autoscale = 0;
    peakSelection.(field) = peakSelection.(field) + sign * dif;
    model.displaySettings.peakSelection = peakSelection;
end