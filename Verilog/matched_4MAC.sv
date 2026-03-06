module matched_4MAC #(
    parameter N = 200
)(
    input  wire clk,
    input  wire rst,
    input  wire sample,
    input  wire signed [15:0] xin_I,
    input  wire signed [15:0] xin_Q,

    output reg  signed [15:0] yout_I,
    output reg  signed [15:0] yout_Q,
    output reg  valid
);

    reg signed [15:0] hI [0:N-1]; 
    reg signed [15:0] hQ [0:N-1]; // coeffs
    reg signed [15:0] xI [0:N-1];
    reg signed [15:0] xQ [0:N-1]; // 코드에서 사용할 x (shift됨)
    
    integer i, j;

    initial begin
        $readmemh("coeffs_I.hex", hI);
        $readmemh("coeffs_Q.hex", hQ);
    end
    
    // shift
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < N; i = i+1) begin
                xI[i] <= '0;
                xQ[i] <= '0;
            end
        end else if (sample) begin
            xI[0] <= xin_I;
            xQ[0] <= xin_Q;
            for (i = N - 1; i > 0; i = i-1) begin
                xI[i] <= xI[i-1];
                xQ[i] <= xQ[i-1];
            end
        end
    end

    reg [$clog2(N/4):0] cnt;
    reg calc;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            calc <= 0;
        end else if (sample) begin // input이 들어오면 
            cnt <= 0;
            calc <= 1; // 계산 중
        end else if (calc) begin // 계산 시작시
            if (cnt == ((N/4)-1)) begin // (N/4) -1번 반복하면 끝 (50번째 clk에서 0)
                calc <= 0;
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

    reg [5:0] calc_pipe;
    reg [5:0] first_pipe;
    reg [5:0] last_pipe;
    reg [$clog2(N/4):0] cnt_d;
    // 파이프라인 지연을 위함
    wire cnt_first = (cnt == 0) && calc; // calc가 처음 켜졌을 때만 1 (sample가 on이 되었을 때만)
    wire cnt_last  = (cnt == ((N/4)-1)) && calc; // 계산이 완전히 끝났을 때만 1

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            calc_pipe <= '0;
            first_pipe <= '0;
            last_pipe <= '0;
            cnt_d <= '0;
        end else begin
            calc_pipe  <= {calc_pipe[4:0], calc}; // (00000,1) -> (00001,1) -> ... -> (11111,0) -> (11110,0) ->...
            first_pipe <= {first_pipe[4:0], cnt_first}; // 처음 켜졌을 때부터 (00000,1) -> (00001,0) -> (00010,0) -> ...
            last_pipe  <= {last_pipe[4:0], cnt_last}; // 마지막 cnt에서 (00000,1) -> (00001,0) ->...
            cnt_d <= cnt; // 1clk 지연된 cnt 저장 (nonblocking), prod 계산에서 cnt - 1을 할 때보다 계산시간 절약
        end
    end

    // stage 1 (prod)
    reg signed [31:0] prod_II [0:3]; 
    reg signed [31:0] prod_QQ [0:3]; 
    reg signed [31:0] prod_IQ [0:3];
    reg signed [31:0] prod_QI [0:3];
    
    always @(posedge clk) begin
        if (calc_pipe[0]) begin
            for (j = 0; j < 4; j = j+1) begin
                prod_II[j] <= xI[cnt_d*4+j] * hI[cnt_d*4+j];
                prod_QQ[j] <= xQ[cnt_d*4+j] * hQ[cnt_d*4+j];
                prod_IQ[j] <= xI[cnt_d*4+j] * hQ[cnt_d*4+j];
                prod_QI[j] <= xQ[cnt_d*4+j] * hI[cnt_d*4+j];
            end
        end
    end

    // stage 2 (sum1)
    reg signed [32:0] sum_I0;
    reg signed [32:0] sum_I1;
    reg signed [32:0] sum_Q0;
    reg signed [32:0] sum_Q1;
    
    always @(posedge clk) begin
        if (calc_pipe[1]) begin
            sum_I0 <= (prod_II[0] - prod_QQ[0]) + (prod_II[1] - prod_QQ[1]);
            sum_I1 <= (prod_II[2] - prod_QQ[2]) + (prod_II[3] - prod_QQ[3]);
            sum_Q0 <= (prod_IQ[0] + prod_QI[0]) + (prod_IQ[1] + prod_QI[1]);
            sum_Q1 <= (prod_IQ[2] + prod_QI[2]) + (prod_IQ[3] + prod_QI[3]);
        end
    end

    // Stage 3 (sum 2)
    reg signed [33:0] sum_I;
    reg signed [33:0] sum_Q;
    
    always @(posedge clk) begin
        if (calc_pipe[2]) begin
            sum_I <= sum_I0 + sum_I1;
            sum_Q <= sum_Q0 + sum_Q1;
        end
    end

    // stage 4 (acc)
    reg signed [41:0] acc_I; // acc_W = prod_bits + log2(N) + 여유bits = 32 + 8 + 2 = 42
    reg signed [41:0] acc_Q;
    reg signed [41:0] acc_out_I;
    reg signed [41:0] acc_out_Q; 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc_I <= 0;
            acc_Q <= 0;
            acc_out_I <= 0;
            acc_out_Q <= 0;
        end else if (calc_pipe[3]) begin
            // acc
            if (first_pipe[3]) begin // 첫 sum할 때
                acc_I <= sum_I; 
                acc_Q <= sum_Q;
            end else begin
                acc_I <= acc_I + sum_I; 
                acc_Q <= acc_Q + sum_Q;
            end
            // non-blocking이므로 다음 clk에 acc_I에 적용되므로 그냥 여기서 바로 저장
            if (last_pipe[3]) begin 
                if (first_pipe[3]) begin
                    acc_out_I <= sum_I;
                    acc_out_Q <= sum_Q;
                end else begin
                    acc_out_I <= acc_I + sum_I;
                    acc_out_Q <= acc_Q + sum_Q;
                end
            end
        end
    end

    // stage 5 (scaling, round)
    localparam SHIFT_BITS = 23; // 15(Q1.15) + log2(N) = 23
    reg signed [41:0] round_I;
    reg signed [41:0] round_Q;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round_I <= 0; 
            round_Q <= 0;
        end else if (last_pipe[4]) begin // 마지막 부분에서만 하면 되므로, 계속 high인 calc_pipe가 아닌 last_pipe로 제어
            round_I <= (acc_out_I + (42'sd1 << (SHIFT_BITS - 1))) >>> SHIFT_BITS;
            round_Q <= (acc_out_Q + (42'sd1 << (SHIFT_BITS - 1))) >>> SHIFT_BITS;
            // 잘리는 부분의 MSB에 1을 더해서 반올림
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            yout_I <= 0;
            yout_Q <= 0;
            valid <= 0;
        end else begin
            valid <= last_pipe[5]; // 마지막 부분에서만 하면 되므로, 계속 high인 calc_pipe가 아닌 last_pipe로 제어
            if (last_pipe[5]) begin
                // I sat
                if (round_I > 42'sd32767) begin
                    yout_I <= 16'sh7FFF;
                end else if (round_I < -42'sd32768) begin
                    yout_I <= 16'sh8000;
                end else begin
                    yout_I <= round_I[15:0];
                end
                // Q sat
                if (round_Q > 42'sd32767) begin
                    yout_Q <= 16'sh7FFF;
                end else if (round_Q < -42'sd32768) begin
                    yout_Q <= 16'sh8000;
                end else begin
                    yout_Q <= round_Q[15:0];
                end
            end
        end
    end

endmodule