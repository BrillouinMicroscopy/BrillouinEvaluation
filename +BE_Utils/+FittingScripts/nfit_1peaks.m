function [estimates2b, model2b, newxb, FittedCurve2b, deviation] = nfit_1peaks(newxb, newdata2b, start, floorb)
    
    model2b = @(params) BE_Utils.FittingScripts.lorentz1(params, newxb, newdata2b, floorb);
    [estimates2b, model2b, newxb, FittedCurve2b, deviation] = BE_Utils.FittingScripts.fitLorentz(model2b, newxb, start);
end

