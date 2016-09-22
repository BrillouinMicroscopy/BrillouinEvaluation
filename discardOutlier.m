function [ values, nrDdiscarded ] = discardOutlier ( values, dim, maxd )
%% DISCARDOUTLIER
% function discards outliers by setting them to NaN

% calculate the median along the specified dimension
med = nanmedian(values,dim);

% create an array of the median value similar with the same size as the
% values array
repeats = ones(1,ndims(values));
repeats(dim) = size(values,dim);
should = repmat(med,repeats);

% calculate the absolute difference between the median and each value
dif = abs(values - should);

mask = dif > abs(maxd*values);
nrDdiscarded = sum(mask(:));

%discard all values which differ from median more than by "maxd"
values(mask) = NaN;

end