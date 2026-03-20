clear; clc; close all;

%% Parameter

SNR_in_dB = -5;

N = 200;

delay = 200; %201번째부터 signal 시작
input_length = 600; % input 총 길이 (1~200, 401~600에서는 noise, 201~400까지는 signal+noise)

peak_idx = delay + N;


%% txt 파일 읽기

signal_I = readhex('output_signal_I.txt');
signal_Q = readhex('output_signal_Q.txt');

noise_I = readhex('output_noise_I.txt');
noise_Q = readhex('output_noise_Q.txt');

signal_noise_I = readhex('output_signal_noise_I.txt');
signal_noise_Q = readhex('output_signal_noise_Q.txt');


%% 계산

signal = signal_I + 1j * signal_Q;
noise = noise_I + 1j * noise_Q;
signal_noise = signal_noise_I + 1j * signal_noise_Q;

signal_power_peak = abs(signal(peak_idx))^2;
noise_power_peak = abs(noise(peak_idx))^2;

SNR_out_dB = 10*log10(signal_power_peak / noise_power_peak);
SNR_gain_dB = SNR_out_dB - SNR_in_dB;

%% Print

fprintf('RTL SNR out = %.2f dB\n', SNR_out_dB);
fprintf('RTL SNR gain = %.2f dB\n', SNR_gain_dB);

fprintf('이론 SNR out = 18.01dB\n');
fprintf('이론 SNR gain = 23.01dB');

%% Plot

figure;

subplot(3, 1, 1);
plot(abs(signal));
title('signal only');

subplot(3, 1, 2);
plot(abs(noise));
title('noise only');

subplot(3, 1, 3);
plot(abs(signal_noise));
title('signal + noise');


%% function
function y = readhex(fname)
    fid = fopen(fname, 'r');
    raw = textscan(fid, '%s'); % 문자열 단위로 읽기
    fclose(fid);

    unsigned = uint16(hex2dec(raw{1})); % 16bit unsigned로 변환
    y = typecast(unsigned, 'int16');
    y = double(y); % matlab 기본 연산 double
end
