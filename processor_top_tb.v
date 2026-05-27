`timescale 1ns/1ps

module processor_top_tb;

    reg clk;
    reg reset;
    integer cycle_count;

    wire [15:0] r0_out;
    wire [15:0] r1_out;
    wire [15:0] r2_out;
    wire [15:0] bus_out;
    wire [15:0] mem_debug_out;
    wire [7:0]  pc_out;

    processor_top dut (
        .clk(clk),
        .reset(reset),

        .r0_out(r0_out),
        .r1_out(r1_out),
        .r2_out(r2_out),
        .bus_out(bus_out),
        .mem_debug_out(mem_debug_out),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    initial begin
        cycle_count = 0;
        $display("Cycle | valid | fetch_pc | execute_pc | execute_instruction | opcode | R0     | R1     | R2");
        $display("------+-------+----------+------------+---------------------+--------+--------+--------+-------");
    end

    always @(posedge clk) begin
        #1;
        cycle_count = cycle_count + 1;
        $display("%5d |   %b   |   %3d    |    %3d     |      0x%h      | 0x%h    | 0x%h | 0x%h | 0x%h",
                 cycle_count,
                 dut.pipeline_valid,
                 dut.fetch_pc,
                 dut.execute_pc,
                 dut.execute_instruction,
                 dut.opcode,
                 r0_out,
                 r1_out,
                 r2_out);
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;

        $dumpfile("processor_top_tb.vcd");
        $dumpvars(0, processor_top_tb);

        // reset for two clock cycles
        @(posedge clk);
        @(posedge clk);
        reset = 1'b0;

        // Wait enough cycles for the program to finish.
        // Some instructions take 1 cycle, arithmetic instructions take 3 cycles.
        repeat (60) @(posedge clk);

        $display("PC = %d", pc_out);
        $display("Final R0 = %d (0x%h)", r0_out, r0_out);
        $display("Final R1 = %d (0x%h)", r1_out, r1_out);
        $display("Final R2 = %d (0x%h)", r2_out, r2_out);
        $display("data_mem[10] = %d", mem_debug_out);

        if (r0_out == 16'h0406 &&
            r1_out == 16'd3 &&
            r2_out == 16'd8 &&
            mem_debug_out == 16'd8) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $stop;
    end

endmodule
