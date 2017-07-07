`timescale  1 ns / 10 ps

module test (
	input [1:0] KEY,
	input CLOCK_50,
	input [3:0] SW,
	output SMA_CLKOUT,
	output [17:0] LEDR,
	output [7:0] LEDG
	);

	wire reset;
	wire next_frequency;
	wire [8:0] frequency;
	wire reconfig_CLK;
	wire freq_ready;
	
	
	
	
	
	
	
	assign LEDG[0] = freq_ready;
	assign LEDR[8:0] = frequency;
	assign next_frequency = !KEY[0];
	assign reset = !KEY[1];
	wire output_clock;
	assign SMA_CLKOUT = output_clock;
	
		
	pll pll1(
		.CLK_50(CLOCK_50),
		.reset(reset),
		.next_frequency(next_frequency),
		.frequency(frequency),
		.reconfig_CLK(output_clock),
		.freq_ready(freq_ready),
		.add(SW),
		.curr_state(LEDR[17:13])
	);

	reg [32:0] counter;
	
	reg test_led;
	assign LEDR[12] = test_led;
	
	assign LEDG [7:1] = counter [26:20];
	
	always @ (posedge output_clock) begin
		if(!KEY[1]) test_led = 1'b1;
		else if(counter > 30'd995000000) test_led = 1'b1;
		else test_led = 1'b0;
		
		if(!KEY[1]) counter = 30'd0;
		else if(counter == 30'd1000000000) counter = 30'd0;
		else counter = counter + 30'd1;
		
	end

	



endmodule 