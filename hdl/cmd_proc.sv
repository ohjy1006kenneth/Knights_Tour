/**
frwrd register. How should we implement it? We could only find solution using frwrd_temp
Test 3: How does IR sensor affect error?
**/


module cmd_proc(clk,rst_n,cmd,cmd_rdy,clr_cmd_rdy,send_resp,strt_cal,
                cal_done,heading,heading_rdy,lftIR,cntrIR,rghtIR,error,
				frwrd,moving,tour_go,fanfare_go);
				
  parameter FAST_SIM = 1;		// speeds up incrementing of frwrd register for faster simulation
				
  input clk,rst_n;					// 50MHz clock and asynch active low reset
  input [15:0] cmd;					// command from BLE
  input cmd_rdy;					// command ready
  output logic clr_cmd_rdy;			// mark command as consumed
  output logic send_resp;			// command finished, send_response via UART_wrapper/BT
  output logic strt_cal;			// initiate calibration of gyro
  input cal_done;					// calibration of gyro done
  input signed [11:0] heading;		// heading from gyro
  input heading_rdy;				// pulses high 1 clk for valid heading reading
  input lftIR;						// nudge error +
  input cntrIR;						// center IR reading (have I passed a line)
  input rghtIR;						// nudge error -
  output reg signed [11:0] error;	// error to PID (heading - desired_heading)
  output reg [9:0] frwrd;			// forward speed register
  output logic moving;				// asserted when moving (allows yaw integration)
  output logic tour_go;				// pulse to initiate TourCmd block
  output logic fanfare_go;			// kick off the "Charge!" fanfare on piezo
  
  // reg[15:0] cmd_internal;
  logic[15:0] cmd_internal;
  assign cmd_internal = cmd;

  // Internal Signals
  logic move_done;
  logic [5:0] ramp_speed;
  logic cntrIR_prev;
  logic cntrIR_pe; // Asserted when cntrlIR has rising edge
  logic [4:0] cntrIR_cnt; // Counter for cntrIR_pe
  logic fanfare; // Asserted when the cmd is a move with fanfare command
  logic set_fanfare; // Asserted when the fanfare is set
  logic clr_fanfare; // Asserted  the fanfare is cleared
  logic [10:0] lft_spd, rght_spd; // Speeds for left and right motors
  logic err_vld; // Asserted when error is valid
  logic [14:0] frwrd_tmp;
  logic inc_frwd, dec_frwd, clr_frwd; // Flags for incrementing, decrementing, and clearing frwrd
  logic [11:0] err_nudge, err_nudge_lft, err_nudge_rght; // Nudge error for left and right motors

  logic set_heading;

  // Instantiate PID
  PID pid (.clk(clk), .rst_n(rst_n), .moving(moving), .err_vld(err_vld), .error(error), .frwrd(frwrd), .lft_spd(lft_spd), .rght_spd(rght_spd));

  // State machine
  typedef enum logic [2:0] {
    IDLE,
    CALIBRATION,
    HEADING,
    RAMP_UP,
    RAMP_DOWN

  } state_t;

  state_t state, next_state;


  // Decode
  logic [3:0] opcode;
  reg [11:0] desired_heading;
  logic [3:0] num_square;

  assign opcode = cmd_internal[15:12];
  assign error = heading - desired_heading + err_nudge;
  assign num_square = cmd_internal[3:0];
  assign err_nudge = err_nudge_lft + err_nudge_rght;
  assign err_nudge_lft = lftIR ? (FAST_SIM ? 12'h1FF : 12'h05F) : 12'h000;
  assign err_nudge_rght = rghtIR ? (FAST_SIM ? 12'hE00 : 12'hFA1) : 12'h000;
  assign ramp_speed = FAST_SIM ? 6'h20 : 6'h03;
  
  // Rising edge detection
  assign cntrIR_pe = cntrIR & ~cntrIR_prev;
  always @ (posedge clk) begin
    cntrIR_prev <= cntrIR;
  end
  
  always @ (posedge clk, negedge rst_n) begin
    if(!rst_n) begin
      cntrIR_cnt <= 0;
    end else
    if (state == RAMP_UP && cntrIR_pe) begin
      cntrIR_cnt <= cntrIR_cnt + 1;
    end else if (state != RAMP_UP) begin
      cntrIR_cnt <= 0;
    end
  end

  // Ramp up and ramp down speed
  always @ (posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      frwrd <= 0;
    end else if (heading_rdy && inc_frwd && ~(&frwrd[9:8])) begin
      frwrd <= frwrd + ramp_speed;
    end else if (heading_rdy && dec_frwd) begin
      frwrd <= frwrd - 2*ramp_speed;
    end
  end

// Desired Heading register
always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		desired_heading <= 'b0;
	end else if(set_heading) begin
		desired_heading <= (|cmd_internal[11:4]) ? {cmd_internal[11:4], 4'hF} : {cmd_internal[11:4], 4'h0};
	end
end

  always_comb begin
    next_state = state;
    clr_cmd_rdy = 0;
    strt_cal = 0;
    send_resp = 0;
    moving = 0;
    move_done = 0;
    fanfare_go = 0;
    tour_go = 0;
    set_fanfare = 0;
    clr_fanfare = 0;
    err_vld = 0;
    inc_frwd = 0;
    dec_frwd = 0;
	  set_heading = 0;

    case (state)
      IDLE: begin
        if (cmd_rdy) begin
          clr_cmd_rdy = 1;

          case (opcode)
            4'b0010: begin // Calibrate command
              strt_cal = 1;
              next_state = CALIBRATION;
            end
            4'b0100: begin // Move command
			  set_heading = 1'b1;
              next_state = HEADING;
            end

            4'b0101: begin // Move with fanfare command
              set_fanfare = 1;
			  set_heading = 1'b1;
			  next_state = HEADING;
            end

            4'b0110: begin // Tour command
              tour_go = 1;
            end
          endcase
        end
      end

      // Assert strt_cal and wait for cal_done
      CALIBRATION: begin
        if (cal_done) begin
          send_resp = 1;
          next_state = IDLE;
        end
      end

      // Let PID do its thing and finish adjusting heading if the error is within 12'h02C
      HEADING: begin
        moving = 1;
        err_vld = 1;
        if (12'h02C > error) begin
          next_state = RAMP_UP;
        end
      end

      // Ramp up to max speed and count the squares as the robot is moving to determine move_done
      RAMP_UP: begin
        moving = 1;
        inc_frwd = 1;

        // Compare 2x number of squares (shift left)
        if (cntrIR_cnt == (num_square << 1)) begin
          if (fanfare) begin
            fanfare_go = 1;
          end
          next_state = RAMP_DOWN;
        end
      end

      // Ramp down speed and stop when the robot is no longer moving
      RAMP_DOWN: begin
        moving = 1;
        dec_frwd = 1;
      

        if (!frwrd) begin
          move_done = 1;
          send_resp = 1;
          next_state = IDLE;
        end
      end

      default: begin
        next_state = IDLE;
      end
    endcase
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else begin
      state <= next_state;
    end
  end


  // SR flip-flop for fanfare
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      fanfare <= 1'b0;
    else if (set_fanfare)
      fanfare <= 1;
    else if (clr_fanfare)
      fanfare <= 0;
  end
  
endmodule
