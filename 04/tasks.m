clc;
clear;
close all;


function generate_prn()
    % Get the directory where this script is located
    % base_dir = fileparts(mfilename('fullpath'));
    % if isempty(base_dir)
    %     base_dir = pwd; % Fallback if run from command line without saving
    % end
    % ca_codes_file = fullfile(base_dir, 'ca_codes.txt');

    % Open the file for writing
    fid = fopen('ca_codes.txt', 'w');
    if fid == -1
        error('Cannot open file ca_codes.txt for writing.');
    end

    fprintf('--- GPS C/A Code Generation Validation ---\n');

    % Loop through all 32 PRNs
    for i = 1:32
        ca_code = generate_ca_code(i);
        octal_val = ten_octal(ca_code);
        
        fprintf('PRN %02d | First 10 chips (Octal): %s\n', i, octal_val);
        
        fprintf(fid, '%d', ca_code);
        fprintf(fid, '\n');
    end
    
    fclose(fid);
end

%% Local Functions

function ca_code = generate_ca_code(sig_num)
    prn_taps = [
        2 6;  3 7;  4 8;  5 9;  1 9;  2 10; 1 8;  2 9; 
        3 10; 2 3;  3 4;  5 6;  6 7;  7 8;  8 9;  9 10; 
        1 4;  2 5;  3 6;  4 7;  5 8;  6 9;  1 3;  4 6; 
        5 7;  6 8;  7 9;  8 10; 1 6;  2 7;  3 8;  4 9
    ];

    if sig_num < 1 || sig_num > size(prn_taps, 1)
        error('Unsupported/Invalid PRN Signal Number');
    end

    tapA = prn_taps(sig_num, 1);
    tapB = prn_taps(sig_num, 2);

    ca_code = zeros(1, 1023);
    G1 = ones(1, 10);
    G2 = ones(1, 10);

    for i = 1:1023
        ca_code(i) = bitxor(G1(10), bitxor(G2(tapA), G2(tapB)));

        new_G1 = bitxor(G1(3), G1(10));
        
        new_G2 = mod(G2(2) + G2(3) + G2(6) + G2(8) + G2(9) + G2(10), 2);
        
        G1 = [new_G1, G1(1:9)];
        G2 = [new_G2, G2(1:9)];
    end
end

function oct_str = ten_octal(chip)
    if length(chip) > 10
        chip = chip(1:10);
    end
    
    p1 = num2str(chip(1));
    p2 = num2str(to_int(chip(2:4)));
    p3 = num2str(to_int(chip(5:7)));
    p4 = num2str(to_int(chip(8:10)));
    
    oct_str = [p1, p2, p3, p4];
end

function val = to_int(chips)
    val = 0;
    for i = 1:length(chips)
        val = bitor(bitshift(val, 1), chips(i)); 
    end
end


%% Task-2
generate_prn();

%% Task-3
% a)
prn_10 = generate_ca_code(10);
chips = prn_10(1:100);
x = 1:100;
figure;
stairs(x, 1 - 2.*chips, 'LineWidth', 2);

yticks([-1 0 1]);
set(gca, 'TickLength', [0 0]);
xlabel('Chip Index');
ylabel('Binary Value');
title('GPS C/A Code (PRN 10) - First 100 Chips');

% b)
[c,lags] = xcorr(1-2.*prn_10, 'normalized');

figure;
plot(lags, c, 'o-');

% c)
prn_5 = generate_ca_code(5);
[c,lags] = xcorr(1-2.*prn_10, 1-2.*prn_5, 'normalized');

figure;
plot(lags, c, 'o-');

%% Task-4
signal = readmatrix('gps_signal_mR_SS26.txt');
y = signal(:);              % received signal as a column vector

max_c = 0;
max_lag = 0;
max_idx = 0;

for prn = 1:32
    x = (1 - 2*generate_ca_code(prn))';   % reference code as +-1 column vector

    % circular correlation (signal is exactly one 1023-chip period)
    CC = zeros(1, length(x));
    for k = 1:length(x)
        CC(k) = sum(circshift(x, k-1) .* y);
    end

    [pk, idx] = max(abs(CC));   % abs(): the embedded code may be inverted
    if pk > max_c
        max_c = pk;
        max_idx = prn;
        max_lag = idx;          % index of the correlation maximum
    end
end

fprintf('Identified PRN code : %d\n', max_idx);
fprintf('Correlation maximum : %.2f\n', max_c);
fprintf('Delay (index)       : %d\n', max_lag);