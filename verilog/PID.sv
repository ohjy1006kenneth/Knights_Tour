`default_nettype none
module PID (clk, rst_n, moving, err_vld, error, frwrd, lft_spd, rght_spd);
input logic clk, rst_n; // Clock and reset
input logic moving; // Clear I_term if not moving
input logic err_vld; // Compute I & D again when vld
input logic [11:0] error; // Signed error into PID
input logic [9:0] frwrd; // Summed with PID to form lft_spd, right_spd

output logic [10:0] lft_spd;
output logic [10:0] rght_spd; // These form the input to mtr_drv

logic [9:0] err_sat; // Saturated error
localparam P_COEFF = 6'h10;
localparam signed D_COEFF = 5'h07;
logic signed[9:0] ff1, ff2, ff3;

//////////////
//  P_term  //
//////////////
logic signed [13:0] P_term;

assign err_sat = (error[11]) ? ((error < 12'he00) ? 10'h200 : error[9:0] ): ((error > 11'h1FF) ? 10'h1FF : error[9:0]);
assign P_term = ff1 * P_COEFF;

//////////////
//  I_term  //
//////////////
logic signed [8:0] I_term; 
logic [14:0] integrator; // The integrator of the PID controller
logic [14:0] nxt_integrator; // The next value of the integrator
logic [14:0] sum; // The sum of the integrator and the error
logic ov; // Overflow flag

assign ov = (ff1[9] ^ integrator[14]) ? 1'b0 :(integrator[14] ^ sum[14]);
assign sum = integrator + {{5{ff1[9]}}, ff1[9:0]};

assign nxt_integrator = moving ? ((~ov & err_vld) ? sum : integrator) : 15'h0000;

// Accumulator register
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        integrator <= 15'h0000;
    else
        integrator <= nxt_integrator;
end

assign I_term = integrator[14:6];

//////////////
//  D_term  //
//////////////
logic signed[9:0] prev_err;
logic signed[9:0] D_diff;
logic signed[7:0] D_diff_sat;
logic [12:0] D_term;

// Flip-flop 1
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        ff1 <= 10'b0;
    else if (err_vld)
        ff1 <= err_sat;
end

// Flip-flop 2
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        ff2 <= 10'b0;
    else if (err_vld)
        ff2 <= ff1;  
end

// Flip-flop 2b
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        ff3 <= 10'b0;
    else if (err_vld)
        ff3 <= ff2;
end

// Flip-flop 3
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        prev_err <= 10'b0;
    else if (err_vld)
        prev_err <= ff3;
end

assign D_diff = ff1 - prev_err;

// Saturate D_diff down to 8 bits
assign D_diff_sat = (D_diff[9]) ? (D_diff < 10'b1110000000 ? 8'h80 : D_diff[7:0]) : (D_diff > 10'h7F ? 8'h7F : D_diff[7:0]);

// Calculate the D term by multiplying the D_diff with the D_COEFF
//assign D_term = D_diff_sat * D_COEFF;
assign D_term = D_diff_sat << 3 - D_diff_sat;


///////////////
//    PID    //
///////////////
logic signed [13:0] PID;
logic signed [13:0] P_term_se; // Sign extend P_term
logic signed [13:0] D_term_se; // Sign extend D_term
logic signed [13:0] I_term_se; // Sign extend D_term
logic [10:0] frwrd_ze; // Zero extend frwrd
logic [10:0] frwrd_ze_ff; // Zero extend frwrd flop

logic [10:0] lft_spd_add1; // PID + frwrd
logic [10:0] rght_spd_add1; // frwrd - PID
logic [10:0] lft_spd_mov; // lft_spd before saturation
logic [10:0] rght_spd_mov; // rght_spd before saturation

assign P_term_se = { P_term[13], P_term[13:1] };    // Divide by two (shift right) and sign extend
assign D_term_se = { D_term[12], D_term[12:0] }; 
assign I_term_se = { {5{I_term[8]}}, I_term[8:0] };

// Flop the PID to meet timing
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        PID <= 14'h0000;
    else
        PID <= P_term_se + D_term_se + I_term_se;
end

// Double flop the zero extended frwrd to meet timing
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        frwrd_ze_ff <= 11'h000;
    else
        frwrd_ze_ff <= { 1'b0, frwrd[9:0] };
end

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        frwrd_ze <= 11'h000;
    else
        frwrd_ze <= frwrd_ze_ff;
end

// assign PID = P_term_se + D_term_se + I_term_se;

assign lft_spd_add1 = frwrd_ze + PID[13:3];
assign rght_spd_add1 = frwrd_ze - PID[13:3];

// Pass value only if the Knight is moving
assign lft_spd_mov = ( moving ? lft_spd_add1 : 11'h000 );
assign rght_spd_mov = ( moving ? rght_spd_add1 : 11'h000 );

assign lft_spd = (!(PID[13])) ? (lft_spd_mov[10] ? 11'h3FF : lft_spd_mov) : lft_spd_mov;
assign rght_spd = (PID[13]) ? (rght_spd_mov[10] ? 11'h3FF : rght_spd_mov) : rght_spd_mov;

endmodule
`default_nettype wire
