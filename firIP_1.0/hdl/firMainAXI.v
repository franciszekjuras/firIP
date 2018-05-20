
`timescale 1 ns / 1 ps

	module firMainAXI #
	(
		// Users to add parameters here
		parameter FIR_DATA_WIDTH = 14,
		parameter FIR_COEF_WIDTH = 18,
		parameter FIR_COEF_MAG = 0,
		parameter FIR_DSP_NR = 4, 
		parameter FIR_TM = 2,
		parameter UPSAMP_DATA_WIDTH_EXT = 4, //TODO: set this parameter as ip customizable or set some sensible value
		parameter UPSAMP_DSP_NR = 10,
		// User parmaters end

		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 16
	)
	(
		// Users to add ports here
		input wire fir_clk,
		input wire signed [FIR_DATA_WIDTH-1 : 0] fir_in,
		output reg signed [FIR_DATA_WIDTH-1 : 0] fir_out,
		output wire [7:0] leds_out,
		// User ports ends
		
		input wire  S_AXI_ACLK,
		input wire  S_AXI_ARESETN,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		input wire [2 : 0] S_AXI_AWPROT,
		input wire  S_AXI_AWVALID,
		output wire  S_AXI_AWREADY,
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input wire  S_AXI_WVALID,
		output wire  S_AXI_WREADY,
		output wire [1 : 0] S_AXI_BRESP,
		output wire  S_AXI_BVALID,
		input wire  S_AXI_BREADY,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		input wire [2 : 0] S_AXI_ARPROT,
		input wire  S_AXI_ARVALID,
		output wire  S_AXI_ARREADY,
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		output wire [1 : 0] S_AXI_RRESP,
		output wire  S_AXI_RVALID,
		input wire  S_AXI_RREADY
	);
	
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits addressing
	// ADDR_LSB = 3 for 64 bits addressing

	localparam FIR_COEFS_NR = FIR_TM * FIR_DSP_NR;
	localparam UPSAMP_COEFS_NR = FIR_TM * UPSAMP_DSP_NR;

	localparam ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam ADDR_BRAM_WIDTH = 7;
	localparam ADDR_DSP_WIDTH = C_S_AXI_ADDR_WIDTH - ADDR_BRAM_WIDTH - ADDR_LSB; //7
	// Addresses' bases in 32/64 bit addressing
	localparam FIR_BASE_COEFS = 1;
	localparam FIR_BASE_UPSAMP_COEFS = 81;
	localparam FIR_OFFSET_DEBUG = 8;
	//reverse order xD
	localparam PROG_NAME = "_RIF";
	localparam PROG_VER = "2MT";

	//Switches:
	localparam SWITCH_CON_EST = 0;
	localparam SWITCH_FIR_EN = 1;
	localparam SWITCH_FIR_UPDATE = 2;
	localparam SWITCH_FIR_SNAP = 5;
	localparam SWITCH_FIR_DEBUG_1 = 6;
	localparam SWITCH_FIR_DEBUG_2 = 7;

	//TODO: Add address space testing



	integer idx;

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH - ADDR_LSB -1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH - ADDR_LSB -1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;
	wire	 reg_rden;
	wire	 reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	reg	 aw_en;

	// I/O Connections assignments
	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;

	// addr separation
	wire [ADDR_DSP_WIDTH-1:0] addr_dsp;
	wire [ADDR_BRAM_WIDTH-1:0] addr_bram;
	reg [ADDR_BRAM_WIDTH-1:0] coef_bram_addr;
	reg signed [FIR_COEF_WIDTH-1:0] coef_bram_data;
	reg fir_bram_en [FIR_DSP_NR];
	reg upsamp_bram_en [UPSAMP_DSP_NR];
	always @( posedge S_AXI_ACLK ) begin
		coef_bram_addr <= addr_bram;
	end
	always @( posedge S_AXI_ACLK ) begin
		coef_bram_data <= {S_AXI_WDATA[C_S_AXI_DATA_WIDTH-1],S_AXI_WDATA[FIR_COEF_WIDTH-2:0]};
	end
	assign addr_bram = axi_awaddr[ADDR_BRAM_WIDTH-1:0];
	assign addr_dsp = axi_awaddr[ADDR_BRAM_WIDTH+ADDR_DSP_WIDTH-1:ADDR_BRAM_WIDTH];

	// Registers connected to AXI
	//read-only
/*0*/    reg [C_S_AXI_DATA_WIDTH-1 : 0] info_1;
/*1*/    reg [C_S_AXI_DATA_WIDTH-1 : 0] info_2; //TODO: add extra info,
/*2*/    reg [C_S_AXI_DATA_WIDTH-1 : 0] fir_coefs_max_nr;
/*3*/    reg [C_S_AXI_DATA_WIDTH-1 : 0] upsamp_coefs_nr;
	//write|read
/*4*/    reg [C_S_AXI_DATA_WIDTH-1 : 0] switches;
/*5*/    reg [C_S_AXI_DATA_WIDTH-1 : 0] fir_coefs_crr_nr;
/*6*/    //reg [C_S_AXI_DATA_WIDTH-1 : 0] unused;
/*7*/    //reg [C_S_AXI_DATA_WIDTH-1 : 0] unused;

	reg signed [FIR_COEF_WIDTH-1 : 0] fir_coefs [FIR_COEFS_NR];
	reg signed [FIR_COEF_WIDTH-1 : 0] upsamp_coefs [UPSAMP_COEFS_NR];

	/*Dozen of boring AXI4-lite procedures*/
	always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		axi_awready <= 1'b0;
		aw_en <= 1'b1;
		end else begin    
		if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
			axi_awready <= 1'b1;
			aw_en <= 1'b0;
			end else if (S_AXI_BREADY && axi_bvalid) begin
				aw_en <= 1'b1;
				axi_awready <= 1'b0;
			end else begin
				axi_awready <= 1'b0;
			end
		end 
	end       

	always @( posedge S_AXI_ACLK )begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_awaddr <= 0;
		else begin    
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
				axi_awaddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH-1 : ADDR_LSB];
		end 
	end       

	always @( posedge S_AXI_ACLK )begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_wready <= 1'b0;
		else begin    
			if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) 
				axi_wready <= 1'b1;
			else
				axi_wready <= 1'b0;
		end 
	end       

	assign reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	//-----------------------------------------------------//
	//--------------------WRITE MAPPING--------------------//
	//-----------------------------------------------------//

	always @( posedge S_AXI_ACLK ) begin: write_data
		if (reg_wren & S_AXI_ARESETN) begin
			for(idx = 0; idx < FIR_DSP_NR; idx = idx + 1) begin
				if(idx + FIR_BASE_COEFS == addr_dsp)
					fir_bram_en[idx] <= 1'b1;
			end

			for(idx = 0; idx < UPSAMP_DSP_NR; idx = idx + 1) begin
				if(idx + FIR_BASE_UPSAMP_COEFS == addr_dsp)
					upsamp_bram_en[idx] <= 1'b1;
			end

			case(axi_awaddr)
				4: switches <= S_AXI_WDATA;
				5: fir_coefs_crr_nr <= S_AXI_WDATA;
				//6: unused <= S_AXI_WDATA;
				//7: unused <= S_AXI_WDATA;
			endcase
		end else begin
			for(idx = 0; idx < FIR_DSP_NR; idx = idx + 1) begin
				fir_bram_en[idx] <= 1'b0;
			end
			for(idx = 0; idx < UPSAMP_DSP_NR; idx = idx + 1) begin
				upsamp_bram_en[idx] <= 1'b0;
			end
		end
	end    

	always @( posedge S_AXI_ACLK ) begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_bvalid  <= 0;
			axi_bresp   <= 2'b0;
		end else begin    
			if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
				axi_bvalid <= 1'b1;
				axi_bresp  <= 2'b0; // 'OKAY' response 
			end else begin
				if (S_AXI_BREADY && axi_bvalid)
					axi_bvalid <= 1'b0; 
			end
		end
	end   

	always @( posedge S_AXI_ACLK ) begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_arready <= 1'b0;
			axi_araddr  <= 32'b0;
		end else begin    
			if (~axi_arready && S_AXI_ARVALID) begin
				axi_arready <= 1'b1;
				axi_araddr  <= S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH-1 : ADDR_LSB];
			end else begin
				axi_arready <= 1'b0;
			end
		end 
	end

	always @( posedge S_AXI_ACLK ) begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_rvalid <= 0;
			axi_rresp  <= 0;
		end else begin    
			if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
				axi_rvalid <= 1'b1;
				axi_rresp  <= 2'b0; // 'OKAY' response
			end else if (axi_rvalid && S_AXI_RREADY) begin
			  axi_rvalid <= 1'b0;
			end                
		end
	end 

	//-----------------------------------------------------//
	//---------------------READ MAPPING--------------------//
	//-----------------------------------------------------//

	assign reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
		// Address decoding for reading registers
		case ( axi_araddr )
		0 : reg_data_out = info_1;
		1 : reg_data_out = info_2;
		2 : reg_data_out = fir_coefs_max_nr;
		3 : reg_data_out = upsamp_coefs_nr;
		4 : reg_data_out = switches;
		5 : reg_data_out = fir_coefs_crr_nr;
		// 6 : reg_data_out = unused;
		// 7 : reg_data_out = unused;
		default : reg_data_out = 0;
		endcase
		// for(idx = 0; idx < (DEBUG_LENGTH*DEBUG_DEPTH); idx = idx + 1) begin
		// 	if(idx + FIR_OFFSET_DEBUG == axi_araddr) begin
		// 		reg_data_out = debug_block[idx]; //WARN:sign bit might not be shifted properly
		// 	end
		// end	   
	end

	always @( posedge S_AXI_ACLK ) begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_rdata  <= 0;
		end else begin 
			if (reg_rden)
				axi_rdata <= reg_data_out;
		end
	end    
	//Pudika kocha Pudimy :3 //
	// NO LOGIC //
	//-----------------------------------------------------//
	//------------------------LOGIC------------------------//
	//-----------------------------------------------------//

	//LEDS
	assign leds_out[7:0] = switches[7:0];

	//COUNTER
	localparam COUNT_WIDTH = $clog2(FIR_TM);
	wire [COUNT_WIDTH-1:0] count;
	wire [COUNT_WIDTH-1:0] count_origin;

	counter #(
	.COUNT_WIDTH(COUNT_WIDTH),
	.MODULO(FIR_TM)) 
	inst_counter (
	.clk(fir_clk),
	.count(count_origin));

	//counter connections wiring
	wire [COUNT_WIDTH-1:0] fir_con_count [FIR_DSP_NR + 1];
	assign fir_con_count[0] = count_origin;
	shiftby #(.BY(2), .WIDTH(COUNT_WIDTH)) shift_count_origin
	(.in(count_origin), .out(count), .clk(fir_clk));


	/*---Partial sums and samples wirings---*/
	localparam SUM_WIDTH = FIR_DATA_WIDTH + FIR_COEF_MAG; /*at the end, sum is shortened by COEFMAG to XW length,
	so there is little reason to add more registers*/

	wire signed [SUM_WIDTH-1:0] fir_con_sum [FIR_DSP_NR:0]; //+1 because of beg and end, ex: ---DSP---DSP---DSP--- || note: 3 DSPs and 4 wires
	wire signed [FIR_DATA_WIDTH-1:0] fir_con_x [FIR_DSP_NR:0]; //same as above
	
	wire signed [SUM_WIDTH-1:0] sum_loop_end;
	wire signed [FIR_DATA_WIDTH-1:0] data_loop_end;
	/*---------------------------------------*/

	/*---Loop shift (synchronization)... and multiplexing---*/
	localparam LOOP_FEEDBACK_SYNC = FIR_TM + 1 - (FIR_DSP_NR%FIR_TM);

	shiftby #(.BY(LOOP_FEEDBACK_SYNC), .WIDTH(FIR_DATA_WIDTH))
	shift_data_loop
	(.in(fir_con_x[FIR_DSP_NR]), .out(data_loop_end), .clk(fir_clk));

	shiftby #(.BY(LOOP_FEEDBACK_SYNC), .WIDTH(SUM_WIDTH))
	shift_sum_loop
	(.in(fir_con_sum[FIR_DSP_NR]), .out(sum_loop_end), .clk(fir_clk));

	/*---...and samples multiplexing...---*/
	loop_multplx #(
	.COUNT_WIDTH(COUNT_WIDTH),
	.DATA_WIDTH(FIR_DATA_WIDTH)	
	) 
	inst_in_multplx (
	.count(count),
	.in(fir_in),
	.loop(data_loop_end),
	.out(fir_con_x[0])
	);

	/*---...and sum multiplexing (with synchronization)---*/
	localparam DSP_PIPELINE_DIFF = 1; // difference in registers from samples multiplexer
	// to first summation in fir block (so fresh sample would contribute to fresh 0 sum)
	wire [COUNT_WIDTH-1:0] sum_count;
	shiftby #(.BY(DSP_PIPELINE_DIFF), .WIDTH(COUNT_WIDTH))
	shift_sum_count 
	(.in(count), .out(sum_count), .clk(fir_clk));

	loop_multplx #(
	.COUNT_WIDTH(COUNT_WIDTH),
	.DATA_WIDTH(SUM_WIDTH)	
	) 
	inst_sum_multplx (
	.count(sum_count),
	.in(0),
	.loop(sum_loop_end),
	.out(fir_con_sum[0])
	);
	/*--------------------------------------*/

	/*----------------------------------------------------------------------------------*/
	/*Generating fir taps (DSP blocks + shifting registers + coefficients' multiplexers)*/
	/*----------------------------------------------------------------------------------*/

	/*---Coefficients' wiring---*/

	wire signed [FIR_COEF_WIDTH-1 : 0] fir_coef_crr [FIR_DSP_NR];
	/*---------------------------------------*/

	/*----------------Fir taps---------------*/
	generate
		for(genvar k = 0; k < FIR_DSP_NR; k = k + 1) begin
			firtap #(
			.XW(FIR_DATA_WIDTH),
			.COEFW(FIR_COEF_WIDTH),
			.OUTW(SUM_WIDTH),
			.SAMPLE_SHIFT(1),
			.SUM_SHIFT(1+FIR_TM)
			) inst_tap(
			.clk(fir_clk),
			.inX(fir_con_x[k]),
			.outX(fir_con_x[k+1]),
			.inCoef(fir_coef_crr[k]),
			.inSum(fir_con_sum[k]),
			.outSum(fir_con_sum[k+1])
			);
		end
	endgenerate
	/*--------------------------------------*/

	/*---Coefficients' multiplexing---*/
	generate
		for(genvar l = 0; l < FIR_DSP_NR; l = l+1) begin
			coef_multplx #(
			.COEFW(FIR_COEF_WIDTH),
			.AW(ADDR_BRAM_WIDTH),
			.TM(FIR_TM),
			.CW(COUNT_WIDTH)
			) inst_fir_coef_multplx(
			.clkw(S_AXI_ACLK),
			.clkr(fir_clk),
			.counter_in(fir_con_count[l]),
			.counter_out(fir_con_count[l+1]),
			.coef_write(coef_bram_data),
			.coef_write_addr(coef_bram_addr),
			.coef_write_en(fir_bram_en[l]),
			.coef_out(fir_coef_crr[l])
			);
		end
	endgenerate
	/*---------------------------------*/

	/*---Transition to upsampler---*/
	localparam UPSAMP_DATA_WIDTH = FIR_DATA_WIDTH + UPSAMP_DATA_WIDTH_EXT;

	reg signed [UPSAMP_DATA_WIDTH-1:0] upsamp_in;
	reg signed [UPSAMP_DATA_WIDTH-1:0] upsamp_in_1;
	wire [COUNT_WIDTH-1:0] upsamp_count;
	always @(posedge fir_clk) begin
		if(sum_count == 0)
			upsamp_in_1[UPSAMP_DATA_WIDTH-1:0] <= sum_loop_end[SUM_WIDTH-1: SUM_WIDTH - UPSAMP_DATA_WIDTH];
	end
	always @(posedge fir_clk) begin
		upsamp_in <= upsamp_in_1;
	end
	//data is shifted 2 times relative to counter
	assign upsamp_count = sum_count;

	/*--------------------------------*/
	/*----------UPSAMPLER-------------*/
	/*--------------------------------*/

	//counter connections wiring
	wire [COUNT_WIDTH-1:0] upsamp_con_count [UPSAMP_DSP_NR + 1];
	assign upsamp_con_count[0] = upsamp_count;


	/*---Partial sums and samples wirings---*/
	localparam UPSAMP_SUM_WIDTH = UPSAMP_DATA_WIDTH + FIR_COEF_MAG; /*at the end, sum is shortened by COEFMAG to XW length,
	so there is little reason to add more registers*/


	wire signed [UPSAMP_SUM_WIDTH-1:0] upsamp_con_sum [UPSAMP_DSP_NR:0]; //+1 because of beg and end, ex: ---DSP---DSP---DSP--- || note: 3 DSPs and 4 wires
	wire signed [UPSAMP_DATA_WIDTH-1:0] upsamp_con_x [UPSAMP_DSP_NR:0]; //same as above
	//starting pipeline values
	assign upsamp_con_x[0] = upsamp_in;
	assign upsamp_con_sum[0] = 0;

	
	/*----------------------------------------------------------------------------------*/
	/*Generating fir taps (DSP blocks + shifting registers + coefficients' multiplexers)*/
	/*----------------------------------------------------------------------------------*/

	/*---Coefficients' wiring---*/

	wire signed [FIR_COEF_WIDTH-1 : 0] upsamp_coef_crr [UPSAMP_DSP_NR];

	/*----------------Fir taps---------------*/
	generate
		for(genvar k = 0; k < UPSAMP_DSP_NR; k = k + 1) begin
			firtap #(
			.XW(UPSAMP_DATA_WIDTH),
			.COEFW(FIR_COEF_WIDTH),
			.OUTW(UPSAMP_SUM_WIDTH),
			.SAMPLE_SHIFT(1),
			.SUM_SHIFT(1+FIR_TM)
			) inst_upsamp_tap(
			.clk(fir_clk),
			.inX(upsamp_con_x[k]),
			.outX(upsamp_con_x[k+1]),
			.inCoef(upsamp_coef_crr[k]),
			.inSum(upsamp_con_sum[k]),
			.outSum(upsamp_con_sum[k+1])
			);
		end
	endgenerate
	/*--------------------------------------*/

	/*---Coefficients' multiplexing---*/
	generate
		for(genvar l = 0; l < UPSAMP_DSP_NR; l = l+1) begin
			coef_multplx #(
			.COEFW(FIR_COEF_WIDTH),
			.AW(ADDR_BRAM_WIDTH),
			.TM(FIR_TM),
			.CW(COUNT_WIDTH)
			) inst_upsamp_coef_multplx(
			.clkw(S_AXI_ACLK),
			.clkr(fir_clk),
			.counter_in(upsamp_con_count[l]),
			.counter_out(upsamp_con_count[l+1]),
			.coef_write(coef_bram_data),
			.coef_write_addr(coef_bram_addr),
			.coef_write_en(upsamp_bram_en[l]),
			.coef_out(upsamp_coef_crr[l])
			);
		end
	endgenerate

	/*---Upsampler output---*/
	wire signed [FIR_DATA_WIDTH-1:0] upsampler_out;
	assign upsampler_out[FIR_DATA_WIDTH-1:0] = upsamp_con_sum[UPSAMP_DSP_NR][UPSAMP_SUM_WIDTH-1: UPSAMP_SUM_WIDTH - FIR_DATA_WIDTH];


	/*---Fir switch on/off---*/
	always @(*)
	begin
		case (switches[SWITCH_FIR_EN])
			1'b0	:	fir_out = fir_in;
			1'b1	:	fir_out = upsampler_out;
			default	:	fir_out = 0;
		endcase
	end
	/*-----------------------*/

	/*-----Fir info------*/
	always @(*) begin
		fir_coefs_max_nr = FIR_COEFS_NR;
		upsamp_coefs_nr = UPSAMP_COEFS_NR;
		info_1 = PROG_NAME;
		info_2 = PROG_VER; 
	end
	/*-------------------*/



	//assign debug_in[0] = upsamp_con_sum[0];
	// assign debug_in[1] = upsamp_con_x[0];
	// assign debug_in[2] = upsamp_coef_crr[0];
	// assign debug_in[3] = upsamp_con_sum[1];
	// assign debug_in[4] = upsamp_con_x[1];
	// assign debug_in[5] = upsamp_coef_crr[1];	
	// assign debug_in[6] = upsamp_con_sum[2];
	// assign debug_in[7] = fir_con_x[2];
	// assign debug_in[8] = fir_coef_crr[2];	
	// assign debug_in[9] = fir_con_sum[3];
	// assign debug_in[10] = fir_con_x[3];
	// assign debug_in[11] = fir_coef_crr[3];	
	// assign debug_in[12] = fir_con_sum[4];
	// assign debug_in[13] = fir_con_x[4];
	// assign debug_in[14] = fir_coef_crr[4];	
	// assign debug_in[15] = fir_con_sum[5];
	// assign debug_in[16] = fir_con_x[5];
	// assign debug_in[17] = fir_coef_crr[5];	
	// assign debug_in[18] = fir_con_sum[6];
	// assign debug_in[19] = fir_con_x[6];
	// assign debug_in[20] = fir_coef_crr[6];	
	// assign debug_in[21] = fir_con_sum[7];
	// assign debug_in[22] = fir_con_x[7];
	// assign debug_in[23] = fir_coef_crr[7];	
	// assign debug_in[24] = fir_con_sum[8];
	// assign debug_in[25] = fir_con_x[8];
	// assign debug_in[26] = fir_coef_crr[8];	
	// assign debug_in[27] = fir_con_sum[9];
	// assign debug_in[28] = fir_con_x[9];
	// assign debug_in[29] = fir_coef_crr[9];
	// assign debug_in[30] = fir_con_sum[10];

	// assign debug_in[0] = upsamp_coef_crr[0];
	// assign debug_in[1] = upsamp_coef_crr[1];
	// assign debug_in[2] = upsamp_coef_crr[2];
	// assign debug_in[3] = upsamp_coef_crr[3];
	// assign debug_in[4] = upsamp_coef_crr[4];
	// assign debug_in[5] = upsamp_coef_crr[5];
	// assign debug_in[6] = upsamp_coef_crr[6];
	// assign debug_in[7] = upsamp_coef_crr[7];
	// assign debug_in[8] = upsamp_coef_crr[8];
	// assign debug_in[9] = upsamp_coef_crr[9];


	// assign debug_in[0] = fir_in;
	// assign debug_in[1] = fir_con_x[0];
	// assign debug_in[2] = upsamp_in;
	// assign debug_in[3] = fir_out;
	//assign debug_in[(DEBUG_DSP_STAGES*3)+3] = fir_in;


	/////////////////////


	// User logic ends

	// localparam DEBUG_LENGTH = 5;
	// localparam DEBUG_DEPTH = 10;

	// localparam DEBUG_WIDTH = UPSAMP_DATA_WIDTH;

	// wire signed [DEBUG_WIDTH-1:0] debug_in [DEBUG_DEPTH];
	// reg signed [DEBUG_WIDTH-1:0] debug [DEBUG_DEPTH][DEBUG_LENGTH];
	// wire signed [DEBUG_WIDTH-1:0] debug_block [DEBUG_LENGTH*DEBUG_DEPTH];

	// reg fir_snap; 
	// xpm_cdc_single fir_snap_cdc (
	// 	.src_clk(S_AXI_ACLK),
	// 	.src_in(switches[SWITCH_FIR_SNAP]),
	// 	.dest_clk(fir_clk),
	// 	.dest_out(fir_snap)
	// );

	// genvar m, n;
	// generate
	// 	for(m = 0; m < DEBUG_DEPTH; m = m + 1)
	// 	begin
	// 		always @(posedge fir_clk)
	// 		begin
	// 			if(fir_snap)
	// 			begin
	// 				debug[m][0] <= debug_in[m];
	// 				for(int k = 1; k < DEBUG_LENGTH; k = k + 1) begin
	// 		            debug[m][k] <= debug[m][k-1];
	// 		        end
	// 		    end
	// 		end
	// 		for(n = 0; n < DEBUG_LENGTH; n = n + 1)
	// 		begin
	// 			assign debug_block[n+(DEBUG_LENGTH*m)] = debug[m][n];
	// 		end
	// 	end		
	// endgenerate


	endmodule