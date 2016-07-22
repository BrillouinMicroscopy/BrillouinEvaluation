function [ n_fit, fun1 ] = VIPAFit( maxima, n_start, d, theta_vipa, lambda, F, x0_start, xS, StartOrder )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    
    start = [n_start, x0_start];
    maxima = sortrows(maxima, 1);

    fun1 = @ComProp;
    options = optimset('MaxFunEvals', 10000000, 'MaxIter', 10000000, 'TolX', 1e-7);
    n_fit = fminsearch(fun1, start, options);
    
    function [sse, xTheo] = ComProp(params)
        
        n = params(1);
        x0 = params(2);
        
        maxNum = size(maxima, 1);
        
        [xTheo, ~] = VIPApeaks( d, n, theta_vipa, lambda, F, x0, xS, maxNum, StartOrder);
        xTheo = sort(xTheo, 'ascend');
        
        xData = maxima(:,1);
        
%         e1 = qualityFunc1(maxNum, xTheo, xData);
        sse = qualityFunc2(maxima, xTheo, xData);
        
%         sse = e1 + e2*1e5;
    end
    %     [~, x_F] = fun1(n_fit);
end

