module PB_release (
    input logic clk,       
    input logic rst_n,     
    input logic PB,        
    output logic released  
);
    logic pb_sync1;
    logic pb_sync2;
    logic pb_sync3;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            pb_sync1 <= 1'b1;
            pb_sync2 <= 1'b1;
        end else begin
            pb_sync1 <= PB;
            pb_sync2 <= pb_sync1;
        end
    end

    always_ff @(posedge clk,negedge rst_n) begin
        if (!rst_n) begin
            pb_sync3 <= 1'b1;
        end else begin
            pb_sync3 <= pb_sync2;
        end
    end

    assign released = pb_sync2 & ~pb_sync3;

endmodule