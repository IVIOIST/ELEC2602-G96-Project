module processor_controller (
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] opcode,

    output reg        immout,
    output reg        rxout,
    output reg        ryout,
    output reg        gout,

    output reg        ain,
    output reg        gin,
    output reg        rxin,

    output reg        alu_sub,
    output reg        done
);

    localparam OP_LDI = 4'b0001;
    localparam OP_MOV = 4'b0010;
    localparam OP_ADD = 4'b0011;
    localparam OP_SUB = 4'b0100;

    localparam S0 = 2'd0;
    localparam S1 = 2'd1;
    localparam S2 = 2'd2;

    reg [1:0] state;
    reg [1:0] next_state;

    always @(posedge clk) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)

            S0: begin
                if (opcode == OP_ADD || opcode == OP_SUB)
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

    always @(*) begin
        immout = 1'b0;
        rxout  = 1'b0;
        ryout  = 1'b0;
        gout   = 1'b0;

        ain    = 1'b0;
        gin    = 1'b0;
        rxin   = 1'b0;

        alu_sub = 1'b0;
        done    = 1'b0;

        case (opcode)

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
                    ryout   = 1'b1;
                    gin     = 1'b1;
                    alu_sub = 1'b0;
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
                    ryout   = 1'b1;
                    gin     = 1'b1;
                    alu_sub = 1'b1;
                end else if (state == S2) begin
                    gout = 1'b1;
                    rxin = 1'b1;
                    done = 1'b1;
                end
            end

            default: begin
                done = 1'b1;
            end

        endcase
    end

endmodule