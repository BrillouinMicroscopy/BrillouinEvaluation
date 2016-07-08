function [ maxima ] = GetMaxima( spectrum, background, cut)
%GetMaxima localises maxima in the data spectrum

%   input:
%   spectrum: matrix with data
%   background: maximum backround intensity
%   cut: number of quadratic layers around the maxima to cut out in
%        progress
%
%   output:
%   maxima: matrix [x, y, intensity]

%   first locating the main maximum, saving position and intensity
%   second cutting out the maximum +/- cut
%   repeat until there is no maximum > backround

n = true;
m = 1;
X = size(spectrum,2);
Y = size(spectrum,1);

maxima = zeros(3, 1);

while n == true
    [Imax, ind] = max(spectrum(:));             % locating main maximum
    if Imax > background
        [y,x] = ind2sub(size(spectrum), ind);  
        
        % specify layers to cut out
        ymin = y - cut;
        ymin(ymin < 1) = 1;
        ymax = y + cut;
        ymax(ymax > Y) = Y;
        xmin = x - cut;
        xmin(xmin < 1) = 1;
        xmax = x + cut;
        xmax(xmax > X) = X;
        
        % cut out maxima
        spectrum(ymin:ymax,xmin:xmax) = 0;
        
        maxima(:, m) = [x; y; Imax];            % save position and intensity
        m = m+1;                                % count-parameter
    else
        n = false;
    end
end

end

