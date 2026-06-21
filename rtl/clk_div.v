module clk_div #(
	parameter CLK_FREQ = 125000000,
	parameter OUT_FREQ = 59
) (
	input clk,
	input reset,
	output slow_tick );

	localparam DIVIDER = CLK_FREQ / OUT_FREQ;
	localparam WIDTH = $clog2(DIVIDER);
	
	reg [WIDTH-1:0] count;
	
	always @(posedge clk) begin
		if (reset || count == DIVIDER - 1) 
			count <= 0;
		else 
			count <= count + 1;			
		end
		
	assign slow_tick = (count == DIVIDER - 1);
	
endmodule
			
	
