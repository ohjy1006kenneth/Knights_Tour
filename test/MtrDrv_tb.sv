`default_nettype none
module MtrDrv_tb();

logic clk;
logic rst_n;
logic[10:0] lft_spd;
logic[10:0] rght_spd;

logic lft_PWM1;
logic lft_PWM2;
logic rght_PWM1;
logic rght_PWM2;

MtrDrv iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .lft_spd(lft_spd),
    .rght_spd(rght_spd),
    
    .lftPWM1(lft_PWM1), 
    .lftPWM2(lft_PWM2),
    .rghtPWM1(rght_PWM1),
    .rghtPWM2(rght_PWM2)
);

initial begin
    clk = 0;
    rst_n = '0;
    lft_spd = 0;
    rght_spd = 0;
    @(posedge clk);

    rst_n = 1'b1;
    @(posedge clk);

    // Test 0% on each motor
    if (lft_PWM1 != 0 || rght_PWM1 != 0) begin
        $display("Test failed: 0 percent on each motor.");
        $stop;
    end

    // Test 50% on each motor
    lft_spd = 11'h3FFF;
    rght_spd = 11'h3FFF;

    @(posedge clk);
    if (lft_PWM1 != 1 || rght_PWM1 != 1) begin
        $display("Test failed: 50 percent on each motor.");
        $stop;
    end

    // Test reverse on each motor
    lft_spd = 11'h7FFF;
    rght_spd = 11'h7FFF;

    @(posedge clk);
    if (lft_PWM2 != 0 || rght_PWM2 != 0) begin
        $display("Test failed: reversing motors.");
        $stop;
    end

    $display("All tests passed.");
    $stop;
    
end

always #5 clk <= ~clk;

endmodule
`default_nettype wire