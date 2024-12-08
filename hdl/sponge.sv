module sponge (
    input logic clk,       // System clock, 50 MHz
    input logic rst_n,     // Active low reset
    input logic go,        // Signal to start playing the tune
    output logic piezo,    // Differential output for piezo
    output logic piezo_n   // Complementary differential output for piezo
);
    parameter FAST_SIM = 1; // Speed-up simulation when 1
    logic [5:0] DURATION_INCREMENT;

    // Frequencies in clock cycles for each note (for 50 MHz clock)
    localparam logic [15:0] FREQ_D7 = 50000000 / 2349;
    localparam logic [15:0] FREQ_E7 = 50000000 / 2637;
    localparam logic [15:0] FREQ_F7 = 50000000 / 2794;
    localparam logic [15:0] FREQ_A6 = 50000000 / 1760;

    // Note durations
    localparam logic [31:0] DURATION_NOTE1 = (1 << 23); // normal duration
    localparam logic [31:0] DURATION_NOTE2 = (1 << 22); // duration_NOTE1 + duration_Note2 will be the extended duration

    logic [15:0] CURR_FREQ;
    logic [23:0] duration_counter_next; // Next value for duration_counter
    logic [23:0] duration_counter;     // Current value of duration_counter

    // State definitions for each note in the tune
    typedef enum logic [3:0] {
        IDLE,
        PLAY_1D7,
        PLAY_1E7,
        PLAY_1F7,
        PLAY_2E7,
        PLAY_2F7,
        PLAY_2D7,
        PLAY_A6,
        PLAY_3D7,
        DONE
    } state_t;

    state_t state, next_state;
    logic [15:0] freq_counter;
    logic piezo_out;
    

    //we want to increase the duration incrmenet if fast sim is enabled
    generate
        if (FAST_SIM) begin
            assign DURATION_INCREMENT = 16;
        end else begin
            assign DURATION_INCREMENT = 1;
        end
    endgenerate

    // State machine to play tune
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            freq_counter <= 0;
            piezo_out <= 0;
            duration_counter <= 0; // Reset duration counter
        end else begin
            state <= next_state;

            // Frequency toggling logic
            if(state == IDLE) begin
            end else if (freq_counter == 0) begin
                piezo_out <= ~piezo_out;
                freq_counter <= CURR_FREQ; // Reload frequency counter
            end else begin
                freq_counter <= freq_counter - 1;
            end

            // Update duration_counter with the computed next value
            duration_counter <= duration_counter_next;
        end
    end

     



    // State Machine Logic
    always_comb begin
        next_state = state;
        CURR_FREQ = 0;
        duration_counter_next = duration_counter;

        case (state)
            IDLE: begin
                if (go) begin
                    next_state = PLAY_1D7;
                    duration_counter_next = DURATION_NOTE1;
                end
            end

            PLAY_1D7: begin
                CURR_FREQ = FREQ_D7;
                if (duration_counter > 0) begin
                    duration_counter_next = duration_counter - DURATION_INCREMENT; // duration incrmenet is determined by fast sim
                end else begin
                    next_state = PLAY_1E7;
                    duration_counter_next = DURATION_NOTE1;
                end
            end

            PLAY_1E7: begin
                CURR_FREQ = FREQ_E7;
                if (duration_counter > 0) begin
                    duration_counter_next = duration_counter - DURATION_INCREMENT; 
                end else begin
                    next_state = PLAY_1F7;
                    duration_counter_next = DURATION_NOTE1;
                end
            end

            PLAY_1F7: begin
                CURR_FREQ = FREQ_F7;
                if (duration_counter > 0) begin
                    duration_counter_next = duration_counter - DURATION_INCREMENT;
                end else begin
                    next_state = PLAY_2E7;
                    duration_counter_next = DURATION_NOTE1 + DURATION_NOTE2; //extended duration
                end
            end

            PLAY_2E7: begin
                CURR_FREQ = FREQ_E7;
                if (duration_counter > 0) begin
                    duration_counter_next = duration_counter - DURATION_INCREMENT;
                end else begin
                    next_state = PLAY_2F7;
                    duration_counter_next = DURATION_NOTE2;
                end
            end

            PLAY_2F7: begin
                CURR_FREQ = FREQ_F7;
                if (duration_counter > 0) begin
                    duration_counter_next = duration_counter - DURATION_INCREMENT;
                end else begin
                    next_state = PLAY_2D7;
                    duration_counter_next = DURATION_NOTE1 + DURATION_NOTE2;
                end
            end

            PLAY_2D7: begin
                CURR_FREQ = FREQ_D7;
                if (duration_counter > 0) begin
                    duration_counter_next = duration_counter - DURATION_INCREMENT;
                end else begin
                    next_state = PLAY_A6;
                    duration_counter_next = DURATION_NOTE2;
                end
            end

            PLAY_A6: begin
                CURR_FREQ = FREQ_A6;
                if (duration_counter > 0) begin
                    duration_counter_next = duration_counter - DURATION_INCREMENT;
                end else begin
                    next_state = PLAY_3D7;
                    duration_counter_next = DURATION_NOTE1;
                end
            end

            PLAY_3D7: begin
                CURR_FREQ = FREQ_D7;
                if (duration_counter > 0) begin
                    duration_counter_next = duration_counter - DURATION_INCREMENT;
                end else begin
                    next_state = DONE;
                end
            end

            DONE: begin
                next_state = IDLE;
                duration_counter_next = 0; // Reset duration counter
            end

            default: begin
                next_state = IDLE;
                duration_counter_next = 0;
            end
        endcase
    end

    // Assign outputs
    assign piezo = piezo_out;
    assign piezo_n = ~piezo_out;

endmodule
