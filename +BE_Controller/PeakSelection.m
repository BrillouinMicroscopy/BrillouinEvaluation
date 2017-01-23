function calibration = PeakSelection(model, view)
%% CALIBRATION Controller

    %% callbacks Calibration
    set(view.peakSelection.selectBrillouin, 'Callback', {@selectPeaks, view, model, 'brillouin'});
    set(view.peakSelection.selectRayleigh, 'Callback', {@selectPeaks, view, model, 'rayleigh'});
    
    calibration = struct( ...
    );
end

function selectPeaks(~, ~, view, model, type)

    xd = get(p, 'XData');
    yd = get(p, 'YData');
    brush = get(p, 'BrushData');
    brushed_x = xd(logical(brush));
    brushed_y = yd(logical(brush));

end