function overlay = Overlay(model, view)
%% EVALUATION Controller

    %% callbacks Overlay
    set(view.overlay.zoomIn, 'Callback', {@zoomCallback, 'in', view});
    set(view.overlay.zoomOut, 'Callback', {@zoomCallback, 'out', view});
    set(view.overlay.panButton, 'Callback', {@pan, view});
    set(view.overlay.rotate3dButton, 'Callback', {@rotate3d, view});
    
    set(view.overlay.ok, 'Callback', {@getprmtrs, view, model});
    set(view.overlay.cancel, 'Callback', {@cancel, view});
    set(view.overlay.sld1, 'Callback', {@zoomslide, view, model});
    set(view.overlay.sld2, 'Callback', {@transpslide, view, model});
    set(view.overlay.sld3, 'Callback', {@angleslide, view, model});
        
    overlay = struct( ...
    ); 
end

function zoomCallback(src, ~, str, view)
    switch get(src, 'UserData')
        case 0
            set(view.overlay.panButton,'UserData',0);
            set(view.overlay.panHandle,'Enable','off');
            set(view.overlay.rotate3dButton,'UserData',0);
            set(view.overlay.rotate3dHandle,'Enable','off');
            switch str
                case 'in'
                    set(view.overlay.zoomHandle,'Enable','on','Direction','in');
                    set(view.overlay.zoomIn,'UserData',1);
                    set(view.overlay.zoomOut,'UserData',0);
                case 'out'
                    set(view.overlay.zoomHandle,'Enable','on','Direction','out');
                    set(view.overlay.zoomOut,'UserData',1);
                    set(view.overlay.zoomIn,'UserData',0);
            end
        case 1
            set(view.overlay.zoomHandle,'Enable','off','Direction','in');
            set(view.overlay.zoomOut,'UserData',0);
            set(view.overlay.zoomIn,'UserData',0);
    end
end

function pan(src, ~, view)
    set(view.overlay.zoomHandle,'Enable','off','Direction','in');
    set(view.overlay.zoomOut,'UserData',0);
    set(view.overlay.zoomIn,'UserData',0);
    set(view.overlay.rotate3dButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.overlay.panButton,'UserData',1);
            set(view.overlay.panHandle,'Enable','on');
        case 1
            set(view.overlay.panButton,'UserData',0);
            set(view.overlay.panHandle,'Enable','off');
    end
end

function rotate3d(src, ~, view)
    set(view.overlay.zoomHandle,'Enable','off','Direction','in');
    set(view.overlay.zoomOut,'UserData',0);
    set(view.overlay.zoomIn,'UserData',0);
    set(view.overlay.panHandle,'Enable','off');
    set(view.overlay.panButton,'UserData',0);
    switch get(src, 'UserData')
        case 0
            set(view.overlay.rotate3dButton,'UserData',1);
            set(view.overlay.rotate3dHandle,'Enable','on');
        case 1
            set(view.overlay.rotate3dButton,'UserData',0);
            set(view.overlay.rotate3dHandle,'Enable','off');
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
    
    xl = get(view.overlay.brightfieldImage, 'xlim');
    yl = get(view.overlay.brightfieldImage, 'ylim');
    
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
    
    close(view.overlay.parent);
    
 end
 
 function cancel(~, ~, view)
   close(view.overlay.parent);
 end
 
function zoomslide(source, ~, view, model)
    val = source.Value/20;
    bright = model.results.brightfield_rot;
    
    halfWidth = size(bright,2)/2;
    halfHeight = size(bright,1)/2;
    
    xCenter = mean(view.overlay.brightfieldImage.XLim);
    xLims = [xCenter-halfWidth/val xCenter+halfWidth/val];

    yCenter = mean(view.overlay.brightfieldImage.YLim);
    yLims = [yCenter-halfHeight/val yCenter+halfHeight/val];

    
    xlmin = (min(xLims));
    xlmax = (max(xLims));
    
    if xlmin < 0.5
        dx = abs(xlmin - 1); 
        xlmin = xlmin + dx;
        xlmax = xlmax + dx;
        if xlmax > 2*halfWidth;
            xlmax = halfWidth*2;
        end
    end
    
    if xlmax > 2*halfWidth
        dx = abs(xlmax - 2*halfWidth); 
        xlmin = xlmin - dx;
        xlmax = xlmax - dx;
        if xlmin < 0.5;
            xlmin = 1;
        end
    end
    
    ylmin = (min(yLims));
    ylmax = (max(yLims));
    
    if ylmin < 0.5
        dy = abs(ylmin - 1); 
        ylmin = ylmin + dy;
        ylmax = ylmax + dy;
        if ylmax > 2*halfHeight;
            ylmax = halfHeight*2;
        end
    end
    
    if ylmax > 2*halfHeight
        dy = abs(ylmax - 2*halfHeight); 
        ylmin = ylmin - dy;
        ylmax = ylmax - dy;
        if ylmin < 0.5;
            ylmin = 1;
        end
    end
    
    xlim([xlmin xlmax]);
    ylim([ylmin ylmax]);
 end
 

function angleslide(source, ~, ~, model)
    bright = model.results.brightfield_raw;
    model.results.brightfield_rot = imrotate(bright, source.Value, 'crop');
end

function transpslide(source, ~, ~, ~)
    val = source.Value/100;
    alpha(val)
end
 