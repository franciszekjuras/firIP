`timescale 1ns / 1ps

module out
	#(parameter COUNT_WIDTH = 1, FIR_DATA_WIDTH = 32)
	(
	input wire clk_fir,
	input wire [COUNT_WIDTH-1:0] count,
	input wire [FIR_DATA_WIDTH-1:0] in,
	input wire clk_dac,
	output wire [FIR_DATA_WIDTH-1:0] out
    );
	

endmodule
