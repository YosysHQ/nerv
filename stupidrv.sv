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
	reg mem_wr_enable;
	reg [31:0] mem_wr_addr;
	reg [31:0] mem_wr_data;
	reg [3:0] mem_wr_strb;

	reg mem_rd_enable;
	reg [31:0] mem_rd_addr;
	reg [4:0] mem_rd_reg;
	reg [4:0] mem_rd_func;

	reg mem_rd_enable_q;
	reg [4:0] mem_rd_reg_q;
	reg [4:0] mem_rd_func_q;

	always @(posedge clock) begin
		if (!stall) begin
			mem_rd_enable_q <= mem_rd_enable;
			mem_rd_reg_q <= mem_rd_reg;
			mem_rd_func_q <= mem_rd_func;
		end
		if (reset) begin
			mem_rd_enable_q <= 0;
		end
	end

	assign dmem_valid = mem_wr_enable || mem_rd_enable;
	assign dmem_addr = mem_wr_enable ? mem_wr_addr : mem_rd_enable ? mem_rd_addr : 32'h x;
	assign dmem_wstrb = mem_wr_enable ? mem_wr_strb : 4'h 0;
	assign dmem_wdata = mem_wr_enable ? mem_wr_data : 32'h x;

	reg [31:0] regfile [0:31];
	wire [31:0] insn;
	reg [31:0] npc;
	reg [31:0] pc;

	reg [31:0] imem_addr_q;

	always @(posedge clock) begin
		imem_addr_q <= imem_addr;
	end

	assign imem_addr = (stall || mem_rd_enable_q) ? imem_addr_q : npc;
	assign insn = imem_data;

	wire [31:0] rs1_value = !insn_rs1 ? 0 : regfile[insn_rs1];
	wire [31:0] rs2_value = !insn_rs2 ? 0 : regfile[insn_rs2];

	wire [6:0] insn_funct7;
	wire [4:0] insn_rs2;
	wire [4:0] insn_rs1;
	wire [2:0] insn_funct3;
	wire [4:0] insn_rd;
	wire [6:0] insn_opcode;

	assign {insn_funct7, insn_rs2, insn_rs1, insn_funct3, insn_rd, insn_opcode} = insn;

	wire [11:0] imm_i;
	assign imm_i = insn[31:20];

	wire [11:0] imm_s;
	assign imm_s[11:5] = insn_funct7, imm_s[4:0] = insn_rd;

	wire [12:0] imm_b;
	assign {imm_b[12], imm_b[10:5]} = insn_funct7, {imm_b[4:1], imm_b[11]} = insn_rd;

	wire [20:0] imm_j;
	assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {insn[31:12], 1'b0};

	wire [31:0] imm_i_sext = $signed(imm_i);
	wire [31:0] imm_s_sext = $signed(imm_s);
	wire [31:0] imm_b_sext = $signed(imm_b);
	wire [31:0] imm_j_sext = $signed(imm_j);

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

		mem_wr_enable = 0;
		mem_wr_addr = 'hx;
		mem_wr_data = 'hx;
		mem_wr_strb = 'hx;

		mem_rd_enable = 0;
		mem_rd_addr = 'hx;
		mem_rd_reg = 'hx;

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
				npc = pc + imm_j_sext;
			end
			OPCODE_JALR: begin
				case (insn_funct3)
					3'b 000 /* JALR */: begin
						next_wr = 1;
						next_rd = npc;
						npc = rs1_value + imm_i_sext;
					end
					default: illinsn = 1;
				endcase
			end
			OPCODE_BRANCH: begin
				case (insn_funct3)
					3'b 000 /* BEQ  */: begin if (rs1_value == rs2_value) npc = pc + imm_b_sext; end
					3'b 001 /* BNE  */: begin if (rs1_value != rs2_value) npc = pc + imm_b_sext; end
					3'b 100 /* BLT  */: begin if ($signed(rs1_value) < $signed(rs2_value)) npc = pc + imm_b_sext; end
					3'b 101 /* BGE  */: begin if ($signed(rs1_value) >= $signed(rs2_value)) npc = pc + imm_b_sext; end
					3'b 110 /* BLTU */: begin if (rs1_value < rs2_value) npc = pc + imm_b_sext; end
					3'b 111 /* BGEU */: begin if (rs1_value >= rs2_value) npc = pc + imm_b_sext; end
					default: illinsn = 1;
				endcase
			end
			OPCODE_LOAD: begin
				case (insn_funct3)
					3'b 000 /* LB  */: begin mem_rd_enable = 1; mem_rd_addr = rs1_value + imm_i_sext; mem_rd_reg = insn_rd; mem_rd_func = insn_funct3; end
					3'b 001 /* LH  */: begin mem_rd_enable = 1; mem_rd_addr = rs1_value + imm_i_sext; mem_rd_reg = insn_rd; mem_rd_func = insn_funct3; end
					3'b 010 /* LW  */: begin mem_rd_enable = 1; mem_rd_addr = rs1_value + imm_i_sext; mem_rd_reg = insn_rd; mem_rd_func = insn_funct3; end
					3'b 100 /* LBU */: begin mem_rd_enable = 1; mem_rd_addr = rs1_value + imm_i_sext; mem_rd_reg = insn_rd; mem_rd_func = insn_funct3; end
					3'b 101 /* LHU */: begin mem_rd_enable = 1; mem_rd_addr = rs1_value + imm_i_sext; mem_rd_reg = insn_rd; mem_rd_func = insn_funct3; end
					default: illinsn = 1;
				endcase
				if (mem_rd_enable && mem_rd_addr[0]) begin
					mem_rd_addr = mem_rd_addr + 1;
					mem_rd_func = mem_rd_func | 5'b 01_000;
				end
				if (mem_rd_enable && mem_rd_addr[1]) begin
					mem_rd_addr = mem_rd_addr + 2;
					mem_rd_func = mem_rd_func | 5'b 10_000;
				end
			end
			OPCODE_STORE: begin
				case (insn_funct3)
					3'b 000 /* SB  */: begin mem_wr_enable = 1; mem_wr_addr = rs1_value + imm_s_sext; mem_wr_data = rs2_value; mem_wr_strb = 4'b 0001; end
					3'b 001 /* SH  */: begin mem_wr_enable = 1; mem_wr_addr = rs1_value + imm_s_sext; mem_wr_data = rs2_value; mem_wr_strb = 4'b 0011; end
					3'b 010 /* SW  */: begin mem_wr_enable = 1; mem_wr_addr = rs1_value + imm_s_sext; mem_wr_data = rs2_value; mem_wr_strb = 4'b 1111; end
					default: illinsn = 1;
				endcase
				if (mem_wr_enable && mem_wr_addr[0] && !mem_wr_strb[3]) begin
					mem_wr_addr = mem_wr_addr + 1;
					mem_wr_data = mem_wr_data << 8;
					mem_wr_strb = mem_wr_strb << 1;
				end
				if (mem_wr_enable && mem_wr_addr[1] && !mem_wr_strb[3:2]) begin
					mem_wr_addr = mem_wr_addr + 2;
					mem_wr_data = mem_wr_data << 16;
					mem_wr_strb = mem_wr_strb << 2;
				end
			end
			OPCODE_OP_IMM: begin
				casez ({insn_funct7, insn_funct3})
					10'b zzzzzzz_000 /* ADDI  */: begin next_wr = 1; next_rd = rs1_value + imm_i_sext; end
					10'b zzzzzzz_010 /* SLTI  */: begin next_wr = 1; next_rd = $signed(rs1_value) < $signed(imm_i_sext); end
					10'b zzzzzzz_011 /* SLTIU */: begin next_wr = 1; next_rd = rs1_value < imm_i_sext; end
					10'b zzzzzzz_100 /* XORI  */: begin next_wr = 1; next_rd = rs1_value ^ imm_i_sext; end
					10'b zzzzzzz_110 /* ORI   */: begin next_wr = 1; next_rd = rs1_value | imm_i_sext; end
					10'b zzzzzzz_111 /* ANDI  */: begin next_wr = 1; next_rd = rs1_value & imm_i_sext; end
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

	reg reset_q;

	reg [31:0] rdata;

	always @* begin
		rdata = dmem_rdata >> (8*mem_rd_func[4:3]);
		case (mem_rd_func_q[2:0])
			3'b 000 /* LB  */: begin rdata = $signed(rdata[7:0]); end
			3'b 001 /* LH  */: begin rdata = $signed(rdata[15:0]); end
			3'b 100 /* LBU */: begin rdata = rdata[7:0]; end
			3'b 101 /* LHU */: begin rdata = rdata[15:0]; end
		endcase
	end

	always @(posedge clock) begin
		reset_q <= reset;

		if (!stall && !reset && !reset_q) begin
			if (mem_rd_enable_q) begin
				regfile[mem_rd_reg_q] <= rdata;
			end else begin
				if (next_wr)
					regfile[insn_rd] <= next_rd;
				pc <= npc;
			end
		end

		if (reset || reset_q) begin
			pc <= RESET_ADDR - (reset ? 4 : 0);
		end
	end
endmodule
