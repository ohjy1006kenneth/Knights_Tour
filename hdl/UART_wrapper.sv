module UART_wrapper(clr_cmd_rdy, cmd_rdy, cmd, trmt, resp, tx_done, clk, rst_n, RX, TX);
	
	input logic clr_cmd_rdy, clk, rst_n, RX, trmt;
	input logic [7:0] resp;
	output [15:0] cmd;
	output logic tx_done, TX;
	output logic cmd_rdy;
	
	// internal output signals for UART Wrapper State Machine
	logic clr_rdy, store, rx_rdy;
	logic [7:0] rx_data;
	logic set_cmd_rdy;
	
	// internal high byte storing flop
	logic [7:0] FF_sig;
	
	// Instantiate UART module
	// Handles transmission (TX) and reception (RX) of data
	// Controls transmission via `trmt` and receives data through `rx_data`
	UART iUart(.clk(clk), .
				rst_n(rst_n), 
				.TX(TX), 
				.RX(RX), 
				.trmt(trmt), 
				.tx_data(resp),
				.rx_data(rx_data),
				.tx_done(tx_done), 
				.clr_rx_rdy(clr_rdy),
				.rx_rdy(rx_rdy));
	
    // High byte storage: Holds the most significant byte (FF_sig)
	// when receiving a command, allowing `cmd` to be a 16-bit command
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			FF_sig <= 16'h0000;
		else if (store)
			FF_sig <= rx_data;
	
	reg[15:0] FF_sig2;

	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			FF_sig2 <= 8'h00;
		end else
		if(set_cmd_rdy) begin
			FF_sig2 <= {FF_sig, rx_data};
		end
	end

	// cmd output: Concatenates FF_sig (high byte) with the most recent rx_data (low byte)
	// This forms a 16-bit command as the `cmd` output
	//assign cmd = {FF_sig, rx_data};
	assign cmd = FF_sig2;
	
	// statemachine states
    // IDLE: Wait for the first byte (high byte) of the command
	// HIGHBYTE: Wait for the second byte (low byte) to complete the command
	typedef enum reg {IDLE, HIGHBYTE} state_t;
	
	state_t state, nxt_state;
	
	// infer state flop
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
			
	always_comb begin
		// default ouputs
		store = 0;
		clr_rdy = 0;	// signal to UART RX
		set_cmd_rdy = 0;
		nxt_state = state;	// default state, meaning stay in the
							// same state until signal changes
		
		case (state)
			IDLE: if (rx_rdy) begin
					//cmd_rdy = 0;
					store = 1;
					clr_rdy = 1;
					nxt_state = HIGHBYTE;
				  end
			
			HIGHBYTE: if (rx_rdy) begin
						clr_rdy = 1;
						set_cmd_rdy = 1;
						nxt_state = IDLE;
					  end
			
			// default case
			default: nxt_state = IDLE;
			
		endcase
	end
	
	// Command Ready Flip-Flop: Controls `cmd_rdy` signal to indicate when a full command is available
	// Clears `cmd_rdy` when `clr_cmd_rdy` is asserted by external logic, otherwise sets it when `set_cmd_rdy` is asserted
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			cmd_rdy <= 1'b0;
		else if (clr_cmd_rdy)
			cmd_rdy <= 1'b0;
		else if (set_cmd_rdy)
			cmd_rdy <= 1'b1;
	
endmodule