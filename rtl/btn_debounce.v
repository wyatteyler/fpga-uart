module btn_debounce (
	input clk, 
	input reset,
	input slow_tick,
	input btn_raw,
	output btn_clean );
	
	reg [3:0] shift_reg;
	
	always @(posedge clk) begin
		if (reset)
			shift_reg <= 4'd0;
		else if (slow_tick)
			shift_reg <= {shift_reg[2:0], btn_raw};
	end
	
	assign btn_clean = &shift_reg;

endmodule
			
		