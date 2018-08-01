//Verilog HDL for "CM_RAM_V1", "DIG_COMPUTE_testbench" "functional"
`timescale 1ns/1ps

module DIG_COMPUTE_testbench (CLK1, SRAM_CLK1, MVM_CLK1, ASYNC_RST_B, IO_MUX, SCAN_OUT, IO_CLK, DATA_DIG_IN, UPLOAD, ADC_IN, UPLOAD_INT, INIT_MR_READ, MVM_EN, MVM_DONE);


parameter DATA_WIDTH = 128; //memory data bitwidth
parameter MUX_ratio_mem = 4; //memory mux ratio
parameter Row_mem = 98; //memory row
parameter RAM_DEPTH = Row_mem * MUX_ratio_mem;
parameter WR_DEPTH = RAM_DEPTH;

parameter Wscale = 16; //16b scale
parameter Wshift = 6; //6b shift

parameter Wreg = Wscale + Wscale + Wshift + Wshift + 4;

integer ii=0;

input SCAN_OUT;
input MVM_DONE;

output CLK1;
output SRAM_CLK1;
output MVM_CLK1;
output ASYNC_RST_B;
output [3:0] IO_MUX;
output IO_CLK;
output DATA_DIG_IN;
output UPLOAD;
output MVM_EN;

//wire MVM_DONE;

reg [DATA_WIDTH-1:0] BUF_DATA[RAM_DEPTH -1 :0];
reg [DATA_WIDTH-1:0] READ_DATA[RAM_DEPTH -1 :0];
reg [511:0] MEM_DATA [96:0];
reg [8:0] ADD_DATA [RAM_DEPTH-1 :0];
reg [7:0] INPUT_REG_TEST[127 : 0];

reg [7:0] INPUT_REG_DATA [127:0];
reg [7:0] PATCH_DATA [65:0];
reg [127:0] OUT_BUF_DATA;
reg [24:0] OUT_BUF_TB [11:0];

reg START_BUF;
reg [8:0] dig_count;
reg [7:0] dig_index;
reg [3:0] dig_add;
reg [3:0] IO_clk_count;
reg [8:0] counter;
reg div;
reg BUF_DONE;

wire IO_CLK;
reg DATA_DIG_IN;
reg UPLOAD;
reg [3:0] IO_MUX;

reg [(Wreg-1):0] SETUP_DATA_INIT;

reg CLK;
reg CLK1;
reg SRAM_CLK;
reg SRAM_CLK1;
reg MVM_CLK;
reg MVM_CLK1;
reg ASYNC_RST_B;

assign IO_CLK = div;

parameter scale = 1.2;  // clock period scale
integer IO_scale = 8;
integer jj = 0;

initial begin
	//$readmemb("/data/shared/shanbhag/Project/Design_IC6/tsmc65_cm/INITIAL_VALUE/x_bin.txt", BUF_DATA);
	$readmemb("/data/shared/shanbhag/Project/Design_IC6/tsmc65_cm/INITIAL_VALUE/mem.txt", MEM_DATA);
	$readmemb("/data/shared/shanbhag/Project/Design_IC6/tsmc65_cm/INITIAL_VALUE/a_x_bin.txt", ADD_DATA);
	//$readmemb("/data/shared/shanbhag/Project/Design_IC6/tsmc65_cm/INITIAL_VALUE/input_reg_bin.txt", INPUT_REG_TEST);
	$readmemb("/data/shared/shanbhag/Project/Design_IC6/tsmc65_cm/INITIAL_VALUE/patch.txt", PATCH_DATA);
	for(ii = 0; ii < 97; ii = ii + 1) begin
		for(jj = 0; jj < 128; jj = jj + 1) begin
			BUF_DATA[4*ii+0][jj] = MEM_DATA[ii][4*jj+0];
			BUF_DATA[4*ii+1][jj] = MEM_DATA[ii][4*jj+1];
			BUF_DATA[4*ii+2][jj] = MEM_DATA[ii][4*jj+2];
			BUF_DATA[4*ii+3][jj] = MEM_DATA[ii][4*jj+3];
		end
	end
	//CLK <= 0;	SRAM_CLK <=0; MVM_CLK <=0;
	ASYNC_RST_B <= 1'b1;
	#(10*scale) ASYNC_RST_B <= 1'b0;
	#(20*scale) ASYNC_RST_B <= 1'b1;
	#(10*scale) ASYNC_RST_B <= 1'b0;
	#(20*scale) ASYNC_RST_B <= 1'b1;
	#(10*scale) ASYNC_RST_B <= 1'b0;
	#(20*scale) ASYNC_RST_B <= 1'b1;
	#(1500000*scale) $finish;
end


// ----- clock generation ------
real delay_clock = 0;
real sram_delay_clock = 0;
real mvm_delay_clock = 0;

initial begin
	CLK1 <= 1;
	# (delay_clock*scale) forever begin
		#(0.5*scale*2) CLK1 <= !CLK1;
	end
end

initial begin
	CLK <= 1;
	forever begin
		#(0.5*scale) CLK <= !CLK;
	end
end
initial begin
	SRAM_CLK <= 1; 
	forever begin
		#(1*scale) SRAM_CLK <= !SRAM_CLK;
	end
end
initial begin
	SRAM_CLK1 <= 1; 
	# (sram_delay_clock*scale) forever begin
		#(1*scale) SRAM_CLK1 <= !SRAM_CLK1;
	end
end
initial begin
	MVM_CLK <= 1; 
	forever begin
		#(8*scale) MVM_CLK = !MVM_CLK;
	end
end

initial begin
	MVM_CLK1 <= 1; 
	# (mvm_delay_clock*scale) forever begin
		#(8*scale) MVM_CLK1 = !MVM_CLK1;
	end
end
// always 	#5 CLK = !CLK;
//always	#10 SRAM_CLK = !SRAM_CLK;
//always	#80 MVM_CLK = !MVM_CLK;

//------------------------------

output [5:0] ADC_IN;
output UPLOAD_INT;
output INIT_MR_READ;

reg INIT_MR_READ;
reg [5:0] ADC_IN_TEST[127:0];
reg [7:0] adc_index;
reg [7:0] adc_delay;
reg [8:0] adc_counter;

reg [5:0] ADC_IN;
reg UPLOAD_INT;

reg IO_flag;
reg ADC_ON;
reg [5:0] SCHEDULE [1024:0];
integer k;

reg MVM_EN;
reg MVM_ON;
reg [7:0] mvm_index;
reg [7:0] mvm_delay;
reg [9:0] mvm_counter;

reg [4:0] mvm_delay_test;

initial begin
	//SETUP_DATA_INIT <= {{Wreg-4}*1'b0,4'b0001};
	SETUP_DATA_INIT[0] <= 1'b1; //RETN
	SETUP_DATA_INIT[3:1] <= 3'b0; //EMA[2:0]
	SETUP_DATA_INIT[(Wshift+3):4] <= 6'd10; //SHIFT_L[(Wshift-1):0];
	SETUP_DATA_INIT[(2*Wshift+3):(Wshift+4)] <= 6'd10; //SHIFT_R[(Wshift-1):0];
	SETUP_DATA_INIT[(2*Wshift+Wscale+3):(2*Wshift+4)] <= 16'd1; //SCALE_L[(Wscale-1):0];
	SETUP_DATA_INIT[(2*Wshift+2*Wscale+3):(2*Wshift+Wscale+4)] <= 16'd1; //SCALE_R[(Wscale-1):0];

	for(ii = 0; ii < 128; ii = ii + 1) begin
		ADC_IN_TEST[ii] <= $random % 64;
	end
	for(ii = 0; ii < 1024; ii = ii + 1) begin
		SCHEDULE[ii] <=0;
	end

	INIT_MR_READ <= 1;

// IO_MUX Simulation scenario
// 1. 4 -> 3 -> 5
// 2. 1 -> 6

// covered IO_MUX: 1,3,4,5,6,7
//////////////////////////// INSTRUCTION
//////////////////////////// SCHEDULE[5] - MVM,  SCHEDULE[4] - ADC, SCHEDULE[3:0] - IO_MUX ///////////////////////
	#1	
// IO_MUX 1-6 test
//	SCHEDULE[0] <= {1'b0,1'b0, 4'd4}; SCHEDULE[1] <= {1'b0,1'b0, 4'd1}; SCHEDULE[2] <= {1'b0,1'b0, 4'd6}; 

// ADC test - IO_MUX: 7
//	SCHEDULE[0] <= {1'b0,1'b0, 4'd4}; SCHEDULE[1] <= {1'b0,1'b1, 4'd0}; SCHEDULE[2] <= {1'b0,1'b0, 4'd7}; 

// MVM test - IO_MUX: 3

	SCHEDULE[0] <= {1'b0,1'b0, 4'd4};
	for (ii = 1; ii < WR_DEPTH + 1; ii = ii + 1) begin
		SCHEDULE[ii] <= {1'b0,1'b0, 4'd3};
	end
	SCHEDULE[WR_DEPTH + 1] <= {1'b0,1'b0, 4'd2};
	for (ii = WR_DEPTH + 2; ii < (WR_DEPTH + 2 +2); ii = ii + 1) begin
		SCHEDULE[ii] <= {1'b1,1'b0, 4'd0};
	end
	SCHEDULE[(WR_DEPTH + 2 +2)] <= {1'b0,1'b0, 4'd6};
// IO MUX 3-5 test
/*	SCHEDULE[0] <= {1'b0,1'b0, 4'd4};
	for (ii = 1; ii < 41; ii = ii + 1) begin
		SCHEDULE[2*ii -1] <= {1'b0,1'b0, 4'd3};
		SCHEDULE[2*ii] <= {1'b0,1'b0, 4'd5};
	end 
*/

end


// control
always @(negedge ASYNC_RST_B or posedge CLK) begin
		if (ASYNC_RST_B == 0 ) begin	
			IO_flag <= 0;
			k <= 0;
			IO_MUX <= SCHEDULE[0][3:0];
			ADC_ON <= SCHEDULE[0][4];
			MVM_ON <= SCHEDULE[0][5];
		end
		else begin
			if (IO_flag == 1) begin
				k <= k + 1;
				IO_flag <= 0;
				counter <= 0;
				IO_MUX <= SCHEDULE[k+1][3:0];
				ADC_ON <= SCHEDULE[k+1][4];
				MVM_ON <= SCHEDULE[k+1][5];
				if (SCHEDULE[k+1] == 6'd0) $finish;
			end
			else begin
				//IO_MUX <= SCHEDULE[k][3:0];
				//ADC_ON <= SCHEDULE[k][4];
				//MVM_EN <= SCHEDULE[k][5];
			end
		end
end

// MVM test
always @(negedge ASYNC_RST_B or posedge CLK) begin 
		if (ASYNC_RST_B == 0 ) begin
			mvm_counter <= 0;
			mvm_index <= 0;
			mvm_delay <= 0;
			MVM_EN <= 0;
			mvm_delay_test <= 0;

		end
		else begin
			if (MVM_ON) begin

				case (mvm_counter) 

				9'd0: begin
					if (mvm_delay_test == 1) begin
						MVM_EN <= 1;
						mvm_counter <= 9'd1;
						mvm_delay_test <= 0;
					end
					else begin
						mvm_delay_test <=  mvm_delay_test + 1;
					end
				end

				9'd1: begin
					if (mvm_delay_test == 31) begin
						MVM_EN <= 0;
						mvm_counter <= 9'd2;
						mvm_delay_test <= 0;
					end
					else begin
						mvm_delay_test <=  mvm_delay_test + 1;
					end
				end

				9'd2: begin
					if (MVM_DONE) begin
						mvm_counter <= 9'd0;
						IO_flag <= 1;					
					end
				end
				default: begin end

				endcase
			end

		end
end
/*

always @(negedge ASYNC_RST_B or posedge MVM_CLK) begin 
		if (ASYNC_RST_B == 0 ) begin
			mvm_counter <= 0;
			mvm_index <= 0;
			mvm_delay <= 0;
			MVM_EN <= 0;
			mvm_delay_test <= 0;

		end
		else begin
			if (MVM_ON) begin

				case (mvm_counter) 

				9'd0: begin
					//MVM_EN <= 1;
					mvm_counter <= 9'd1;
					mvm_delay_test <= 0;
				end

				9'd1: begin
					//MVM_EN <= 0;
					if (MVM_DONE) begin
						mvm_counter <= 9'd0;
						IO_flag <= 1;					
					end
				end
				default: begin end

				endcase
			end

		end
end


always @(negedge CLK) begin 
		if (MVM_ON) begin
			case (mvm_counter) 
			9'd0: begin
				if (mvm_delay_test == 0) begin
					MVM_EN <= 1;
				end
				else begin
					mvm_delay_test <=  mvm_delay_test + 1;
				end
			end

			9'd1: begin
				MVM_EN <= 0;
			end
			default: begin end
			endcase
		end
end
*/

// ADC test
always @(negedge ASYNC_RST_B or posedge CLK) begin 
		if (ASYNC_RST_B == 0 ) begin
			adc_counter <= 0;
			adc_index <= 0;
			adc_delay <= 0;
			ADC_IN <= 0;
			UPLOAD_INT <= 1'b0;
			IO_flag <= 0;
			//ADC_ON <= 0;
		end
		else begin
			if (ADC_ON) begin

			case (adc_counter) 

			9'd0: begin
				if (adc_delay == 4) begin
					adc_index <= 8'd0;
					adc_delay <= 0;
					adc_counter <=9'd1;
				end
				else begin
					adc_delay <=adc_delay + 1'b1;
				end
			end	

			9'd1: begin
				if (adc_delay == 4) begin
					adc_counter <=9'd2;
					adc_delay <= 0;
					UPLOAD_INT <= 1'b0;		
				end
				else begin
					//adc_index <= 8'd0;
					UPLOAD_INT <= 1'b1;
					adc_delay <=adc_delay + 1'b1;
					ADC_IN <= ADC_IN_TEST[adc_index];
				end
			end	

			9'd2: begin
				if (adc_delay == 15 + 4) begin //2 is ADC processing add time
					if (adc_index == 127) begin
						adc_counter <= 9'd3;
						adc_index <= 0; 
						// IO_MUX <= 4'd7;
						//IO_flag <= 1;
					end
					else begin
						//ADC_IN <= ADC_IN_TEST[adc_index];
						adc_index <= adc_index + 1'b1;
						adc_delay <= 0;
						adc_counter <= 9'd1;
					end
				end
				else begin
					adc_delay <=adc_delay + 1'b1;
				end				
			end

			9'd3: begin
				ADC_ON <= 0;
				IO_flag <= 1;
			end
			default: ;

			endcase		
			end
		end
end


// IO_MUX test
always @(negedge ASYNC_RST_B or posedge CLK) begin 
		if (ASYNC_RST_B == 0 ) begin
			dig_count <= 0;
			dig_index <= 0;
			dig_add <= 0;
			div <= 1'b0;
			counter <= 0;
			BUF_DONE <= 0;
			UPLOAD <= 0;
			//IO_MUX <= 4'd0; // it should be selected (rewritten) for test you want
			START_BUF <= 1'b1;
			DATA_DIG_IN <= 0;
			OUT_BUF_DATA <= 0;
			IO_clk_count <= 0;
		end

		else begin

		if (IO_MUX == 4'd1) begin
			if (counter == 9'd0) begin
				UPLOAD <= 1'b0;
				div <= 1'b0;
				counter <= counter + 1'b1;
			end
			else if (counter == 9'd1) begin
				div <= 1'b0;
				counter <= counter + 1'b1;
			end
			else if (counter == 9'd2) begin
				div <= 1'b1;
				counter <= counter + 1'b1;
			end
			else if (counter == 9'd3) begin
				if (div == 1'b0) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b1;
						dig_index <= dig_index + 1'b1;
						if (dig_index == 8'd7) begin						
							dig_index <= 0;
							dig_count <= dig_count + 1'b1;
							counter <= 9'd4;
							UPLOAD <= 1'b1;
							if (dig_count >= 8'd127) begin
								dig_count <= 0;
								counter <= 9'd40;
							end
						end
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
				else if (div == 1'b1) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b0;
						DATA_DIG_IN <= INPUT_REG_TEST[127-dig_count][7-dig_index];
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
			end
			else if (counter >= 9'd4 && counter <= (9'd4 + 15) ) begin
				if (counter == 9'd4 + 15) begin
					counter <= 9'd23;
					UPLOAD <= 1'b0;
				end
				else counter <= counter + 1'b1;
			end
			if (counter >= 9'd23 && counter <= (9'd23 + 15)) begin
				if (counter == 9'd23 + 15) begin
					counter <= 9'd3;
				end
				else counter <= counter + 1'b1;
			end
			if (counter == 9'd40) begin
				//IO_MUX <= 4'b0110;
				IO_flag <= 1;
				counter <= 0;
			end
		end

		else if (IO_MUX == 4'd2) begin
			if (counter == 9'd0) begin
				UPLOAD <= 1'b0;
				div <= 1'b0;
				counter <= 9'd3;
				IO_clk_count <= 0;
				dig_count <= 0;
			end
			else if (counter == 9'd3) begin
				if (div == 1'b0) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b1;
						dig_index <= dig_index + 1'b1;
						if (dig_index == 8'd7) begin						
							dig_index <= 0;
							dig_count <= dig_count + 1'b1;
							counter <= 9'd4;
							UPLOAD <= 1'b1;
							if (dig_count >= 8'd66) begin
								dig_count <= 0;
								counter <= 9'd40;
							end
						end
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
				else if (div == 1'b1) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b0;
						DATA_DIG_IN <= PATCH_DATA[65-dig_count][7-dig_index];
						//DATA_DIG_IN <= INPUT_REG_TEST[127-dig_count][7-dig_index];
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
			end
			else if (counter >= 9'd4 && counter <= (9'd4 + 15) ) begin
				if (counter == 9'd4 + 15) begin
					counter <= 9'd23;
					UPLOAD <= 1'b0;
				end
				else counter <= counter + 1'b1;
			end
			if (counter >= 9'd23 && counter <= (9'd23 + 15)) begin
				if (counter == 9'd23 + 15) begin
					counter <= 9'd3;
				end
				else counter <= counter + 1'b1;
			end
			if (counter == 9'd40) begin
				//IO_MUX <= 4'b0110;
				IO_flag <= 1;
				counter <= 0;
			end
		end

		else if (IO_MUX==4'd3) begin
			if (counter == 9'd0) begin
				dig_index <= 8'd0;
				div <= 1;
				if (IO_flag == 0) counter <=1'b1;
			end
			else if (counter == 9'd1) begin
				if (div == 1'b1) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 0;
						DATA_DIG_IN <= (!BUF_DONE)? BUF_DATA[RAM_DEPTH-1-dig_count][DATA_WIDTH-1-dig_index]:ADD_DATA[RAM_DEPTH-1-dig_count][8-dig_add];
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
				else if (div == 1'b0) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b1;
						if ( !BUF_DONE ) begin
							if (dig_index == DATA_WIDTH - 1) begin
								BUF_DONE <= 1;
								dig_index <= 8'd0;
							end
							else dig_index <= dig_index + 1'b1;
						end	
						else if (BUF_DONE) begin
							if (dig_add == 4'd8) begin
								dig_add <= 0;
								dig_index <= 8'd0;
								BUF_DONE <= 0;
								UPLOAD <= 1;
								dig_count <= dig_count + 1'b1;					
								if (dig_count == WR_DEPTH) begin
									counter <=  9'd120;
								end
								else counter <=  9'd2;
							end
							else dig_add <= dig_add + 1'b1;		
						end
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
			end
			else if (counter >= 9'd2 && counter <= 9'd64) begin
				if (counter == 9'd15) begin
					counter <= 9'd65;
					UPLOAD <= 1'b0;
				end
				else counter <= counter + 1;
			end
			else if (counter >= 9'd65 && counter <= 9'd100) begin
				if (counter == 9'd65 + 20) begin
					counter <= 9'd0;
					//IO_MUX <= 4'b0101;
					IO_flag <= 1;
				end
				else counter <= counter + 1;
			end
			else if (counter == 9'd120) begin
				IO_flag <= 1;
				for(ii=0; ii<RAM_DEPTH; ii=ii+1) begin
					$display("[%d]: TEST_DATA - %h, OUTPUT - %h", ii,BUF_DATA[ii], READ_DATA[ii]);		 
				end
				for(ii=0; ii<RAM_DEPTH; ii=ii+1) begin
					if(BUF_DATA[ii] !== READ_DATA[ii]) begin
						$display("Error error [%d]: ", ii);
					end	
				end
			end

/*
			else if (counter == 9'd2) begin
				if (div == 1'b1 && IO_clk_count == IO_scale) begin
					IO_clk_count <= 0;
					div <= 0;
				end
				else if (div == 1'b0 && IO_clk_count == IO_scale) begin
					if (dig_add != 4'd8) begin
						IO_clk_count <= 0;
						div <= 1'b1;
						dig_add <= dig_add + 1'b1;
						UPLOAD <= 1'b0;
					end
					else if (dig_add == 4'd8) begin
						dig_add <= 0;
						counter <= 9'd0;
						IO_MUX <= 4'b0101;
					end
				end
				else IO_clk_count <= IO_clk_count + 1'b1;
			end
*/
		end

		else if (IO_MUX == 4'd4) begin
			if (counter == 9'd0) begin
				UPLOAD <= 1'b0;
				div <= 1'b0;
				counter <= counter + 1'b1;
			end
			else if (counter == 9'd1) begin
				if (div == 1'b0) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b1;
						dig_count <= dig_count + 1'b1;
						if (dig_count == Wreg) begin						
							dig_count <= 0;
							counter <= 9'd2;
							//UPLOAD <= 1'b1;
						end
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
				else if (div == 1'b1) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b0;
						DATA_DIG_IN <= SETUP_DATA_INIT[Wreg-dig_count];
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
			end
			else if (counter == 9'd2) begin
				if (div == 1'b0) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b1;
						counter <= 9'd3;
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
				else if (div == 1'b1) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b0;
						UPLOAD <= 1'b1;
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
			end

			else if (counter == 9'd3) begin
				if (IO_clk_count == IO_scale) begin
					div <= 1'b0;
					counter <= 9'd4;
					UPLOAD <= 1'b0;
					IO_clk_count <= 0;
				end
				else IO_clk_count <= IO_clk_count + 1'b1;
			end

			else if (counter == 9'd4) begin
				if (IO_clk_count == IO_scale) begin
					//IO_MUX <= 4'd3;
					IO_flag <= 1;
					counter <= 9'd0;
					IO_clk_count <= 0;
				end
				else IO_clk_count <= IO_clk_count + 1'b1;
			end
		end

		else if (IO_MUX == 4'd5) begin
			if (counter == 9'd0) begin
				UPLOAD <= 1'b0;
				dig_index <= 8'd0;
				div <= 1'b0;
				IO_clk_count <= 0;
				counter <= counter + 1'b1;
			end
			else if (counter == 9'd1) begin
				UPLOAD <= 1'b1;
				counter <= counter + 1'b1;
			end
			else if (counter >= 9'd2 && counter <= 9'd9) begin
				if (counter == 9'd4) begin 
					UPLOAD <= 1'b0;
					counter <= 9'd10;
				end
				else counter <= counter + 1'b1;
			end
			else if (counter >= 9'd10 && counter <= 9'd15) begin
				if (counter == 9'd15) begin 
					counter <= 9'd20;
					div <= 1'b0;
				end
				else counter <= counter + 1'b1;
			end
/*
			else if (counter == 9'd16) begin
				if (div) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b0;
						counter <= 9'd20;
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
			end
*/
			else if (counter == 9'd20) begin
				if (div == 1'b1) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b0;
						READ_DATA[RAM_DEPTH-dig_count][dig_index-1] <= SCAN_OUT;
						if (dig_index == (DATA_WIDTH )) begin						
							dig_index <= 8'd0;
							//IO_MUX <= 4'b0011;
							IO_flag <= 1;
							counter <= 9'd25;
						end
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
				else if (div == 1'b0) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b1;
						dig_index <= dig_index + 1'b1;
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
			end

			else if (counter == 9'd25) begin
				counter <= 0;
				$display("[%d]: TEST_DATA - %h, OUTPUT - %h",RAM_DEPTH-dig_count,BUF_DATA[RAM_DEPTH-dig_count], READ_DATA[RAM_DEPTH-dig_count]);
			end
		end

		else if (IO_MUX == 4'd6 || IO_MUX == 4'd7) begin			
			if (counter == 9'd0) begin
				UPLOAD <= 1'b0;
				div <= 1'b1;
				counter <= counter + 1'b1;
			end
			else if (counter == 9'd1) begin
				div <= 1'b0;
				UPLOAD <= 1'b1;
				counter <= counter + 1'b1;
			end
			else if (counter == 9'd2) begin
				div <= 1'b1;
				counter <= counter + 1'b1;
			end
			else if (counter == 9'd3) begin
				div <= 1'b0;
				UPLOAD <= 1'b0;
				counter <= counter + 1'b1;
			end
			else if (counter == 9'd4) begin
				if (div == 1'b0) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b1;
						dig_count <= dig_count + 1'b1;
						if (dig_count == 9'd128) begin						
							dig_count <= 0;
							dig_index <= dig_index + 1'b1;
							counter <= 9'd0;
							if (dig_index >= 8'd7) begin
								dig_index <= 0;
								counter <= 9'd270;
								// IO_flag <= 1;
							end
						end
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
				else if (div == 1'b1) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b0;
						INPUT_REG_DATA[128-dig_count][dig_index] <= SCAN_OUT;
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
			end
			else if (counter == 9'd270) begin
				IO_flag <= 1;
				// counter <= counter + 1'b1;

				$display("IO_MUX 6 is done");
				for(ii=0;ii<128;ii=ii+1) begin
					if(INPUT_REG_DATA[ii] !== INPUT_REG_TEST[ii]) begin
						$display("[%d]: INPUT_REG_DATA - %h, INPUT_REG_TEST - %h", ii,INPUT_REG_DATA[ii],INPUT_REG_TEST[ii]);
					end			 
				end
/*
				$display("ADC_TEST is done");
				for(ii=0; ii<128; ii=ii+1) begin
					$display("[%d]: ADC_TEST_DATA - %h, OUTPUT - %h", ii,ADC_IN_TEST[ii],INPUT_REG_DATA[ii]);		 
				end
				for(ii=0; ii<RAM_DEPTH; ii=ii+1) begin
					if(ADC_IN_TEST[ii] !== INPUT_REG_DATA[ii]) begin
						$display("Error error [%d]: ", ii);
					end	
				end
*/

			end
			else begin

			end
		end

		else if (IO_MUX == 4'd8) begin
			counter <= counter + 1'b1;
			if (counter == 9'd0) begin
				UPLOAD <= 1'b0;
				div <= 1'b1;
			end
			else if (counter == 9'd1) begin
				div <= 1'b0;
				UPLOAD <= 1'b1;
			end
			else if (counter == 9'd2) begin
				div <= 1'b1;
			end
			else if (counter == 9'd3) begin
				div <= 1'b0;
				UPLOAD <= 1'b0;
			end
			else if (counter >= 9'd4 && counter <= 9'd265) begin
				if (div == 1'b0) begin
					if (IO_clk_count == IO_scale) begin
						IO_clk_count <= 0;
						div <= 1'b1;
						dig_count <= dig_count + 1'b1;
						if (dig_count == 9'd128) begin						
							dig_count <= 0;
							dig_index <= dig_index + 1'b1;
							counter <= 9'd0;
							for(ii=0;ii<25;ii=ii+1) begin
								OUT_BUF_TB[ 4*(2-dig_index) + 3 ][24-ii] <= OUT_BUF_DATA[120-ii]; //MSB FIRST
								OUT_BUF_TB[ 4*(2-dig_index) + 2 ][24-ii] <= OUT_BUF_DATA[88-ii]; //MSB FIRST
								OUT_BUF_TB[ 4*(2-dig_index) + 1 ][24-ii] <= OUT_BUF_DATA[56-ii]; //MSB FIRST
								OUT_BUF_TB[ 4*(2-dig_index) + 0 ][24-ii] <= OUT_BUF_DATA[24-ii]; //MSB FIRST
							end
							if (dig_index >= 8'd2) begin
								dig_index <= 0;
							end
						end
					end
					else IO_clk_count <= IO_clk_count + 1'b1;		
				end
				else if (div == 1'b1) begin
				if (div == 1'b0) begin
					if (IO_clk_count == IO_scale) begin
						div <= 1'b0;
						OUT_BUF_DATA[128-dig_count] <= SCAN_OUT;
					end
					else IO_clk_count <= IO_clk_count + 1'b1;
				end
				end
			end
		end

		else begin

		end
	end	
	end

endmodule
