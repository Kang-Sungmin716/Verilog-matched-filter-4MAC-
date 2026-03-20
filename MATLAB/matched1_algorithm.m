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


%% Noise가 없을 때
y_signal = conv(s, h); % 신호의 자기상관형태
mag_signal = abs(y_signal);
mag2_signal = mag_signal.^2;

[peak_val, peak_idx] = max(mag_signal); % 최댓값과 인덱스

%% -3dB 기준 mainlobe 범위 (PSLR, ISLR 확인용)

mainlobe_3dB = peak_val / sqrt(2); % -3dB = -20log(sqrt(2))

% 왼쪽
left_idx = find(mag_signal(1:peak_idx) <= mainlobe_3dB, 1, 'last'); %처음~peak 범위에서 -3dB인 부분 중 가장 마지막에 나오는 지점
if isempty(left_idx) % -3dB인 지점이 없다면 -> 1
    left_idx = 1;
end

% 오른쪽
right_idx = find(mag_signal(peak_idx:end) <= mainlobe_3dB, 1, 'first');
if isempty(right_idx) % -3dB 밑으로 내려간 적이 없으면
    right_idx = length(mag_signal); % 끝까지 mainlobe로 지정
else
    right_idx = peak_idx -1 + right_idx;
end


main_region = left_idx:right_idx;
side_region = setdiff(1:length(mag_signal), main_region); % 전체 범위에서 mainlobe가 아닌 나머지 부분

mainlobe_width = right_idx - left_idx + 1;


%% PSLR, ISLR

PSLR_dB = 20*log10(max(mag_signal(side_region)) / peak_val); % 20log(peak_sidelobe / peak_mainlobe)
ISLR_dB = 10*log10(sum(mag2_signal(side_region)) / sum(mag2_signal(main_region))); % 10log(energy_sidelobe / energy_mainlobe)


%% SNR 시뮬레이션 (몬테-카를로)

signal_power = mean(abs(s).^2);
noise_power = signal_power / (10^(SNR_in_dB/10));

signal_sum = 0;
noise_sum = 0;

for m = 1:1000
    noise = sqrt(noise_power/2) * (randn(1, N) + 1j*randn(1, N)); % 복소 AWGN

    y = conv(s + noise, h);
    y_noise = conv(noise, h);

    signal_sum = signal_sum + abs(y(peak_idx))^2;
    noise_sum = noise_sum + abs(y_noise(peak_idx))^2;
end

SNR_out_simul = 10*log10(signal_sum / noise_sum);
SNR_gain_simul = SNR_out_simul - SNR_in_dB;

%% SNR 이론값

SNR_out_theory = 10*log10(N) + SNR_in_dB;
SNR_gain_theory = 10*log10(N);


%% Print

fprintf("PSLR = %.2f dB\n", PSLR_dB);
fprintf("ISLR = %.2f dB\n", ISLR_dB);
fprintf("Mainlobe width = %d\n", mainlobe_width);

fprintf("시뮬레이션 SNR out = %.2f dB\n", SNR_out_simul);
fprintf("시뮬레이션 SNR gain = %.2f dB\n", SNR_gain_simul);

fprintf("이론값 SNR out = %.2f dB\n", SNR_out_theory);
fprintf("이론값 SNR gain = %.2f dB", SNR_gain_theory);
