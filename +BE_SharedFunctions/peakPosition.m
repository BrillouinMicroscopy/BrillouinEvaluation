function [ r ] = peakPosition( VIPAparams, constants, frequencies )
%PEAKPOSITION
% Find the position on the camera for a given frequency

a = VIPAparams.C;
b = VIPAparams.B;
c = VIPAparams.A - 1./(frequencies + 1e-9*constants.f_0);

r1 = -b./(2*a) + sqrt(b^2 - 4*a*c)./(2*a);
r2 = -b./(2*a) - sqrt(b^2 - 4*a*c)./(2*a);

if sum(r1(:)) > sum(r2(:))
    r = r1;
else
    r = r2;
end

end