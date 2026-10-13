`timescale 1ns / 1ps
`default_nettype none

// -----------------------------------------------------------------------------
// Testbench   : tb_uart_tx
// Description : Sends one byte (0xA5) through uart_tx and lets us inspect
//               the serial waveform on tx.
// -----------------------------------------------------------------------------

module tb_uart_tx;          // no ports: the testbench is the outermost module

    // -------------------------------------------------------------------------
    // 1) Signals
    //    inputs of the DUT  -> reg  (the testbench drives them)
    //    outputs of the DUT -> wire (the DUT drives them)
    // -------------------------------------------------------------------------
    reg        clk      = 1'b0;
    reg        rst      = 1'b1;     // start in reset
    reg        tx_start = 1'b0;
    reg  [7:0] tx_data  = 8'h00;
    wire       tx;
    wire       tx_busy;

    // -------------------------------------------------------------------------
    // 2) Clock: 100 MHz (period 10 ns)
    // -------------------------------------------------------------------------
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // 3) Device under test
    // -------------------------------------------------------------------------
    uart_tx dut (
        .clk      (clk),
        .rst      (rst),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx       (tx),
        .tx_busy  (tx_busy)
    );

    // -------------------------------------------------------------------------
    // 4) Stimulus
    // -------------------------------------------------------------------------
initial begin
    repeat (5) @(posedge clk);    
    rst <= 0;                    

    @(posedge clk);
    tx_data <= 8'hA3;             

    tx_start <= 1'b1;             
    @(posedge clk);
    tx_start <= 1'b0;

    wait (tx_busy == 1);          
    wait (tx_busy == 0);         

    repeat (100) @(posedge clk);  

    $display("Simulation finished at %t", $time);
    $finish;
end

endmodule

`default_nettype wire