%% script normalizes drifting processes

%% Read in all required data
filepath = 'EvalData/Brillouin.mat';

results = load(filepath, 'results');
results = results.results;

% Brillouin shift
BS = results.results.BrillouinShift_frequency;

% Positions
x = results.parameters.positions.X;
y = results.parameters.positions.Y;

% Mask with values which should have the same Brillouin shift
mask = results.results.masks.m1.mask;

% Array with the times at which the values were acquired
times = results.results.times(:);

%% Correct setup drift
% We create a normalization array to normalize the values which should be
% equal to the same value. For this, we sort by acquisition time, select
% the corresponding values using the mask, interpolate missing values and
% reshape the array to have the same size as the acquisition array.

% Create a 4D mask corresponding to the size of the Brillouin shift (needs
% adjustment when measurement dimensons change)
mask_4D = repmat(mask, 1, 1, 1, 2);
% Only select values which correspond to the mask
BS_mask = BS;
BS_mask(mask_4D == 0) = NaN;

% Calculate the mean value of the masked region
BS_mask_mean = nanmean(BS_mask(:));

% Sort the time array and save the indices to sort the Brillouin shift
% array by acquisition time
[times_sorted, indices] = sort(times, 'ascend');
% Create indices vector for reversing the sort
indices_reverse(indices) = 1:numel(BS);

% Sort the Brillouin shift by acquisition time
BS_medium_sorted = BS_mask(indices);

% Only select valid values
valid = ~isnan(BS_medium_sorted);

% Interpolate the missing values and smoothen the curve to not average out
% the noise
BS_mask_sorted_int = interp1(times_sorted(valid), BS_medium_sorted(valid), times_sorted, 'linear');
BS_mask_sorted_int_smooth = movmedian(BS_mask_sorted_int, 40, 'omitnan');

% Reverse the sort by acquisition time to allow reshaping to 4D array
BS_mask_int_smooth = BS_mask_sorted_int_smooth(indices_reverse);

% Reshape to size of Brillouin shift array
BS_mask_int_smooth_4D = reshape(BS_mask_int_smooth, size(BS));

% Calculate normalization array
normalization = BS_mask_mean/BS_mask_int_smooth_4D;

% Finally normalize the Brillouin shift
BS_normalized = BS.*normalization;

%% Save the values back to the evaluation file
results.results.BrillouinShift_frequency_normalized = BS_normalized;
save(filepath, 'results');

%% Plot data before correction
figure;
imagesc(x(1,:), y(:,1), nanmean(BS, 4));
axis image;
caxis([6.8 7.4]);
xlabel('$x$ [$\mu$m]', 'interpreter', 'latex');
ylabel('$y$ [$\mu$m]', 'interpreter', 'latex');
cb = colorbar;
title(cb, '$\nu_\mathrm{B}$ [GHz]', 'interpreter', 'latex');

%% Plot data after correction
figure;
imagesc(x(1,:), y(:,1), nanmean(BS_normalized,4));
axis image;
caxis([6.8 7.4]);
xlabel('$x$ [$\mu$m]', 'interpreter', 'latex');
ylabel('$y$ [$\mu$m]', 'interpreter', 'latex');
cb = colorbar;
title(cb, '$\nu_\mathrm{B}$ [GHz]', 'interpreter', 'latex');
