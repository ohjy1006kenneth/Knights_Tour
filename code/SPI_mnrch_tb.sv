`default_nettype none
module SPI_mnrch_tb();

logic clk, rst_n;
logic [15:0] cmd;
logic [15:0] resp;
logic snd, done;
logic SS_n, SCLK, MISO, MOSI;
logic INT;

// Instantiate the SPI_mnrch module
SPI_mnrch iDUT_mnrch(
    .clk(clk),
    .rst_n(rst_n),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MISO(MISO),
    .snd(snd),
    .cmd(cmd),
    .MOSI(MOSI),
    .done(done),
    .resp(resp)
);

// Instantiate the SPI_iNEMO1 module
SPI_iNEMO1 iDUT_iNEMO1(
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MISO(MISO),
    .MOSI(MOSI),
    .INT(INT)
);

// Testbench
initial begin
    clk = 0;
    rst_n = 0;

    @(negedge clk);
    rst_n = 1;

    @(negedge clk);
    cmd = 16'h8Fxx;
    snd = 1;

    @(negedge clk);
    snd = 0;

    // Test 1: Read from 0x0F (cmd = 16'h8Fxx). Expected response is 16'h006A
    @(posedge done);
    
    if (resp !== 16'h006A) begin
        $display("Test1 failed: Expected 16'h8Fxx, got 16'h%h", resp);
        $stop;
    end

    @(negedge clk);
    // rst_n = 1'b0;
    @(negedge clk);
    //rst_n = 1'b1;
    @(negedge clk);
    cmd = 16'h0D02;
    snd = 1;

    @(negedge clk);
    snd = 0;

    // Test 2: Write 0x02 to the register at address 0x0D (cmd = 16'h0D02). Expected INT to be high.
    @(posedge done);
    @(posedge INT);
    if (INT !== 1) begin
        $display("Test2 failed: Expected INT to be high");
        $stop;
    end

    $display("Yahoo! All tests passed");
end

// Clock generation
always
    #5 clk = ~clk;


endmodule
`default_nettype wire