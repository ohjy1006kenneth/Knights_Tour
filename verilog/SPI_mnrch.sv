module SPI_mnrch(clk, rst_n, SS_n, SCLK, MOSI, MISO, snd, cmd, done, resp);

input clk, rst_n, snd, MISO;
input [15:0] cmd;
output [15:0] resp;
output logic done, SS_n, SCLK, MOSI;

logic shft, init, ld_SCLK, done16, full, set_done;
logic [15:0] shft_reg;
logic [4:0] SCLK_div, bit_cntr, bit_cntr_loader;

// Shift Register: Holds data to be sent and also receives data on MISO line
// Initialized with command, then shifted out and filled with MISO bits during transaction
always_ff @(posedge clk)
	if (init)
		shft_reg <= cmd;
	else if (shft)
		shft_reg <= {shft_reg[14:0], MISO};

// MOSI: Outputs the most significant bit of the shift register	
assign MOSI = shft_reg[15];
assign resp = shft_reg;

// SCLK Divider: Generates the SPI clock signal from the main clock by dividing down
// The frequency is controlled by the SCLK_div register
always_ff @(posedge clk)
	if (ld_SCLK)
		SCLK_div <= 5'b10111;
	else
		SCLK_div <= SCLK_div + 1;
		
assign SCLK = SCLK_div[4];
		
assign shft = (SCLK_div == 5'b10001) ? 1'b1 : 1'b0;

assign full = (SCLK_div == 5'b11111) ? 1'b1 : 1'b0;

// topmost mux for bit counter
assign bit_cntr_loader = shft ? (bit_cntr + 1) : bit_cntr;

always_ff @(posedge clk)
	if (init)
		bit_cntr <= 5'b00000;
	else
		bit_cntr <= bit_cntr_loader;

// Done16 Flag: Indicates when 16 bits have been sent/received, marking the end of the transaction		
assign done16 = (bit_cntr == 5'b10000);

// State Machine for SPI Transaction Control
// Three states:
// - IDLE: Wait for `snd` signal to start transaction
// - TRANSACT: Shift data out/in for 16-bit transaction
// - BACKPORCH: Complete transaction and reset signals before returning to IDLE
typedef enum reg [1:0] {IDLE, TRANSACT, BACKPORCH} state_t;

state_t state, nxt_state;

// infer state flops
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
		
always_comb begin
	// default outputs
	init = 0;
	ld_SCLK = 0;
	set_done = 0;
	// default state
	nxt_state = state;
	
	case (state)
		IDLE : //begin
			//ld_SCLK = 1;
				if (snd) begin
					init = 1;
					nxt_state = TRANSACT;
				end else ld_SCLK = 1;
			//end
			
		TRANSACT : if (done16)
				nxt_state = BACKPORCH;
				
		BACKPORCH : if (full) begin
				set_done = 1;
				ld_SCLK = 1;
				nxt_state = IDLE;
			end
			
		default : nxt_state = IDLE;
	endcase
end 

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		done <= 1'b0;
	else if (init)
		done <= 1'b0;
	else if (set_done)
		done <= 1'b1;

// SS_n (Slave Select): Asserted low during transaction, deasserted high after transaction completion
		
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		SS_n <= 1'b1;	// preset
	else if (init)
		SS_n <= 1'b0;
	else if (set_done)
		SS_n <= 1'b1;

endmodule
