classdef ProgressBar < handle
    properties (Access = private)
        parent;
        ax;
        patch;
        text;
    end
    properties
        position;
        value;
        label;
    end

	methods
        %% Constructor
        function obj = ProgressBar(parent, position, value, label)
            arguments
                parent handle
                position (1,4)
                value double = 0.0
                label string = ''
            end
            obj.parent = parent;
            obj.position = position;
            obj.value = abs(value) / 100;
            obj.label = label;

            obj.ax = axes( ...
                'Parent', obj.parent, ...
                'Position', obj.position, ...
                'XTick', [], ...
                'YTick', [], ...
                'XLimMode', 'manual', ...
                'YLimMode', 'manual', ...
                'XLim', [0 1], ...
                'YLim', [0 1], ...
                'Box', 'on' ...
            );
            obj.patch = patch(obj.ax, ...
                [0 obj.value obj.value 0], ...
                [0 0 1 1], ...
                [36, 142, 230]/255 ...
            );
            obj.text = text(obj.ax, 0.5, 0.5, ...
                obj.label, ...
                'HorizontalAlignment', 'center' ...
            );
        end

        %% Destructor
        function delete(~)
            try
            catch
            end
        end
    end
    methods
        %% Get the position
        function position = get.position(obj)
            try
                position = obj.position;
            catch
            end
        end

        %% Set the position
        function set.position(obj, position)
            try
                obj.position = position;
            catch
            end
        end

        %% Get the current progress value
        function value = get.value(obj)
            try
                value = obj.value;
            catch
            end
        end

        %% Set the current progress value
        function set.value(obj, value)
            try
                obj.value = value;
            catch
            end
        end

        %% Get the current label
        function label = get.label(obj)
            try
                label = obj.label;
            catch
            end
        end

        %% Set the current label
        function set.label(obj, label)
            try
                obj.label = label;
            catch
            end
        end
        
        %% Functions to set the values
        
        function setValue(obj, value)
            obj.value = abs(double(value)) / 100;
            obj.patch.XData = [0 obj.value obj.value 0];
        end
        
        function setString(obj, label)
            obj.label = label;
            obj.text.String = obj.label;
        end
    end
end