// Processor controller.
//
// This is a small finite-state machine that turns the current opcode into
// datapath, PC, and instruction-register control signals. Simple instructions
// complete in one execute cycle. Arithmetic instructions use the classic
// multi-cycle A/G datapath sequence:
//   EXEC0: Rx -> bus -> A
//   EXEC1: Ry/bus and A -> ALU -> G
//   EXEC2: G -> bus -> Rx, then PC increments
module processor_controller (
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] opcode, // Opcode from the instruction register.
    input  wire       equal,  // Datapath comparison result used by BEQ/BNE.

    // Bus source enables.
    output reg        immout,
    output reg        rxout,
    output reg        ryout,
    output reg        gout,
    output reg        memout,

    // Datapath write/load enables.
    output reg        ain,
    output reg        gin,
    output reg        rxin,
    output reg        memwrite,

    // ALU and top-level sequencing controls.
    output reg [2:0]  alu_op,
    output reg        ir_load,
    output reg        pc_write,
    output reg [1:0]  pc_src,

    output reg        done,   // High for the cycle in which an instruction completes.
    output reg        halted  // High while HALT is active.
);

    // Instruction opcodes. These values must match processor_top.
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

    // ALU operation encodings. These values must match processor_datapath.
    localparam ALU_ADD = 3'd0;
    localparam ALU_SUB = 3'd1;
    localparam ALU_MUL = 3'd2;
    localparam ALU_INC = 3'd3;
    localparam ALU_DEC = 3'd4;

    // PC update choices used by processor_top.
    localparam PC_NEXT     = 2'd0;
    localparam PC_ABSOLUTE = 2'd1;
    localparam PC_RELATIVE = 2'd2;

    // FSM states:
    // S_FETCH loads instruction_memory[PC] into the instruction register.
    // S_EXEC0 handles one-cycle instructions or captures Rx into A.
    // S_EXEC1 performs the ALU operation into G.
    // S_EXEC2 writes G back to Rx and advances the PC.
    localparam S_FETCH = 2'd0;
    localparam S_EXEC0 = 2'd1;
    localparam S_EXEC1 = 2'd2;
    localparam S_EXEC2 = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;

    wire is_arithmetic;

    // Arithmetic instructions share the same three-cycle datapath sequence.
    assign is_arithmetic = (opcode == OP_ADD) ||
                           (opcode == OP_SUB) ||
                           (opcode == OP_MUL) ||
                           (opcode == OP_INC) ||
                           (opcode == OP_DEC);

    // State register.
    always @(posedge clk) begin
        if (reset)
            state <= S_FETCH;
        else
            state <= next_state;
    end

    // Next-state logic. HALT intentionally remains in S_EXEC0 forever so PC
    // and instruction stop changing after the program finishes.
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

    // Output/control logic. Defaults are inactive so each instruction only
    // asserts the controls it needs in its current state.
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
                // Fetch the instruction at the current PC. PC is not advanced
                // here; it advances only after the fetched instruction finishes.
                ir_load = 1'b1;
            end

            S_EXEC0: begin
                case (opcode)

                    OP_NOP: begin
                        // NOP does no datapath work and simply moves to PC + 1.
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_LDI: begin
                        // LDI Rx, imm: immediate -> bus -> Rx.
                        immout   = 1'b1;
                        rxin     = 1'b1;
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_MOV: begin
                        // MOV Rx, Ry: Ry -> bus -> Rx.
                        ryout    = 1'b1;
                        rxin     = 1'b1;
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_ADD, OP_SUB, OP_MUL, OP_INC, OP_DEC: begin
                        // First arithmetic cycle: save Rx as the left operand A.
                        rxout = 1'b1;
                        ain   = 1'b1;
                    end

                    OP_LOAD: begin
                        // LOAD Rx, [imm]: memory data -> bus -> Rx.
                        memout   = 1'b1;
                        rxin     = 1'b1;
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_STORE: begin
                        // STORE Rx, [imm]: Rx -> bus -> memory.
                        rxout    = 1'b1;
                        memwrite = 1'b1;
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_JMP: begin
                        // JMP imm: load PC with an absolute instruction address.
                        pc_write = 1'b1;
                        pc_src   = PC_ABSOLUTE;
                        done     = 1'b1;
                    end

                    OP_JREL: begin
                        // JREL imm: load PC with current PC + signed imm.
                        pc_write = 1'b1;
                        pc_src   = PC_RELATIVE;
                        done     = 1'b1;
                    end

                    OP_BEQ: begin
                        // BEQ Rx, Ry, imm: branch to PC + imm when Rx == Ry.
                        pc_write = 1'b1;
                        pc_src   = equal ? PC_RELATIVE : PC_NEXT;
                        done     = 1'b1;
                    end

                    OP_BNE: begin
                        // BNE Rx, Ry, imm: branch to PC + imm when Rx != Ry.
                        pc_write = 1'b1;
                        pc_src   = equal ? PC_NEXT : PC_RELATIVE;
                        done     = 1'b1;
                    end

                    OP_HALT: begin
                        // HALT completes every cycle but never writes PC.
                        done   = 1'b1;
                        halted = 1'b1;
                    end

                    default: begin
                        // Unknown opcodes are treated like NOP so execution can continue.
                        pc_write = 1'b1;
                        pc_src   = PC_NEXT;
                        done     = 1'b1;
                    end

                endcase
            end

            S_EXEC1: begin
                // Second arithmetic cycle: perform ALU operation and store it in G.
                // INC/DEC only need A, so Ry is not driven onto the bus for them.
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
                // Final arithmetic cycle: G -> bus -> Rx, then advance PC.
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
