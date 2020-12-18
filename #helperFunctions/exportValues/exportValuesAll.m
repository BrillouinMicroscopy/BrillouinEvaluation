%% export measurements to excel file
masks = {'nc', 'sc', 'muscle'};
validityLimit = 40;
xlsFilename = 'BrillouinShift';
% basepaths = {'.'};    % use this to only seach the folder this file is stored in
basepaths = {'2018-06_TreatedLarva', '2018-07_UntreatedLarva'};

%% find all measurements fulfilling the query
measurements = struct();
nr = 1;
for jj = 1:length(basepaths)
    mes = dir([basepaths{jj} filesep '**' filesep '*.h5']);
    for ii = 1:length(mes)
        [filepath, name, ext] = fileparts(mes(ii).name);
        measurements(nr).filename = name;
        measurements(nr).path = erase(mes(ii).folder, [filesep 'RawData']);
        measurements(nr).metadata.sample = [erase(measurements(nr).path, basepaths{jj}) filesep measurements(nr).filename];
        nr = nr + 1;
    end
end

%% construct excel file name
xlsFilename = [xlsFilename '.xls'];

%% export values
for jj = 1:length(measurements)
    % do not break in case a file was not found, e.g. because it was not
    % evaluated
    try
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
            % do not break in case a mask was not found
            try
                maskName = masks{kk};
                %% write header
                writecell({measurements(jj).metadata.sample}, xlsFilename, 'Sheet', maskName, 'Range', conv2xlscell(1, jj));

                %% extract values with respect to the mask
                availableMasks = results.results.results.masks;
                field = findField(availableMasks, 'name', maskName);

                mask = availableMasks.(field);

                vals = BrillouinShift;
                vals(~mask.mask) = NaN;
                vals = vals(~isnan(vals));

                %% extract values and write to file
                writematrix(vals, xlsFilename, 'Sheet', maskName, 'Range', conv2xlscell(2, jj));
            catch
            end
        end
    catch
    end
end