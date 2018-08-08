%% export measurements to excel file
searchQuery = struct(...
    'treatment', 'IWR', ...
    'dpf', 4.0 ...
);   % the search query

masks = {'notochord', 'spinal cord', 'muscle'};
validityLimit = 40;

%% find all measurements fulfilling the query
measurements = findBrillouinMeasurements(searchQuery, 'basepath', '.');
% measurements = findBrillouinMeasurements(searchQuery, 'basepath', ...
%     {'01_ZebraFish\2018-03_TreatedLarva\','01_ZebraFish\2018-04_TreatedLarva\'});

%% construct excel file name
xlsFilename = 'BrillouinShift';
searchQueries = fields(searchQuery);
for ii = 1:length(searchQueries)
    xlsFilename = [xlsFilename, '_' searchQueries{ii} '-' num2str(searchQuery.(searchQueries{ii}))]; %#ok<AGROW>
end
xlsFilename = [xlsFilename '.xls'];

%% export values
for jj = 1:length(measurements)
    %% load file and get Brillouin shift
    results = load([measurements(jj).path filesep 'EvalData' filesep measurements(jj).filename '.mat']);

    BrillouinShift = results.results.results.BrillouinShift_frequency;
    validity = results.results.results.validity;
    validityLevel = results.results.results.peaksBrillouin_dev./results.results.results.peaksBrillouin_int;
    
    % filter invalid values
    BrillouinShift(~validity) = NaN;
    BrillouinShift(validityLevel > validityLimit) = NaN;

    BrillouinShift = mean(BrillouinShift, 4);

    BrillouinShift = squeeze(BrillouinShift);

    for kk = 1:length(masks)
        try
            maskName = masks{kk};
            %% write header
            xlswrite(xlsFilename, {measurements(jj).metadata.sample}, maskName, conv2xlscell(1, jj));

            %% extract values with respect to the mask
            availableMasks = results.results.results.masks;
            field = findField(availableMasks, 'name', maskName);
            
            mask = availableMasks.(field);
            
            vals = BrillouinShift;
            vals(~mask.mask) = NaN;
            vals = vals(~isnan(vals));

            %% extract values and write to file
            xlswrite(xlsFilename, vals, maskName, conv2xlscell(2, jj));
        catch
        end
    end
end