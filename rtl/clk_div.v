module clk_div (
	input clk,
	input reset,
	output slow_tick );
	
	reg [21:0] count;
	
	always @(posedge clk) begin
		if (reset || count == 22'd2118643) 
			count <= 22'd0;
		else 
			count <= count + 22'd1;			
		end
		
	assign slow_tick = (count == 22'd2118643);
	
endmodule
			
	