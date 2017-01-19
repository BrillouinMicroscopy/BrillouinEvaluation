function extraction = Extraction(model, view)
%% CALIBRATION Controller

    %% callbacks Calibration
    set(view.extraction.selectPeaks, 'Callback', {@selectPeaks, model});
    set(view.extraction.optimizePeaks, 'Callback', {@optimizePeaks, model});
    
    set(view.extraction.extractionAxis, 'Callback', {@changeSettings, view, model});
    set(view.extraction.interpolationDirection, 'Callback', {@changeSettings, view, model});
    
    set(view.extraction.width, 'Callback', {@changeSettings, view, model});
    
    set(view.extraction.zoomIn, 'Callback', {@zoom, 'in', view});
    set(view.extraction.zoomOut, 'Callback', {@zoom, 'out', view});
    set(view.extraction.panButton, 'Callback', {@pan, view});
    
    set(view.extraction.autoscale, 'Callback', {@toggleAutoscale, model, view});
    set(view.extraction.cap, 'Callback', {@setCameraParameters, model});
    set(view.extraction.floor, 'Callback', {@setCameraParameters, model});
    
    set(view.extraction.increaseFloor, 'Callback', {@increaseClim, model});
    set(view.extraction.decreaseFloor, 'Callback', {@decreaseClim, model});
    set(view.extraction.increaseCap, 'Callback', {@increaseClim, model});
    set(view.extraction.decreaseCap, 'Callback', {@decreaseClim, model});
    
    extraction = struct( ...
    );
end

function selectPeaks(~, ~, model)
    % manually select the peaks of the spectrum
    x = [25, 144, 214, 271];    % placeholder data
    y = [12, 119, 199, 274];    % placeholder data
    model.settings.extraction.peaks = struct( ...
        'x', x, ...
        'y', y ...
    );
end

function optimizePeaks(~, ~, model)
    if isa(model.file, 'Utils.HDF5Storage.h5bm') && isvalid(model.file)
        img = model.file.readPayloadData(1, 1, 1, 'data');
        r=10;
        % do a median filtering to prevent finding maxixums which are none,
        % reduce radius if medfilt2 is not possible (license checkout
        % failure)
        try
            img = medfilt2(img);
        catch
            r = 4;
        end
        peaks = model.settings.extraction.peaks;
        siz=size(img);
        for jj = 1:length(peaks.x)
            cx=peaks.x(jj);
            cy=peaks.y(jj);
            [x,y]=meshgrid(-(cx-1):(siz(2)-cx),-(cy-1):(siz(1)-cy));
            mask=((x.^2+y.^2)<=r^2);
            tmp = img;
            tmp(~mask) = NaN;
            [~, ind] = max(tmp(:));
            [peaks.y(jj),peaks.x(jj)] = ind2sub(siz,ind);
        end
        model.settings.extraction.peaks = peaks;
    end
end

function changeSettings(~, ~, view, model)
    % create a copy of the struct, otherwise model is reset after first
    % value has been changed
    extraction = model.settings.extraction;
    
    % set new values
    extractionAxis = get(view.extraction.extractionAxisGroup,'SelectedObject');
    extraction.extractionAxis = extractionAxis.String;

    interpolationDirection = get(view.extraction.interpolationDirectionGroup,'SelectedObject');
    extraction.interpolationDirection = interpolationDirection.String;
    
    extraction.width = str2double(get(view.extraction.width, 'String'));
    
    model.settings.extraction = extraction;
end

function setCameraParameters(UIControl, ~, model)
    field = get(UIControl, 'Tag');
    model.settings.extraction.(field) = str2double(get(UIControl, 'String'));
end

function toggleAutoscale(~, ~, model, view)
    model.settings.extraction.autoscale = get(view.extraction.autoscale, 'Value');
end

function zoom(src, ~, str, view)
switch get(src, 'UserData')
    case 0
        set(view.extraction.panButton,'UserData',0);
        set(view.extraction.panHandle,'Enable','off');
        switch str
            case 'in'
                set(view.extraction.zoomHandle,'Enable','on','Direction','in');
                set(view.extraction.zoomIn,'UserData',1);
                set(view.extraction.zoomOut,'UserData',0);
            case 'out'
                set(view.extraction.zoomHandle,'Enable','on','Direction','out');
                set(view.extraction.zoomOut,'UserData',1);
                set(view.extraction.zoomIn,'UserData',0);
        end
    case 1
        set(view.extraction.zoomHandle,'Enable','off','Direction','in');
        set(view.extraction.zoomOut,'UserData',0);
        set(view.extraction.zoomIn,'UserData',0);
end
        
end

function pan(src, ~, view)
    set(view.extraction.zoomOut,'UserData',0);
    set(view.extraction.zoomIn,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.extraction.panButton,'UserData',1);
            set(view.extraction.panHandle,'Enable','on');
        case 1
            set(view.extraction.panButton,'UserData',0);
            set(view.extraction.panHandle,'Enable','off');
    end
end

function decreaseClim(UIControl, ~, model)
    model.settings.extraction.autoscale = 0;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(model.settings.extraction.cap - model.settings.extraction.floor));
    model.settings.extraction.(field) = model.settings.extraction.(field) - dif;
end

function increaseClim(UIControl, ~, model)
    model.settings.extraction.autoscale = 0;
    field = get(UIControl, 'Tag');
    dif = abs(0.1*(model.settings.extraction.cap - model.settings.extraction.floor));
    model.settings.extraction.(field) = model.settings.extraction.(field) + dif;
end