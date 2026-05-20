module processor_top (
    input  wire        clk,
    input  wire        reset,

    output wire [15:0] r0_out,
    output wire [15:0] r1_out,
    output wire [15:0] r2_out,
    output wire [15:0] bus_out,
    output wire [15:0] mem_debug_out,
    output wire [7:0]  pc_out
);

    // Program counter
    reg [7:0] pc;

    // Instruction from instruction memory
    wire [23:0] instruction;


    // Decoded instruction fields
    wire [3:0]  opcode;
    wire [1:0]  rx;
    wire [1:0]  ry;
    wire [15:0] imm;

    // Control signals: outputs to bus
    wire immout;
    wire rxout;
    wire ryout;
    wire gout;
    wire memout;

    // Control signals: inputs / writes
    wire ain;
    wire gin;
    wire rxin;
    wire memwrite;

    // ALU control
    wire [2:0] alu_op;

    // Internal done signal
    wire done;
	 wire jump;
	 wire branch_zero;
	 
	 wire rx_zero;

    assign pc_out = pc;

    // Instruction memory
    instruction_memory imem_inst (
        .address(pc),
        .instruction(instruction)
    );

    // Instruction decoder
    assign opcode = instruction[23:20];
    assign rx     = instruction[19:18];
    assign ry     = instruction[17:16];
    assign imm    = instruction[15:0];

    // PC update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 8'd0;
        end else begin
            if (done) begin
                if (jump || (branch_zero && rx_zero))
                    pc <= imm[7:0];
                else
                    pc <= pc + 8'd1;
            end
        end
    end

    // Controller
		processor_controller controller_inst (
			 .clk(clk),
			 .reset(reset),
			 .opcode(opcode),

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

			 .jump(jump),
			 .branch_zero(branch_zero),

			 .done(done)
		);

    // Datapath
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

			 .r0_out(r0_out),
			 .r1_out(r1_out),
			 .r2_out(r2_out),
			 .bus_out(bus_out),
			 .mem_debug_out(mem_debug_out),
			 .rx_zero(rx_zero)
		);

endmodule