module uart_tx (
	input clk,
	input reset,
	input baud_tick,
	input tx_start,
	input [7:0] tx_datain,
	output reg tx,
	output reg tx_done );
	
	localparam IDLE = 2'b00;
	localparam START = 2'b01;
	localparam DATA = 2'b10;
	localparam STOP = 2'b11;

	reg [1:0] current_state;
	reg [1:0] next_state;
	reg [2:0] bit_count;
	reg [7:0] shift_reg;
	
	always @(posedge clk) begin
		if (reset) begin
			current_state <= IDLE;
			tx <= 1'b1;
			bit_count <= 3'd0;
			shift_reg <= 8'd0;
		end
		else begin
			current_state <= next_state;
			case (current_state)
				IDLE: begin
					if (tx_start == 1'b1)
						shift_reg <= tx_datain;
				end
				DATA: begin
					if (baud_tick) begin
						shift_reg <= shift_reg >> 1;
						if (bit_count == 3'd7)
							bit_count <= 3'd0;
						else
							bit_count <= bit_count + 1;
					end
				end
				default: ;
			endcase
		end
	end
		
	always @(*) begin
		case (current_state)
			IDLE: next_state = tx_start ? START : IDLE;
			START: next_state = baud_tick ? DATA : START;
			DATA: next_state = (baud_tick && (bit_count == 3'd7)) ? STOP : DATA;
			STOP: next_state = baud_tick ? IDLE : STOP;
			default: next_state = IDLE;
		endcase
	end
	
	always @(*) begin
		tx_done = 1'b0;
		case (current_state)
			IDLE: tx = 1'b1;
			START: tx = 1'b0;
			DATA: tx = shift_reg[0];
			STOP: begin 
				if (baud_tick) begin
					tx_done = 1'b1;
				end
				tx = 1'b1;
			end
			default: tx = 1'b1;
		endcase
	end
endmodule