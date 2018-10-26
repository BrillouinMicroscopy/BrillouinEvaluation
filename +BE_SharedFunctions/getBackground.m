function [thres] = getBackground(img)
%% GETBACKGROUND finds most frequent value in a certain range of values
%   This function calculates the backgroud signal by determining the most
%   frequently occuring value in an array
%
%   ##INPUT
%   img:            [1]     array containing the image
% 
%   ##OUTPUT
%   thres:          [1]     value of the background signal

%%
% chose number of bins so that the bin size is 0.5 pix
nrBins = round(length(img(:))/0.5);

% calculate the histogram
[N,edges] = histcounts(img,nrBins);

% find the index of the most frequent value
[Nmax, ind] = max(N);

%% check the significancy of the count
% most frequent value has to occur five times more often  than the average)
if Nmax > 5*mean(N(N~=0))
    % calculate the threshold from the borders of the bin
    thres = mean(edges(ind:ind+1));
% if it does not, use the minimum value
else
    thres = min(img(:));
end
    
%% Check results
% figure(14);
% bar(edges(1:end-1),N)
    
end