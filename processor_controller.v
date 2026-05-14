module processor_controller (
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] opcode,
    input  wire       equal,

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
    output reg        ir_load,
    output reg        pc_write,
    output reg [1:0]  pc_src,

    output reg        done,
    output reg        halted
);

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

    localparam ALU_ADD = 3'd0;
    localparam ALU_SUB = 3'd1;
    localparam ALU_MUL = 3'd2;
    localparam ALU_INC = 3'd3;
    localparam ALU_DEC = 3'd4;

    localparam PC_NEXT     = 2'd0;
    localparam PC_ABSOLUTE = 2'd1;
    localparam PC_RELATIVE = 2'd2;

    localparam S_FETCH = 2'd0;
    localparam S_EXEC0 = 2'd1;
    localparam S_EXEC1 = 2'd2;
    localparam S_EXEC2 = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;

    wire is_arithmetic;

    assign is_arithmetic = (opcode == OP_ADD) ||
                           (opcode == OP_SUB) ||
                           (opcode == OP_MUL) ||
                           (opcode == OP_INC) ||
                           (opcode == OP_DEC);

    always @(posedge clk) begin
        if (reset)
            state <= S_FETCH;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)

            S_FETCH: begin
                next_state = S_EXEC0;
            end

            S_EXEC0: begin
                if (opcode == OP_HALT)
                    next_state = S_EXEC0;
                else if (is_arithmetic)
                    next_state = S_EXEC1;
                else
                    next_state = S_FETCH;
            end

            S_EXEC1: begin
                next_state = S_EXEC2;
            end

            S_EXEC2: begin
                next_state = S_FETCH;
            end

            default: begin
                next_state = S_FETCH;
            end

        endcase
    end

    always @(*) begin
        immout = 1'b0;
        rxout  = 1'b0;
        ryout  = 1'b0;
        gout   = 1'b0;
        memout = 1'b0;

        ain    = 1'b0;
        gin    = 1'b0;
        rxin   = 1'b0;
        memwrite = 1'b0;

        alu_op   = ALU_ADD;
        ir_load  = 1'b0;
        pc_write = 1'b0;
        pc_src   = PC_NEXT;

        done   = 1'b0;
        halted = 1'b0;

        case (state)

            S_FETCH: begin
                ir_load = 1'b1;
            end

            S_EXEC0: begin
                case (opcode)

                    OP_NOP: begin
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_LDI: begin
                        immout   = 1'b1;
                        rxin     = 1'b1;
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_MOV: begin
                        ryout    = 1'b1;
                        rxin     = 1'b1;
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_ADD, OP_SUB, OP_MUL, OP_INC, OP_DEC: begin
                        rxout = 1'b1;
                        ain   = 1'b1;
                    end

                    OP_LOAD: begin
                        memout   = 1'b1;
                        rxin     = 1'b1;
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_STORE: begin
                        rxout    = 1'b1;
                        memwrite = 1'b1;
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_JMP: begin
                        pc_write = 1'b1;
                        pc_src   = PC_ABSOLUTE;
                        done     = 1'b1;
                    end

                    OP_JREL: begin
                        pc_write = 1'b1;
                        pc_src   = PC_RELATIVE;
                        done     = 1'b1;
                    end

                    OP_BEQ: begin
                        pc_write = 1'b1;
                        pc_src   = equal ? PC_RELATIVE : PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_BNE: begin
                        pc_write = 1'b1;
                        pc_src   = equal ? PC_NEXT : PC_RELATIVE;
                        done     = 1'b1;
                    end

                    OP_HALT: begin
                        done   = 1'b1;
                        halted = 1'b1;
                    end

                    default: begin
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                endcase
            end

            S_EXEC1: begin
                ryout = (opcode == OP_INC || opcode == OP_DEC) ? 1'b0 : 1'b1;
                gin   = 1'b1;

                case (opcode)
                    OP_SUB:  alu_op = ALU_SUB;
                    OP_MUL:  alu_op = ALU_MUL;
                    OP_INC:  alu_op = ALU_INC;
                    OP_DEC:  alu_op = ALU_DEC;
                    default: alu_op = ALU_ADD;
                endcase
            end

            S_EXEC2: begin
                gout     = 1'b1;
                rxin     = 1'b1;
                pc_write = 1'b1;
                pc_src   = PC_NEXT;
                done     = 1'b1;
            end

            default: begin
                ir_load = 1'b1;
            end

        endcase
    end

endmodule
