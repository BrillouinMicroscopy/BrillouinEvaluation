function masking = Masking(model, view)
%% EVALUATION Controller

    %% callbacks Masking
    set(view.masking.zoomIn, 'Callback', {@zoomCallback, 'in', view});
    set(view.masking.zoomOut, 'Callback', {@zoomCallback, 'out', view});
    set(view.masking.panButton, 'Callback', {@pan, view});
    set(view.masking.rotate3dButton, 'Callback', {@rotate3d, view});
    
    set(view.masking.cancel, 'Callback', {@cancel, view});
        
    masking = struct( ...
    ); 
end

function zoomCallback(src, ~, str, view)
    switch get(src, 'UserData')
        case 0
            set(view.masking.panButton,'UserData',0);
            set(view.masking.panHandle,'Enable','off');
            set(view.masking.rotate3dButton,'UserData',0);
            set(view.masking.rotate3dHandle,'Enable','off');
            switch str
                case 'in'
                    set(view.masking.zoomHandle,'Enable','on','Direction','in');
                    set(view.masking.zoomIn,'UserData',1);
                    set(view.masking.zoomOut,'UserData',0);
                case 'out'
                    set(view.masking.zoomHandle,'Enable','on','Direction','out');
                    set(view.masking.zoomOut,'UserData',1);
                    set(view.masking.zoomIn,'UserData',0);
            end
        case 1
            set(view.masking.zoomHandle,'Enable','off','Direction','in');
            set(view.masking.zoomOut,'UserData',0);
            set(view.masking.zoomIn,'UserData',0);
    end
end

function pan(src, ~, view)
    set(view.masking.zoomHandle,'Enable','off','Direction','in');
    set(view.masking.zoomOut,'UserData',0);
    set(view.masking.zoomIn,'UserData',0);
    set(view.masking.rotate3dButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.masking.panButton,'UserData',1);
            set(view.masking.panHandle,'Enable','on');
        case 1
            set(view.masking.panButton,'UserData',0);
            set(view.masking.panHandle,'Enable','off');
    end
end

function rotate3d(src, ~, view)
    set(view.masking.zoomHandle,'Enable','off','Direction','in');
    set(view.masking.zoomOut,'UserData',0);
    set(view.masking.zoomIn,'UserData',0);
    set(view.masking.panHandle,'Enable','off');
    set(view.masking.panButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.masking.rotate3dButton,'UserData',1);
            set(view.masking.rotate3dHandle,'Enable','on');
        case 1
            set(view.masking.rotate3dButton,'UserData',0);
            set(view.masking.rotate3dHandle,'Enable','off');
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
    
    xl = get(view.masking.brightfieldImage, 'xlim');
    yl = get(view.masking.brightfieldImage, 'ylim');
    
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
    
    msgbox('Brightfield image has been adapted')
    
    close(view.masking.parent);
end
 
function cancel(~, ~, view)
    close(view.masking.parent);
end
 