module uart_tx (
	input clk,
	input reset,
	input baud_tick,			// baud_tick is functionally an enable, it is derived from the desired baud rate and system clock within clk_div.v
	input tx_start,				// tx_start is the "go ahead" flag for the start phase and the system to send a byte, in this case it's a button press
	input [7:0] tx_datain,		// data to be transmitted
	output reg tx,				// data line where the data will be sent one by one
	output reg tx_done );		// tx_done is the flag telling the system a full transmission has been completed

	/* these localparams assign binary values to named constants, for use in case statements
		there is no external signal driving these, internal labels only */
	
	localparam IDLE = 2'b00;
	localparam START = 2'b01;
	localparam DATA = 2'b10;
	localparam STOP = 2'b11;

	reg [1:0] current_state;	// the current state the system is in
	reg [1:0] next_state;		// next state of the system
	reg [2:0] bit_count;		// tracks which of the current bits is being transmitted
	reg [7:0] shift_reg;		// this register holds the byte being transmitted
	
	always @(posedge clk) begin
		if (reset) begin				// when reset is triggered all values are reset and the system is put back into IDLE state
			current_state <= IDLE;
			tx <= 1'b1;
			bit_count <= 3'd0;
			shift_reg <= 8'd0;
		end
		else begin
			current_state <= next_state;			// when not reset, the current state is set to the next state in line determined by the second always block
			case (current_state)
				IDLE: begin							// when the system is IDLE, if tx_start is triggered, the shift register loads the datain value
					if (tx_start)
						shift_reg <= tx_datain;
				end
				DATA: begin									// when the system is in DATA state, the shift register shifts right one bit per baud period, outputting the LSB on the tx line
					if (baud_tick) begin
						shift_reg <= shift_reg >> 1;
						if (bit_count == 3'd7)				// all 8 bits sent (0-7), reset the bit_count
							bit_count <= 3'd0;
						else
							bit_count <= bit_count + 1; 	// if not, keep incrementing the bit_count
					end
				end
				default: ;
			endcase
		end
	end

	/* these next two always blocks are determining the state for the system and the output of the tx line */
	
	always @(*) begin																// this combinational always block is determining the next state for the current state to be set to based upon certain conditions
		case (current_state)
			IDLE: next_state = tx_start ? START : IDLE;								// if the state is IDLE the next state is determined by the start tick. If there is no start tick it stays in IDLE state
			START: next_state = baud_tick ? DATA : START;							// when in the START state, a single baud period sends to the DATA state, START is purely timing, meant to hold the tx line low for one baud period
			DATA: next_state = (baud_tick && (bit_count == 3'd7)) ? STOP : DATA;	// the DATA state only stops if the bit_counter has gone through 0-7 AND a baud period has elapsed
			STOP: next_state = baud_tick ? IDLE : STOP;								// after a baud_tick, the next state after STOP is IDLE
			default: next_state = IDLE;												// the default state should always be IDLE
		endcase
	end
	
	always @(*) begin						// this combinational always block determines what is be outputted on the tx line
		tx_done = 1'b0;						// tx_done default is always 0, overriden in STOP when baud_tick occurs
		case (current_state)
			IDLE: tx = 1'b1;				// during IDLE tx line is held high when START begins, the reciever detects the falling edge
			START: tx = 1'b0;				// tx is pulled low for one baud period, signals reciever that byte is incoming
			DATA: tx = shift_reg[0];		// during DATA, tx outputs the current LSB on shift_reg, this changes each baud period
			STOP: begin						// during STOP after a baud period tx_done is pulled high signaling a transmission is complete
				if (baud_tick) begin
					tx_done = 1'b1;
				end
				tx = 1'b1;					// tx is returned high ready for next transmission
			end
			default: tx = 1'b1;				// default tx is high matching IDLE convention
		endcase
	end
endmodule
