`default_nettype none
module PWM11(
    input wire clk,
    input wire rst_n,

    input wire[10:0] duty,

    output reg PWM_sig,
    output wire PWM_sig_n
);

assign PWM_sig_n = ~PWM_sig;

reg[10:0] cnt;

//counter logic

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        cnt <= '0;
    end else begin
        cnt <= cnt + 1;
    end
end
// PWM generation logic: compare the counter with the duty cycle
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        PWM_sig <= 1'b0;
    end else begin
        PWM_sig <= (cnt < duty); // Set PWM high if counter is less than duty cycle
    end
end


endmodule;
`default_nettype wire