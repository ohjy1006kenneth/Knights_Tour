//////////////////////////////////////////////////////
// Interfaces with ST 6-axis inertial sensor.  In  //
// this application we only use Z-axis gyro for   //
// heading of robot.  Fusion correction comes    //
// from "gaurdrail" signals lftIR/rghtIR.       //
/////////////////////////////////////////////////
module inert_intf(clk,rst_n,strt_cal,cal_done,heading,rdy,lftIR,
                  rghtIR,SS_n,SCLK,MOSI,MISO,INT,moving);

  parameter FAST_SIM = 1;	// used to speed up simulation
  
  input clk, rst_n;
  input MISO;					// SPI input from inertial sensor
  input INT;					// goes high when measurement ready
  input strt_cal;				// initiate claibration of yaw readings
  input moving;					// Only integrate yaw when going
  input lftIR,rghtIR;			// gaurdrail sensors
  
  output cal_done;				// pulses high for 1 clock when calibration done
  output signed [11:0] heading;	// heading of robot.  000 = Orig dir 3FF = 90 CCW 7FF = 180 CCW
  output rdy;					// goes high for 1 clock when new outputs ready (from inertial_integrator)
  output SS_n,SCLK,MOSI;		// SPI outputs


  //////////////////////////////////
  // Declare any internal signal //
  ////////////////////////////////
  logic vld;		// vld yaw_rt provided to inertial_integrator
  logic snd;        // snd provided to SPI_mnrch
  logic [15:0] cmd; // cmd provided to SPI_mnrch
  logic done;
  logic [15:0] resp; // response from SPI_mnrch
  logic [7:0] yawL, yawH; // yaw readings from inertial sensor
  logic signed [15:0] yaw_rt; // raw gyro rate readings from inertial sensor
  logic set_yawH, set_yawL; // flags to set yawH and yawL


  // Instantiate SPI Monarch
  SPI_mnrch spi (.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .snd(snd), .cmd(cmd),
                 .MOSI(MOSI), .done(done), .resp(resp));

  // 16-bit timer for calibration
  logic [15:0] timer;
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        timer <= 16'h0;
    else if (strt_cal)
        timer <= 16'h0;
    else
        timer <= timer + 16'h1;
  end


  // Double-flop INT signal for metastability
  logic INT_ff1;
  logic INT_ff2;
  logic [7:0] yawL_ff1;
  logic [7:0] yawL_ff2;
  logic [7:0] yawH_ff1;
  logic [7:0] yawH_ff2;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        yawL <= 'b0;
        yawH <= 'b0;
    end else begin
        if ( set_yawH) begin
            yawH <= resp[7:0];
        end
        if( set_yawL) begin
            yawL <= resp[7:0];
        end
    end
end

  // Double-flop for metastability
  always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            INT_ff1 <= 1'b0;
            INT_ff2 <= 1'b0;
            yawL_ff1 <= 8'h00;
            yawL_ff2 <= 8'h00;
            yawH_ff1 <= 8'h00;
            yawH_ff2 <= 8'h00;
        end else begin
            INT_ff1 <= INT;
            INT_ff2 <= INT_ff1;
            //yawL_ff1 <= yawL;
            yawL_ff2 <= yawL;
            //yawH_ff1 <= yawH;
            yawH_ff2 <= yawH;
        end
  end

  assign yaw_rt = signed'({yawH_ff2, yawL_ff2});
  

  // State Machine Logic
  typedef enum logic [2:0] { INIT1, INIT2, INIT3, INTERRUPT, READ_YAWL, READ_YAWH } state_t;
  state_t state, next_state;

  always_comb begin
    next_state = state;
    cmd = 16'h0;
    snd = 0;
    set_yawH = 0;
    vld = 0;
    set_yawL = 0;

    case (state)
      // Enable interrupt upon data ready
      INIT1: begin
        if (&timer) begin
          cmd = 16'h0D02;
          snd = 1;
          next_state = INIT2;
        end
      end
      // Setup gyro for 416Hz data rate, +/- 250 deg/sec range
      INIT2: begin
        if (done) begin
            cmd = 16'h1160;
            snd = 1;
            next_state = INIT3;
        end
      end
      // Turn roundign on for gyro readings
      INIT3: begin
        if (done) begin
          cmd = 16'h1440;
          snd = 1;
          next_state = INTERRUPT;
        end
      end
      // Wait for interrupt to happen
      INTERRUPT: begin
            if (INT_ff2) begin
                cmd = 16'hA6xx;
                snd = 1;
                next_state = READ_YAWL;
            end
      end
      // Read and store yasL from Gyro
      READ_YAWL: begin
        if (done) begin
            cmd = 16'hA7xx;
            snd = 1;
            set_yawL = 1;
            next_state = READ_YAWH;
        end
      end
      // Read and store yawH from Gyro
      READ_YAWH: begin
        if (done) begin
            set_yawH = 1;
            vld = 1; // yaw_rt is ready
            next_state = INTERRUPT;
        end
      end

      default: begin
        next_state = INIT1;
      end
    endcase
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        state <= INIT1;
    else if (strt_cal)
        state <= INIT1;
    else
        state <= next_state;
  end

  ////////////////////////////////////////////////////////////////////
  // Instantiate Angle Engine that takes in angular rate readings  //
  // and acceleration info and produces a heading reading         //
  /////////////////////////////////////////////////////////////////
  inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal),.vld(vld),
                           .rdy(rdy),.cal_done(cal_done), .yaw_rt(yaw_rt),.moving(moving),.lftIR(lftIR),
                           .rghtIR(rghtIR),.heading(heading));
						   

endmodule
	  