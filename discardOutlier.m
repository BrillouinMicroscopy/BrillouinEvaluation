function [values, nrDiscarded] = discardOutlier(values, dim, maxd)
%% DISCARDOUTLIER
%   function discards outliers which differ from the median by more than maxd
%   by setting them to NaN
% 
%   ##INPUT
%   values:         [1]     array containing the values to be cleaned
%   dim:            [1]     dimension along which the cleaning is done
%   maxd:           [1]     maximum difference a value is allowed to have from
%                           median
% 
%   ##OUTPUT
%   values:         [1]     cleaned array
%   nrDiscarded     [1]     number of discarded values

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
nrDiscarded = sum(mask(:));

%discard all values which differ from median more than by "maxd"
values(mask) = NaN;

end