clear; clc; close all;

FIG = 'figures';
if ~exist(FIG, 'dir'); mkdir(FIG); end

% column names (INSTINCT log headers, kept verbatim)
C_N   = 'North/South [m]';   % local North offset -> N
C_E   = 'East/West [m]';     % local East  offset -> E
C_ALT = 'Altitude [m]';      % ellipsoidal height -> used for Up
C_NS  = 'Number satellites';
C_T   = 'Time [s]';

stdp = @(x) std(x, 1);       % population standard deviation (ddof = 0)

%%  TASK 1 - GPS only, elevation mask 5 deg, both atmospheric models (default)
t1 = loadlog('task1_logs');
t  = t1.(C_T);

% --- 1a  number of received satellites
ns = t1.(C_NS);
[ns_min, ns_max, ns_mean] = mmm(ns);

f = figure('Position', [100 100 1100 400]);
plot(t, ns, 'LineWidth', 0.8, 'Color', [0 0.45 0.74]); hold on;
yline(ns_mean, '--k', sprintf('mean = %.2f', ns_mean), 'LineWidth', 1);
xlabel('Time [s]'); ylabel('Number of satellites');
title('Task 1a - Number of received GPS satellites (El > 5 deg)');
ylim([0 max(ns)+2]); grid on;
exportgraphics(f, fullfile(FIG, 'task1a_num_satellites.png'), 'Resolution', 140);

% --- 1b  PDOP / HDOP / VDOP
[p_min, p_max, p_mean] = mmm(t1.PDOP);
[h_min, h_max, h_mean] = mmm(t1.HDOP);
[v_min, v_max, v_mean] = mmm(t1.VDOP);

f = figure('Position', [100 100 1100 400]);
plot(t, t1.PDOP, 'LineWidth', 0.8); hold on;
plot(t, t1.HDOP, 'LineWidth', 0.8);
plot(t, t1.VDOP, 'LineWidth', 0.8);
xlabel('Time [s]'); ylabel('DOP [-]');
title('Task 1b - Dilution of Precision (El > 5 deg, GPS only)');
legend({'PDOP', 'HDOP', 'VDOP'}, 'Location', 'best'); grid on;
exportgraphics(f, fullfile(FIG, 'task1b_dop.png'), 'Resolution', 140);

% --- 1c  GPS vs GPS+Galileo
t1c = loadlog('task1-c_logs');
nsg = t1c.(C_NS);
[nsg_min, nsg_max, nsg_mean] = mmm(nsg);

f = figure('Position', [100 100 1100 400]);
plot(t, ns, 'LineWidth', 0.8, ...
     'DisplayName', sprintf('GPS only (mean %.2f)', ns_mean)); hold on;
plot(t1c.(C_T), nsg, 'LineWidth', 0.8, 'Color', [0.85 0.33 0.10], ...
     'DisplayName', sprintf('GPS + Galileo (mean %.2f)', nsg_mean));
xlabel('Time [s]'); ylabel('Number of satellites');
title('Task 1c - Satellite count: GPS only vs. GPS + Galileo (El > 5 deg)');
legend('Location', 'best'); grid on;
exportgraphics(f, fullfile(FIG, 'task1c_gps_vs_galileo.png'), 'Resolution', 140);

%%  TASK 2 - atmospheric models, E/N/U mean & std
% common Up reference: mean altitude of the "both models / El>5" solution
ALT_REF = mean(t1.(C_ALT));

t2_labels = {'a) no model', 'b) tropo only (Saast.)', ...
             'c) iono only (Klobuchar)', 'd) both models'};
t2_files  = {'task2-a_logs', 'task2-b_logs', 'task2-c_logs', 'task2-d_logs'};

t2 = struct('label', {}, 'E_mean', {}, 'E_std', {}, 'N_mean', {}, 'N_std', {}, ...
            'U_mean', {}, 'U_std', {}, 'hor_rms', {});

f = figure('Position', [100 100 1100 900]);
ax1 = subplot(3,1,1); hold(ax1,'on'); grid(ax1,'on');
ax2 = subplot(3,1,2); hold(ax2,'on'); grid(ax2,'on');
ax3 = subplot(3,1,3); hold(ax3,'on'); grid(ax3,'on');
for k = 1:numel(t2_files)
    df = loadlog(t2_files{k});
    [E, N, U] = enu(df, C_E, C_N, C_ALT, ALT_REF);
    t2(k).label   = t2_labels{k};
    t2(k).E_mean  = mean(E); t2(k).E_std = stdp(E);
    t2(k).N_mean  = mean(N); t2(k).N_std = stdp(N);
    t2(k).U_mean  = mean(U); t2(k).U_std = stdp(U);
    t2(k).hor_rms = sqrt(mean(E.^2 + N.^2));
    tt = df.(C_T);
    plot(ax1, tt, E, 'LineWidth', 0.7, 'DisplayName', t2_labels{k});
    plot(ax2, tt, N, 'LineWidth', 0.7, 'DisplayName', t2_labels{k});
    plot(ax3, tt, U, 'LineWidth', 0.7, 'DisplayName', t2_labels{k});
end
ylabel(ax1, 'East [m]');  ylabel(ax2, 'North [m]');  ylabel(ax3, 'Up [m] (rel. ref)');
xlabel(ax3, 'Time [s]');
title(ax1, 'Task 2 - E/N/U position, effect of atmospheric models (El > 5 deg)');
legend(ax1, 'Location', 'northeast', 'NumColumns', 4, 'FontSize', 8);
exportgraphics(f, fullfile(FIG, 'task2_enu_atmos.png'), 'Resolution', 140);

% horizontal scatter (E vs N)
f = figure('Position', [100 100 600 600]); hold on; grid on;
for k = 1:numel(t2_files)
    df = loadlog(t2_files{k});
    [E, N, ~] = enu(df, C_E, C_N, C_ALT, ALT_REF);
    scatter(E, N, 6, 'filled', 'MarkerFaceAlpha', 0.3, 'DisplayName', t2_labels{k});
end
xlabel('East [m]'); ylabel('North [m]');
title('Task 2 - Horizontal scatter'); axis equal;
legend('Location', 'best', 'FontSize', 8);
exportgraphics(f, fullfile(FIG, 'task2_scatter.png'), 'Resolution', 140);

%%  TASK 3 - elevation mask, E/N/U mean & std (both models enabled)
t3_labels = {'a) El > 5', 'b) El > 15', 'c) El > 30'};
t3_files  = {'task1_logs', 'task3-E15_logs', 'task3-E30_logs'};  % t1 = t2d (both, El>5)

t3 = struct('label', {}, 'n', {}, 'E_mean', {}, 'E_std', {}, 'N_mean', {}, ...
            'N_std', {}, 'U_mean', {}, 'U_std', {}, 'hor_rms', {}, ...
            'ns_min', {}, 'ns_max', {}, 'ns_mean', {}, ...
            'pdop_mean', {}, 'hdop_mean', {}, 'vdop_mean', {});

f = figure('Position', [100 100 1100 900]);
ax1 = subplot(3,1,1); hold(ax1,'on'); grid(ax1,'on');
ax2 = subplot(3,1,2); hold(ax2,'on'); grid(ax2,'on');
ax3 = subplot(3,1,3); hold(ax3,'on'); grid(ax3,'on');
for k = 1:numel(t3_files)
    df = loadlog(t3_files{k});
    [E, N, U] = enu(df, C_E, C_N, C_ALT, ALT_REF);
    nvalid = height(df);
    t3(k).label   = t3_labels{k};  t3(k).n = nvalid;
    t3(k).E_mean  = mean(E); t3(k).E_std = stdp(E);
    t3(k).N_mean  = mean(N); t3(k).N_std = stdp(N);
    t3(k).U_mean  = mean(U); t3(k).U_std = stdp(U);
    t3(k).hor_rms = sqrt(mean(E.^2 + N.^2));
    [t3(k).ns_min, t3(k).ns_max, t3(k).ns_mean] = mmm(df.(C_NS));
    t3(k).pdop_mean = mean(df.PDOP);
    t3(k).hdop_mean = mean(df.HDOP);
    t3(k).vdop_mean = mean(df.VDOP);
    tt = df.(C_T);
    if nvalid == 1, mk = 'o'; else, mk = 'none'; end
    plot(ax1, tt, E, 'LineWidth', 0.7, 'Marker', mk, 'DisplayName', t3_labels{k});
    plot(ax2, tt, N, 'LineWidth', 0.7, 'Marker', mk, 'DisplayName', t3_labels{k});
    plot(ax3, tt, U, 'LineWidth', 0.7, 'Marker', mk, 'DisplayName', t3_labels{k});
end
ylabel(ax1, 'East [m]');  ylabel(ax2, 'North [m]');  ylabel(ax3, 'Up [m] (rel. ref)');
xlabel(ax3, 'Time [s]');
title(ax1, 'Task 3 - E/N/U position, effect of elevation mask (both models)');
legend(ax1, 'Location', 'northeast', 'NumColumns', 3, 'FontSize', 8);
exportgraphics(f, fullfile(FIG, 'task3_enu_elevmask.png'), 'Resolution', 140);

% satellites & PDOP vs elevation mask (E5 vs E15)
f = figure('Position', [100 100 1100 600]);
axa = subplot(2,1,1); hold(axa,'on'); grid(axa,'on');
axb = subplot(2,1,2); hold(axb,'on'); grid(axb,'on');
for k = 1:2
    df = loadlog(t3_files{k});
    plot(axa, df.(C_T), df.(C_NS), 'LineWidth', 0.7, 'DisplayName', t3_labels{k});
    plot(axb, df.(C_T), df.PDOP,   'LineWidth', 0.7, 'DisplayName', t3_labels{k});
end
ylabel(axa, 'Num. satellites'); ylabel(axb, 'PDOP'); xlabel(axb, 'Time [s]');
title(axa, 'Task 3 - Satellite count & PDOP vs elevation mask');
legend(axa, 'Location', 'best', 'FontSize', 8);
legend(axb, 'Location', 'best', 'FontSize', 8);
exportgraphics(f, fullfile(FIG, 'task3_sats_pdop.png'), 'Resolution', 140);

%%  print all results
line = repmat('=', 1, 74);
fprintf('%s\n', line);
fprintf('TASK 1a  Number of received satellites (GPS only, El>5)\n');
fprintf('   min = %.0f   max = %.0f   mean = %.2f\n\n', ns_min, ns_max, ns_mean);

fprintf('TASK 1b  DOP values\n');
fprintf('   %-5s  min = %.3f   max = %.3f   mean = %.3f\n', 'PDOP', p_min, p_max, p_mean);
fprintf('   %-5s  min = %.3f   max = %.3f   mean = %.3f\n', 'HDOP', h_min, h_max, h_mean);
fprintf('   %-5s  min = %.3f   max = %.3f   mean = %.3f\n\n', 'VDOP', v_min, v_max, v_mean);

fprintf('TASK 1c  Satellite count with Galileo added\n');
fprintf('   GPS only        min=%.0f max=%.0f mean=%.2f\n', ns_min, ns_max, ns_mean);
fprintf('   GPS + Galileo   min=%.0f max=%.0f mean=%.2f\n', nsg_min, nsg_max, nsg_mean);
fprintf('   mean increase   = +%.2f satellites\n\n', nsg_mean - ns_mean);

fprintf('%s\n', line);
fprintf('TASK 2  E/N/U mean & std [m]  (Up relative to ref alt = %.3f m)\n', ALT_REF);
fprintf('%-26s %8s %7s %8s %7s %8s %7s %7s\n', ...
        'case', 'E_mean', 'E_std', 'N_mean', 'N_std', 'U_mean', 'U_std', 'H_rms');
fprintf('%s\n', repmat('-', 1, 82));
for k = 1:numel(t2)
    s = t2(k);
    fprintf('%-26s %8.3f %7.3f %8.3f %7.3f %8.3f %7.3f %7.3f\n', ...
            s.label, s.E_mean, s.E_std, s.N_mean, s.N_std, s.U_mean, s.U_std, s.hor_rms);
end
fprintf('\n%s\n', line);
fprintf('TASK 3  E/N/U mean & std [m] + geometry  (both models enabled)\n');
fprintf('%-12s %5s %8s %7s %8s %7s %8s %7s %8s %6s\n', ...
        'case', 'n', 'E_mean', 'E_std', 'N_mean', 'N_std', 'U_mean', 'U_std', 'sat_mean', 'PDOP');
fprintf('%s\n', repmat('-', 1, 88));
for k = 1:numel(t3)
    s = t3(k);
    fprintf('%-12s %5d %8.3f %7.3f %8.3f %7.3f %8.3f %7.3f %8.2f %6.3f\n', ...
            s.label, s.n, s.E_mean, s.E_std, s.N_mean, s.N_std, ...
            s.U_mean, s.U_std, s.ns_mean, s.pdop_mean);
end
fprintf('\nSatellite/geometry detail by mask:\n');
for k = 1:numel(t3)
    s = t3(k);
    fprintf('   %-10s  sats min/max/mean = %.0f/%.0f/%.2f   PDOP %.3f  HDOP %.3f  VDOP %.3f   (epochs=%d)\n', ...
            s.label, s.ns_min, s.ns_max, s.ns_mean, ...
            s.pdop_mean, s.hdop_mean, s.vdop_mean, s.n);
end

%%  local functions
function T = loadlog(name)
    T = readtable([name '.csv'], 'VariableNamingRule', 'preserve');
end

function [lo, hi, av] = mmm(x)
    x  = x(~isnan(x));
    lo = min(x); hi = max(x); av = mean(x);
end

function [E, N, U] = enu(df, C_E, C_N, C_ALT, ALT_REF)
    E = df.(C_E);
    N = df.(C_N);
    U = df.(C_ALT) - ALT_REF;
end
