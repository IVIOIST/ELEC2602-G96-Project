// Processor datapath.
//
// This module contains the values that the processor operates on: four general
// registers, two temporary ALU registers, a shared internal bus, the ALU, a
// comparator for branches, and direct-addressed data memory.
module processor_datapath (
    input  wire        clk,
    input  wire        reset,

    // Instruction fields decoded in processor_top.
    input  wire [15:0] imm,
    input  wire [1:0]  rx,
    input  wire [1:0]  ry,

    // Bus source controls. Exactly one should be asserted by the controller in
    // a given cycle so that the bus has one clear source.
    input  wire        immout,
    input  wire        rxout,
    input  wire        ryout,
    input  wire        gout,
    input  wire        memout,

    // Register and memory write controls.
    input  wire        ain,
    input  wire        gin,
    input  wire        rxin,
    input  wire        memwrite,

    // Selects which arithmetic operation the ALU performs.
    input  wire [2:0]  alu_op,

    output wire        equal,    // High when Rx and Ry currently hold the same value.
    output wire [15:0] r0_out,   // Register debug outputs for simulation/FPGA display.
    output wire [15:0] r1_out,
    output wire [15:0] r2_out,
    output wire [15:0] r3_out,
    output wire [15:0] bus_out   // Debug view of the shared bus.
);

    // Direct-addressed data memory uses the low 8 bits of imm, so addresses
    // 0 to 255 are valid for LOAD and STORE.
    localparam DATA_ADDR_WIDTH = 8;
    localparam DATA_DEPTH      = 256;

    // ALU operation encodings must match the controller.
    localparam ALU_ADD = 3'd0;
    localparam ALU_SUB = 3'd1;
    localparam ALU_MUL = 3'd2;
    localparam ALU_INC = 3'd3;
    localparam ALU_DEC = 3'd4;

    // Four 16-bit general-purpose registers. The 2-bit register fields select:
    // 00 = R0, 01 = R1, 10 = R2, 11 = R3.
    reg [15:0] R0;
    reg [15:0] R1;
    reg [15:0] R2;
    reg [15:0] R3;

    // A stores the first ALU operand. G stores the ALU result before it is
    // written back to Rx on the final arithmetic cycle.
    reg [15:0] A;
    reg [15:0] G;

    // Shared internal bus and data memory.
    reg [15:0] bus;
    reg [15:0] data_memory [0:DATA_DEPTH-1];

    // Selected register values and combinational ALU/memory outputs.
    wire [15:0] rx_value;
    wire [15:0] ry_value;
    wire [15:0] mem_value;
    wire [15:0] alu_result;

    integer i;

    assign r0_out  = R0;
    assign r1_out  = R1;
    assign r2_out  = R2;
    assign r3_out  = R3;
    assign bus_out = bus;
    assign equal   = (rx_value == ry_value);

    // Read ports for the small register file. These are combinational so the
    // controller can place Rx or Ry onto the bus in the same cycle.
    assign rx_value = (rx == 2'b00) ? R0 :
                      (rx == 2'b01) ? R1 :
                      (rx == 2'b10) ? R2 :
                                      R3;

    assign ry_value = (ry == 2'b00) ? R0 :
                      (ry == 2'b01) ? R1 :
                      (ry == 2'b10) ? R2 :
                                      R3;

    // LOAD reads directly from data memory at address imm[7:0].
    assign mem_value = data_memory[imm[DATA_ADDR_WIDTH-1:0]];

    // ALU is combinational. A is the left operand; bus is normally the right
    // operand for ADD/SUB/MUL. INC and DEC ignore the bus and operate on A.
    assign alu_result = (alu_op == ALU_SUB) ? (A - bus) :
                        (alu_op == ALU_MUL) ? (A * bus) :
                        (alu_op == ALU_INC) ? (A + 16'd1) :
                        (alu_op == ALU_DEC) ? (A - 16'd1) :
                                              (A + bus);

    // Initialize data memory to a known state for simulation and FPGA startup.
    initial begin
        for (i = 0; i < DATA_DEPTH; i = i + 1)
            data_memory[i] = 16'd0;
    end

    // Bus multiplexer. The controller selects which datapath value appears on
    // the bus for this cycle.
    always @(*) begin
        if (immout)
            bus = imm;
        else if (rxout)
            bus = rx_value;
        else if (ryout)
            bus = ry_value;
        else if (gout)
            bus = G;
        else if (memout)
            bus = mem_value;
        else
            bus = 16'd0;
    end

    // Sequential state updates. Values are sampled from the bus/ALU on the
    // rising edge when their corresponding load-enable signal is asserted.
    always @(posedge clk) begin
        if (reset) begin
            R0 <= 16'd0;
            R1 <= 16'd0;
            R2 <= 16'd0;
            R3 <= 16'd0;
            A  <= 16'd0;
            G  <= 16'd0;
        end else begin
            if (ain)
                A <= bus;

            if (gin)
                G <= alu_result;

            // rxin writes the current bus value into the register selected by Rx.
            if (rxin) begin
                case (rx)
                    2'b00: R0 <= bus;
                    2'b01: R1 <= bus;
                    2'b10: R2 <= bus;
                    2'b11: R3 <= bus;
                    default: ;
                endcase
            end

            // STORE writes the current bus value into data_memory[imm[7:0]].
            if (memwrite)
                data_memory[imm[DATA_ADDR_WIDTH-1:0]] <= bus;
        end
    end

endmodule
