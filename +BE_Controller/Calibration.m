function calibration = Calibration(model, view)
%% CALIBRATION Controller

    %% callbacks Calibration    
    set(view.calibration.zoomIn, 'Callback', {@zoom, 'in', view});
    set(view.calibration.zoomOut, 'Callback', {@zoom, 'out', view});
    set(view.calibration.panButton, 'Callback', {@pan, view});
    set(view.calibration.cursorButton, 'Callback', {@cursor, view});
    
    set(view.calibration.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.calibration.cap, 'Callback', {@setClim, model});
    set(view.calibration.floor, 'Callback', {@setClim, model});
    
    set(view.calibration.increaseFloor, 'Callback', {@changeClim, model, 1});
    set(view.calibration.decreaseFloor, 'Callback', {@changeClim, model, -1});
    set(view.calibration.increaseCap, 'Callback', {@changeClim, model, 1});
    set(view.calibration.decreaseCap, 'Callback', {@changeClim, model, -1});
    
    calibration = struct( ...
    );
end

function zoom(src, ~, str, view)
    switch get(src, 'UserData')
        case 0
            set(view.calibration.panButton,'UserData',0);
            set(view.calibration.panHandle,'Enable','off');
            set(view.calibration.cursorButton,'UserData',0);
            set(view.calibration.cursorHandle,'Enable','off');
            switch str
                case 'in'
                    set(view.calibration.zoomHandle,'Enable','on','Direction','in');
                    set(view.calibration.zoomIn,'UserData',1);
                    set(view.calibration.zoomOut,'UserData',0);
                case 'out'
                    set(view.calibration.zoomHandle,'Enable','on','Direction','out');
                    set(view.calibration.zoomOut,'UserData',1);
                    set(view.calibration.zoomIn,'UserData',0);
            end
        case 1
            set(view.calibration.zoomHandle,'Enable','off','Direction','in');
            set(view.calibration.zoomOut,'UserData',0);
            set(view.calibration.zoomIn,'UserData',0);
    end
end

function pan(src, ~, view)
    set(view.calibration.zoomHandle,'Enable','off','Direction','in');
    set(view.calibration.cursorHandle,'Enable','off');
    set(view.calibration.zoomOut,'UserData',0);
    set(view.calibration.zoomIn,'UserData',0);
    set(view.calibration.cursorButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.calibration.panButton,'UserData',1);
            set(view.calibration.panHandle,'Enable','on');
        case 1
            set(view.calibration.panButton,'UserData',0);
            set(view.calibration.panHandle,'Enable','off');
    end
end

function cursor(src, ~, view)
    set(view.calibration.zoomHandle,'Enable','off','Direction','in');
    set(view.calibration.panHandle,'Enable','off');
    set(view.calibration.zoomOut,'UserData',0);
    set(view.calibration.zoomIn,'UserData',0);
    set(view.calibration.panButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.calibration.cursorButton,'UserData',1);
            set(view.calibration.cursorHandle,'Enable','on');
        case 1
            set(view.calibration.cursorButton,'UserData',0);
            set(view.calibration.cursorHandle,'Enable','off');
    end
end

function setClim(UIControl, ~, model)
    calibration = model.displaySettings.calibration;
    field = get(UIControl, 'Tag');
    calibration.(field) = str2double(get(UIControl, 'String'));
    calibration.autoscale = 0;
    model.displaySettings.calibration = calibration;
end

function toggleAutoscale(~, ~, model, view)
    model.displaySettings.calibration.autoscale = get(view.calibration.autoscale, 'Value');
end

function changeClim(UIControl, ~, model, sign)
    calibration = model.displaySettings.calibration;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(calibration.cap - calibration.floor));
    calibration.autoscale = 0;
    calibration.(field) = calibration.(field) + sign * dif;
    model.displaySettings.calibration = calibration;
end