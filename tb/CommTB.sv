`default_nettype none
module CommTB();

logic clk, rst_n;
logic [15:0] cmd_wrapper, cmd_remote;
logic snd_cmd, cmd_snt;
logic tx_done;
logic [7:0] resp_wrapper, resp_remote;
logic resp_rdy;
logic TX_RX, RX_TX;
logic trmt;
logic clr_cmd_rdy;
logic cmd_rdy;

// Instantiate RemoteComm
RemoteComm iDUT_remote (
    .clk(clk),
    .rst_n(rst_n),
    .snd_cmd(snd_cmd),
    .cmd(cmd_remote),
    .RX(RX_TX),
    .TX(TX_RX),
    .resp(resp_remote),
    .cmd_snt(cmd_snt),
    .resp_rdy(resp_rdy)
);

// Instantiate UART_wrapper
UART_wrapper iDUT_wrapper (
    .clk(clk),
    .rst_n(rst_n),
    .RX(TX_RX),
    .trmt(trmt),
    .resp(resp_wrapper),
    .clr_cmd_rdy(clr_cmd_rdy),
    .TX(RX_TX),
    .tx_done(tx_done),
    .cmd(cmd_wrapper),
    .cmd_rdy(cmd_rdy)
);

initial begin
    clk = 0;
    rst_n = 0;

    @(negedge clk);
    rst_n = 1;
    cmd_remote = 16'hABCD;

    @(negedge clk);
    snd_cmd = 1;
    @(negedge clk);
    snd_cmd = 0;

    @(posedge cmd_rdy);
    // Test1: Check if the wrapper properly received 16'hABCD from remote.
    if (cmd_wrapper !== cmd_remote) begin
        $display("Error: cmd_wrapper = %h. But cmd_remote = %h", cmd_wrapper, cmd_remote);
        $stop;
    end

    // Test2: Check if the wrapper receives data properly when remote sends consecutive data. 
    @(posedge cmd_snt)
    @(negedge clk);
    clr_cmd_rdy = 1;

    @(negedge clk);
    clr_cmd_rdy = 0;
    cmd_remote = 16'h1234;

    @(negedge clk);
    snd_cmd = 1;
    @(negedge clk);
    snd_cmd = 0;

    @(posedge cmd_rdy);
    // Check if the wrapper properly received 16'h1234 from remote.
    if (cmd_wrapper !== cmd_remote) begin
        $display("Error: cmd_wrapper = %h. But cmd_remote = %h", cmd_wrapper, cmd_remote);
        $stop;
    end

    @(posedge cmd_snt)
    @(negedge clk);
    clr_cmd_rdy = 1;

    @(negedge clk);
    clr_cmd_rdy = 0;
    cmd_remote = 16'hBA1D;

    @(negedge clk);
    snd_cmd = 1;
    @(negedge clk);
    snd_cmd = 0;

    @(posedge cmd_rdy);
    // Check if the wrapper properly received 16'hBA1D from remote.
    if (cmd_wrapper != cmd_remote) begin
        $display("Error: cmd_wrapper = %h. But cmd_remote = %h", cmd_wrapper, cmd_remote);
        $stop;
    end

    $display("Yahoo! All tests passed!");
    $stop;
end

// Clock generation
always begin
    #5 clk = ~clk;
end

endmodule
`default_nettype wire