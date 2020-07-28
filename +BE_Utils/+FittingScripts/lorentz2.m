function [y] = lorentz2(x, sa, sb, wa, wb, Ba, Bb)
% LORENTZ2 model for a lorentz function with 2 peaks

    y = Ba * ((wa/2).^2) ./ ((x - sa).^2 + (wa/2).^2) + ...
        Bb * ((wb/2).^2) ./ ((x - sb).^2 + (wb/2).^2);
end