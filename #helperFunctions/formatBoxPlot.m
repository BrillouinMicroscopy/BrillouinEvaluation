function formatBoxPlot(hndl, colors)
    nrColors = size(colors, 1);
    
    for kk = 1:size(hndl,2)
        color = colors(mod(kk-1, nrColors)+1,:);
        
        %% format boxes
        set(hndl(5,kk), 'XData', [kk kk]);
        tmp = get(hndl(5,kk), 'YData');
        set(hndl(5,kk), 'YData', tmp(1:2));
        set(hndl(5,kk), 'LineWidth', 10);
        set(hndl(5,kk), 'Color', color);

        %% whiskers
        set(hndl(1,kk), 'Color', color);
        set(hndl(1,kk), 'LineStyle', '-');
        set(hndl(2,kk), 'Color', color);
        set(hndl(2,kk), 'LineStyle', '-');

        %% turn off adjacent values
        set(hndl(3,kk), 'Visible', 'off');
        set(hndl(4,kk), 'Visible', 'off');

        %% format median line
        set(hndl(6,kk), 'XData', [-0.15 0.15] + kk);
        set(hndl(6,kk), 'Color', 'white');
        set(hndl(6,kk), 'LineWidth', 1);
    end
end