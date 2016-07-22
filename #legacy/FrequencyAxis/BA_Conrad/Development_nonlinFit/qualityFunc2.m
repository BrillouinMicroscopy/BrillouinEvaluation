function [sse] = qualityFunc2(maxima, xTheo, xData)

%     errorVector = (xData.' - xTheo) .* (maxima(:, 2).');
    errorVector = (xData.' - xTheo) .* [0.05 0.99 0.99 0.05 0.05 0.05];
%     errorVector = (xData - xTheo);
    sse = sum(abs(errorVector).^2);

end