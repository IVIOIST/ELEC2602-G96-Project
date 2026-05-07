module processor_top (
    input  wire        clk,
    input  wire        reset,
    input  wire [23:0] instruction,

    output wire        done,
    output wire [15:0] r0_out,
    output wire [15:0] r1_out,
    output wire [15:0] r2_out,
    output wire [15:0] bus_out
);

    wire [3:0]  opcode;
    wire [1:0]  rx;
    wire [1:0]  ry;
    wire [15:0] imm;

    wire immout;
    wire rxout;
    wire ryout;
    wire gout;

    wire ain;
    wire gin;
    wire rxin;

    wire alu_sub;

    assign opcode = instruction[23:20];
    assign rx     = instruction[19:18];
    assign ry     = instruction[17:16];
    assign imm    = instruction[15:0];

    processor_controller controller_inst (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),

        .immout(immout),
        .rxout(rxout),
        .ryout(ryout),
        .gout(gout),

        .ain(ain),
        .gin(gin),
        .rxin(rxin),

        .alu_sub(alu_sub),
        .done(done)
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

        .ain(ain),
        .gin(gin),
        .rxin(rxin),

        .alu_sub(alu_sub),

        .r0_out(r0_out),
        .r1_out(r1_out),
        .r2_out(r2_out),
        .bus_out(bus_out)
    );

endmodule