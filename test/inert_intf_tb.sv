`default_nettype none
module inert_intf_tb();

logic clk, rst_n;
logic strt_cal, cal_done;
logic signed [11:0] heading;
logic rdy;
logic lftIR, rightIR;
logic SS_n, SCLK, MOSI, MISO;
logic INT;
logic moving;

// Instantiate the inert_intf
inert_intf iDUT_inert (
    .clk(clk),
    .rst_n(rst_n),
    .strt_cal(strt_cal),
    .cal_done(cal_done),
    .heading(heading),
    .rdy(rdy),
    .lftIR(lftIR),
    .rghtIR(rightIR),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .INT(INT),
    .moving(moving)
);

// Instantiate the SPI_iNEMO2
SPI_iNEMO2 iDUT_iNEMO2 (
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .INT(INT)
);

initial begin
    clk = 0;
    rst_n = 0;
    iDUT_iNEMO2.POR_n = 1'b0;

    strt_cal = 0;
    moving = 1;
    lftIR = 0;
    rightIR = 0;

    @(negedge clk);
    rst_n = 1;
    iDUT_iNEMO2.POR_n = 1'b1;
    @(negedge clk);

    fork
    begin 
        @(posedge iDUT_iNEMO2.NEMO_setup);
        disable timeout1;
    end
    begin: timeout1
        repeat (1000000) @(posedge clk);
        $display("Time out");
        $stop;
    end
    join

    strt_cal = 1;
    @(negedge clk);
    @(negedge clk);
    strt_cal = 0;

    fork
    begin 
        @(posedge cal_done);
        disable timeout2;
    end
    begin: timeout2
        repeat (1000000) @(posedge clk);
        $display("Time out");
        $stop;
    end
    join

    $display("Yahoo! All test passed!");
    repeat (8000000) @(posedge clk);
    $stop;

end

// Clock generation
always
    #5 clk = ~clk;

endmodule
`default_nettype wire