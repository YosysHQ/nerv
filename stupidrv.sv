module stupidrv #(
	parameter [31:0] RESET_ADDR = 32'h 0000_0000
) (
	input clock,
	input reset,
	input stall,

	output [31:0] imem_addr,
	input  [31:0] imem_data,

	output        dmem_valid,
	output [31:0] dmem_addr,
	output [ 3:0] dmem_wstrb,
	output [31:0] dmem_wdata,
	input  [31:0] dmem_rdata
);
	reg [31:0] regfile [0:31];
	wire [31:0] insn;
	reg [31:0] npc;
	reg [31:0] pc;

	assign imem_addr = npc;
	assign insn = imem_data;

	reg [31:0] bypass_value = 0;
	reg [ 4:0] bypass_reg = 0;

	wire [31:0] rs1_value = !insn_rs1 ? 0 : insn_rs1 == bypass_reg ? bypass_value : regfile[insn_rs1];
	wire [31:0] rs2_value = !insn_rs2 ? 0 : insn_rs2 == bypass_reg ? bypass_value : regfile[insn_rs2];

	wire [6:0] insn_funct7;
	wire [4:0] insn_rs2;
	wire [4:0] insn_rs1;
	wire [2:0] insn_funct3;
	wire [4:0] insn_rd;
	wire [6:0] insn_opcode;

	assign {insn_funct7, insn_rs2, insn_rs1, insn_funct3, insn_rd, insn_opcode} = insn;

	localparam OPCODE_LOAD       = 7'b 00_000_11;
	localparam OPCODE_STORE      = 7'b 01_000_11;
	localparam OPCODE_MADD       = 7'b 10_000_11;
	localparam OPCODE_BRANCH     = 7'b 11_000_11;

	localparam OPCODE_LOAD_FP    = 7'b 00_001_11;
	localparam OPCODE_STORE_FP   = 7'b 01_001_11;
	localparam OPCODE_MSUB       = 7'b 10_001_11;
	localparam OPCODE_JALR       = 7'b 11_001_11;

	localparam OPCODE_CUSTOM_0   = 7'b 00_010_11;
	localparam OPCODE_CUSTOM_1   = 7'b 01_010_11;
	localparam OPCODE_NMSUB      = 7'b 10_010_11;
	localparam OPCODE_RESERVED_0 = 7'b 11_010_11;

	localparam OPCODE_MISC_MEM   = 7'b 00_011_11;
	localparam OPCODE_AMO        = 7'b 01_011_11;
	localparam OPCODE_NMADD      = 7'b 10_011_11;
	localparam OPCODE_JAL        = 7'b 11_011_11;

	localparam OPCODE_OP_IMM     = 7'b 00_100_11;
	localparam OPCODE_OP         = 7'b 01_100_11;
	localparam OPCODE_OP_FP      = 7'b 10_100_11;
	localparam OPCODE_SYSTEM     = 7'b 11_100_11;

	localparam OPCODE_AUIPC      = 7'b 00_101_11;
	localparam OPCODE_LUI        = 7'b 01_101_11;
	localparam OPCODE_RESERVED_1 = 7'b 10_101_11;
	localparam OPCODE_RESERVED_2 = 7'b 11_101_11;

	localparam OPCODE_OP_IMM_32  = 7'b 00_110_11;
	localparam OPCODE_OP_32      = 7'b 01_110_11;
	localparam OPCODE_CUSTOM_2   = 7'b 10_110_11;
	localparam OPCODE_CUSTOM_3   = 7'b 11_110_11;

	reg next_wr;
	reg [31:0] next_rd;
	reg illinsn;

	always @* begin
		npc = pc + 4;
		next_wr = 0;
		next_rd = 0;
		illinsn = 0;

		case (insn_opcode)
			OPCODE_LUI: begin
				next_wr = 1;
				next_rd = insn[31:12] << 12;
			end
			OPCODE_AUIPC: begin
				next_wr = 1;
				next_rd = (insn[31:12] << 12) + pc;
			end
			OPCODE_JAL: begin
				// TBD
			end
			OPCODE_BRANCH: begin
				case (insn_funct3)
					3'b 000 /* BEQ  */: begin /* TBD */ end
					3'b 001 /* BNE  */: begin /* TBD */ end
					3'b 100 /* BLT  */: begin /* TBD */ end
					3'b 101 /* BGE  */: begin /* TBD */ end
					3'b 110 /* BLTU */: begin /* TBD */ end
					3'b 111 /* BGEU */: begin /* TBD */ end
					default: illinsn = 1;
				endcase
			end
			OPCODE_LOAD: begin
				case (insn_funct3)
					3'b 000 /* LB  */: begin /* TBD */ end
					3'b 001 /* LH  */: begin /* TBD */ end
					3'b 010 /* LW  */: begin /* TBD */ end
					3'b 100 /* LBU */: begin /* TBD */ end
					3'b 101 /* LHU */: begin /* TBD */ end
					default: illinsn = 1;
				endcase
			end
			OPCODE_STORE: begin
				case (insn_funct3)
					3'b 000 /* SB  */: begin /* TBD */ end
					3'b 001 /* SH  */: begin /* TBD */ end
					3'b 010 /* SW  */: begin /* TBD */ end
					default: illinsn = 1;
				endcase
			end
			OPCODE_OP_IMM: begin
				casez ({insn_funct7, insn_funct3})
					10'b zzzzzzz_000 /* ADDI  */: begin next_wr = 1; next_rd = rs1_value + $signed(insn[31:20]); end
					10'b zzzzzzz_010 /* SLTI  */: begin next_wr = 1; next_rd = $signed(rs1_value) < $signed(insn[31:20]); end
					10'b zzzzzzz_011 /* SLTIU */: begin next_wr = 1; next_rd = rs1_value < $signed(insn[31:20]); end
					10'b zzzzzzz_100 /* XORI  */: begin next_wr = 1; next_rd = rs1_value ^ $signed(insn[31:20]); end
					10'b zzzzzzz_110 /* ORI   */: begin next_wr = 1; next_rd = rs1_value | $signed(insn[31:20]); end
					10'b zzzzzzz_111 /* ANDI  */: begin next_wr = 1; next_rd = rs1_value & $signed(insn[31:20]); end
					10'b 0000000_001 /* SLLI  */: begin next_wr = 1; next_rd = rs1_value << insn[24:20]; end
					10'b 0000000_101 /* SRLI  */: begin next_wr = 1; next_rd = rs1_value >> insn[24:20]; end
					10'b 0100000_101 /* SRAI  */: begin next_wr = 1; next_rd = $signed(rs1_value) >>> insn[24:20]; end
					default: illinsn = 1;
				endcase
			end
			OPCODE_OP: begin
				casez ({insn_funct7, insn_funct3})
					10'b 0000000_000 /* ADD  */: begin next_wr = 1; next_rd = rs1_value + rs2_value; end
					10'b 0100000_000 /* SUB  */: begin next_wr = 1; next_rd = rs1_value - rs2_value; end
					10'b 0000000_001 /* SLL  */: begin next_wr = 1; next_rd = rs1_value << rs2_value[4:0]; end
					10'b 0000000_010 /* SLT  */: begin next_wr = 1; next_rd = $signed(rs1_value) < $signed(rs2_value); end
					10'b 0000000_011 /* SLTU */: begin next_wr = 1; next_rd = rs1_value < rs2_value; end
					10'b 0000000_100 /* XOR  */: begin next_wr = 1; next_rd = rs1_value ^ rs2_value; end
					10'b 0000000_101 /* SRL  */: begin next_wr = 1; next_rd = rs1_value >> rs2_value[4:0]; end
					10'b 0100000_101 /* SRA  */: begin next_wr = 1; next_rd = $signed(rs1_value) >>> rs2_value[4:0]; end
					10'b 0000000_110 /* OR   */: begin next_wr = 1; next_rd = rs1_value | rs2_value; end
					10'b 0000000_111 /* AND  */: begin next_wr = 1; next_rd = rs1_value & rs2_value; end
					default: illinsn = 1;
				endcase
			end
			default: illinsn = 1;
		endcase

		if (reset) begin
			npc = RESET_ADDR;
			next_wr = 0;
			illinsn = 0;
		end
	end

	always @(posedge clock) begin
		bypass_value <= 32'd 0;
		bypass_reg <= 5'd 0;

		if (!stall) begin
			pc <= npc;
			if (next_wr) begin
				bypass_value <= next_rd;
				bypass_reg <= insn_rd;
				regfile[insn_rd] <= next_rd;
			end
		end

		if (reset) begin
			pc <= RESET_ADDR;
			bypass_reg <= 0;
		end
	end
endmodule
