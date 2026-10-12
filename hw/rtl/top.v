`timescale 1ns / 1ps
`default_nettype none

// -----------------------------------------------------------------------------
// Module      : top
// Project     : Basys 3 Mini L1 Trigger - Stage 0 (bring-up)
// Target      : Digilent Basys 3 (xc7a35tcpg236-1), 100 MHz clock
// Description : sw[14:0] drive led[14:0] directly.
//               led[15] blinks at 1 Hz (0.5 s on / 0.5 s off).
//               btnC (center button) resets the blink logic while pressed.
// -----------------------------------------------------------------------------

module top (
    input  wire        clk,     // 100 MHz board clock
    input  wire        btnC,    // center button, active high, asynchronous
    input  wire [15:0] sw,
    output wire [15:0] led
);

    // 0.5 s at 100 MHz = 50,000,000 cycles (counts 0 .. 49,999,999)
    localparam integer COUNT_MAX = 50_000_000 - 1;

    // -------------------------------------------------------------------------
    // 2-FF synchronizer for the asynchronous button input
    // -------------------------------------------------------------------------
    reg btn_meta = 1'b0;   // first stage: may go metastable
    reg btn_sync = 1'b0;   // second stage: safe to use in the design

    always @(posedge clk) begin
        btn_meta <= btnC;
        btn_sync <= btn_meta;
    end

    // -------------------------------------------------------------------------
    // Blink counter
    // -------------------------------------------------------------------------
    reg [25:0] counter = 26'd0;
    reg        blink   = 1'b0;

    always @(posedge clk) begin
        if (btn_sync) begin
            counter <= 26'd0;
            blink   <= 1'b0;
        end else if (counter >= COUNT_MAX) begin
            counter <= 26'd0;
            blink   <= ~blink;       // toggle every 0.5 s -> 1 Hz blink
        end else begin
            counter <= counter + 26'd1;
        end
    end

    // -------------------------------------------------------------------------
    // Outputs
    // -------------------------------------------------------------------------
    assign led[14:0] = sw[14:0];     // sw[15] intentionally unused
    assign led[15]   = blink;

endmodule

`default_nettype wire
