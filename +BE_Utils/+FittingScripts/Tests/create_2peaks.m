function [lorentziancurve] = create_2peaks(s, s0, s1, B0, B1, w0, floor)
    lorentziancurve = floor + ...
                B0*((w0/2).^2)./((s-s0).^2+(w0/2).^2) + ...
                B1*((w0/2).^2)./((s-s1).^2+(w0/2).^2);
end