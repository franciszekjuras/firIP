`timescale 1ns / 1ps

module counter
	#(parameter COUNT_WIDTH = 1, MODULO = 2)
	(
		input wire clk,
		output reg [COUNT_WIDTH-1:0] count
	);
	if(2**COUNT_WIDTH < MODULO)
		$fatal(2,"Fatal elab. error: invalid parameters values 2^%d < %d in counter", COUNT_WIDTH, MODULO);

	always @(posedge clk) 
	begin
		if(count == MODULO - 1)
			count <= 32'b0;
		else
			count <= count + 1;
	end
endmodule