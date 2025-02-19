//In this test bench we are looking at the wave to see that the states transition properly and that the piezo output is correct
module sponge_tb;
    // Inputs and outputs
    logic clk;             // 50 MHz clock
    logic RST_n; 	// Unsynchronized reset input from push button
    logic GO;              // Raw push button signal for go
    logic rst_n_sync;      // Synchronized reset signal
    logic go_sync;         // Synchronized go signal
    logic piezo, piezo_n;  // Differential drive signals for piezo
	logic rst_n;
    // Clock generation
    initial clk = 0;
    always #10 clk = ~clk;  // 50 MHz clock (20 ns period)


    

    sponge #(.FAST_SIM(1)) sponge_inst (
        .clk(clk),
        .rst_n(rst_n),
        .go(GO),
        .piezo(piezo),
        .piezo_n(piezo_n)
    );

    // Stimulus for testing
    initial begin
        // Initial values
        rst_n = 0;
        GO = 0;

        // Release reset
		@(negedge clk);
        rst_n = 1;
		@(posedge clk);
        // Simulate button press to generate GO signal
        @(negedge clk);
        GO = 1;
        @(negedge clk);
        GO = 0; //push button was released
        @(negedge clk);
        
		repeat (4200000) @(posedge clk); // wait clock cycles for fanfare to finish

        

        $stop();
    end

    // Monitor signals
    
    initial begin
        $monitor("Time: %t | RST_n: %b | GO: %b | go_sync: %b | piezo: %b | piezo_n: %b",
                 $time, RST_n, GO, go_sync, piezo, piezo_n);
    end
endmodule
