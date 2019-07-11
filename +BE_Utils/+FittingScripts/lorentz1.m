function [sseb, FittedCurve2b] = lorentz1(params, newxb, newdata2b, floorb)
% LORENTZ1 model for a lorentz function with 1 peak

    s0b = params(1);

    w0b = params(2);

    B0b = abs(params(3))-floorb;

    FittedCurve2b = floorb + ...
                    B0b*((w0b/2).^2)./((newxb-s0b).^2+(w0b/2).^2);

    ErrorVectorb = FittedCurve2b - newdata2b;

    sseb = sum(ErrorVectorb.^2);
end