module uart_rx (
	input clk,
	input reset,
	input rx,
	input baud_tick16,
	output reg [7:0] rx_dataout,
	output reg rx_datavalid );
	
	localparam IDLE = 2'b00;
	localparam START = 2'b01;
	localparam DATA = 2'b10;
	localparam STOP = 2'b11;
	
	wire start_detect;
	reg rx_flop;
	reg rx_sync;
	reg rx_prev;
	reg [1:0] current_state;
	reg [1:0] next_state;
	reg [2:0] bit_count;
	reg [3:0] oversample_count;
	reg [7:0] shift_reg;
	
	assign start_detect = ~rx_sync && rx_prev;
	
	always @(posedge clk) begin
		if (reset) begin
			rx_flop <= 1'b1;
			rx_sync <= 1'b1;
		end
		else begin
			rx_flop <= rx;
			rx_sync <= rx_flop;
		end
	end
	
	always @(posedge clk) begin
		if (reset) begin
			current_state <= IDLE;
			bit_count <= 3'd0;
			oversample_count <= 4'd0;
			shift_reg <= 8'd0;
			rx_prev <= 1'b1;
		end
		else begin
			rx_prev <= rx_sync;
			current_state <= next_state;
		end
		if (start_detect && (current_state == IDLE)) begin		// possible redundancy 
			bit_count <= 3'd0;
			oversample_count <= 4'd0;
			shift_reg <= 8'd0;
			rx_prev <= 1'b1;
		end
		case (current_state)
			START: begin
				if (baud_tick16) begin
					if (oversample_count == 4'd15) begin
						oversample_count <= 4'b0;
					end
					else begin
					oversample_count <= oversample_count + 1;
					end
				end
			end
			DATA: begin
				if ((oversample_count == 4'd8) && baud_tick16) begin
					shift_reg <= {shift_reg[6:0], rx_sync};
				end
				if (baud_tick16) begin
					if (oversample_count == 4'd15) begin
						bit_count <= bit_count + 1;
						oversample_count <= 4'b0;
					end
					else begin
					oversample_count <= oversample_count + 1;
					end
				end
			end
			STOP: begin
				if (baud_tick16) begin			// wrong
					oversample_count <= 4'd0;
				else
					oversample_count <= oversample_count + 1;
				end
				if ((oversample_count == 4'd8) && rx_sync)
					rx_dataout <= shift_reg;
			end
			default: ;
		endcase
	end
	
	always @(*) begin
		case (current_state)
			IDLE: next_state = (start_detect) ? START : IDLE;
			START: next_state = ((oversample_count == 4'd8) && (rx_sync == 1'b0)) ? DATA : START;
			DATA: next_state = ((oversample_count == 4'd8) && (bit_count == 3'd7)) ? STOP : DATA;
			STOP: next_state = ((oversample_count == 4'd8) && rx_sync) ? IDLE : STOP;
			default: next_state = IDLE;
		endcase
	end
	
	always @(*) begin
		rx_datavalid = 1'b0;
		case (current_state)
			STOP: begin
				if (baud_tick16) begin
					rx_datavalid = 1'b1;
				end
			end
			default: rx_datavalid = 1'b0;
		endcase
	end
endmodule