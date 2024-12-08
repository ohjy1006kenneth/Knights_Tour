`timescale 1ns/1ps
module KnightsTour_tb1_post();

  localparam FAST_SIM = 1;
  
  
  /////////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk, RST_n;
  reg [15:0] cmd;
  reg send_cmd;

  ///////////////////////////////////
  // Declare any internal signals //
  /////////////////////////////////
  wire SS_n,SCLK,MOSI,MISO,INT;
  wire lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
  wire TX_RX, RX_TX;
  logic cmd_sent;
  logic resp_rdy;
  logic [7:0] resp;
  wire IR_en;
  wire lftIR_n,rghtIR_n,cntrIR_n;
  
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  KnightsTour iDUT(.clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK),
                   .MOSI(MOSI), .MISO(MISO), .INT(INT), .lftPWM1(lftPWM1),
				   .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
				   .RX(TX_RX), .TX(RX_TX), .piezo(piezo), .piezo_n(piezo_n),
				   .IR_en(IR_en), .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n),
				   .cntrIR_n(cntrIR_n));
				  
  /////////////////////////////////////////////////////
  // Instantiate RemoteComm to send commands to DUT //
  ///////////////////////////////////////////////////
  RemoteComm_e iRMT(.clk(clk), .rst_n(RST_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd),
             .send_cmd(send_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp));
				   
  //////////////////////////////////////////////////////
  // Instantiate model of Knight Physics (and board) //
  ////////////////////////////////////////////////////
  KnightPhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                      .MOSI(MOSI),.INT(INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
					  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.IR_en(IR_en),
					  .lftIR_n(lftIR_n),.rghtIR_n(rghtIR_n),.cntrIR_n(cntrIR_n)); 
				   
  initial begin
  clk = 0;
 
  // Initialize KnightsTour
  initialize;

  
	@(negedge clk);

  cmd = 16'h2000;
  send_cmd = 1'b1;

   @(negedge clk);

   send_cmd = 1'b0;

  $display("Calibration finished");

  @(posedge resp_rdy);
  if (resp !== 8'hA5) begin
	$display("Incorrect response!");
	$stop();
  end

  $display("Got correct response!");
  $display("Testing heading");

  @(negedge clk);

  $display("Move east one square");

  cmd = 16'h4BF1;
  send_cmd = 1'b1;
  @(negedge clk);
  send_cmd = 1'b0;

  @(posedge resp_rdy);

  @(negedge clk);
  @(negedge clk);
  @(negedge clk);
  @(negedge clk);
  @(negedge clk);
  @(negedge clk);
  @(negedge clk);
  @(negedge clk);
  @(negedge clk);
  @(negedge clk);
  @(negedge clk);

  $display("YAHOO! All test passed!");
  $stop();
  

  end

  // Task to initialize the DUT
  task initialize;
    @(negedge clk);
    RST_n = 0;

    @ (negedge clk);
    RST_n = 1;
    @ (negedge clk);
  endtask

  // // Task to send a command to the DUT
  // task snd_cmd;
  //   input logic [15:0] cmd;

  //   snd_cmd = 1;
  // endtask
  
  
  always
    #5 clk = ~clk;
  
endmodule


