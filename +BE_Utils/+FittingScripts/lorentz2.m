function [sseb, FittedCurve2b] = lorentz2(params, newxb, newdata2b, floorb)
% LORENTZ2 model for a lorentz function with 2 peaks

    s0b = params(1);
    s1b = params(2);

    w0b = params(3);
    w1b = params(4);

    B0b = params(5)-floorb;
    B1b = params(6)-floorb;

    FittedCurve2b = floorb + ...
                    B0b*((w0b/2).^2)./((newxb-s0b).^2+(w0b/2).^2) + ...
                    B1b*((w1b/2).^2)./((newxb-s1b).^2+(w1b/2).^2);

    ErrorVectorb = FittedCurve2b - newdata2b;

    sseb = sum(ErrorVectorb.^2);
end