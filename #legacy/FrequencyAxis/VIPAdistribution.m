%% set parameters for the VIPA
f = 0.20;                                    % focal length first lens
F = 0.20;                                    % focal length second lens
W = 0.005;                                  % width of the beam
R = 0.995;                                      % reflectivity mirror 1
r = 0.95;                                   % reflectivity mirror 2
t = 0.00677;                                % width of the VIPA cavity
Lambda1 = 780.24e-9;
Lambda1 = 7.802477122933031e-07;
Lambda1 = 7.802322878591584e-07;                      % wavelengths of the incident light
% Lambda2 = 779*10^(-9);
% Lambda3 = 781*10^(-9);
n = 1.45375;                                    % refractiv index of the VIPA
theta_vipa = 2*1/360*2*pi;                  % angle inside the VIPA
% theta_in = asin(sin(theta_vipa)/n); % angle of the VIPA

%% set parameters for the plot
xMin = -0.01;                              % min x value
xMax = 0.01;                               % max x value
xRes = 0.000001;                            % x resolution

%% calculate intensity distributions

x = xMin:xRes:xMax;                  % creating x values

I_out1 = IntDistVIPA(f, F, W, R, r, t, Lambda1, n, theta_vipa, x);

% I_out2 = IntDistVIPA(f, F, W, R, r, t, Lambda2, n, theta_in, theta_vipa, x);

% I_out3 = IntDistVIPA(f, F, W, R, r, t, Lambda3, n, theta_in, theta_vipa, x);

% I_out = I_out1 + I_out2 + I_out3;

% start = ones(12, 1);
% start(1) = 0.21;
% start(2) = 0.19;
% start(3) = 0.0016;
% start(4) = 0.99;
% start(5) = 0.93;
% start(6) = 0.005;
% start(7) = 780.93*10^(-9);
% start(8) = 1.2;
% start(9) = 0.8*1/360*2*pi;
% start(10) = 1;
% 
% lb = zeros(12, 1);
% lb(1) = 0.21;
% lb(2) = 0.19;
% lb(3) = 0.0016;
% lb(4) = 0.99;
% lb(5) = 0.93;
% lb(6) = 0.005;
% lb(7) = 780.93*10^(-9);
% lb(8) = 1.2;
% lb(9) = 0.8*1/360*2*pi;
% lb(10) = -inf;
% lb(11) = -inf;
% lb(12) = -inf;
% 
% ub = zeros(12, 1);
% ub(1) = 0.21;
% ub(2) = 0.19;
% ub(3) = 0.0016;
% ub(4) = 0.99;
% ub(5) = 0.93;
% ub(6) = 0.005;
% ub(7) = 780.93*10^(-9);
% ub(8) = 1.2;
% ub(9) = 0.8*1/360*2*pi;
% ub(10) = inf;
% ub(11) = inf;
% ub(12) = inf;

% x1 = x+1.001;

% [estimates, intensity] = IntDistVIPAfit(x1, I_out1, start, lb, ub);

x0 = 0;
k = 10;

% x_p = VIPApeaks( t, n, theta_vipa, Lambda1, F, x0, k );
figure(4)
hold on
plot(x, I_out1, 'g')
% plot(x_p, ones(size(x_p, 2)), 'rX')
% plot(x, intensity, 'b')