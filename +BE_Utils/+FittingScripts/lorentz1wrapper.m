function [sseb, FittedCurve2b] = lorentz1wrapper(params, newxb, newdata2b, floorb)
% LORENTZ1WRAPPER model for a lorentz function with 1 peak

    sa = params(1);

    wa = params(2);

    Ba = abs(params(3)) - floorb;

    FittedCurve2b = floorb + BE_Utils.FittingScripts.lorentz1(newxb, sa, wa, Ba);

    ErrorVectorb = FittedCurve2b - newdata2b;

    sseb = sum(ErrorVectorb.^2);
end