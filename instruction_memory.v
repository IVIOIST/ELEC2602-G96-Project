module instruction_memory (
    input  wire [7:0]  address,
    output reg  [23:0] instruction
);

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
    localparam OP_PADD  = 4'b1100;
    localparam OP_MAC   = 4'b1101;

    always @(*) begin
        case (address)

            // ------------------------------------------------------------
            // Program:
            //
            // R0 = 0
            // BZ R0, 4       because R0 == 0, jump to address 4
            // LDI R1, 99     skipped
            // JMP 5          skipped because BZ jumped over it
            //
            // address 4:
            // LDI R1, 3      executed
            //
            // address 5:
            // LDI R0, 5
            // ADD R0, R1     R0 = 8
            // INC R0         R0 = 9
            // DEC R0         R0 = 8
            // STORE R0, [10] data_mem[10] = 8
            // LOAD R2, [10]  R2 = 8
            // MUL R2, R1     R2 = 24
            // SUB R2, R1     R2 = 21
            //
            // JMP 15         jump over bad instruction
            // LDI R2, 99     skipped
            //
            // Advanced features:
            // PADD R0, R1    parallel byte add: 0102 + 0304 = 0406
            // MAC R2, R1     multiply accumulate: R2 = R2 + R2 * R1 = 8
            //
            // Final:
            // R0 = 0406 hex
            // R1 = 3
            // R2 = 8
            // data_mem[10] = 8
            // ------------------------------------------------------------

            8'd0:  instruction = {OP_LDI,   2'b00, 2'b00, 16'd0};   // LDI R0, 0
            8'd1:  instruction = {OP_BZ,    2'b00, 2'b00, 16'd4};   // if R0 == 0, PC = 4

            8'd2:  instruction = {OP_LDI,   2'b01, 2'b00, 16'd99};  // skipped
            8'd3:  instruction = {OP_JMP,   2'b00, 2'b00, 16'd5};   // skipped

            8'd4:  instruction = {OP_LDI,   2'b01, 2'b00, 16'd3};   // LDI R1, 3

            8'd5:  instruction = {OP_LDI,   2'b00, 2'b00, 16'd5};   // LDI R0, 5
            8'd6:  instruction = {OP_ADD,   2'b00, 2'b01, 16'd0};   // R0 = 8
            8'd7:  instruction = {OP_INC,   2'b00, 2'b00, 16'd0};   // R0 = 9
            8'd8:  instruction = {OP_DEC,   2'b00, 2'b00, 16'd0};   // R0 = 8

            8'd9:  instruction = {OP_STORE, 2'b00, 2'b00, 16'd10};  // data_mem[10] = R0 = 8
            8'd10: instruction = {OP_LOAD,  2'b10, 2'b00, 16'd10};  // R2 = data_mem[10] = 8

            8'd11: instruction = {OP_MUL,   2'b10, 2'b01, 16'd0};   // R2 = 8 * 3 = 24
            8'd12: instruction = {OP_SUB,   2'b10, 2'b01, 16'd0};   // R2 = 24 - 3 = 21

            8'd13: instruction = {OP_JMP,   2'b00, 2'b00, 16'd15};  // jump to 15
            8'd14: instruction = {OP_LDI,   2'b10, 2'b00, 16'd99};  // skipped

            8'd15: instruction = {OP_LDI,   2'b00, 2'b00, 16'h0102}; // R0 = 0102
            8'd16: instruction = {OP_LDI,   2'b01, 2'b00, 16'h0304}; // R1 = 0304
            8'd17: instruction = {OP_PADD,  2'b00, 2'b01, 16'd0};    // R0 = 0406

            8'd18: instruction = {OP_LDI,   2'b01, 2'b00, 16'd3};    // R1 = 3
            8'd19: instruction = {OP_LDI,   2'b10, 2'b00, 16'd2};    // R2 = 2
            8'd20: instruction = {OP_MAC,   2'b10, 2'b01, 16'd0};    // R2 = 2 + 2 * 3 = 8

            8'd21: instruction = {OP_NOP,   2'b00, 2'b00, 16'd0};

            default: instruction = {OP_NOP, 2'b00, 2'b00, 16'd0};

        endcase
    end

endmodule
