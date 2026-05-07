`timescale 1ns/1ps

module processor_top_tb;

    reg clk;
    reg reset;
    reg [23:0] instruction;

    wire done;
    wire [15:0] r0_out;
    wire [15:0] r1_out;
    wire [15:0] r2_out;
    wire [15:0] bus_out;

    localparam OP_LDI = 4'b0001;
    localparam OP_MOV = 4'b0010;
    localparam OP_ADD = 4'b0011;
    localparam OP_SUB = 4'b0100;

    processor_top dut (
        .clk(clk),
        .reset(reset),
        .instruction(instruction),

        .done(done),
        .r0_out(r0_out),
        .r1_out(r1_out),
        .r2_out(r2_out),
        .bus_out(bus_out)
    );

    always #5 clk = ~clk;

    task run_instruction;
        input [23:0] instr;
        begin
            instruction = instr;

            @(posedge clk);
            while (done == 1'b0) begin
                @(posedge clk);
            end

            #1;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        instruction = 24'd0;

        // reset  clock
        @(posedge clk);
        @(posedge clk);
        reset = 1'b0;

        // LDI R0, 5
        run_instruction({OP_LDI, 2'b00, 2'b00, 16'd5});

        // LDI R1, 3
        run_instruction({OP_LDI, 2'b01, 2'b00, 16'd3});

        // ADD R0, R1
        // R0 = 5 + 3 = 8
        run_instruction({OP_ADD, 2'b00, 2'b01, 16'd0});

        // MOV R2, R0
        // R2 = 8
        run_instruction({OP_MOV, 2'b10, 2'b00, 16'd0});

        // SUB R2, R1
        // R2 = 8 - 3 = 5
        run_instruction({OP_SUB, 2'b10, 2'b01, 16'd0});

        $display("Final R0 = %d", r0_out);
        $display("Final R1 = %d", r1_out);
        $display("Final R2 = %d", r2_out);

        if (r0_out == 16'd8 && r1_out == 16'd3 && r2_out == 16'd5)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");

        $stop;
    end

endmodule