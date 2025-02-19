module TourCmd_tb();

logic clk,rst_n;			// 50MHz clock and asynch active low reset
logic start_tour;			// from done signal from TourLogic
logic [7:0] move;			// encoded move to perform
logic [4:0] mv_indx;	// "address" to access next move
logic [15:0] cmd_UART;	// cmd from UART_wrapper
logic cmd_rdy_UART;		// cmd_rdy from UART_wrapper
logic [15:0] cmd;		// multiplexed cmd to cmd_proc
logic cmd_rdy;			// cmd_rdy signal to cmd_proc
logic clr_cmd_rdy;		// from cmd_proc (goes to UART_wrapper too)
logic send_resp;			// lets us know cmd_proc is done with the move command
logic [7:0] resp;		// either 0xA5 (done) or 0x5A (in progress)

// Instantiate the TourCmd module
TourCmd iDUT (
  .clk(clk),
  .rst_n(rst_n),
  .start_tour(start_tour),
  .move(move),
  .mv_indx(mv_indx),
  .cmd_UART(cmd_UART),
  .cmd_rdy_UART(cmd_rdy_UART),
  .cmd(cmd),
  .cmd_rdy(cmd_rdy),
  .clr_cmd_rdy(clr_cmd_rdy),
  .send_resp(send_resp),
  .resp(resp)
);

initial begin 
  clk = 0;
  rst_n = 0;

  @(negedge clk);
  rst_n = 1;
  start_tour = 1;

  // Test move 0 (Up 2 squares and right 1 square) 
  @(negedge clk);
  move = 8'b00000001;
  start_tour = 0;
  @(negedge clk);
  clr_cmd_rdy = 1;
  @(negedge clk);
  clr_cmd_rdy = 0;
  repeat (5) @(negedge clk);
  if (cmd !== 16'h4002) begin // Check if vertical move cmd is correct
    $display("Test failed for vertical move 0");
    $stop;
  end
  

  send_resp = 1;
  @(negedge clk);
  clr_cmd_rdy = 1;
  send_resp = 0;
  @(negedge clk);
  repeat (5) @(negedge clk);
  if (cmd !== 16'h5BF1) begin // Check if horizontal move cmd is correct
    $display("Test failed for horizontal move 0");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  send_resp = 0;

  // Test move 1 (Up 2 squares and left 1 square)
  @(negedge clk);
  start_tour = 1;
  @(negedge clk);
  move = 8'b00000010;
  start_tour = 0;
  @(negedge clk);
  clr_cmd_rdy = 1;
  @(negedge clk);
  clr_cmd_rdy = 0;
  repeat (5) @(negedge clk);
  if (cmd !== 16'h4002) begin // Check if vertical move cmd is correct
    $display("Test failed for vertical move 1");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  clr_cmd_rdy = 1;
  send_resp = 0;
  @(negedge clk);
  repeat (5) @(negedge clk);
  if (cmd !== 16'h53F1) begin // Check if horizontal move cmd is correct
    $display("Test failed for horizontal move 1");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  send_resp = 0;

  // Test move 2 (Up 1 square and left 2 squares)
  @(negedge clk);
  start_tour = 1;
  @(negedge clk);
  move = 8'b00000100;
  start_tour = 0;
  @(negedge clk);
  clr_cmd_rdy = 1;
  @(negedge clk);
  clr_cmd_rdy = 0;
  repeat (5) @(negedge clk);
  if (cmd !== 16'h4001) begin // Check if vertical move cmd is correct
    $display("Test failed for vertical move 2");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  clr_cmd_rdy = 1;
  send_resp = 0;
  @(negedge clk);
  repeat (5) @(negedge clk);
  if (cmd !== 16'h53F2) begin // Check if horizontal move cmd is correct
    $display("Test failed for horizontal move 2");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  send_resp = 0;

  // Test move 3 (Down 1 square and left 2 squares)
  @(negedge clk);
  start_tour = 1;
  @(negedge clk);
  move = 8'b00001000;
  start_tour = 0;
  @(negedge clk);
  clr_cmd_rdy = 1;
  @(negedge clk);
  clr_cmd_rdy = 0;
  repeat (5) @(negedge clk);
  if (cmd !== 16'h47F1) begin // Check if vertical move cmd is correct
    $display("Test failed for vertical move 3");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  clr_cmd_rdy = 1;
  send_resp = 0;
  @(negedge clk);
  repeat (5) @(negedge clk);
  if (cmd !== 16'h53F2) begin // Check if horizontal move cmd is correct
    $display("Test failed for horizontal move 3");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  send_resp = 0;

  // Test move 4 (Down 2 squares and left 1 square)
  @(negedge clk);
  start_tour = 1;
  @(negedge clk);
  move = 8'b00010000;
  start_tour = 0;
  @(negedge clk);
  clr_cmd_rdy = 1;
  @(negedge clk);
  clr_cmd_rdy = 0;
  repeat (5) @(negedge clk);
  if (cmd !== 16'h47F2) begin // Check if vertical move cmd is correct
    $display("Test failed for vertical move 4");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  clr_cmd_rdy = 1;
  send_resp = 0;
  @(negedge clk);
  repeat (5) @(negedge clk);
  if (cmd !== 16'h53F1) begin // Check if horizontal move cmd is correct
    $display("Test failed for horizontal move 4");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  send_resp = 0;

  // Test move 5 (Down 2 squares and right 1 square)
  @(negedge clk);
  start_tour = 1;
  @(negedge clk);
  move = 8'b00100000;
  start_tour = 0;
  @(negedge clk);
  clr_cmd_rdy = 1;
  @(negedge clk);
  clr_cmd_rdy = 0;
  repeat (5) @(negedge clk);
  if (cmd !== 16'h47F2) begin // Check if vertical move cmd is correct
    $display("Test failed for vertical move 5");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  clr_cmd_rdy = 1;
  send_resp = 0;
  @(negedge clk);
  repeat (5) @(negedge clk);
  if (cmd !== 16'h5BF1) begin // Check if horizontal move cmd is correct
    $display("Test failed for horizontal move 5");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  send_resp = 0;

  // Test move 6 (Down 1 square and right 2 squares)
  @(negedge clk);
  start_tour = 1;
  @(negedge clk);
  move = 8'b01000000;
  start_tour = 0;
  @(negedge clk);
  clr_cmd_rdy = 1;
  @(negedge clk);
  clr_cmd_rdy = 0;
  repeat (5) @(negedge clk);
  if (cmd !== 16'h47F1) begin // Check if vertical move cmd is correct
    $display("Test failed for vertical move 6");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  clr_cmd_rdy = 1;
  send_resp = 0;
  @(negedge clk);
  repeat (5) @(negedge clk);
  if (cmd !== 16'h5BF2) begin // Check if horizontal move cmd is correct
    $display("Test failed for horizontal move 6");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  send_resp = 0;

  // Test move 7 (Up 1 square and right 2 squares)
  @(negedge clk);
  start_tour = 1;
  @(negedge clk);
  move = 8'b10000000;
  start_tour = 0;
  @(negedge clk);
  clr_cmd_rdy = 1;
  @(negedge clk);
  clr_cmd_rdy = 0;
  repeat (5) @(negedge clk);
  if (cmd !== 16'h4001) begin // Check if vertical move cmd is correct
    $display("Test failed for vertical move 7");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  clr_cmd_rdy = 1;
  send_resp = 0;
  @(negedge clk);
  repeat (5) @(negedge clk);
  if (cmd !== 16'h5BF2) begin // Check if horizontal move cmd is correct
    $display("Test failed for horizontal move 7");
    $stop;
  end

  send_resp = 1;
  @(negedge clk);
  send_resp = 0;



  $display("YAHOO! All tests passed!");
  $stop;
end



always begin
  #5 clk = ~clk;
end

endmodule