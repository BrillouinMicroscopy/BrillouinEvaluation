function [sseb, FittedCurve2b] = lorentz4wrapper(params, newxb, newdata2b, floorb)
% LORENTZ4WRAPPER model for a lorentz function with 4 peaks

    sa = params(1);
    sb = params(2);
    sc = params(3);
    sd = params(4);

    wa = params(5);
    wb = params(6);
    wc = params(7);
    wd = params(8);

    Ba = abs(params(9)) - floorb;
    Bb = abs(params(10)) - floorb;
    Bc = abs(params(11)) - floorb;
    Bd = abs(params(12)) - floorb;

    FittedCurve2b = floorb + BE_Utils.FittingScripts.lorentz4(newxb, sa, sb, sc, sd, wa, wb, wc, wd, Ba, Bb, Bc, Bd);
    ErrorVectorb = FittedCurve2b - newdata2b;

    sseb = sum(ErrorVectorb.^2);
end