module KnightsTour_tb1();

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

  fork
    begin : timeout0
        repeat (100000) @(posedge clk);
        $display("Error: NEMO_setup didn't assert.");
        $stop();
    end
    begin
        @(posedge iPHYS.iNEMO.NEMO_setup);
        if (iDUT.iMTR.lft_spd != 0 || iDUT.iMTR.rght_spd != 0) begin
            $display("Error: MtrDrv.lft_spd or rght_spd not 0.");
            $stop();
        end

        if (SS_n != 1) begin
            $display("Error: SS_n not 1. Should be not selecting.");
            $stop();
        end

        if (RX_TX != 1'b1) begin
            $display("Error: RX_TX not 1. Should be not transmitting.");
            $stop();
        end

        if (piezo != 1'b0 | piezo_n != 1'b1) begin
            $display("Error: PIezo should be off.");
            $stop();
        end
        disable timeout0;
    end
  join
  
	@(negedge clk);
  cmd = 16'h2000; // Send command to callibarate NEMO
   send_cmd = 1'b1;

   @(negedge clk);

   send_cmd = 1'b0;

  @(posedge iDUT.iNEMO.cal_done); // Wait for calibration to finish

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

  // Send command to move east 1 square
  cmd = 16'h4BF1;
  send_cmd = 1'b1;
  @(negedge clk);
  send_cmd = 1'b0;

  @(posedge resp_rdy); // Wait for the response

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
  @(negedge clk); // For Debugging

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


