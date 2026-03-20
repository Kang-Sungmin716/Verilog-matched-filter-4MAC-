`timescale 1ns/1ps

module tb_matched_4MAC_600;

    parameter N = 200;
    parameter length = 600;
    
    reg clk;
    reg rst;
    reg sample;
    reg signed [15:0] xin_I;
    reg signed [15:0] xin_Q;
    wire signed [15:0] yout_I;
    wire signed [15:0] yout_Q;
    wire valid;
    
    reg signed [15:0] input_I [0:length-1];
    reg signed [15:0] input_Q [0:length-1];
    
    
    integer i;
    integer out_count = 0;

    matched_4MAC #(
        .N(N)
    ) dut (
        .clk(clk),
        .rst(rst),
        .sample(sample),
        .xin_I(xin_I),
        .xin_Q(xin_Q),
        .yout_I(yout_I),
        .yout_Q(yout_Q),
        .valid(valid)
    );
    
    initial clk = 0;
    always #5 clk = ~clk; // 10ns 주기
    
    initial begin
        rst = 1;
        sample = 0;
        xin_I = 0;
        xin_Q = 0;
        
        $readmemh("xI_signal_noise.hex", input_I);
        $readmemh("xQ_signal_noise.hex", input_Q);// 파일 이름을 바꿔가며 noise, signal, signal_noise 출력 확인

        repeat (10) @(posedge clk);
        rst = 0;
        
        for (i = 0; i < length; i = i+1) begin
            @(posedge clk);
            sample = 1;
            xin_I  = input_I[i];
            xin_Q  = input_Q[i];
            
            @(posedge clk);
            sample = 0;
            xin_I  = 0;
            xin_Q  = 0;
            repeat(N/4 + 8) @(posedge clk);
        end
        
        repeat (50) 
        @(posedge clk); 
        $display("total output : %0d", out_count); 
    $finish; 
    end
        
    
    integer file_I;
    integer file_Q;
    
    initial begin
        file_I = $fopen("output_signal_noise_I.txt", "w");
        file_Q = $fopen("output_signal_noise_Q.txt", "w");  // 파일 이름을 바꿔가며 noise, signal, signal_noise 출력 확인
    end
    
    always @(posedge clk) begin
        if (valid) begin
            $display("y[%0d] = I:%x  Q:%x", out_count, yout_I, yout_Q);
            
            $fdisplay(file_I, "%x", yout_I);
            $fdisplay(file_Q, "%x", yout_Q);
            out_count <= out_count + 1;
        end
    end

endmodule
