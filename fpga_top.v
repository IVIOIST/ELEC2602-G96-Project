module fpga_top (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5
);

    wire reset;
    assign reset = ~KEY[0];

    // ------------------------------------------------------------
    // Slow clock
    // ------------------------------------------------------------
    parameter DIV_MAX = 26'd4_999_999;

    reg [25:0] div_count;
    reg cpu_clk;

    always @(posedge CLOCK_50) begin
        if (reset) begin
            div_count <= 26'd0;
            cpu_clk   <= 1'b0;
        end else begin
            if (div_count == DIV_MAX) begin
                div_count <= 26'd0;
                cpu_clk   <= ~cpu_clk;
            end else begin
                div_count <= div_count + 26'd1;
            end
        end
    end

    // ------------------------------------------------------------
    // Processor outputs
    // ------------------------------------------------------------
    wire [15:0] r0_out;
    wire [15:0] r1_out;
    wire [15:0] r2_out;
    wire [15:0] bus_out;
    wire [15:0] mem_debug_out;
    wire [7:0]  pc_out;

    processor_top cpu (
        .clk(cpu_clk),
        .reset(reset),

        .r0_out(r0_out),
        .r1_out(r1_out),
        .r2_out(r2_out),
        .bus_out(bus_out),
        .mem_debug_out(mem_debug_out),
        .pc_out(pc_out)
    );

    // ------------------------------------------------------------
    // LEDR for debugging
    // ------------------------------------------------------------
    assign LEDR[7:0] = pc_out;
    assign LEDR[8]   = cpu_clk;
    assign LEDR[9]   = reset;

    // ------------------------------------------------------------
    // Convert each register to two decimal digits
    // Only display value modulo 100
    // ------------------------------------------------------------
    wire [6:0] r0_display;
    wire [6:0] r1_display;
    wire [6:0] r2_display;

    assign r0_display = r0_out % 100;
    assign r1_display = r1_out % 100;
    assign r2_display = r2_out % 100;

    wire [3:0] r0_ones;
    wire [3:0] r0_tens;
    wire [3:0] r1_ones;
    wire [3:0] r1_tens;
    wire [3:0] r2_ones;
    wire [3:0] r2_tens;

    assign r0_ones = r0_display % 10;
    assign r0_tens = r0_display / 10;

    assign r1_ones = r1_display % 10;
    assign r1_tens = r1_display / 10;

    assign r2_ones = r2_display % 10;
    assign r2_tens = r2_display / 10;

    // ------------------------------------------------------------
    // HEX mapping
    //
    // R0 -> HEX1 HEX0
    // R1 -> HEX3 HEX2
    // R2 -> HEX5 HEX4
    // ------------------------------------------------------------
    assign HEX0 = seven_seg(r0_ones);
    assign HEX1 = seven_seg(r0_tens);

    assign HEX2 = seven_seg(r1_ones);
    assign HEX3 = seven_seg(r1_tens);

    assign HEX4 = seven_seg(r2_ones);
    assign HEX5 = seven_seg(r2_tens);

    // ------------------------------------------------------------
    // Seven segment decoder
    // Active-low display:
    // 0 means segment ON
    // 1 means segment OFF
    // ------------------------------------------------------------
    function [6:0] seven_seg;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: seven_seg = 7'b1000000;
                4'd1: seven_seg = 7'b1111001;
                4'd2: seven_seg = 7'b0100100;
                4'd3: seven_seg = 7'b0110000;
                4'd4: seven_seg = 7'b0011001;
                4'd5: seven_seg = 7'b0010010;
                4'd6: seven_seg = 7'b0000010;
                4'd7: seven_seg = 7'b1111000;
                4'd8: seven_seg = 7'b0000000;
                4'd9: seven_seg = 7'b0010000;
                default: seven_seg = 7'b1111111;
            endcase
        end
    endfunction

endmodule