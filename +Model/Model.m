classdef Model < handle
%% MODEL

    % observable properties, listeners are notified on change
    properties (SetObservable = true)
        file;       % handle to the H5BM file
        filename;   % name of the H5BM file
    end

    methods
        function obj = Model()
            obj.filename = [];
            obj.file = [];
        end
    end
end