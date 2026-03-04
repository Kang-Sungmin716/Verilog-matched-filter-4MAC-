# Verilog-matched-filter-4MAC-

LFM 펄스 압축 정합 필터 Verilog 구현 (4MAC 시분할 구조)

노션 링크 : https://www.notion.so/LFM-4MAC-31857629ddf180389927e55163f707fd?source=copy_link

# 개요
레이더 신호처리 기법인 LFM 펄스 압축을 Verilog에서 구현

초기 완전 병렬 FIR 구조에서 DSP 사용량 초과로 인해 4MAC 시분할 구조로 변경하였습니다.

Vivado synthesis 및 Implementation을 통해 WNS, DSP 등의 지표를 확인하였고, MATLAB을 통해 PSLR, ISLR, SNR gain을 확인하였습니다.

# 시뮬레이션 결과
|항목|값|
|---------|---------|
|SNR gain (시뮬레이션)|23.27dB|
|DSP 사용량|18|
|PSLR (테일러 윈도우)| -32.14 dB|
|ISLR (테일러 윈도우)| -21.5 dB|
|WNS (100MHz 기준) | 1.957ns|

