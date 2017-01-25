function calibration = PeakSelection(model, view)
%% CALIBRATION Controller

    %% callbacks Calibration
    set(view.peakSelection.selectBrillouin, 'Callback', {@selectPeaks, view, model, 'brillouin'});
    set(view.peakSelection.selectRayleigh, 'Callback', {@selectPeaks, view, model, 'rayleigh'});
    
    set(view.peakSelection.peakTableBrillouin, 'CellEditCallback', {@editPeaks, model, 'brillouin'});
    set(view.peakSelection.peakTableRayleigh, 'CellEditCallback', {@editPeaks, model, 'rayleigh'});
    
    set(view.peakSelection.clearBrillouin, 'Callback', {@clearPeaks, model, 'brillouin'});
    set(view.peakSelection.clearRayleigh, 'Callback', {@clearPeaks, model, 'rayleigh'});
    
    set(view.peakSelection.zoomIn, 'Callback', {@zoom, 'in', view});
    set(view.peakSelection.zoomOut, 'Callback', {@zoom, 'out', view});
    set(view.peakSelection.panButton, 'Callback', {@pan, view});
    
    set(view.peakSelection.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.peakSelection.cap, 'Callback', {@setCameraParameters, model});
    set(view.peakSelection.floor, 'Callback', {@setCameraParameters, model});
    
    set(view.peakSelection.increaseFloor, 'Callback', {@increaseClim, model});
    set(view.peakSelection.decreaseFloor, 'Callback', {@decreaseClim, model});
    set(view.peakSelection.increaseCap, 'Callback', {@increaseClim, model});
    set(view.peakSelection.decreaseCap, 'Callback', {@decreaseClim, model});
    
    calibration = struct( ...
    );
end

function selectPeaks(~, ~, view, model, type)
    if ~model.settings.peakSelection.selecting
        switch type
            case 'brillouin'
                color = [0 0 1];
            case 'rayleigh'
                color = [1 0 0];
        end
        set(view.peakSelection.brushHandle, 'Enable', 'on', 'color', color);
    else
        brushed = logical(get(model.handles.plotSpectrum, 'BrushData'));
        set(view.peakSelection.brushHandle, 'Enable', 'off');
        
        xd = get(model.handles.plotSpectrum, 'XData');
        ind = xd(brushed);
        model.settings.peakSelection.(type) = vertcat(model.settings.peakSelection.(type), findBorders(ind));
        
%         yd = get(model.handles.plotSpectrum, 'YData');
%         brushed_x = xd(logical(brush));
%         brushed_y = yd(logical(brush));
%         disp(brushed);
    end
    
    model.settings.peakSelection.selecting = ~model.settings.peakSelection.selecting;

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
    model.settings.peakSelection.(type) = [];
end

function editPeaks(~, table, model, type)
    model.settings.peakSelection.(type)(table.Indices(1), table.Indices(2)) = table.NewData;
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

function setCameraParameters(UIControl, ~, model)
    field = get(UIControl, 'Tag');
    model.displaySettings.peakSelection.(field) = str2double(get(UIControl, 'String'));
end

function toggleAutoscale(~, ~, model, view)
    model.displaySettings.peakSelection.autoscale = get(view.peakSelection.autoscale, 'Value');
end

function decreaseClim(UIControl, ~, model)
    model.displaySettings.peakSelection.autoscale = 0;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(model.displaySettings.peakSelection.cap - model.displaySettings.peakSelection.floor));
    model.displaySettings.peakSelection.(field) = model.displaySettings.peakSelection.(field) - dif;
end

function increaseClim(UIControl, ~, model)
    model.displaySettings.peakSelection.autoscale = 0;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(model.displaySettings.peakSelection.cap - model.displaySettings.peakSelection.floor));
    model.displaySettings.peakSelection.(field) = model.displaySettings.peakSelection.(field) + dif;
end