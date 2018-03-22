`timescale 1ns / 1ps

module coef_multplx
	#(parameter COEFW = 18, TM = 2, CW = 1)
	(
	input wire clk,
	input wire [CW-1:0] counter_in,
	output reg [CW-1:0] counter_out,
	input wire [COEFW-1:0] coef_pack [TM],
	output reg [COEFW-1:0] coef_out
    );
	
	integer idx;
	
	always @(*)
	begin
		for(idx = 0; idx < TM; idx = idx + 1)
		begin
			if(idx == counter_in)
				coef_out = coef_pack[idx];
		end
	end

	always @(posedge clk)
		counter_out <= counter_in;
endmodule
