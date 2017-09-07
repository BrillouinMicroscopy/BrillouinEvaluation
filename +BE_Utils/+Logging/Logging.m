classdef Logging < handle
    properties (Access = private)
        logPath;
        logHandle;
    end
    
	methods
        %% Constructor
        function obj = Logging (logPath)
            obj.logPath = logPath;
            obj.logHandle = fopen(obj.logPath, 'a');
        end
        
        %% Destructor
        function delete (obj)
            fclose(obj.logHandle);
        end
        
        %% Add new line to log
        function write (obj, data)
            fprintf(obj.logHandle, '%s', data);
            fprintf(obj.logHandle, '\r\n');
        end
        
        %% Add new line to log
        function log (obj, data)
            % add datetime string
            datum = datetime('now', 'format', 'uuuu-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'local');
            datum = char(datum);
            data = [char(datum), ': ', data];
            fprintf(obj.logHandle, '%s', data);
            fprintf(obj.logHandle, '\r\n');
        end
    end
    methods (Static)
    end
end