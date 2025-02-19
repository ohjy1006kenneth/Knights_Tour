module TourLogic_tb;

    // Inputs to DUT
    reg clk, rst_n, go;
    reg [2:0] x_start, y_start;
    reg [4:0] indx;

    // Outputs from DUT
    wire done;
    wire [7:0] move;
  

    int fd;

    // Instantiate DUT
    TourLogic DUT (
        .clk(clk),
        .rst_n(rst_n),
        .x_start(x_start),
        .y_start(y_start),
        .go(go),
        .indx(indx),
        .done(done),
        .move(move)
  
    );

    // Clock generation
    always #5 clk = ~clk;

    // Monitor board state
    always @(negedge DUT.backup) begin
        integer x, y;
        for (y = 4; y >= 0; y = y - 1) begin
            $display(" %2d  %2d  %2d  %2d  %2d", 
                     DUT.board[0][y], DUT.board[1][y], DUT.board[2][y], DUT.board[3][y], DUT.board[4][y]);
        end
        $display(fd, "--------------------------\n");
    end

    // Testbench logic
    initial begin
        // Initialize inputs

        //fd = $fopen("/tmp/dump.log", "w");
        clk = 0;
        rst_n = 0;
        go = 0;
        x_start = 3'b010;
        y_start = 3'b010;
        indx = 0;

        // Reset
        #10 rst_n = 1;

        // Start the tour
        #20 go = 1;
        #10 go = 0;

        // Wait for solution
        wait(done);
        $display("Solution complete!");

        // Print moves
        for (indx = 0; indx < 24; indx = indx + 1) begin
            #10;
            $display("Move %2d: %b", indx, move);
        end

        $stop;
    end

endmodule