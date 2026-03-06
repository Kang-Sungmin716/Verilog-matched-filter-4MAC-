clear; clc; close all;

%% parameter
fs = 10e6;
T = 20e-6;
B = 7.5e6;
k = B/T;
N = round(T*fs); % 200 taps
t = (0:N-1)/fs; % 이산시간

SNR_in_dB = -5;

delay = 200; % 201번째부터 signal 시작
WINDOW = 600; % input 윈도우 총 길이 ( 1~200, 401~600에선 0, 201~400까지 signal input)

s = exp(1j*pi*k*t.^2);
w = taylorwin(N,4,-30).';

h = conj(flip(s));
h = h .* w;

%% 수신 신호 생성
% 노이즈 윈도우에 delay 위치에 chirp 삽입
signal_power = mean(abs(s).^2);
noise_power  = signal_power/(10^(SNR_in_dB/10));

% signal only (노이즈 없이 chirp만 삽입)
signal = zeros(1, WINDOW); % signal 1~600까지 0
signal(delay+1 : delay+N) = s; % delay=200이면 201~400번째 범위에 s(LFM signal) 적용

% noise only
noise = sqrt(noise_power/2) * (randn(1,WINDOW) + 1j*randn(1,WINDOW)); % AWGN 생성

% signal + noise
signal_noise = signal + noise;

%% scaling
% coeff
coeff_peak = max(abs([real(h), imag(h)]));
coeff_scaled = 0.9 / coeff_peak;

hI_scaled = real(h) * coeff_scaled;
hQ_scaled = imag(h) * coeff_scaled;

% input
all_real = [real(signal), real(noise), real(signal_noise)];
all_imag = [imag(signal), imag(noise), imag(signal_noise)];
peak_all = max(abs([all_real, all_imag]));

scaling = 0.9 / peak_all;

signal_scaled = signal * scaling;
noise_scaled = noise * scaling;
signal_noise_scaled = signal_noise * scaling;

%% Q1.15 양자화
MAX = 2^15 - 1;
MIN = -(2^15);

hI_q = quantize_sat(hI_scaled, MAX, MIN);
hQ_q = quantize_sat(hQ_scaled, MAX, MIN);

xI_signal_q = quantize_sat(real(signal_scaled), MAX, MIN);
xQ_signal_q = quantize_sat(imag(signal_scaled), MAX, MIN);

xI_noise_q = quantize_sat(real(noise_scaled), MAX, MIN);
xQ_noise_q = quantize_sat(imag(noise_scaled), MAX, MIN);

xI_signal_noise_q = quantize_sat(real(signal_noise_scaled), MAX, MIN);
xQ_signal_noise_q = quantize_sat(imag(signal_noise_scaled), MAX, MIN);

%% hex 파일 저장 (WINDOW 길이)
write_hex('coeffs_I.hex', hI_q);
write_hex('coeffs_Q.hex', hQ_q);

write_hex('xI_signal.hex', xI_signal_q);
write_hex('xQ_signal.hex', xQ_signal_q);

write_hex('xI_noise.hex', xI_noise_q);
write_hex('xQ_noise.hex', xQ_noise_q);

write_hex('xI_signal_noise.hex', xI_signal_noise_q);
write_hex('xQ_signal_noise.hex', xQ_signal_noise_q);

%% function

function vals = quantize_sat(x, MAX, MIN)
    vals = int16(max(min(round(x * MAX), MAX), MIN));
end


function write_hex(fname, data)
    fid = fopen(fname, 'w');
    for i = 1:length(data)
        fprintf(fid, '%04x\n', typecast(data(i), 'uint16'));
    end
    fclose(fid);
end