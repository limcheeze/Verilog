module test;

parameter [3:0] IDLE = 0,
                BBUSY = 1,
                BWAIT = 2,
                BFRER = 3;
reg clk;
reg [3:0] state;



    initial begin
        clk = 0;
        #0 state <= 4'b0;
        $display ("Welcome to JDoodle!!!");
        #1 state[BWAIT] <= 1'b1;
        #1 state[IDLE] <= 1'b1;
        #2 $display(state[0]);
        #2 $display(state[1]);
        #2 $display(state[2]);
        #2 $display(state[3]);

        #20 $finish;
    end

always
#5 clk = !clk ;

always @(posedge clk) begin
    case(1'b1)
        state[IDLE]:    $display("first");
        state[BBUSY]:   $display("second");
        state[BWAIT]:   $display("third");
    endcase
end
    
endmodule