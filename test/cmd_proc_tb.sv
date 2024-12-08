`default_nettype none
module cmd_proc_tb();


logic clk, rst_n;
logic snd_cmd;
logic [15:0] cmd;
logic TX_RX, RX_TX;
logic [7:0] resp;
logic cmd_snt, resp_rdy;

logic clr_cmd_rdy, cmd_rdy, send_resp, tx_done;
logic [15:0] cmd_proc_cmd;

logic strt_cal, cal_done, heading_rdy;
logic cntrIR, lftIR, rghtIR;
logic signed [11:0] heading;
logic signed [11:0] error;
logic [9:0] frwrd;
logic moving, tour_go, fanfare_go;

logic SS_n, SCLK, MOSI, MISO, INT;


// Instantiate RemoteComm
RemoteComm RemoteComnm(
    .clk(clk),
    .rst_n(rst_n),
    .snd_cmd(snd_cmd),
    .cmd(cmd),
    .RX(RX_TX),
    .TX(TX_RX),
    .resp(resp),
    .cmd_snt(cmd_snt),
    .resp_rdy(resp_rdy)
);

// Instantiate UART_wrapper
UART_wrapper UART_wrapper (
    .clr_cmd_rdy(clr_cmd_rdy),
    .cmd_rdy(cmd_rdy),
    .cmd(cmd_proc_cmd),
    .trmt(send_resp),
    .resp(8'hA5),
    .tx_done(tx_done),
    .clk(clk),
    .rst_n(rst_n),
    .RX(TX_RX),
    .TX(RX_TX)
);

// Instantiate inert_intf
inert_intf inert_intf (
    .clk(clk),
    .rst_n(rst_n),
    .strt_cal(strt_cal),
    .cal_done(cal_done),
    .heading(heading),
    .rdy(heading_rdy),
    .lftIR(lftIR),
    .rghtIR(rghtIR),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .INT(INT),
    .moving(moving)
);


// Instantiate cmd_proc
cmd_proc iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .cmd(cmd_proc_cmd),
    .cmd_rdy(cmd_rdy),
    .clr_cmd_rdy(clr_cmd_rdy),
    .send_resp(send_resp),
    .strt_cal(strt_cal),
    .cal_done(cal_done),
    .heading(heading),
    .heading_rdy(heading_rdy),
    .lftIR(lftIR),
    .cntrIR(cntrIR),
    .rghtIR(rghtIR),
    .error(error),
    .frwrd(frwrd),
    .moving(moving),
    .tour_go(tour_go),
    .fanfare_go(fanfare_go)
);

SPI_iNEMO3 SPI_iNEMO3 (.MOSI(MOSI), .INT(INT), .SS_n(SS_n), .SCLK(SCLK), .MISO(MISO));

initial begin
    clk = 0;
    rst_n = 0;
    snd_cmd = 0;
    cmd = 0;
    lftIR = 0;
    rghtIR = 0;
    cntrIR = 0;

    @(negedge clk);
    @(negedge clk);
    rst_n = 1;

    cmd = 16'h2000;
    snd_cmd = 1;
    @(negedge clk);

    snd_cmd = 0;
    @(negedge clk);

    // Test 1: Send Calibrate command and wait for cal_done and resp_rdy
    fork
        begin : timeout0
            repeat (1000000) @(posedge clk);
            $display("Test 1 Failed: Timeout 0");
            $stop();
        end
        begin
            @(posedge cal_done);
            disable timeout0;
        end
    join

    fork
        begin : timeout1
            repeat (1000000) @(posedge clk);
            $display("Test 1 Failed: Timeout 1");
            $stop;
        end
        begin
            @(posedge resp_rdy);
            disable timeout1;
        end
    join

    @(negedge clk);
    cmd = 16'h4001;
    snd_cmd = 1;
    @(negedge clk);

    snd_cmd = 0;
    @(negedge clk);

    // Test 2: Send command to move "north" 1 square (0x4001)
    // Wait for cmd_sent then check if frwrd == 10'h00
    @(posedge cmd_rdy);
    if (frwrd != 10'h00) begin
        $display("Test 2 Failed: frwrd = %h", frwrd);
        $stop();
    end

    // Wait for 10 positive edges of heading_rdy then check if frwrd == 10'h120 (or possibly 10'h140)
    // Check that movign signal is asserted at this time
    repeat (10) @(posedge heading_rdy);
    //@(posedge clk);
    if (frwrd != 10'h120) begin
        $display("Test 2 Failed: frwrd = %h", frwrd);
        $stop();
    end

    // Wait for 20 positive edges of heading_rdy then check if frwrd == 10'hFF
    repeat (24) @(posedge heading_rdy);
    @(posedge clk);
    if (~(&frwrd[9:8])) begin
        $display("Test 2 Failed: frwrd = %h", frwrd);
        $stop();
    end

    @(negedge clk);
    cntrIR = 1;
    @(negedge clk);
    cntrIR = 0;
    @(negedge clk);

    repeat (10) @(posedge clk);
    // frwrd shouldremain saturated at max speed
    if (~(&frwrd[9:8])) begin
        $display("Test 2 Failed: frwrd = %h", frwrd);
        $stop();
    end

    @(negedge clk);
    cntrIR = 1;
    @(negedge clk);
    cntrIR = 0;
    @(negedge clk);

    repeat (10) @(posedge clk);

    // Wait until frwrd hits zero
    while (frwrd != 10'h000) @(posedge heading_rdy);
    if (frwrd != 0) begin
        $display("Test 2 Failed: frwrd = %h", frwrd);
        $stop();
    end

    fork
        begin : timeout2
            repeat (1000000) @(posedge clk);
            $display("Test 2 Failed: Timeout 2");
            $stop;
        end
        begin
            @(posedge resp_rdy);
            disable timeout2;
        end
    join

    // Test 3: Send another move "north" 1 square command
    @(negedge clk);
    cmd = 16'h4001;
    snd_cmd = 1;
    @(negedge clk);

    snd_cmd = 0;
    @(negedge clk);

    // Wait for frwrd to be up to speed
    @(frwrd == 10'h300);

    @(negedge clk);
    lftIR = 1;
    @(negedge clk);
    lftIR = 0;
    repeat (10) @(negedge clk);

    rghtIR = 1;
    repeat (10) @(negedge clk);


    $display("Yahoo! All Test passed");
    $stop();





end



always begin
    #5 clk = ~clk;
end
endmodule
`default_nettype wire