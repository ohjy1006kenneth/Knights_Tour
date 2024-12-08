module UART_rx(clk, rst_n, RX, clr_rdy, rx_data, rdy);

	input clk, rst_n, clr_rdy, RX;
	output rdy;
	output logic [7:0] rx_data;
	
	logic start, shift, receiving, set_rdy, done, rdy;
	logic [11:0] baud_cnt, baud_rate;
	logic [3:0] bit_cnt;
	logic [8:0] rx_shft_reg;
	
	// Flops to ensure metastability in the RX input signal
	logic sig_FF1, sig_FF2;
	
	// Double flip-flop to ensure metastability
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
			sig_FF1 <= 1;
			sig_FF2 <= 1;
		end
		else begin
			sig_FF1 <= RX;
			sig_FF2 <= sig_FF1;
		end
	
    // Shift register to store the received data 
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			rx_shft_reg <= 9'h1FF;
		else if (shift)
			rx_shft_reg <= {sig_FF2, rx_shft_reg[8:1]};
	
	assign rx_data = rx_shft_reg[7:0];
	
	assign baud_rate = start ? 12'd1302 : 12'd2604;
	
    // Baud rate counter to control the timing of bit sampling
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			baud_cnt <= 12'h000;
		else if (start | shift)
			baud_cnt <= baud_rate;
		else if (receiving)
			baud_cnt <= baud_cnt - 1;
			
	assign shift = (baud_cnt == 12'h000) ? 1'b1 : 1'b0;
	
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			bit_cnt <= 4'h0;
		else if (start)
			bit_cnt <= 4'h0;
		else if (shift)
			bit_cnt <= bit_cnt + 1;
	
    //when bit_cnt is 10 we are finished
	assign done = (bit_cnt == 4'b1010) ? 1'b1 : 1'b0;
	
	typedef enum reg {IDLE, RECEIVE} state_t;
	
	state_t state, nxt_state;
	
    //transition state logic
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
			
	always_comb begin
		start = 0;
		receiving = 0;
		set_rdy = 0;
		nxt_state = state;	
		
		case (state)
			IDLE : 
				
				if (~RX) begin
					start = 1;
					nxt_state = RECEIVE;	
				end
			
			RECEIVE : begin
				receiving = 1;
				if (done) begin
					receiving = 0;
					set_rdy = 1;	
					nxt_state = IDLE;	
				end
			end
					
			default : 
				nxt_state = IDLE;
			
		endcase
	end
	// Ready signal logic to indicate when a byte has been received and is ready to be read
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			rdy <= 1'b0;
		else if (start | clr_rdy)
			rdy <= 1'b0;
		else if (set_rdy)
			rdy <= 1'b1;

endmodule