module rst_synch(

input RST_n,               
input clk,                  
output logic rst_n          
);

logic flop1;

always @(negedge clk, negedge RST_n) begin
    if (!RST_n) begin
        flop1 <= 0;
        rst_n <= 0;
    end
    else begin
        flop1 <= 1;
        rst_n <= flop1;
    end
end

endmodule