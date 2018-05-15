function found = findMeasurements(searchQuery, varargin)
    % function searches for measurements with given metadata values and returns
    % their path, name and metadata

    %% parse input parameters
    p = inputParser;

    addRequired(p, 'searchQuery', @isstruct);
    addParameter(p, 'basepaths', '.', @ispathCell);     % base directory in which to search

    parse(p, searchQuery, varargin{:});

    originalPath = pwd; % the original path

    %% create struct for results
    found = struct();

    if ischar(p.Results.basepaths)
        basepaths = {p.Results.basepaths};
    else
        basepaths = p.Results.basepaths;
    end
    
    filesFound = 0;
    for ii = 1:length(basepaths)
        %% find all metadata files
        filelist = dir([basepaths{ii} filesep '**' filesep 'getMetaData.m']);

        %% read all metadata files and keep results matching the request
        for jj = 1:length(filelist)
            % change path to metadata file
            cd(filelist(jj).folder);
            % query metadata
            metadata = getMetaData();

            % search metadata entries
            measurements = fields(metadata);
            for kk = 1:length(measurements)
                mdata = metadata.(measurements{kk});
                if matchQuery(mdata, p.Results.searchQuery)
                    filesFound = filesFound + 1;
                    found(filesFound).filename = mdata.filename;
                    found(filesFound).path = filelist(jj).folder;
                    found(filesFound).metadata = mdata;
                end
            end
        end

        %% return to original path
        cd(originalPath);
    end

    %% remove duplicates
    filenames = {found.filename};
    paths = {found.path};
    c = cellfun(@(x, y) [x y], paths.', filenames.', 'UniformOutput', false);
    [~, ii] = unique(c, 'stable');
    found = found(ii);

    %% helper functions
    function  valid = ispathCell(obj)
        valid = ischar(obj) || iscell(obj);
    end

    function matched = matchQuery(metadata, searchQuery)
        matched = true;
        queries = fields(searchQuery);
        % check if queried keys have the same value in metadata
        % this can fail, when the key is not present --> try-catch
        try
            for ll = 1:length(queries)
                key = queries{ll};
                if ~isequal(metadata.(key), searchQuery.(key))
                    matched = false;
                    return
                end
            end
        catch
            matched = false;
            return;
        end
    end
end