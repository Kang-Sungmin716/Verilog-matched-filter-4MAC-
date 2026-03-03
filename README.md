# Verilog-matched-filter-4MAC-

LFM 펄스 압축 매칭 필터 Verilog 구현 (4MAC 시분할 구조)

# 개요
레이더 신호처리 기법인 LFM 펄스 압축을 Verilog에서 구현
초기 완전 병렬 FIR 구조에서 DSP 사용량 초과로 인해 4MAC 시분할 구조로 변경하였습니다.
Vivado synthesis 및 Implementation을 통해 WNS, DSP 등의 지표를 확인하였고, MATLAB을 통해 PSLR, ISLR, SNR gain을 확인하였습니다.

