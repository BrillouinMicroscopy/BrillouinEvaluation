function [ estimates, FittedCurve ] = LinEqFit( xData, yData, start )
%This function fits a linear equation to the data
% parameters:
% xData             data from x-axis
% yData             data from y-axis
% start = [m, n]    start parameters for fit


fun = @lineq;
options = optimset('TolFun', 1e-13);
estimates = fminsearch(fun, start, options);

    function [error, y] = lineq(params)
        m = params(1);
        n = params(2);
        
        y = m*xData + n;
        error = sum((y - yData).^2);
    end
[~, FittedCurve] = lineq(estimates);
end

