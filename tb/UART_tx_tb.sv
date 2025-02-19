`default_nettype none
module UART_tx_tb();

logic clk, rst_n;
logic TX;
logic trmt;
logic [7:0] tx_data;
logic tx_done;

UART_tx iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .TX(TX),
    .trmt(trmt),
    .tx_data(tx_data),
    .tx_done(tx_done)
);

initial begin
    clk = 0;
    rst_n = 0;
    trmt = 0;
    tx_data = 8'h3A;

    @(negedge clk);
    rst_n = 1;

    @(negedge clk);
    trmt = 1;

    @(negedge clk);
    trmt = 0;

    @(posedge tx_done);
    $stop;
end


always #5 clk <= ~clk;

endmodule

`default_nettype wire