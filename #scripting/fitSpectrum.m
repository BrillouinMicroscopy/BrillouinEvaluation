function [estimates2b, model2b, newxb, FittedCurve2b] = fitSpectrum(newxb, newdata2b, start)

    model2b = @(params) circle(params, newxb, newdata2b, -1);
    [estimates2b, model2b, newxb, FittedCurve2b] = fitCircle(model2b, newxb, start);
    
    function [estimates2b, model2b, newxb, FittedCurve2b] = fitCircle(model2b, newxb, start)

        options = optimset('MaxFunEvals', 100000, 'MaxIter', 100000);
        estimates2b = fminsearch(model2b, start, options);

        [~, FittedCurve2b] = model2b(estimates2b);
    end
    
end