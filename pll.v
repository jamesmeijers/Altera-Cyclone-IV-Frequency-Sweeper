
module pll(
	input CLK_50,
	input reset,
	input next_frequency,
	output reg [8:0] frequency,
	output reg freq_ready,
	output reconfig_CLK,
	output [4:0] curr_state,
	input [3:0] add
); 
	wire pll_reset, configupdate_sig, scanclk_sig, scanclkena_sig, scandata_sig, locked_sig, scandataout_sig, scandone_sig;
	reg [8:0] data_in_sig;
	reg [3:0] counter_type_sig;
	reg [2:0] counter_param_sig;
	reg read_param_sig, write_param_sig, reconfig_sig;
	wire busy_sig;
	wire [8:0] data_out_sig;
	
	localparam start_freq = 1;
	wire phasestep;
	assign phasestep = next_frequency;
	

	reg [3:0] counter_type;
	
	reconfig_pll  pll1(
		.areset(pll_reset),
		.configupdate(configupdate_sig),
		.inclk0(CLK_50),
		.scanclk(scanclk_sig),
		.scanclkena(scanclkena_sig),
		.scandata(scandata_sig),
		.c0(reconfig_CLK),
		.locked(locked_sig),
		.scandataout(scandataout_sig),
		.scandone(scandone_sig)
	);
	
	
	pll_reconfig	pll_reconfig_inst (
		.clock ( CLK_50 ),
		.counter_param ( counter_param_sig ),
		.counter_type (counter_type),
		.data_in ( data_in_sig ),
		.pll_areset_in ( reset ),
		.pll_scandataout ( scandataout_sig ),
		.pll_scandone ( scandone_sig ),
		.read_param ( read_param_sig ),
		.reconfig ( reconfig_sig ),
		.reset ( reset ),
		.write_param ( write_param_sig ),
		.busy ( busy_sig ),
		.data_out ( data_out_sig ),
		.pll_areset ( pll_reset),
		.pll_configupdate ( configupdate_sig ),
		.pll_scanclk ( scanclk_sig ),
		.pll_scanclkena(scanclkena_sig),
		.pll_scandata ( scandata_sig )
	);
	
	assign curr_state = state;

	reg [4:0] state, next_state;
	
	//reg [2:0] counter_param;
	
	localparam M_param = 4'h1;
	localparam N_param = 4'h0;
	localparam C_param = 4'd4;
	
	localparam begin_sweep = 5'd0; //set initial values
	
	localparam write_N = 5'd1;             //write new N value
	localparam wait_busy_N = 5'd2;         //wait for busy to go high
	localparam hold_N = 5'd3;					//wait for busy to go low
	localparam cycle_N = 5'd4;					//set values for M writing
	
	localparam write_C_high = 5'd21;
	localparam wait_busy_C_high = 5'd22;
	localparam hold_C_high = 5'd23;
	localparam cycle_C_high = 5'd24;
	
	localparam write_C_low = 5'd25;
	localparam wait_busy_C_low = 5'd26;
	localparam hold_C_low = 5'd27;
	localparam cycle_C_low = 5'd28;
	
	localparam write_M = 5'd11;				//write new M value
	localparam wait_busy_M = 5'd12;			//wait for busy to go high
	localparam hold_M = 5'd13;					//wait for busy to go low
	localparam cycle_M = 5'd14;				//add one to M for next frequency
	
	localparam write_config = 5'd15;			//update the PLL
	localparam wait_busy_config = 5'd16;	//wait for busy to go high
	localparam hold_config = 5'd17;			//wait for busy to go low
	localparam cycle_config = 5'd18;			//add one to frequency
	
	localparam hold_frequency = 5'd19;		//wait for next frequency signal and display when PLL is locked
	localparam wait_button = 5'd20;

	
	always @ (posedge CLK_50) begin
		if(reset) state <= begin_sweep;
		else state <= next_state;
	end
	
	always @ (*) begin
		case (state)
			begin_sweep: next_state = write_N;
			
			write_N: next_state = wait_busy_N;
			wait_busy_N: if(busy_sig) next_state = hold_N;
					else next_state = wait_busy_N;
			hold_N: if(busy_sig) next_state = hold_N;
					else next_state = cycle_N;
			cycle_N: if(next_frequency) next_state = write_C_high;
					else next_state = cycle_N;
			
			write_C_high: next_state = wait_busy_C_high;
			wait_busy_C_high: if(busy_sig) next_state = hold_C_high;
				else next_state = wait_busy_C_high;
			hold_C_high: if(busy_sig) next_state = hold_C_high;
				else next_state = cycle_C_high;
			cycle_C_high: next_state = write_C_low;
			
			write_C_low: next_state = wait_busy_C_low;
			wait_busy_C_low: if(busy_sig) next_state = hold_C_low;
				else next_state = wait_busy_C_low;
			hold_C_low: if(busy_sig) next_state = hold_C_low;
				else next_state = cycle_C_low;
			cycle_C_low: next_state = write_M;
			
			write_M: next_state = wait_busy_M;
			wait_busy_M: if(busy_sig) next_state = hold_M;
					else next_state = wait_busy_M;
			hold_M: if(busy_sig) next_state = hold_M;
					else next_state = cycle_M;
			cycle_M: next_state = write_config;
			write_config: next_state = wait_busy_config;
			wait_busy_config: if(busy_sig) next_state = hold_config;
					else next_state = wait_busy_config;
			hold_config: if(busy_sig) next_state = hold_config;
					else next_state = cycle_config;
			cycle_config: next_state = hold_frequency;
			hold_frequency: if(next_frequency) next_state = wait_button;
				else next_state = hold_frequency;
			wait_button: if(~next_frequency) next_state = write_M;
				else next_state = wait_button;
			default: next_state = hold_frequency;
		endcase	
	end
	
	reg [8:0] M;
	localparam N_value = 9'd25; //divisor
	localparam C_high = 9'd1;   //post scale divisor (C_high + C_low)
	localparam C_low = 9'd1;
	
	always @ (posedge CLK_50) begin
		read_param_sig = 1'b0;
		M = M;
		frequency = frequency;
		write_param_sig = 1'b0;
		reconfig_sig = 1'b0;
		data_in_sig = M;
		freq_ready = 1'b0;
		counter_type = M_param;
		counter_param_sig = 3'b111;
		case (state)
			begin_sweep: begin
				M = 9'd100;
				frequency = 9'd100;
				counter_type = N_param;
				data_in_sig = N_value;
			end
			
			write_N: begin
				counter_type = N_param;
				data_in_sig = N_value;
				write_param_sig = 1'b1;
			end
			hold_N: begin
				counter_type = N_param;
				data_in_sig = N_value;
			end
			wait_busy_N: begin
				counter_type = N_param;
				data_in_sig = N_value;
			end
			
			cycle_N: begin
				counter_type = C_param;
				counter_param_sig = 3'b000; //c high
				data_in_sig = C_high;
			end
			
			write_C_high: begin
				counter_type = C_param;
				counter_param_sig = 3'b000; //c high
				data_in_sig = C_high;
				write_param_sig = 1'b1;
			end
			hold_C_high: begin
				counter_type = C_param;
				counter_param_sig = 3'b000; //c high
				data_in_sig = C_high;
			end
			wait_busy_C_high: begin
				counter_type = C_param;
				counter_param_sig = 3'b000; //c high
				data_in_sig = C_high;
			end
			cycle_C_high: begin
				counter_type = C_param;
				counter_param_sig = 3'b001; //c low
				data_in_sig = C_low;
			end
			
			write_C_low: begin
				counter_type = C_param;
				counter_param_sig = 3'b001; //c low
				data_in_sig = C_high;
				write_param_sig = 1'b1;
			end
			hold_C_low: begin
				counter_type = C_param;
				counter_param_sig = 3'b001; //c low
				data_in_sig = C_high;
			end
			wait_busy_C_low: begin
				counter_type = C_param;
				counter_param_sig = 3'b001; //c low
				data_in_sig = C_high;
			end
			cycle_C_low: begin
			
			end
			
			write_M: begin
				write_param_sig = 1'b1;
			end
			hold_M: begin
			end
			wait_busy_M: begin
			end
			cycle_M: begin
				M = M + add;
			end
			write_config: begin
				reconfig_sig = 1'b1;
			end
			hold_config: begin
			
			end
			cycle_config: begin
				frequency = M - add;
			end
			hold_frequency: begin
				if(next_frequency != 1'b1 && locked_sig == 1'b1 && busy_sig != 1'b1) freq_ready = 1'b1;
			end
			wait_button: begin
				if(next_frequency != 1'b1 && locked_sig == 1'b1 && busy_sig != 1'b1) freq_ready = 1'b1;
			end
			default: begin
			
			end
		endcase
	
	
	end
	

endmodule 