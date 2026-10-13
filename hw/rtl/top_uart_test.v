`timescale 1ns / 1ps
`default_nettype none

// -----------------------------------------------------------------------------
// Module      : top_uart_test
// Description : Hardware test for uart_tx. Pressing btnC sends the byte set on
//               sw[7:0] to the PC over the USB-UART (115200 8N1).
// -----------------------------------------------------------------------------

module top_uart_test (
    input  wire       clk,
    input  wire       btnC,
    input  wire [7:0] sw,
    output wire       RsTx,       // FPGA -> PC serial line
    output wire [1:0] led
);

    // -------------------------------------------------------------------------
    // 1) 2-FF synchronizer for btnC
    // -------------------------------------------------------------------------
    reg btn_meta = 1'b0;
    reg btn_sync = 1'b0;

    always @(posedge clk) begin
        btn_meta <= btnC;
        btn_sync <= btn_meta;
    end

    // -------------------------------------------------------------------------
    // 2) Rising-edge detector -> one-cycle pulse
    // -------------------------------------------------------------------------
    reg  btn_prev = 1'b0;
    wire btn_pulse;

    always @(posedge clk) begin
        btn_prev <= btn_sync;
    end

    assign btn_pulse = btn_sync & ~btn_prev;

    // -------------------------------------------------------------------------
    // 3) UART transmitter
    // -------------------------------------------------------------------------
    wire tx_busy;

    uart_tx u_tx (
        .clk      (clk),
        .rst      (1'b0),
        .tx_start (btn_pulse),
        .tx_data  (sw),
        .tx       (RsTx),
        .tx_busy  (tx_busy)
    );

    // -------------------------------------------------------------------------
    // 4) Debug LEDs
    // -------------------------------------------------------------------------
    assign led[0] = btn_sync;   // button as seen by the logic
    assign led[1] = tx_busy;    // high for ~87 us per byte (too short to see)

endmodule

`default_nettype wire