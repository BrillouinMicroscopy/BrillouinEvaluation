function [estimates2b, model2b, newxb, FittedCurve2b, deviation] = nfit_2peakscon(newxb, newdata2b, start, floorb)
    
    model2b = @(params) BE_Utils.FittingScripts.lorentz2(params, newxb, newdata2b, floorb);
    %fit lorentzfunction with two peaks and constrains
    [estimates2b, model2b, newxb, FittedCurve2b, deviation] = BE_Utils.FittingScripts.fitLorentzcon(model2b, newxb, start);
end

