function [sseb, FittedCurve2b] = lorentz2wrapper(params, newxb, newdata2b, floorb)
% LORENTZ2WRAPPER model for a lorentz function with 2 peaks

    sa = params(1);
    sb = params(2);

    wa = params(3);
    wb = params(4);

    Ba = abs(params(5)) - floorb;
    Bb = abs(params(6)) - floorb;

    FittedCurve2b = floorb + BE_Utils.FittingScripts.lorentz2(newxb, sa, sb, wa, wb, Ba, Bb);

    ErrorVectorb = FittedCurve2b - newdata2b;

    sseb = sum(ErrorVectorb.^2);
end