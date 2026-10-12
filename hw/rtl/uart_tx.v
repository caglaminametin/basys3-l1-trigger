`timescale 1ns / 1ps
`default_nettype none

// -----------------------------------------------------------------------------
// Module      : uart_tx
// Description : UART transmitter, 8N1, LSB first.
//               Latches tx_data on tx_start and shifts it out on tx.
// -----------------------------------------------------------------------------

module uart_tx #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       rst,        // synchronous, active high
    input  wire       tx_start,   // one-cycle pulse: start sending tx_data
    input  wire [7:0] tx_data,
    output reg        tx,         // serial output
    output wire       tx_busy     // high while a frame is being sent
);

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;   // 868 @ 100 MHz
    localparam integer CNT_W        = $clog2(CLKS_PER_BIT);

    localparam [1:0] S_IDLE  = 2'd0,
                     S_START = 2'd1,
                     S_DATA  = 2'd2,
                     S_STOP  = 2'd3;

    // -------------------------------------------------------------------------
    // Registers
    // -------------------------------------------------------------------------
    reg [1:0]       state   = S_IDLE;
    reg [CNT_W-1:0] clk_cnt = 0;       // clock cycles inside one bit
    reg [2:0]       bit_idx = 0;       // data bit being sent (0..7)
    reg [7:0]       shreg   = 8'd0;    // latched copy of tx_data

    assign tx_busy = (state != S_IDLE);

    // -------------------------------------------------------------------------
    // FSM
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state   <= S_IDLE;
            clk_cnt <= 0;
            bit_idx <= 0;
            shreg   <= 8'd0;
            tx      <= 1'b1;           // line idles high
        end else begin
            case (state)

                S_IDLE: begin
                    tx <= 1'b1;
                    if (tx_start) begin
                        shreg   <= tx_data;
                        clk_cnt <= 0;
                        state   <= S_START;
                    end
                end

                S_START: begin
                    tx <= 1'b0;                        // start bit
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        bit_idx <= 0;
                        state   <= S_DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_DATA: begin
                    tx <= shreg[0];                    // LSB first
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        shreg   <= shreg >> 1;
                        if (bit_idx == 7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_STOP: begin
                    tx <= 1'b1;                        // stop bit
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire