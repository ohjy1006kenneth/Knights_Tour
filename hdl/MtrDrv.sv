`default_nettype none
module MtrDrv(
    input wire clk,
    input wire rst_n,

    input wire[10:0] lft_spd,
    input wire[10:0] rght_spd,

    output wire lftPWM1,
    output wire lftPWM2,
    output wire rghtPWM1,
    output wire rghtPWM2
);
//left
PWM11 ldrive(
    .clk(clk),
    .rst_n(rst_n),
    .duty(lft_spd + 11'h400),
    .PWM_sig(lftPWM1),
    .PWM_sig_n(lftPWM2)
);
//right
PWM11 rdrive(
    .clk(clk),
    .rst_n(rst_n),
    .duty(rght_spd + 11'h400),
    .PWM_sig(rghtPWM1),
    .PWM_sig_n(rghtPWM2)
);

endmodule

`default_nettype wire