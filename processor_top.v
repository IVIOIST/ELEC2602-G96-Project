module processor_top (
    input  wire        clk,
    input  wire        reset,

    output wire        done,
    output wire        halted,
    output wire [15:0] r0_out,
    output wire [15:0] r1_out,
    output wire [15:0] r2_out,
    output wire [15:0] r3_out,
    output wire [15:0] bus_out,
    output wire [7:0]  pc_out,
    output wire [23:0] instruction_out
);

    localparam PC_WIDTH     = 8;
    localparam INSTR_WIDTH  = 24;
    localparam IMEM_DEPTH   = 256;

    localparam OP_NOP   = 4'h0;
    localparam OP_LDI   = 4'h1;
    localparam OP_MOV   = 4'h2;
    localparam OP_ADD   = 4'h3;
    localparam OP_SUB   = 4'h4;
    localparam OP_MUL   = 4'h5;
    localparam OP_INC   = 4'h6;
    localparam OP_DEC   = 4'h7;
    localparam OP_LOAD  = 4'h8;
    localparam OP_STORE = 4'h9;
    localparam OP_JMP   = 4'hA;
    localparam OP_JREL  = 4'hB;
    localparam OP_BEQ   = 4'hC;
    localparam OP_BNE   = 4'hD;
    localparam OP_HALT  = 4'hF;

    localparam PC_NEXT     = 2'd0;
    localparam PC_ABSOLUTE = 2'd1;
    localparam PC_RELATIVE = 2'd2;

    reg [PC_WIDTH-1:0]    pc;
    reg [INSTR_WIDTH-1:0] instruction;
    reg [INSTR_WIDTH-1:0] instruction_memory [0:IMEM_DEPTH-1];

    wire [3:0]  opcode;
    wire [1:0]  rx;
    wire [1:0]  ry;
    wire [15:0] imm;

    wire immout;
    wire rxout;
    wire ryout;
    wire gout;
    wire memout;

    wire ain;
    wire gin;
    wire rxin;
    wire memwrite;

    wire [2:0] alu_op;
    wire       equal;

    wire       ir_load;
    wire       pc_write;
    wire [1:0] pc_src;

    wire signed [15:0] pc_signed;
    wire signed [15:0] pc_relative_target;

    integer i;

    assign opcode = instruction[23:20];
    assign rx     = instruction[19:18];
    assign ry     = instruction[17:16];
    assign imm    = instruction[15:0];

    assign pc_out          = pc;
    assign instruction_out = instruction;

    assign pc_signed          = {8'd0, pc};
    assign pc_relative_target = pc_signed + $signed(imm);

    initial begin
        for (i = 0; i < IMEM_DEPTH; i = i + 1)
            instruction_memory[i] = {OP_HALT, 20'd0};

        instruction_memory[0]  = {OP_LDI,   2'b00, 2'b00, 16'd5};      // R0 = 5
        instruction_memory[1]  = {OP_LDI,   2'b01, 2'b00, 16'd3};      // R1 = 3
        instruction_memory[2]  = {OP_ADD,   2'b00, 2'b01, 16'd0};      // R0 = 8
        instruction_memory[3]  = {OP_SUB,   2'b00, 2'b01, 16'd0};      // R0 = 5
        instruction_memory[4]  = {OP_INC,   2'b00, 2'b00, 16'd0};      // R0 = 6
        instruction_memory[5]  = {OP_DEC,   2'b01, 2'b00, 16'd0};      // R1 = 2
        instruction_memory[6]  = {OP_LDI,   2'b10, 2'b00, 16'd4};      // R2 = 4
        instruction_memory[7]  = {OP_MUL,   2'b10, 2'b00, 16'd0};      // R2 = 24
        instruction_memory[8]  = {OP_STORE, 2'b00, 2'b00, 16'd10};     // MEM[10] = R0
        instruction_memory[9]  = {OP_LOAD,  2'b11, 2'b00, 16'd10};     // R3 = MEM[10]
        instruction_memory[10] = {OP_BEQ,   2'b00, 2'b11, 16'd2};      // If R0 == R3, PC = PC + 2
        instruction_memory[11] = {OP_LDI,   2'b10, 2'b00, 16'd999};    // Skipped when branch works
        instruction_memory[12] = {OP_JREL,  2'b00, 2'b00, 16'd2};      // PC = PC + 2
        instruction_memory[13] = {OP_LDI,   2'b10, 2'b00, 16'd555};    // Skipped by relative jump
        instruction_memory[14] = {OP_MOV,   2'b01, 2'b00, 16'd0};      // R1 = R0 = 6
        instruction_memory[15] = {OP_BNE,   2'b01, 2'b11, 16'd2};      // Not taken because R1 == R3
        instruction_memory[16] = {OP_JMP,   2'b00, 2'b00, 16'd18};     // Absolute jump to HALT
        instruction_memory[17] = {OP_LDI,   2'b10, 2'b00, 16'd777};    // Skipped by absolute jump
        instruction_memory[18] = {OP_HALT,  2'b00, 2'b00, 16'd0};
    end

    always @(posedge clk) begin
        if (reset) begin
            pc          <= {PC_WIDTH{1'b0}};
            instruction <= {OP_NOP, 20'd0};
        end else begin
            if (ir_load)
                instruction <= instruction_memory[pc];

            if (pc_write) begin
                case (pc_src)
                    PC_NEXT:     pc <= pc + {{(PC_WIDTH-1){1'b0}}, 1'b1};
                    PC_ABSOLUTE: pc <= imm[PC_WIDTH-1:0];
                    PC_RELATIVE: pc <= pc_relative_target[PC_WIDTH-1:0];
                    default:     pc <= pc;
                endcase
            end
        end
    end

    processor_controller controller_inst (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .equal(equal),

        .immout(immout),
        .rxout(rxout),
        .ryout(ryout),
        .gout(gout),
        .memout(memout),

        .ain(ain),
        .gin(gin),
        .rxin(rxin),
        .memwrite(memwrite),

        .alu_op(alu_op),
        .ir_load(ir_load),
        .pc_write(pc_write),
        .pc_src(pc_src),

        .done(done),
        .halted(halted)
    );

    processor_datapath datapath_inst (
        .clk(clk),
        .reset(reset),

        .imm(imm),
        .rx(rx),
        .ry(ry),

        .immout(immout),
        .rxout(rxout),
        .ryout(ryout),
        .gout(gout),
        .memout(memout),

        .ain(ain),
        .gin(gin),
        .rxin(rxin),
        .memwrite(memwrite),

        .alu_op(alu_op),

        .equal(equal),
        .r0_out(r0_out),
        .r1_out(r1_out),
        .r2_out(r2_out),
        .r3_out(r3_out),
        .bus_out(bus_out)
    );

endmodule
