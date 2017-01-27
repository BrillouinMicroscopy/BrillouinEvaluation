function [sseb, FittedCurve] = circle(params, newxb, newdata2b, sign)
% CIRCLE model for a circle

    xm = params(1);

    ym = params(2);

    r = params(3);

    FittedCurve = ym + sign * sqrt(r.^2 - (newxb-xm).^2);

    ErrorVectorb = FittedCurve - newdata2b;

    sseb = sum(ErrorVectorb.^2);
end