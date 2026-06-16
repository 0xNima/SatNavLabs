clc; clear;

%% TASK 2 : PDOP, HDOP, VDOP  (clock-free solution)
% Receiver position: geodetic (WGS84) -> ECEF
wgs84 = wgs84Ellipsoid('meter');
a  = wgs84.SemimajorAxis;        % semi-major axis [m]
e2 = wgs84.Eccentricity ^ 2;     % eccentricity squared

phi = deg2rad(69 + 39/60);   % 69 deg 39' N
lam = deg2rad(18 + 57/60);   % 18 deg 57' E
h   = 20;                    % [m]

N = a / sqrt(1 - e2 * sin(phi)^2);

r_rec = [
    (N + h) * cos(phi) * cos(lam);
    (N + h) * cos(phi) * sin(lam);
    (N*(1 - e2) + h) * sin(phi)
];

% Satellite positions (ECEF) [m]
S = [
    9999598.95   20702312.67   10697867.26;
    19179944.99  -12028284.00   11419688.38;
    6151266.24    9704891.74   24503075.43;
    -12519128.32   -4298464.96   21608750.10
];


nSat = size(S, 1);
A = zeros(nSat, 3);
for k = 1:nSat
    los  = S(k, :) - r_rec';
    rho  = norm(los);
    A(k, :) = los / rho;
end

Qx   = inv(A' * A);
PDOP = sqrt(trace(Qx));

% Rotate Qx into the local horizon system (ENU) for HDOP / VDOP.
R = [
    -sin(lam) -sin(phi)*cos(lam) cos(phi)*cos(lam);
    cos(lam) -sin(phi)*sin(lam) cos(phi)*sin(lam);
    0 cos(phi) sin(phi)
];

Q_local = R' * Qx * R;

HDOP = sqrt(Q_local(1,1) + Q_local(2,2));   % East + North
VDOP = sqrt(Q_local(3,3));                  % Up

fprintf('===== TASK 2 : DOP =====\n');
fprintf('Receiver ECEF [m]: %.3f  %.3f  %.3f\n', r_rec);
fprintf('PDOP = %.4f\n', PDOP);
fprintf('HDOP = %.4f\n', HDOP);
fprintf('VDOP = %.4f\n', VDOP);

%{

Receiver ECEF [m]: 2104017.444  722418.129  5957592.281
PDOP = 1.5264
HDOP = 1.2609
VDOP = 0.8602

%}


%% TASK 3 : Tropospheric and ionospheric propagation delays
PRN  = [13 24 10 19  7 31 27  2];
elev = [45 10 11 42  5 87 60 19];

ZHD = 2.30;
ZWD = 0.25;
ZTD = ZHD + ZWD;     % total zenith delay [m] (constant = 2.55 m)

% a)
mf = 1 ./ sind(elev);

d_hyd   = ZHD * mf;
d_wet   = ZWD * mf;
d_total = d_hyd + d_wet;     % total tropospheric delay [m]

fprintf('\n===== TASK 3a : Tropospheric delays =====\n');
fprintf(' PRN  elev   mf      hyd[m]   wet[m]  total[m]\n');
for k = 1:numel(PRN)
    fprintf('G%02d   %3d  %6.3f  %7.3f  %6.3f  %7.3f\n', ...
        PRN(k), elev(k), mf(k), d_hyd(k), d_wet(k), d_total(k));
end

%{

PRN  elev   mf      hyd[m]   wet[m]  total[m]
---------------------------------------------
G13    45   1.414    3.253   0.354    3.606
G24    10   5.759   13.245   1.440   14.685
G10    11   5.241   12.054   1.310   13.364
G19    42   1.494    3.437   0.374    3.811
G07     5  11.474   26.390   2.868   29.258
G31    87   1.001    2.303   0.250    2.553
G27    60   1.155    2.656   0.289    2.944
G02    19   3.072    7.065   0.768    7.832

%}

[mh, ih] = max(d_hyd);
[mw, iw] = max(d_wet);
[mt, it] = max(d_total);
fprintf('Max hydrostatic delay : %.3f m  (G%02d, eps = %d deg)\n', mh, PRN(ih), elev(ih));
fprintf('Max wet delay         : %.3f m  (G%02d, eps = %d deg)\n', mw, PRN(iw), elev(iw));
fprintf('Largest TOTAL delay   : %.3f m  (G%02d, eps = %d deg)\n', mt, PRN(it), elev(it));
% Largest delays always occur at the LOWEST elevation -> G07 (eps = 5 deg).

%{

Max hydrostatic delay : 26.390 m  (G07, eps = 5 deg)
Max wet delay         : 2.868 m  (G07, eps = 5 deg)
Largest TOTAL delay   : 29.258 m  (G07, eps = 5 deg)

%}


% b)
eps_v = linspace(0.1, 90, 1000);
mfp   = 1 ./ sind(eps_v);

figure;
plot(eps_v, ZHD*mfp, 'b-', 'LineWidth', 1.5); hold on;
plot(eps_v, ZWD*mfp, 'r-', 'LineWidth', 1.5);
plot(eps_v, (ZHD+ZWD)*mfp, 'k--', 'LineWidth', 1.2);
grid on; ylim([0 30]);
xlabel('Elevation angle \epsilon [deg]');
ylabel('Tropospheric delay [m]');
legend('Hydrostatic  ZHD/sin\epsilon', 'Wet  ZWD/sin\epsilon', ...
       'Total  ZTD/sin\epsilon', 'Location', 'northeast');
title('Tropospheric slant delay vs elevation (mf = 1/sin\epsilon)');

% c-e)
f1 = 1575.42e6;   % GPS L1 [Hz]
f2 = 1227.60e6;   % GPS L2 [Hz]

iono = @(TECU, f) 40.3 * (TECU * 1e16) ./ f.^2;   % [m], TEC given in TECU

fprintf('\n===== TASK 3c/d : Ionospheric pseudorange delay =====\n');
for TECU = [20.77, 110]
    IL1 = iono(TECU, f1);
    IL2 = iono(TECU, f2);
    fprintf('TEC = %6.2f TECU :  L1 = +%.3f m,  L2 = +%.3f m\n', TECU, IL1, IL2);
end

%{

c) TEC =  20.77 TECU :  L1 = +3.372 m,  L2 = +5.554 m
d) TEC = 110.00 TECU :  L1 = +17.861 m,  L2 = +29.416 m
e) carrier phase: same magnitude, OPPOSITE sign (phase ADVANCE),
i.e. L1 = -3.37 m, L2 = -5.55 m at 20.77 TECU.

%}

%% TASK 4
L1 =  f1^2 / (f1^2 - f2^2);
L2 = -f2^2 / (f1^2 - f2^2);

% Error propagation:  sigma_L3^2 = a1^2 * sigma_L1^2 + a2^2 * sigma_L2^2
sigma_L1 = 1.5;   % [mm]
sigma_L2 = 2.0;   % [mm]
sigma_L3 = sqrt(L1^2 * sigma_L1^2 + L2^2 * sigma_L2^2);

fprintf('\n===== TASK 4 : Ionosphere-free combination L3 =====\n');
fprintf('L1 = %+.4f\n', L1);
fprintf('L2 = %+.4f\n', L2);
fprintf('L1 + L2 = %.4f  (geometry-preserving -> must equal 1)\n', L1 + L2);
fprintf('sigma_L1 = %.1f mm,  sigma_L2 = %.1f mm\n', sigma_L1, sigma_L2);
fprintf('sigma_L3 = %.3f mm\n', sigma_L3);
fprintf('amplification factor sqrt(L1^2+L2^2) = %.3f\n', sqrt(L1^2 + L2^2));

%{

L1 = +2.5457
L2 = -1.5457
L1 + L2 = 1.0000  (geometry-preserving -> must equal 1)
sigma_L1 = 1.5 mm,  sigma_L2 = 2.0 mm
sigma_L3 = 4.913 mm
amplification factor sqrt(L1^2+L2^2) = 2.978

%}
