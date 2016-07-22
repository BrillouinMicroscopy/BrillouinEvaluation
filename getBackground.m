function [ thres ] = getBackground( img )
%GETBACKGROUND   most frequent value in a certain range of values
%   backgroud = getBackground(img)

    [N,edges] = histcounts(img,1000);
    
    [~, ind] = max(N);
    
    thres = mean(edges(ind:ind));
    
end