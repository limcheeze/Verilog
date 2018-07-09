module test_MAC(CLK, ASYNC_RST_B,DATA_IN,WEIGHT_INPUT, DATA_OUT);

parameter LEN_WEIGHT = 8;
parameter LEN_DATA_IN = 8;
parameter LEN_DATA_OUT = 18;

input ASYNC_RST_B, CLK;
input signed [LEN_WEIGHT-1:0] DATA_IN;
input signed [LEN_DATA_IN-1:0] WEIGHT_INPUT;
output signed [LEN_DATA_OUT-1:0] DATA_OUT;

reg signed [LEN_DATA_OUT-1:0] DATA_OUT;

always @(posedge CLK or negedge ASYNC_RST_B) begin
    if (ASYNC_RST_B == 0) begin
        DATA_OUT <= 0;
    end
    else begin
        DATA_OUT <= DATA_OUT + DATA_IN * WEIGHT_INPUT;
    end
end

endmodule

//------------------------------------------------------------------------

module test();

parameter len_w = 10;
parameter len_i = 10;
parameter len_o = 20;

reg CLK;
wire signed [len_o-1:0] DATA_OUT;
reg signed [len_i-1:0] DATA_IN;
reg signed [len_w-1:0] WEIGHT_INPUT;

reg ASYNC_RST_B;

    initial begin
        #4 DATA_IN = -8'd125;
        #4 WEIGHT_INPUT= 8'd3;
        CLK = 0;
        #1 ASYNC_RST_B = 1;
        #2 ASYNC_RST_B = 0;
        #3 ASYNC_RST_B = 1;
        #50 $finish;
    end

always begin
    #5 CLK = !CLK;
    $display("%b", DATA_OUT);
    $display("%d", DATA_OUT);
end

// test_MAC MAC (.ASYNC_RST_B(ASYNC_RST_B), .DATA_IN(DATA_IN), .WEIGHT_INPUT(WEIGHT_INPUT), .DATA_OUT(DATA_OUT), .CLK(CLK));

// parameter overrride
test_MAC #( .LEN_WEIGHT(len_w),
            .LEN_DATA_IN(len_i),
            .LEN_DATA_OUT(len_o)) MAC(.ASYNC_RST_B(ASYNC_RST_B), .DATA_IN(DATA_IN), .WEIGHT_INPUT(WEIGHT_INPUT), .DATA_OUT(DATA_OUT), .CLK(CLK));
endmodule
