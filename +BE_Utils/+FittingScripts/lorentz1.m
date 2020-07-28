function [y] = lorentz1(x, sa, wa, Ba)
% LORENTZ1 model for a lorentz function with 1 peak

    y = Ba * ((wa/2).^2) ./ ((x - sa).^2 + (wa/2).^2);
end