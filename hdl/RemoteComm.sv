`default_nettype none

module RemoteComm_e (
    input wire clk,
    input wire rst_n,
    input wire send_cmd,
    input wire [15:0] cmd,
    input wire RX,


    output logic TX,
    output logic [7:0] resp,
    output logic cmd_sent,
    output logic resp_rdy
);

    // Internal signals
    logic [7:0] upper_byte, lower_byte;
    logic trmt;
    logic [1:0] state, next_state;
    logic clr_rx_rdy;
    logic [7:0] tx_data;
    logic tx_done;
    logic set_cmd_snt;

    // State encoding
    typedef enum logic [1:0] {
        IDLE,
        UPPER_BYTE,
        LOWER_BYTE
    } state_t;

    // Assign bytes from command
    assign upper_byte = cmd[15:8];
    assign lower_byte = cmd[7:0];

    // Instantiate UART module
    UART uart (
        .clk(clk),
        .rst_n(rst_n),
        .RX(RX),
        .TX(TX),
        .rx_rdy(resp_rdy),
        .clr_rx_rdy(clr_rx_rdy),
        .rx_data(resp),
        .trmt(trmt),
        .tx_data(tx_data),
        .tx_done(tx_done)
    );

    // State machine for sending two bytes
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        trmt = 0;
        set_cmd_snt = 0;

        case (state)
            IDLE: begin
                if (send_cmd) begin
                    next_state = UPPER_BYTE;
                    tx_data = upper_byte;
                    trmt = 1;
                end
            end
            UPPER_BYTE: begin
                if (tx_done) begin
                    next_state = LOWER_BYTE;
                    tx_data = lower_byte;
                    trmt = 1;
                end
            end
            LOWER_BYTE: begin
                if (tx_done) begin
                    next_state = IDLE;
                    set_cmd_snt = 1;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Set cmd_snt signal after sending all bytes
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            cmd_sent <= 1'b0;
        end else if (set_cmd_snt) begin
            cmd_sent <= 1'b1;
        end else if (send_cmd) begin
            cmd_sent <= 1'b0;
        end
    end

endmodule

`default_nettype wire