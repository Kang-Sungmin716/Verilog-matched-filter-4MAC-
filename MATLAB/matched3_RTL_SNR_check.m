clear; clc; close all;

%% Parameter
SNR_in_dB = -5;
delay = 200;
N = 200;
peak_idx = delay + N;  % 200 delay + 200 tap = 400 위치

%% txt 파일 읽기
signal_I = hexFileToSigned('output_signal_I.txt');
signal_Q = hexFileToSigned('output_signal_Q.txt');

noise_I = hexFileToSigned('output_noise_I.txt');
noise_Q = hexFileToSigned('output_noise_Q.txt');

signal_noise_I = hexFileToSigned('output_signal_noise_I.txt');
signal_noise_Q = hexFileToSigned('output_signal_noise_Q.txt');

%% 계산
signal = signal_I + 1j*signal_Q;
noise = noise_I + 1j*noise_Q;
signal_noise = signal_noise_I + 1j*signal_noise_Q;

signal_power_peak = abs(signal(peak_idx))^2; 
noise_power_peak = abs(noise(peak_idx))^2;

SNR_out_dB = 10*log10(signal_power_peak / noise_power_peak); % peak 값 기준
SNR_gain_dB = SNR_out_dB - SNR_in_dB;


fprintf('RTL SNR_out : %.2f dB\n', SNR_out_dB);
fprintf('RTL SNR_gain : %.2f dB\n', SNR_gain_dB);
fprintf('이론 SNR_out : 18.01 dB\n');
fprintf('이론 SNR_gain : 23.01 dB\n');

%% plot
figure;

subplot(3,1,1);
plot(abs(signal));
title('Signal_only');
xlabel('Sample');
ylabel('|y|');

subplot(3,1,2);
plot(abs(noise));
title('Noise_only');
xlabel('Sample');
ylabel('|y|');

subplot(3,1,3); 
plot(abs(signal_noise));  
title('signal+noise');
xlabel('Sample'); 
ylabel('|y|');


%% function
function out = hexFileToSigned(filename)
    fid = fopen(filename,'r');
    raw = textscan(fid,'%s'); % 문자열 단위로 읽기 (%s)
    fclose(fid);
    
    unsigned = uint16(hex2dec(raw{1})); % 16bit unsigned로 변환
    out = typecast(unsigned,'int16');
    out = double(out); % matlab 기본 연산은 double로
end
