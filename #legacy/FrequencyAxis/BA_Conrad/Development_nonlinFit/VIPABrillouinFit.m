function [ fitParams, fun1 ] = VIPABrillouinFit( peaks, start, ub, lb, lambda, lambdaS, lambdaAS, F, StartOrder, RpeakNum )
%UNTITLED4 Summary of this function goes here
%   start  = [dStart, nStart, thetaStart, x0Start, xsStart]
%   ub = [dMax, nMax, thetaMax, x0Max, xsMax]
%   lb = [dMin, nMin, thetaMin, x0Min, xsMin]

    fun1 = @ComProp;
    options = optimset('MaxFunEvals', 10000000, 'MaxIter', 10000000, 'TolX', 1e-13, 'TolFun', 1e-9);
    fitParams = fmincon(fun1, start, [], [], [], [], lb, ub, [], options);
    
    function [ErrorVector, xTheo] = ComProp(params)
        
        d = params(1);
        n = params(2);
        theta = params(3);
        x0 = params(4);
        xs = params(5);
        peaks = sort(peaks, 'ascend');
        
        [xTheo, m] = VIPApeaks( d, n, theta, lambda, F, x0, xs, RpeakNum, StartOrder);
        m = sort(m, 'descend');
        xTheoS = ShiftPeaks( d, n, theta, lambdaS, F, x0, xs, m(2));
        xTheoAS = ShiftPeaks( d, n, theta, lambdaAS, F, x0, xs, m(1));
         
        xTheo(RpeakNum + 1:RpeakNum + 2) = [xTheoS, xTheoAS];
        xTheo = sort(xTheo, 'ascend');
        
        err = (peaks - xTheo); % .* [0.1 0.99 0.99 0.5 0.3 0.1];
        ErrorVector = sum(err.^2);
        
        
        
    end
    %     [~, x_F] = fun1(n_fit);
end

