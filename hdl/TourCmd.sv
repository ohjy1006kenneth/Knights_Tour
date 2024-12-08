module TourCmd(clk,rst_n,start_tour,move,mv_indx,
               cmd_UART,cmd,cmd_rdy_UART,cmd_rdy,
			   clr_cmd_rdy,send_resp,resp);

  input clk,rst_n;			// 50MHz clock and asynch active low reset
  input start_tour;			// from done signal from TourLogic
  input [7:0] move;			// encoded move to perform
  output reg [4:0] mv_indx;	// "address" to access next move
  input [15:0] cmd_UART;	// cmd from UART_wrapper
  input cmd_rdy_UART;		// cmd_rdy from UART_wrapper
  output [15:0] cmd;		// multiplexed cmd to cmd_proc
  output logic cmd_rdy;			// cmd_rdy signal to cmd_proc
  input clr_cmd_rdy;		// from cmd_proc (goes to UART_wrapper too)
  input send_resp;			// lets us know cmd_proc is done with the move command
  output logic [7:0] resp;		// either 0xA5 (done) or 0x5A (in progress)
  
   // Internal Logics
   logic cmd_select; // Select between command from UART or TourLogic (0=TourLogic, 1=UART)
   logic clr_indx, inc_indx; // Clear and increment index
   logic vh_select; // Vertical or horizontal move (0=vertical, 1=horizontal)
   logic cmd_rdy_tour; // Command ready from TourLogic

   // Decompose move command
   assign cmd = cmd_select ? cmd_UART :
               move[0] ? (vh_select ? 16'h5BF1 : 16'h4002) :
               move[1] ? (vh_select ? 16'h53F1 : 16'h4002) :
               move[2] ? (vh_select ? 16'h53F2 : 16'h4001) :
               move[3] ? (vh_select ? 16'h53F2 : 16'h47F1) :
               move[4] ? (vh_select ? 16'h53F1 : 16'h47F2) :
               move[5] ? (vh_select ? 16'h5BF1 : 16'h47F2) :
               move[6] ? (vh_select ? 16'h5BF2 : 16'h47F1) :
               move[7] ? (vh_select ? 16'h5BF2 : 16'h4001) : 16'h8000;

   // Logic to send out cmd_rdy sig
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			cmd_rdy <= 'b0;
		end else begin
			cmd_rdy <= cmd_select ? cmd_rdy_UART : cmd_rdy_tour;
		end
	end

   // Clear and increment logic for mv_indx
   always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n) begin
         mv_indx <= 5'b0;
      end else if (clr_indx) begin
         mv_indx <= 5'b0;
      end else if (inc_indx) begin
         mv_indx <= mv_indx + 1;
      end
   end
   // states for state machine
   typedef enum logic [2:0] {
      IDLE,
      READ_VERTICAL,
      MOVE_VERTICAL,
      READ_HORIZONTAL,
      MOVE_HORIZONTAL
   } state_t;

   state_t state, next_state;

   // State transition logic
   always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n)
         state <= IDLE;
      else
         state <= next_state;
   end

   // Next state logic
   always_comb begin
      next_state = state;
      cmd_select = 0;
      clr_indx = 0;
      inc_indx = 0;
      vh_select = 0;
      cmd_rdy_tour = 0;

      case (state)
         IDLE: begin
            cmd_select = 1;
            // start if 
            if (start_tour) begin
               cmd_select = 0;
               clr_indx = 1;
               next_state = READ_VERTICAL;
            end
         end
         READ_VERTICAL: begin
            cmd_rdy_tour = 1;
            if (clr_cmd_rdy) begin // cmd_proc ready to take the next command / movement
               cmd_rdy_tour = 0;
               next_state = MOVE_VERTICAL;
            end
         end
         MOVE_VERTICAL: begin
            if (send_resp) begin
               next_state = READ_HORIZONTAL;
            end
         end
         READ_HORIZONTAL: begin
            vh_select = 1;
            cmd_rdy_tour = 1;
            if (clr_cmd_rdy) begin // cmd_proc ready to take the next command 
               cmd_rdy_tour = 0;
               next_state = MOVE_HORIZONTAL;
            end
         end
         MOVE_HORIZONTAL: begin
            vh_select = 1;
            if (send_resp) begin
               if (mv_indx == 23) begin // If this is the last move, return to IDLE state and stop moving
                  next_state = IDLE;
               end else begin // waits for next move in READ_VERTICAL
                  next_state = READ_VERTICAL;
                  inc_indx = 1;
               end
            end
         end
         default: next_state = IDLE;
      endcase
   end

   assign resp = cmd_select ? 8'hA5 : mv_indx == 23 ? 8'hA5 : 8'h5A; // update status on movement
  
endmodule
