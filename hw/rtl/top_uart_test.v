`timescale 1ns / 1ps
`default_nettype none

// -----------------------------------------------------------------------------
// Module      : top_uart_test
// Description : Hardware test for uart_tx. Pressing btnC sends the byte set on
//               sw[7:0] to the PC over the USB-UART (115200 8N1).
//               btnC path: 2-FF synchronizer -> 10 ms debouncer -> edge detector.
// -----------------------------------------------------------------------------

module top_uart_test (
    input  wire       clk,
    input  wire       btnC,
    input  wire [7:0] sw,
    output wire       RsTx,       // FPGA -> PC serial line
    output wire [1:0] led
);

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------
    localparam integer CLK_FREQ        = 100_000_000;
    localparam integer DEBOUNCE_MS     = 10;
    localparam integer DEBOUNCE_CYCLES = CLK_FREQ / 1000 * DEBOUNCE_MS;   // 1_000_000
    localparam integer DB_CNT_W        = $clog2(DEBOUNCE_CYCLES);         // 20

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
    // 2) Debouncer: accept a new level only after it is stable for 10 ms
    // -------------------------------------------------------------------------
    reg [DB_CNT_W-1:0] db_cnt = 0;
    reg                btn_db = 1'b0;

    always @(posedge clk) begin
        if (btn_sync == btn_db) begin
            db_cnt <= 0;                          // stable: restart the count
        end else if (db_cnt == DEBOUNCE_CYCLES - 1) begin
            db_cnt <= 0;
            btn_db <= btn_sync;                   // stable for 10 ms: accept
        end else begin
            db_cnt <= db_cnt + 1;                 // different: keep counting
        end
    end

    // -------------------------------------------------------------------------
    // 3) Rising-edge detector -> one-cycle pulse
    // -------------------------------------------------------------------------
    reg  btn_prev = 1'b0;
    wire btn_pulse;

    always @(posedge clk) begin
        btn_prev <= btn_db;
    end

    assign btn_pulse = btn_db & ~btn_prev;

    // -------------------------------------------------------------------------
    // 4) UART transmitter
    // -------------------------------------------------------------------------
    wire tx_busy;

    uart_tx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (115_200)
    ) u_tx (
        .clk      (clk),
        .rst      (1'b0),
        .tx_start (btn_pulse),
        .tx_data  (sw),
        .tx       (RsTx),
        .tx_busy  (tx_busy)
    );

    // -------------------------------------------------------------------------
    // 5) Debug LEDs
    // -------------------------------------------------------------------------
    assign led[0] = btn_db;     // debounced button
    assign led[1] = tx_busy;    // high for ~87 us per byte (too short to see)

endmodule

`default_nettype wire