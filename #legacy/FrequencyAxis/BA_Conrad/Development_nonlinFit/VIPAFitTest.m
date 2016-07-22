function [ n_fit, fun1, x_F ] = VIPAFitTest( maxima, n_start, d, theta_vipa, lambda, lambdaS, lambdaAS, F, x0_start, xS, StartOrder )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    
    start = [n_start, x0_start];
%     maxima = sortrows(maxima, 1);

    fun1 = @ComProp;
    options = optimset('MaxFunEvals', 10000000, 'MaxIter', 10000000, 'TolX', 1e-7);
    n_fit = fminsearch(fun1, start, options);
    
    function [sse, xTheo] = ComProp(params)
        
        n = params(1);
        x0 = params(2);
        
        [xTheo, m] = VIPApeaks( d, n, theta_vipa, lambda, F, x0, xS, 2, StartOrder);
        xTheoS = ShiftPeaks( d, n, theta_vipa, lambdaS, F, x0, xS, m(1));
        xTheoAS = ShiftPeaks( d, n, theta_vipa, lambdaAS, F, x0, xS, m(2));
        
        xTheo(3:4) = [xTheoS, xTheoAS];
        xTheo = sort(xTheo, 'ascend');
        
        xData = maxima;
        
%         e1 = qualityFunc1(maxNum, xTheo, xData);
        sse = qualityFunc2(maxima, xTheo, xData);
        
%         sse = e1 + e2*1e5;
    end
    [~, x_F] = fun1(n_fit);
end

