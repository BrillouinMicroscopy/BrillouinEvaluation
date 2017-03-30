function overlay = Overlay(model, view)
%% EVALUATION Controller

    %% callbacks Overlay
    set(view.zoomIn, 'Callback', {@zoomCallback, 'in', view});
    set(view.zoomOut, 'Callback', {@zoomCallback, 'out', view});
    set(view.panButton, 'Callback', {@pan, view});
    set(view.rotate3dButton, 'Callback', {@rotate3d, view});
    
    set(view.ok, 'Callback', {@getprmtrs, view, model});
    set(view.cancel, 'Callback', {@cancel, view, model});
    set(view.sld1, 'Callback', {@zoomslide, view, model});
    set(view.sld2, 'Callback', {@transpslide, view, model});
        
    overlay = struct( ...
    ); 
end

function zoomCallback(src, ~, str, view)
    switch get(src, 'UserData')
        case 0
            set(view.panButton,'UserData',0);
            set(view.panHandle,'Enable','off');
            set(view.rotate3dButton,'UserData',0);
            set(view.rotate3dHandle,'Enable','off');
            switch str
                case 'in'
                    set(view.zoomHandle,'Enable','on','Direction','in');
                    set(view.zoomIn,'UserData',1);
                    set(view.zoomOut,'UserData',0);
                case 'out'
                    set(view.zoomHandle,'Enable','on','Direction','out');
                    set(view.zoomOut,'UserData',1);
                    set(view.zoomIn,'UserData',0);
            end
        case 1
            set(view.zoomHandle,'Enable','off','Direction','in');
            set(view.zoomOut,'UserData',0);
            set(view.zoomIn,'UserData',0);
    end
end

function pan(src, ~, view)
    set(view.zoomHandle,'Enable','off','Direction','in');
    set(view.zoomOut,'UserData',0);
    set(view.zoomIn,'UserData',0);
    set(view.rotate3dButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.panButton,'UserData',1);
            set(view.panHandle,'Enable','on');
        case 1
            set(view.panButton,'UserData',0);
            set(view.panHandle,'Enable','off');
    end
end

function rotate3d(src, ~, view)
    set(view.zoomHandle,'Enable','off','Direction','in');
    set(view.zoomOut,'UserData',0);
    set(view.zoomIn,'UserData',0);
    set(view.panHandle,'Enable','off');
    set(view.panButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.rotate3dButton,'UserData',1);
            set(view.rotate3dHandle,'Enable','on');
        case 1
            set(view.rotate3dButton,'UserData',0);
            set(view.rotate3dHandle,'Enable','off');
    end
end

 function getprmtrs(~, ~, view, model)
    bright = model.results.brightfield_rot;
    dims = {'Y', 'X', 'Z'};
    for jj = 1:length(dims)
        positions.([dims{jj} '_zm']) = ...
            model.parameters.positions.(dims{jj}) - mean(model.parameters.positions.(dims{jj})(:))*ones(size(model.parameters.positions.(dims{jj})));
    end
    
    maxx = max(max(positions.X_zm));
    minx = min(min(positions.X_zm));
    maxy = max(max(positions.Y_zm));
    miny = min(min(positions.Y_zm));
    
    xl = get(view.brightfieldImage, 'xlim');
    yl = get(view.brightfieldImage, 'ylim');
    
    model.parameters.evaluation.xl = xl;
    model.parameters.evaluation.yl = yl;
    
    xlmin = round(min(xl));
    if xlmin < 1
        xlmin = 1;
    end
    xlmax = round(max(xl));
    if xlmax > size(bright,2)
        xlmax = size(bright,2);
    end
    
    ylmin = round(min(yl));
    if ylmin < 1
        ylmin = 1;
    end
    ylmax = round(max(yl));
    if ylmax > size(bright,1)
        ylmax = size(bright,1);
    end
    
    cut = bright(ylmin:ylmax , xlmin:xlmax);
    x = linspace(minx, maxx ,size(cut,2));
    y = linspace(miny, maxy ,size(cut,1));
    
    [X,Y,Z] = meshgrid(x, y, 1);
    
    model.parameters.positions_brightfield.X = X;
    model.parameters.positions_brightfield.Y = Y;
    model.parameters.positions_brightfield.Z = Z;
    model.results.brightfield = cut;
    close(model.handles.overlay);
    
 end
 
 function cancel(~, ~, view, model)
   close(model.handles.overlay);
 end
 
function zoomslide(source, event, view, model)
    val = source.Value/10;
    zoom(val)
 end
 
function transpslide(source, event, view, model)
    val = source.Value/100;
    alpha(val)
end
 