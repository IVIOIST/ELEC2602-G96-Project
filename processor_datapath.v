module processor_datapath (
    input  wire        clk,
    input  wire        reset,

    input  wire [15:0] imm,
    input  wire [1:0]  rx,
    input  wire [1:0]  ry,

    input  wire        immout,
    input  wire        rxout,
    input  wire        ryout,
    input  wire        gout,

    input  wire        ain,
    input  wire        gin,
    input  wire        rxin,

    input  wire        alu_sub, 

    output wire [15:0] r0_out,
    output wire [15:0] r1_out,
    output wire [15:0] r2_out,
    output wire [15:0] bus_out
);

    reg [15:0] R0;
    reg [15:0] R1;
    reg [15:0] R2;

    reg [15:0] A;
    reg [15:0] G;

    reg [15:0] bus;

    wire [15:0] rx_value;
    wire [15:0] ry_value;
    wire [15:0] alu_result;

    assign r0_out  = R0;
    assign r1_out  = R1;
    assign r2_out  = R2;
    assign bus_out = bus;

    assign rx_value = (rx == 2'b00) ? R0 :
                      (rx == 2'b01) ? R1 :
                      (rx == 2'b10) ? R2 :
                                      16'd0;

    assign ry_value = (ry == 2'b00) ? R0 :
                      (ry == 2'b01) ? R1 :
                      (ry == 2'b10) ? R2 :
                                      16'd0;

    assign alu_result = alu_sub ? (A - bus) : (A + bus); //(alu_sub = 0 -> alu_result = A + bus), (alu_sub = 1 -> alu_result = A - bus)

    always @(*) begin
        if (immout)
            bus = imm;
        else if (rxout)
            bus = rx_value;
        else if (ryout)
            bus = ry_value;
        else if (gout)
            bus = G;
        else
            bus = 16'd0;
    end

    always @(posedge clk) begin
        if (reset) begin
            R0 <= 16'd0;
            R1 <= 16'd0;
            R2 <= 16'd0;
            A  <= 16'd0;
            G  <= 16'd0;
        end else begin
            if (ain)
                A <= bus;

            if (gin)
                G <= alu_result;

            if (rxin) begin
                case (rx)
                    2'b00: R0 <= bus;
                    2'b01: R1 <= bus;
                    2'b10: R2 <= bus;
                    default: ;
                endcase
            end
        end
    end

endmodule