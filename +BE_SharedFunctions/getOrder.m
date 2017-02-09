function m = getOrder( VIPAparams, constants, order )
%GETORDER 
% Uses the non-linear description from DOI 10.1109/JQE.2004.825210

%% number of wavelengths in the cavity
% solve eq. 14 in the above mentioned paper for max[m]
m_max = BE_SharedFunctions.getMinimalOrder(VIPAparams, constants);

%% interesting number of wavelengths
% (given by startOrder and number of requested peaks)
m = m_max - order + 1;
end