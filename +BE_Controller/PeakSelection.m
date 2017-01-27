function calibration = PeakSelection(model, view)
%% CALIBRATION Controller

    %% callbacks Calibration
    set(view.peakSelection.selectBrillouin, 'Callback', {@selectPeaks, view, model, 'Brillouin'});
    set(view.peakSelection.selectRayleigh, 'Callback', {@selectPeaks, view, model, 'Rayleigh'});
    
    set(view.peakSelection.peakTableBrillouin, 'CellEditCallback', {@editPeaks, model, 'Brillouin'});
    set(view.peakSelection.peakTableRayleigh, 'CellEditCallback', {@editPeaks, model, 'Rayleigh'});
    
    set(view.peakSelection.clearBrillouin, 'Callback', {@clearPeaks, model, 'Brillouin'});
    set(view.peakSelection.clearRayleigh, 'Callback', {@clearPeaks, model, 'Rayleigh'});
    
    set(view.peakSelection.zoomIn, 'Callback', {@zoom, 'in', view});
    set(view.peakSelection.zoomOut, 'Callback', {@zoom, 'out', view});
    set(view.peakSelection.panButton, 'Callback', {@pan, view});
    
    set(view.peakSelection.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.peakSelection.cap, 'Callback', {@setClim, model});
    set(view.peakSelection.floor, 'Callback', {@setClim, model});
    
    set(view.peakSelection.increaseFloor, 'Callback', {@changeClim, model, 1});
    set(view.peakSelection.decreaseFloor, 'Callback', {@changeClim, model, -1});
    set(view.peakSelection.increaseCap, 'Callback', {@changeClim, model, 1});
    set(view.peakSelection.decreaseCap, 'Callback', {@changeClim, model, -1});
    
    calibration = struct( ...
    );
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
        brushed = logical(get(model.handles.plotSpectrum, 'BrushData'));
        set(view.peakSelection.brushHandle, 'Enable', 'off');
        
        xd = get(model.handles.plotSpectrum, 'XData');
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
    set(view.peakSelection.zoomOut,'UserData',0);
    set(view.peakSelection.zoomIn,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.peakSelection.panButton,'UserData',1);
            set(view.peakSelection.panHandle,'Enable','on');
        case 1
            set(view.peakSelection.panButton,'UserData',0);
            set(view.peakSelection.panHandle,'Enable','off');
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