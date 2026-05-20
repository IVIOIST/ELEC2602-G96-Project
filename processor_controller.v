module processor_controller (
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] opcode,

    output reg        immout,
    output reg        rxout,
    output reg        ryout,
    output reg        gout,
    output reg        memout,

    output reg        ain,
    output reg        gin,
    output reg        rxin,
    output reg        memwrite,

    output reg [2:0]  alu_op,

    output reg        jump,
    output reg        branch_zero,

    output reg        done
);

    // Instruction opcodes
    localparam OP_NOP   = 4'b0000;
    localparam OP_LDI   = 4'b0001;
    localparam OP_MOV   = 4'b0010;
    localparam OP_ADD   = 4'b0011;
    localparam OP_SUB   = 4'b0100;
    localparam OP_MUL   = 4'b0101;
    localparam OP_INC   = 4'b0110;
    localparam OP_DEC   = 4'b0111;
    localparam OP_LOAD  = 4'b1000;
    localparam OP_STORE = 4'b1001;
    localparam OP_JMP   = 4'b1010;
    localparam OP_BZ    = 4'b1011;

    // ALU operation codes
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_MUL = 3'b010;
    localparam ALU_INC = 3'b011;
    localparam ALU_DEC = 3'b100;

    // FSM states
    localparam S0 = 2'd0;
    localparam S1 = 2'd1;
    localparam S2 = 2'd2;

    reg [1:0] state;
    reg [1:0] next_state;

    // State register
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        case (state)

            S0: begin
                if (opcode == OP_ADD || opcode == OP_SUB || opcode == OP_MUL ||
                    opcode == OP_INC || opcode == OP_DEC)
                    next_state = S1;
                else
                    next_state = S0;
            end

            S1: begin
                next_state = S2;
            end

            S2: begin
                next_state = S0;
            end

            default: begin
                next_state = S0;
            end

        endcase
    end

    // Output control logic
    always @(*) begin
        // Default values
        immout      = 1'b0;
        rxout       = 1'b0;
        ryout       = 1'b0;
        gout        = 1'b0;
        memout      = 1'b0;

        ain         = 1'b0;
        gin         = 1'b0;
        rxin        = 1'b0;
        memwrite    = 1'b0;

        alu_op      = ALU_ADD;

        jump        = 1'b0;
        branch_zero = 1'b0;

        done        = 1'b0;

        case (opcode)

            OP_NOP: begin
                done = 1'b1;
            end

            OP_LDI: begin
                if (state == S0) begin
                    immout = 1'b1;
                    rxin   = 1'b1;
                    done   = 1'b1;
                end
            end

            OP_MOV: begin
                if (state == S0) begin
                    ryout = 1'b1;
                    rxin  = 1'b1;
                    done  = 1'b1;
                end
            end

            OP_ADD: begin
                if (state == S0) begin
                    rxout = 1'b1;
                    ain   = 1'b1;
                end else if (state == S1) begin
                    ryout  = 1'b1;
                    gin    = 1'b1;
                    alu_op = ALU_ADD;
                end else if (state == S2) begin
                    gout = 1'b1;
                    rxin = 1'b1;
                    done = 1'b1;
                end
            end

            OP_SUB: begin
                if (state == S0) begin
                    rxout = 1'b1;
                    ain   = 1'b1;
                end else if (state == S1) begin
                    ryout  = 1'b1;
                    gin    = 1'b1;
                    alu_op = ALU_SUB;
                end else if (state == S2) begin
                    gout = 1'b1;
                    rxin = 1'b1;
                    done = 1'b1;
                end
            end

            OP_MUL: begin
                if (state == S0) begin
                    rxout = 1'b1;
                    ain   = 1'b1;
                end else if (state == S1) begin
                    ryout  = 1'b1;
                    gin    = 1'b1;
                    alu_op = ALU_MUL;
                end else if (state == S2) begin
                    gout = 1'b1;
                    rxin = 1'b1;
                    done = 1'b1;
                end
            end

            OP_INC: begin
                if (state == S0) begin
                    rxout = 1'b1;
                    ain   = 1'b1;
                end else if (state == S1) begin
                    gin    = 1'b1;
                    alu_op = ALU_INC;
                end else if (state == S2) begin
                    gout = 1'b1;
                    rxin = 1'b1;
                    done = 1'b1;
                end
            end

            OP_DEC: begin
                if (state == S0) begin
                    rxout = 1'b1;
                    ain   = 1'b1;
                end else if (state == S1) begin
                    gin    = 1'b1;
                    alu_op = ALU_DEC;
                end else if (state == S2) begin
                    gout = 1'b1;
                    rxin = 1'b1;
                    done = 1'b1;
                end
            end

            OP_LOAD: begin
                if (state == S0) begin
                    memout = 1'b1;
                    rxin   = 1'b1;
                    done   = 1'b1;
                end
            end

            OP_STORE: begin
                if (state == S0) begin
                    rxout    = 1'b1;
                    memwrite = 1'b1;
                    done     = 1'b1;
                end
            end

            OP_JMP: begin
                if (state == S0) begin
                    jump = 1'b1;
                    done = 1'b1;
                end
            end

            OP_BZ: begin
                if (state == S0) begin
                    branch_zero = 1'b1;
                    done        = 1'b1;
                end
            end

            default: begin
                done = 1'b1;
            end

        endcase
    end

endmodule