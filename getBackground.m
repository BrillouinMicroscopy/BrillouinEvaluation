function [ thres ] = getBackground( img )
%GETBACKGROUND   most frequent value in a certain range of values
%   backgroud = getBackground(img)

    % chose number of bins so that the bin size is 0.5 pix
    nrBins = round(max(img(:))/0.5);
    
    % calculate the histogram
    [N,edges] = histcounts(img,nrBins);
    
    % find the index of the most frequent value
    [~, ind] = max(N);
    
    % calculate the threshold from the borders of the bin
    thres = mean(edges(ind:ind+1));
    
    %% Check results
%     figure(14);
%     bar(edges(1:end-1),N)
    
end