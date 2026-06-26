module uart_rx ( 					/////DRAFT/////
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

	wire sample_point;
	wire bit_done;
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
 	assign bit_done = (oversample_count == 4'd15) && baud_tick16;
  	assign sample_point = (oversample_count == 4'd8) && baud_tick16;
	
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
			if (start_detect && current_state == IDLE) begin
				oversample_count <= 4'd0;
				bit_count <= 3'd0;
				shift_reg <= 8'd0;
			end
			if (baud_tick16 && current_state != IDLE)
				oversample_count <= oversample_count + 1;
          case (current_state)
            DATA: begin
				if (sample_point)
					shift_reg <= {shift_reg[6:0], rx_sync};
				if (bit_done)
					bit_count <= bit_count + 1;
            end
            STOP: begin
				if (sample_point && rx_sync)
					rx_dataout <= shift_reg;
            end
            default: ;
          endcase
        end
    end

	always @(*) begin
		case (current_state)
			IDLE: next_state = (start_detect) ? START : IDLE;
         	START: next_state = (sample_point && (rx_sync == 1'b0)) ? DATA : START;
         	DATA: next_state = (sample_point && (bit_count == 3'd7)) ? STOP : DATA;
         	STOP: next_state = (sample_point && rx_sync) ? IDLE : STOP;
			default: next_state = IDLE;
		endcase
	end
  
	always @(*) begin
		rx_datavalid = 1'b0;
		case (current_state)
		STOP: 
			if (sample_point && rx_sync)
			rx_datavalid = 1'b1;
		default:
			rx_datavalid = 1'b0;
		endcase
	end
endmodule
