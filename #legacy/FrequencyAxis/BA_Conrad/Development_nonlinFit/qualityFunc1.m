function [sse] = qualityFunc1(maxNum, xTheo, xData)        

    errorVector = zeros(maxNum - 2, 1);

    for kk = 1:1:maxNum-2
        TheoProp = (xTheo(kk) - xTheo(kk+1))/(xTheo(kk+1) - xTheo(kk+2));
        DataProp = (xData(kk) - xData(kk+1))/(xData(kk+1) - xData(kk+2));
        errorVector(kk, :) = (DataProp - TheoProp);
    end

    sse = sum(errorVector.^2);
end