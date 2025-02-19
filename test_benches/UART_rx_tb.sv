module UART_rx_tb();

logic clk, rst_n;
logic DATA;
logic trmt;
logic [7:0] tx_data;
logic tx_done;
logic clr_rdy;
logic rdy;
logic [7:0] rx_data;

UART_tx iDUT_tx(
    .clk(clk),
    .rst_n(rst_n),
    .TX(DATA),
    .trmt(trmt),
    .tx_data(tx_data),
    .tx_done(tx_done)
);

UART_rx iDUT_rx(
	.clk(clk),
	.rst_n(rst_n),
	.RX(DATA),
	.rdy(rdy),
    .cmd(rx_data),
    .clr_rdy(clr_rdy)
);

always #5 clk <= ~clk;

initial begin
	clk = 0;
	rst_n = 0;
	trmt = 0;
	tx_data = 8'h3A;
	clr_rdy = 1'b0;
	
	@(negedge clk);
	rst_n = 1;

    @(negedge clk);
    trmt = 1;

    @(negedge clk);
    trmt = 0;

    // Test 1: Test tx_done and rdy
    @(posedge tx_done);
    @(posedge rdy);

    // Test 2: Test tx and rx with arbitary data
    @(negedge clk);
    if (rx_data !== 8'h3A) begin
        $display("Error: rx_data = %h", rx_data);
        $stop;
    end

    @(negedge clk);
    clr_rdy = 1'b1;
    tx_data = 8'hFF;
    trmt = 1;

    @(negedge clk);
    trmt = 0;
    clr_rdy = 1'b0;
    // Test 3: Test clk_rdy functionality
    if (rdy !== 0) begin
        $display("Error: rdy = %b", rdy);
        $stop;
    end

    // Test 4: Test tx and rx with 0xFF
    @(posedge tx_done);
    @(posedge rdy);
    @(negedge clk);
    if (rx_data !== 8'hFF) begin
        $display("Error: rx_data = %h", rx_data);
        $stop;
    end

    @(negedge clk);
    clr_rdy = 1'b1;
    tx_data = 8'h00;
    trmt = 1;

    @(negedge clk);
    trmt = 0;
    clr_rdy = 1'b0;

    // Test 5: Test tx and rx with 0x00
    @(posedge tx_done);
    @(posedge rdy);
    @(negedge clk);
    if (rx_data !== 8'h00) begin
        $display("Error: rx_data = %h", rx_data);
        $stop;
    end

	$display("Yahoo! All tests passed!");
	$stop;
end


endmodule;
