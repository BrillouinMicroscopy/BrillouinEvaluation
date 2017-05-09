classdef View < handle
%% VIEW

    % observable properties, listeners are notified on change
    properties (SetObservable = true)
        figure;
        menubar;
        data;
        extraction;
        peakSelection;
        calibration;
        evaluation;
        overlay;
    end

    methods
        function obj = View()
        end
    end
end