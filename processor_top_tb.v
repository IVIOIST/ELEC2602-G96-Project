`timescale 1ns/1ps

// Testbench for the self-contained processor.
//
// The testbench does not drive instructions. It only provides clk/reset, then
// waits for the hardcoded ROM program inside processor_top to reach HALT.
module processor_top_tb;

    reg clk;
    reg reset;

    // Debug outputs from the processor. These are the same kinds of signals
    // that can be routed to switches/LEDs/seven-segment display logic on FPGA.
    wire done;
    wire halted;
    wire [15:0] r0_out;
    wire [15:0] r1_out;
    wire [15:0] r2_out;
    wire [15:0] r3_out;
    wire [15:0] bus_out;
    wire [7:0]  pc_out;
    wire [23:0] instruction_out;

    integer cycle_count;

    // Device under test. Notice there is no instruction input: the CPU fetches
    // instructions from its own internal ROM.
    processor_top dut (
        .clk(clk),
        .reset(reset),

        .done(done),
        .halted(halted),
        .r0_out(r0_out),
        .r1_out(r1_out),
        .r2_out(r2_out),
        .r3_out(r3_out),
        .bus_out(bus_out),
        .pc_out(pc_out),
        .instruction_out(instruction_out)
    );

    // 100 MHz-equivalent simulation clock period of 10 ns.
    always #5 clk = ~clk;

    initial begin
        // Start in reset so PC, instruction register, and data registers are known.
        clk = 1'b0;
        reset = 1'b1;
        cycle_count = 0;

        // Hold reset for two rising edges, then release the processor.
        @(posedge clk);
        @(posedge clk);
        reset = 1'b0;

        // Let the internal program run until HALT or until the timeout prevents
        // an infinite simulation if the control flow is broken.
        while (halted == 1'b0 && cycle_count < 200) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        // Print final architectural state for debugging.
        $display("Final R0 = %d", r0_out);
        $display("Final R1 = %d", r1_out);
        $display("Final R2 = %d", r2_out);
        $display("Final R3 = %d", r3_out);
        $display("Final PC = %d", pc_out);
        $display("Cycles   = %d", cycle_count);

        // Expected final state of the ROM program:
        // R0 = 6 after ADD/SUB/INC
        // R1 = 6 after MOV R1, R0
        // R2 = 24 after MUL, proving skipped instructions did not overwrite it
        // R3 = 6 after LOAD from data memory address 10
        if (halted == 1'b1 &&
            r0_out == 16'd6 &&
            r1_out == 16'd6 &&
            r2_out == 16'd24 &&
            r3_out == 16'd6)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");

        $finish;
    end

endmodule
