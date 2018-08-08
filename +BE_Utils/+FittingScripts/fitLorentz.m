function [estimates2b, model2b, newxb, FittedCurve2b, deviation] = fitLorentz(model2b, newxb, start)

    options = optimset('MaxFunEvals', 100000, 'MaxIter', 100000, 'Display', 'off');
    estimates2b = fminsearch(model2b, start, options);
    
    [deviation, FittedCurve2b] = model2b(estimates2b);
end

