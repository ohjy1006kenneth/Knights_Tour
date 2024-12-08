
module TourLogic(clk,rst_n,x_start,y_start,go,done,indx,move);

  input wire clk,rst_n;				// 50MHz clock and active low asynch reset
  input wire [2:0] x_start, y_start;	// starting position on 5x5 board
  input wire go;						// initiate calculation of solution
  input wire [4:0] indx;				// used to specify index of move to read out
  output logic done;			// pulses high for 1 clock when solution complete
  output wire [7:0] move;			// the move addressed by indx (1 of 24 moves)

  ////////////////////////////////////////
  // Declare needed internal registers //
  //////////////////////////////////////

  reg board[0:4][0:4];				// keeps track if position visited
  reg [7:0] last_move[0:24];		// last move tried from this spot
  reg [7:0] move_try;				// one hot encoding of move we will try next
  reg [4:0] move_num;				// keeps track of move we are on
  reg [2:0] xx,yy;					// current x & y position  

  logic[7:0] poss_moves_cur; 
  assign poss_moves_cur = calc_poss(xx, yy);

  logic set_possible;
  logic init_move_try;
  logic shift_move_try;
  logic zero;
  logic init;
  logic update_position;
  logic backup;
  logic set_done;
  
  assign move = last_move[indx + 1];
 
  ///////////////////////////////////////////////////
  // The board memory structure keeps track of where 
  // the knight has already visited.  Initially this 
  // should be a 5x5 array of 5-bit numbers to store
  // the move number (helpful for debug).  Later it 
  // can be reduced to a single bit (visited or not)
  ////////////////////////////////////////////////	  
  always_ff @(posedge clk) begin
    if (zero) begin // resetting board ordering to all zero
	  board <= '{'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0}};
    end else if (init)
	  board[x_start][y_start] <= 1'h1;	// mark starting position
    else if (backup)
	  board[xx][yy] <= 1'h0;			// mark as unvisited
	else if (update_position)
	  board[xx + off_x(move_try)][yy + off_y(move_try)] <= 1'h1;	// mark as visited
   end


  // move try register
  always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        move_try <= 'b0;
    end else if(init_move_try) begin
        move_try <= 1'b1;
    end else if(shift_move_try) begin // increments move_try by 1
        move_try <= move_try << 1;
    end else if(backup) begin // move was tried, revert to last move
        $display(last_move[move_num-1]);
        move_try <= last_move[move_num-1] << 1;
    end
  end
  
  // Updates Knight's position
  always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        xx <= 'b0;
        yy <= 'b0;
    end else if(init) begin
        xx <= x_start;
        yy <= y_start;
    end else if(update_position) begin
        xx <= xx + off_x(move_try);
        yy <= yy + off_y(move_try);
    end else if(backup) begin
        xx <= xx - off_x(last_move[move_num-1]);
        yy <= yy - off_y(last_move[move_num-1]);
    end
  end

  // Move counter tracking
  always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        move_num <= 'b0;
    end else if(init) begin
        move_num <= 5'h1;
    end else if(update_position) begin
        move_num <= move_num + 1;
    end else if(backup) begin
        move_num <= move_num - 1;
    end
  end
  
  // Used for position logging
  always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        integer i;
        for(i = 0; i < 24; i = i + 1) begin
            last_move[i] <= 'b0;
        end
    end else if(zero) begin // reseting board to all zeros 
        integer i;
        for(i = 0; i < 24; i = i + 1) begin
            last_move[i] <= 'b0;
        end
    end else if(update_position) begin // Updates last move to reset to later
        last_move[move_num] <= move_try;
    end else if(backup) begin // Reset to last move (incomplete)
        last_move[move_num] <= 'b0;
    end
  end
 // State declaration
 typedef enum reg[2:0] {IDLE, INIT, POSSIBLE, MAKE_MOVE, BACKUP} state_t;
 state_t state, next_state;
 // State transition logic
 always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
 end
        integer i;

    //realized we dont need this because we only need the current possible moves of the current move and storing the possible moves for the previous moves
    //does not help us in any way because we have to recompute the possible moves every single time after we make a move.

 /*always @(posedge clk, negedge rst_n) begin
    if(!rst_n ) begin
        for(i = 0; i < 24; i = i + 1) begin
           poss_moves[i] <= 'b0;
        end
    end else if (zero) begin
        for(i = 0; i < 24; i = i + 1) begin
            poss_moves[i] <= 'b0;
        end
    end else begin
        poss_moves[move_num] <= poss_moves_cur;
    end
 end*/

 // Logic to send out done sig
 always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        done <= 1'b0;
    end else if(set_done) begin
        done <= 1'b1;
    end else if(go) begin
        done <= 1'b0;
    end
 end

  // State transition logic

always_comb begin
    next_state = state;
    zero = 0;
    init = 0;
    backup = 0;
    update_position = 0;
    set_possible = 1'b0;
    init_move_try = 1'b0;
    shift_move_try = 1'b0;
	set_done = 1'b0;
    case(state)
        IDLE: begin
            if(go) begin
                // $display("INIT! GO!");
                next_state = INIT;
                zero = 1;
            end
        end
        INIT: begin // first move
            init = 1;
            next_state = POSSIBLE;
        end
        POSSIBLE: begin // Still moves left to take and repeat MAKE_MOVE state
            // $display("POSSIBLE!");
            set_possible = 1'b1;
            init_move_try = 1'b1;
            next_state = MAKE_MOVE;
        end
        MAKE_MOVE: begin
            // $display("Try move: %b", move_try);
			//if(move_num) begin
			//	$display("IMPORTANT: %b %b", poss_moves[move_num], move_try);
			//end
            if((poss_moves_cur & move_try) &&
            board[xx + off_x(move_try)][yy + off_y(move_try)] == 0) begin // Checks if next move is legal
                update_position = 1'b1;
                $display("Move %0d: %b", move_num, move_try);
                if(move_num == 24) begin // If finished finding solution, return to IDLE state
                    next_state = IDLE;
                    set_done = 1'b1;
                end else begin
                    // Still have more moves to try
                    next_state = POSSIBLE;
                end    
            end else if (move_try != 8'h80) begin // all moves tried, resetting counter
                shift_move_try = 1'b1;
            end else begin 
                $display("NEED TO BACK UP! STALLED!");
                next_state = BACKUP;
            end
        end
        BACKUP: begin
            backup = 1;
            if(move_num == 1) begin
                //Tried all moves from starting position
                next_state = IDLE;
                set_done = 1'b1;
            end else if(last_move[move_num-1] != 8'h80) begin // revert a move if the last move made is not 24th move
                next_state = MAKE_MOVE;
            end
        end
    endcase
end










































































  function [7:0] calc_poss(input [2:0] xpos, ypos);
    logic [7:0] poss;
    integer i;
    logic signed [3:0] new_x, new_y, current_off_x, current_off_y;
    begin
        poss = 8'b0;

        for (i = 0; i < 8; i++) begin // should maybe start from last_move?
            // Call off_x and off_y
            current_off_x = off_x(8'b1 << i);
            current_off_y = off_y(8'b1 << i);

            // Compute new positions
            new_x = xpos + current_off_x;
            new_y = ypos + current_off_y;

            // Debug all relevant values
            // $display("DEBUG: Move %0d -> xpos: %0d, ypos: %0d, off_x: %0d, off_y: %0d, new_x: %0d, new_y: %0d", 
                    //  i, xpos, ypos, current_off_x, current_off_y, new_x, new_y);

            // Check bounds and unvisited condition
            if (new_x >= 0 && new_x < 5 && new_y >= 0 && new_y < 5) begin
                poss[i] = 1'b1;
            end
        end

        // Debug final possible moves
// $display("DEBUG: calc_poss -> move_num: %0d, xpos: %0d, ypos: %0d, possible_moves: %b", move_num, xpos, ypos, poss);
        
        calc_poss = poss;
    end
endfunction


  
  function signed [2:0] off_x(input [7:0] try);
    ///////////////////////////////////////////////////
	// Consider writing a function that returns a the x-offset
	// the Knight will move given the encoding of the move you
	// are going to try.  Can also be useful when backing up
	// by passing in last move you did try, and subtracting 
	// the resulting offset from xx
	/////////////////////////////////////////////////////
   begin
        case (try)
            8'b00000001: off_x = 1;  // Move 1 in X, 2 in Y
            8'b00000010: off_x = -1; // Move -1 in X, 2 in Y
            8'b00000100: off_x = -2; // Move -2 in X, 1 in Y
            8'b00001000: off_x = -2; // Move -2 in X, -1 in Y
            8'b00010000: off_x = -1; // Move -1 in X, -2 in Y
            8'b00100000: off_x = 1;  // Move 1 in X, -2 in Y
            8'b01000000: off_x = 2;  // Move 2 in X, -1 in Y
            8'b10000000: off_x = 2;  // Move 2 in X, 1 in Y
            default: off_x = 0;      // Invalid move
        endcase
    end
  endfunction
  
  function signed [2:0] off_y(input [7:0] try);
    ///////////////////////////////////////////////////
	// Consider writing a function that returns a the y-offset
	// the Knight will move given the encoding of the move you
	// are going to try.  Can also be useful when backing up
	// by passing in last move you did try, and subtracting 
	// the resulting offset from yy
	/////////////////////////////////////////////////////
    begin
        case (try)
            8'b00000001: off_y = 2;  // Move 1 in X, 2 in Y
            8'b00000010: off_y = 2;  // Move -1 in X, 2 in Y
            8'b00000100: off_y = 1;  // Move -2 in X, 1 in Y
            8'b00001000: off_y = -1; // Move -2 in X, -1 in Y
            8'b00010000: off_y = -2; // Move -1 in X, -2 in Y
            8'b00100000: off_y = -2; // Move 1 in X, -2 in Y
            8'b01000000: off_y = -1; // Move 2 in X, -1 in Y
            8'b10000000: off_y = 1;  // Move 2 in X, 1 in Y
            default: off_y = 0;      // Invalid move
        endcase
    end
  endfunction
  
endmodule
