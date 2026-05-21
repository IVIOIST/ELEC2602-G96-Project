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

    localparam [23:0] NOP_INSTRUCTION = {4'b0000, 2'b00, 2'b00, 16'd0};

    // Two-stage instruction pipeline:
    // fetch_pc reads the next instruction while execute_instruction is running.
    reg  [7:0]  fetch_pc;
    reg  [7:0]  execute_pc;
    reg  [23:0] execute_instruction;
    reg         pipeline_valid;
    wire [23:0] fetched_instruction;


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

    assign pc_out = execute_pc;

    // Instruction memory
    instruction_memory imem_inst (
        .address(fetch_pc),
        .instruction(fetched_instruction)
    );

    // Instruction decoder
    assign opcode = execute_instruction[23:20];
    assign rx     = execute_instruction[19:18];
    assign ry     = execute_instruction[17:16];
    assign imm    = execute_instruction[15:0];

    // Pipeline and PC update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fetch_pc            <= 8'd0;
            execute_pc          <= 8'd0;
            execute_instruction <= NOP_INSTRUCTION;
            pipeline_valid      <= 1'b0;
        end else begin
            if (done) begin
                if (pipeline_valid && (jump || (branch_zero && rx_zero))) begin
                    fetch_pc            <= imm[7:0];
                    execute_instruction <= NOP_INSTRUCTION;
                    pipeline_valid      <= 1'b0;
                end else begin
                    execute_pc          <= fetch_pc;
                    execute_instruction <= fetched_instruction;
                    fetch_pc            <= fetch_pc + 8'd1;
                    pipeline_valid      <= 1'b1;
                end
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
