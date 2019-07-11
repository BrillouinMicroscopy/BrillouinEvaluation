function [sseb, FittedCurve2b] = lorentz4(params, newxb, newdata2b, floorb)
% LORENTZ4 model for a lorentz function with 4 peaks

    s0b = params(1);
    s1b = params(2);
    s2b = params(3);
    s3b = params(4);

    w0b = params(5);
    w1b = params(6);
    w2b = params(7);
    w3b = params(8);

    B0b = abs(params(9))-floorb;
    B1b = abs(params(10))-floorb;
    B2b = abs(params(11))-floorb;
    B3b = abs(params(12))-floorb;

    FittedCurve2b = floorb + ...
                    B0b*((w0b/2).^2)./((newxb-s0b).^2+(w0b/2).^2) + ...
                    B1b*((w1b/2).^2)./((newxb-s1b).^2+(w1b/2).^2) + ...
                    B2b*((w2b/2).^2)./((newxb-s2b).^2+(w2b/2).^2) + ...
                    B3b*((w3b/2).^2)./((newxb-s3b).^2+(w3b/2).^2);

    ErrorVectorb = FittedCurve2b - newdata2b;

    sseb = sum(ErrorVectorb.^2);
end