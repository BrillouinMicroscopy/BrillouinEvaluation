function getgraphinput
hf = figure;
ha = axes('position',[0.1 0.3 0.8 0.6]);
x = linspace(0,1);
hp = plot(x,sin(5*pi*x));
set(hp,'hittest','off')

hstart = uicontrol('style','pushbutton','string','Start',...
    'units','normalized','position',[0.2 0.1 0.2 0.1],...
    'callback',@startgin);
hstop = uicontrol('style','pushbutton','string','Done',...
    'units','normalized','position',[0.6 0.1 0.2 0.1],...
    'callback',@stopgin,'enable','off');

    function startgin(hObj,handles,eventdat)
        set(hObj,'Enable','off')
        set(hstop,'enable','on')
        set(hf,'WindowButtonMotionFcn',@changepointer)
        set(ha,'ButtonDownFcn',@getpoints)
    end

    function stopgin(hObj,handles,eventdat)
        set(hObj,'Enable','off')
        set(hstart,'enable','on')
        set(hf,'Pointer','arrow')
        set(hf,'WindowButtonMotionFcn',[])
        set(ha,'ButtonDownFcn',@getpoints)
        xy = getappdata(hf,'xypoints');
line(xy(:,1),xy(:,2))
    end

    function changepointer(hObj,handles,eventdat)
        axlim = get(ha,'Position');
        fglim = get(hf,'Position');
        x1 = axlim(1)*fglim(3) + fglim(1);
        x2 = (axlim(1)+axlim(3))*fglim(3) + fglim(1);
        y1 = axlim(2)*fglim(4) + fglim(2);
        y2 = (axlim(2)+axlim(4))*fglim(4) + fglim(2);
        pntr = get(0,'PointerLocation');
        if pntr(1)>x1 && pntr(1)<x2 && pntr(2)>y1 && pntr(2)<y2
            set(hf,'Pointer','crosshair')
        else
            set(hf,'Pointer','arrow')
        end
    end

    function getpoints(hObj,~,~)
        cp = get(hObj,'CurrentPoint');
        line(cp(1,1),cp(1,2),'linestyle','none',...
            'marker','o','color','r')
        xy = getappdata(hf,'xypoints');
        xy = [xy;cp(1,1:2)];
        setappdata(hf,'xypoints',xy);
    end

end
