clear; clc; close all;

%% Parameter
fs = 10e6; % sampling frequency
T = 20e-6; % LFM 길이
B = 7.5e6; % bandwidth
k = B/T;
N = round(T*fs); % 200 taps
t = (0:N-1)/fs; % 이산시간

SNR_in_dB = -5;

s = exp(1j*pi*k*t.^2);
w = taylorwin(N, 4, -30).'; % 테일러 윈도우

h = conj(flip(s));
h = h.*w;

delay = 200; %201번째부터 signal 시작
input_length = 600; % input 총 길이 (1~200, 401~600에서는 noise, 201~400까지는 signal+noise)


%% 신호

signal_power = mean(abs(s).^2);
noise_power = signal_power / (10^(SNR_in_dB/10));

% signal only
signal = zeros(1, input_length);
signal(delay + 1 : delay + N) = s; % 201~400 범위까지 signal

% noise only
noise = sqrt(noise_power/2) * (randn(1, input_length) + 1j*randn(1, input_length)); % 복소 AWGN

% signal + noise
signal_noise = signal + noise;


%% scaling

coeff_peak = max(abs([real(h), imag(h)]));
coeff_scaled = 0.9 / coeff_peak;

hI_scaled = real(h) * coeff_scaled;
hQ_scaled = imag(h) * coeff_scaled;


real_input = [real(signal), real(noise), real(signal_noise)];
imag_input = [imag(signal), imag(noise), imag(signal_noise)];
peak_input = max(abs([real_input, imag_input]));

scaling_input = 0.9 / peak_input;

signal_scaled = signal * scaling_input;
noise_scaled = noise * scaling_input;
signal_noise_scaled = signal_noise * scaling_input;


%% 양자화 (Q1.15)

MAX = -1 + 2^15;
MIN = -(2^15);

hI_q = quantized_sat(hI_scaled, MAX, MIN);
hQ_q = quantized_sat(hQ_scaled, MAX, MIN);

xI_signal_q = quantized_sat(real(signal_scaled), MAX, MIN);
xQ_signal_q = quantized_sat(imag(signal_scaled), MAX, MIN);

xI_noise_q = quantized_sat(real(noise_scaled), MAX, MIN);
xQ_noise_q = quantized_sat(imag(noise_scaled), MAX, MIN);

xI_signal_noise_q = quantized_sat(real(signal_noise_scaled), MAX, MIN);
xQ_signal_noise_q = quantized_sat(imag(signal_noise_scaled), MAX, MIN);


%% hex 파일 저장

write_hex('coeffs_I.hex', hI_q);
write_hex('coeffs_Q.hex', hQ_q);

write_hex('xI_signal.hex', xI_signal_q);
write_hex('xQ_signal.hex', xQ_signal_q);

write_hex('xI_noise.hex', xI_noise_q);
write_hex('xQ_noise.hex', xQ_noise_q);

write_hex('xI_signal_noise.hex', xI_signal_noise_q);
write_hex('xQ_signal_noise.hex', xQ_signal_noise_q);

%% function

function y = quantized_sat(x, MAX, MIN)
    y = int16(max(min(round(x * MAX), MAX), MIN));
end

function write_hex(fname, data)
    fid = fopen(fname, 'w');

    for i = 1 : length(data)
        fprintf(fid, '%04x\n', typecast(data(i), 'uint16'));
    end
    fclose(fid);
end
