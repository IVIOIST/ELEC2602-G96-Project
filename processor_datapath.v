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
    input  wire        memout,

    input  wire        ain,
    input  wire        gin,
    input  wire        rxin,
    input  wire        memwrite,

    input  wire [2:0]  alu_op,

    output wire [15:0] r0_out,
    output wire [15:0] r1_out,
    output wire [15:0] r2_out,
    output wire [15:0] bus_out,
    output wire [15:0] mem_debug_out,
	 output wire        rx_zero
);

    // ALU operation codes
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_MUL = 3'b010;
    localparam ALU_INC = 3'b011;
    localparam ALU_DEC = 3'b100;
    localparam ALU_PADD = 3'b101;

    // General purpose registers
    reg [15:0] R0;
    reg [15:0] R1;
    reg [15:0] R2;

    // Internal registers
    reg [15:0] A;
    reg [15:0] G;

    // Data memory: 256 x 16-bit
    reg [15:0] data_mem [0:255];

    // Bus
    reg [15:0] bus;

    // Selected register values
    wire [15:0] rx_value;
    wire [15:0] ry_value;

    // Memory address uses lower 8 bits of imm
    wire [7:0] mem_addr;
    wire [15:0] mem_read_data;

    // ALU result
    reg [15:0] alu_result;

    assign r0_out  = R0;
    assign r1_out  = R1;
    assign r2_out  = R2;
    assign bus_out = bus;

    assign mem_addr = imm[7:0];
    assign mem_read_data = data_mem[mem_addr];

    // For simulation/debug: show data_mem[10]
    assign mem_debug_out = data_mem[8'd10];

    // Select Rx register value
    assign rx_value = (rx == 2'b00) ? R0 :
                      (rx == 2'b01) ? R1 :
                      (rx == 2'b10) ? R2 :
                                      16'd0;

    // Select Ry register value
    assign ry_value = (ry == 2'b00) ? R0 :
                      (ry == 2'b01) ? R1 :
                      (ry == 2'b10) ? R2 :
                                      16'd0;
	 
	 // rx_zero value
	 assign rx_zero = (rx_value == 16'd0);

    // ALU
    always @(*) begin
        case (alu_op)
            ALU_ADD: alu_result = A + bus;
            ALU_SUB: alu_result = A - bus;
            ALU_MUL: alu_result = A * bus;
            ALU_INC: alu_result = A + 16'd1;
            ALU_DEC: alu_result = A - 16'd1;
            ALU_PADD: alu_result = {A[15:8] + bus[15:8], A[7:0] + bus[7:0]};
            default: alu_result = 16'd0;
        endcase
    end

    // Bus multiplexer
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
            bus = mem_read_data;
        else
            bus = 16'd0;
    end

    // Registers and data memory write
		always @(posedge clk or posedge reset) begin
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

				  if (memwrite)
						data_mem[mem_addr] <= bus;
			 end
		end
endmodule
