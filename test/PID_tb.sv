`default_nettype none
module PID_tb();
logic clk, rst_n;
logic moving, err_vld;
logic [11:0] error;
logic [9:0] frwrd;
logic [10:0] lft_spd, rght_spd;

logic [24:0] mem_stim[0:1999];
logic [21:0] mem_resp[0:1999];
int addr;

// Instantiate iDUT (PID)
PID iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .moving(moving),
    .err_vld(err_vld),
    .error(error),
    .frwrd(frwrd),
    .lft_spd(lft_spd),
    .rght_spd(rght_spd)
);


initial begin
    $readmemh("PID_stim.hex", mem_stim);
    $readmemh("PID_resp.hex", mem_resp);
    clk = 0;
    rst_n = 0;
    addr = 0;

    while(1) begin
        rst_n = mem_stim[addr][24];
        moving = mem_stim[addr][23];
        err_vld = mem_stim[addr][22];
        error = mem_stim[addr][21:10];
        frwrd = mem_stim[addr][9:0];

        @(negedge clk);
        if (lft_spd != mem_resp[addr][21:11] || rght_spd != mem_resp[addr][10:0]) begin
            $display("Error at addr: %d\nlft_spd = %h, expected = %h\nrght_spd = %h, expected = %h\n", addr, lft_spd, mem_resp[addr][21:11], rght_spd, mem_resp[addr][10:0]);
            $stop;
        end

        
        addr = addr + 1;

        if (addr === 2000) begin
            $display("Yahoo! All test passed! name: Kenneth Oh");
            $stop;
        end

    end
end

always
    #5 clk = ~clk;

endmodule
`default_nettype wire