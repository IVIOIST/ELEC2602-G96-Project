`timescale 1ns/1ps

module processor_top_tb;

    reg clk;
    reg reset;

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

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        cycle_count = 0;

        @(posedge clk);
        @(posedge clk);
        reset = 1'b0;

        while (halted == 1'b0 && cycle_count < 200) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        $display("Final R0 = %d", r0_out);
        $display("Final R1 = %d", r1_out);
        $display("Final R2 = %d", r2_out);
        $display("Final R3 = %d", r3_out);
        $display("Final PC = %d", pc_out);
        $display("Cycles   = %d", cycle_count);

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
