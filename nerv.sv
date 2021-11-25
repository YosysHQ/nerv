/*
 *  NERV -- Naive Educational RISC-V Processor
 *
 *  Copyright (C) 2020  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`define NERV_CSR

module nerv #(
	parameter [31:0] RESET_ADDR = 32'h 0000_0000,
	parameter integer NUMREGS = 32
) (
	input clock,
	input reset,
	input stall,
	output trap,

`ifdef NERV_RVFI
	output reg        rvfi_valid,
	output reg [63:0] rvfi_order,
	output reg [31:0] rvfi_insn,
	output reg        rvfi_trap,
	output reg        rvfi_halt,
	output reg        rvfi_intr,
	output reg [ 1:0] rvfi_mode,
	output reg [ 1:0] rvfi_ixl,
	output reg [ 4:0] rvfi_rs1_addr,
	output reg [ 4:0] rvfi_rs2_addr,
	output reg [31:0] rvfi_rs1_rdata,
	output reg [31:0] rvfi_rs2_rdata,
	output reg [ 4:0] rvfi_rd_addr,
	output reg [31:0] rvfi_rd_wdata,
	output reg [31:0] rvfi_pc_rdata,
	output reg [31:0] rvfi_pc_wdata,
	output reg [31:0] rvfi_mem_addr,
	output reg [ 3:0] rvfi_mem_rmask,
	output reg [ 3:0] rvfi_mem_wmask,
	output reg [31:0] rvfi_mem_rdata,
	output reg [31:0] rvfi_mem_wdata,
`endif

	// we have 2 external memories
	// one is instruction memory
	output [31:0] imem_addr,
	input  [31:0] imem_data,

	// the other is data memory
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

	// delayed copies of mem_rd
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

	// memory signals
	assign dmem_valid = mem_wr_enable || mem_rd_enable;
	assign dmem_addr  = mem_wr_enable ? mem_wr_addr : mem_rd_enable ? mem_rd_addr : 32'h x;
	assign dmem_wstrb = mem_wr_enable ? mem_wr_strb : mem_rd_enable ? 4'h 0 : 4'h x;
	assign dmem_wdata = mem_wr_enable ? mem_wr_data : 32'h x;

	// registers, instruction reg, program counter, next pc
	reg [31:0] regfile [0:NUMREGS-1];
	wire [31:0] insn;
	reg [31:0] npc;
	reg [31:0] pc;

	reg [31:0] imem_addr_q;

	always @(posedge clock) begin
		imem_addr_q <= imem_addr;
	end

	// instruction memory pointer
	assign imem_addr = (stall || trap || mem_rd_enable_q) ? imem_addr_q : npc;
	assign insn = imem_data;

	// rs1 and rs2 are source for the instruction
	wire [31:0] rs1_value = !insn_rs1 ? 0 : regfile[insn_rs1];
	wire [31:0] rs2_value = !insn_rs2 ? 0 : regfile[insn_rs2];

	// components of the instruction
	wire [6:0] insn_funct7;
	wire [4:0] insn_rs2;
	wire [4:0] insn_rs1;
	wire [2:0] insn_funct3;
	wire [4:0] insn_rd;
	wire [6:0] insn_opcode;

	// split R-type instruction - see section 2.2 of RiscV spec
	assign {insn_funct7, insn_rs2, insn_rs1, insn_funct3, insn_rd, insn_opcode} = insn;

	// setup for I, S, B & J type instructions
	// I - short immediates and loads
	wire [11:0] imm_i;
	assign imm_i = insn[31:20];

	// S - stores
	wire [11:0] imm_s;
	assign imm_s[11:5] = insn_funct7, imm_s[4:0] = insn_rd;

	// B - conditionals
	wire [12:0] imm_b;
	assign {imm_b[12], imm_b[10:5]} = insn_funct7, {imm_b[4:1], imm_b[11]} = insn_rd, imm_b[0] = 1'b0;

	// J - unconditional jumps
	wire [20:0] imm_j;
	assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {insn[31:12], 1'b0};

	wire [31:0] imm_i_sext = $signed(imm_i);
	wire [31:0] imm_s_sext = $signed(imm_s);
	wire [31:0] imm_b_sext = $signed(imm_b);
	wire [31:0] imm_j_sext = $signed(imm_j);

	// opcodes - see section 19 of RiscV spec
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

	// next write, next destination (rd), illegal instruction registers
	reg next_wr;
	reg [31:0] next_rd;
	reg illinsn;

	reg trapped;
	reg trapped_q;
	assign trap = trapped;

`ifdef NERV_CSR
	reg [ 1:0] csr_mode; // 00=None, 01=RW, 10=RS, 11=RC
	reg        csr_ack;
	reg [11:0] csr_addr;
	reg [31:0] csr_rsval;
	reg [31:0] csr_rdval;

	/**********************
	 *  CSR DECLARATIONS  *
	 **********************/

	`define NERV_CSR_REG(name, addr, init) \
localparam [11:0] csr_``name``_addr = addr; \
localparam [31:0] csr_``name``_init = init; \
wire csr_``name``_sel = csr_addr == csr_``name``_addr; \
reg [31:0] csr_``name``_value; \
reg [31:0] csr_``name``_next; \
always @(posedge clock) begin \
  csr_``name``_value <= csr_``name``_next; \
  if (reset || reset_q) csr_``name``_value <= csr_``name``_init; \
end

	`define NERV_CSR_VAL(name, addr, value) \
localparam [11:0] csr_``name``_addr = addr; \
localparam [31:0] csr_``name``_value = value; \
wire csr_``name``_sel = csr_addr == csr_``name``_addr; \
reg [31:0] csr_``name``_next;

	// FIXME: Memory-Mapped Machine Timer (mtime ad timecmp)
	// FIXME: Additional instructions: ECALL, EBREAK, MRET, WFI

	/* Machine Information CSRs */

	`NERV_CSR_VAL(mvendorid,         12'h F11, 31'h 0000_0000)
	`NERV_CSR_VAL(marchid,           12'h F12, 31'h 0000_0000)
	`NERV_CSR_VAL(mimpid,            12'h F13, 31'h 0000_0000)
	`NERV_CSR_VAL(mhartid,           12'h F14, 31'h 0000_0000)

	/* Machine Trap Setup CSRs */

	`NERV_CSR_REG(mstatus,           12'h 300, 31'h 0000_0000)   // FIXME
	`NERV_CSR_VAL(misa,              12'h 301, 31'h 0000_0000)   // FIXME
	`NERV_CSR_REG(medeleg,           12'h 302, 31'h 0000_0000)   // FIXME
	`NERV_CSR_REG(mideleg,           12'h 303, 31'h 0000_0000)   // FIXME
	`NERV_CSR_REG(mie,               12'h 304, 31'h 0000_0000)   // FIXME
	`NERV_CSR_REG(mtvec,             12'h 305, 31'h 0000_0000)   // FIXME
//	`NERV_CSR_REG(mcounteren,        12'h 306, 31'h 0000_0000)

	/* Machine Trap Handling CSRs */

	`NERV_CSR_REG(mscratch,          12'h 340, 31'h 0000_0000)
	`NERV_CSR_REG(mepc,              12'h 341, 31'h 0000_0000)   // FIXME
	`NERV_CSR_REG(mcause,            12'h 342, 31'h 0000_0000)   // FIXME
	`NERV_CSR_REG(mtval,             12'h 343, 31'h 0000_0000)   // FIXME
	`NERV_CSR_REG(mip,               12'h 344, 31'h 0000_0000)   // FIXME

	/* Machine Memory Protection CSRs */

`ifdef NERV_PMP
	`NERV_CSR_VAL(pmpcfg0,           12'h 3A0, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpcfg1,           12'h 3A1, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpcfg2,           12'h 3A2, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpcfg3,           12'h 3A3, 31'h 0000_0000)

	`NERV_CSR_VAL(pmpaddr0,          12'h 3B0, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr1,          12'h 3B1, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr2,          12'h 3B2, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr3,          12'h 3B3, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr4,          12'h 3B4, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr5,          12'h 3B5, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr6,          12'h 3B6, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr7,          12'h 3B7, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr8,          12'h 3B8, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr9,          12'h 3B9, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr10,         12'h 3BA, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr11,         12'h 3BB, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr12,         12'h 3BC, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr13,         12'h 3BD, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr14,         12'h 3BE, 31'h 0000_0000)
	`NERV_CSR_VAL(pmpaddr15,         12'h 3BF, 31'h 0000_0000)
`endif

	/* Machine Counter/Timers CSRs */

	`NERV_CSR_REG(mcycle,            12'h B00, 31'h 0000_0000)
	`NERV_CSR_REG(minstret,          12'h B02, 31'h 0000_0000)

	`NERV_CSR_VAL(mhpmcounter3,      12'h B03, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter4,      12'h B04, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter5,      12'h B05, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter6,      12'h B06, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter7,      12'h B07, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter8,      12'h B08, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter9,      12'h B09, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter10,     12'h B0A, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter11,     12'h B0B, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter12,     12'h B0C, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter13,     12'h B0D, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter14,     12'h B0E, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter15,     12'h B0F, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter16,     12'h B10, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter17,     12'h B11, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter18,     12'h B12, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter19,     12'h B13, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter20,     12'h B14, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter21,     12'h B15, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter22,     12'h B16, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter23,     12'h B17, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter24,     12'h B18, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter25,     12'h B19, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter26,     12'h B1A, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter27,     12'h B1B, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter28,     12'h B1C, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter29,     12'h B1D, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter30,     12'h B1E, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter31,     12'h B1F, 31'h 0000_0000)

	`NERV_CSR_REG(mcycleh,           12'h B80, 31'h 0000_0000)
	`NERV_CSR_REG(minstreth,         12'h B82, 31'h 0000_0000)

	`NERV_CSR_VAL(mhpmcounter3h,     12'h B03, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter4h,     12'h B04, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter5h,     12'h B05, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter6h,     12'h B06, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter7h,     12'h B07, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter8h,     12'h B08, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter9h,     12'h B09, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter10h,    12'h B0A, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter11h,    12'h B0B, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter12h,    12'h B0C, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter13h,    12'h B0D, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter14h,    12'h B0E, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter15h,    12'h B0F, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter16h,    12'h B10, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter17h,    12'h B11, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter18h,    12'h B12, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter19h,    12'h B13, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter20h,    12'h B14, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter21h,    12'h B15, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter22h,    12'h B16, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter23h,    12'h B17, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter24h,    12'h B18, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter25h,    12'h B19, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter26h,    12'h B1A, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter27h,    12'h B1B, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter28h,    12'h B1C, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter29h,    12'h B1D, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter30h,    12'h B1E, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmcounter31h,    12'h B1F, 31'h 0000_0000)

	/* Machine Counter Setup CSRs */

//	`NERV_CSR_VAL(mcountinhibit,     12'h 320, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent3,        12'h 323, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent4,        12'h 324, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent5,        12'h 325, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent6,        12'h 326, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent7,        12'h 327, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent8,        12'h 328, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent9,        12'h 329, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent10,       12'h 32A, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent11,       12'h 32B, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent12,       12'h 32C, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent13,       12'h 32D, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent14,       12'h 32E, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent15,       12'h 32F, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent16,       12'h 330, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent17,       12'h 331, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent18,       12'h 332, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent19,       12'h 333, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent20,       12'h 334, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent21,       12'h 335, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent22,       12'h 336, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent23,       12'h 337, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent24,       12'h 338, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent25,       12'h 339, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent26,       12'h 33A, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent27,       12'h 33B, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent28,       12'h 33C, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent29,       12'h 33D, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent30,       12'h 33E, 31'h 0000_0000)
	`NERV_CSR_VAL(mhpmevent31,       12'h 33F, 31'h 0000_0000)

	/*********************
	 *  CSR DEFINITIONS  *
	 *********************/

	wire csr_en = !trapped && !stall && csr_mode;

	`define NERV_CSR_MRO(name) \
csr_``name``_next = csr_``name``_value; \
if (csr_en && csr_``name``_sel) begin \
  csr_ack = 1; \
  csr_rdval = csr_``name``_value; \
  case (csr_mode) \
    2'b 01 /* RW */: csr_ack = 0; \
    2'b 10 /* RS */: csr_ack = !csr_rsval; \
    2'b 11 /* RC */: csr_ack = !csr_rsval; \
  endcase \
end

	`define NERV_CSR_MRW(name) \
csr_``name``_next = csr_``name``_value; \
if (csr_en && csr_``name``_sel) begin \
  csr_ack = 1; \
  csr_rdval = csr_``name``_value; \
  case (csr_mode) \
    2'b 01 /* RW */: csr_``name``_next = csr_rsval; \
    2'b 10 /* RS */: csr_``name``_next = csr_``name``_next | csr_rsval; \
    2'b 11 /* RC */: csr_``name``_next = csr_``name``_next & ~csr_rsval; \
  endcase \
end

	always @* begin
		csr_ack = 0;
		csr_rdval = 'hx;

		/* Machine Information CSRs */

		`NERV_CSR_MRO(mvendorid)
		`NERV_CSR_MRO(marchid)
		`NERV_CSR_MRO(mimpid)
		`NERV_CSR_MRO(mhartid)

		/* Machine Trap Setup CSRs */

		`NERV_CSR_MRW(mstatus)
		`NERV_CSR_MRW(misa)
		`NERV_CSR_MRW(medeleg)
		`NERV_CSR_MRW(mideleg)
		`NERV_CSR_MRW(mie)
		`NERV_CSR_MRW(mtvec)
//		`NERV_CSR_MRW(mcounteren)

		/* Machine Trap Handling CSRs */

		`NERV_CSR_MRW(mscratch)
		`NERV_CSR_MRW(mepc)
		`NERV_CSR_MRW(mcause)
		`NERV_CSR_MRW(mtval)
		`NERV_CSR_MRW(mip)

		/* Machine Memory Protection CSRs */

`ifdef NERV_PMP
		`NERV_CSR_MRW(pmpcfg0)
		`NERV_CSR_MRW(pmpcfg1)
		`NERV_CSR_MRW(pmpcfg2)
		`NERV_CSR_MRW(pmpcfg3)

		`NERV_CSR_MRW(pmpaddr0)
		`NERV_CSR_MRW(pmpaddr1)
		`NERV_CSR_MRW(pmpaddr2)
		`NERV_CSR_MRW(pmpaddr3)
		`NERV_CSR_MRW(pmpaddr4)
		`NERV_CSR_MRW(pmpaddr5)
		`NERV_CSR_MRW(pmpaddr6)
		`NERV_CSR_MRW(pmpaddr7)
		`NERV_CSR_MRW(pmpaddr8)
		`NERV_CSR_MRW(pmpaddr9)
		`NERV_CSR_MRW(pmpaddr10)
		`NERV_CSR_MRW(pmpaddr11)
		`NERV_CSR_MRW(pmpaddr12)
		`NERV_CSR_MRW(pmpaddr13)
		`NERV_CSR_MRW(pmpaddr14)
		`NERV_CSR_MRW(pmpaddr15)
`endif

		/* Machine Counter/Timers CSRs */

		`NERV_CSR_MRW(mcycle)
		`NERV_CSR_MRW(minstret)

		`NERV_CSR_MRW(mhpmcounter3)
		`NERV_CSR_MRW(mhpmcounter4)
		`NERV_CSR_MRW(mhpmcounter5)
		`NERV_CSR_MRW(mhpmcounter6)
		`NERV_CSR_MRW(mhpmcounter7)
		`NERV_CSR_MRW(mhpmcounter8)
		`NERV_CSR_MRW(mhpmcounter9)
		`NERV_CSR_MRW(mhpmcounter10)
		`NERV_CSR_MRW(mhpmcounter11)
		`NERV_CSR_MRW(mhpmcounter12)
		`NERV_CSR_MRW(mhpmcounter13)
		`NERV_CSR_MRW(mhpmcounter14)
		`NERV_CSR_MRW(mhpmcounter15)
		`NERV_CSR_MRW(mhpmcounter16)
		`NERV_CSR_MRW(mhpmcounter17)
		`NERV_CSR_MRW(mhpmcounter18)
		`NERV_CSR_MRW(mhpmcounter19)
		`NERV_CSR_MRW(mhpmcounter20)
		`NERV_CSR_MRW(mhpmcounter21)
		`NERV_CSR_MRW(mhpmcounter22)
		`NERV_CSR_MRW(mhpmcounter23)
		`NERV_CSR_MRW(mhpmcounter24)
		`NERV_CSR_MRW(mhpmcounter25)
		`NERV_CSR_MRW(mhpmcounter26)
		`NERV_CSR_MRW(mhpmcounter27)
		`NERV_CSR_MRW(mhpmcounter28)
		`NERV_CSR_MRW(mhpmcounter29)
		`NERV_CSR_MRW(mhpmcounter30)
		`NERV_CSR_MRW(mhpmcounter31)

		`NERV_CSR_MRW(mcycleh)
		`NERV_CSR_MRW(minstreth)

		`NERV_CSR_MRW(mhpmcounter3h)
		`NERV_CSR_MRW(mhpmcounter4h)
		`NERV_CSR_MRW(mhpmcounter5h)
		`NERV_CSR_MRW(mhpmcounter6h)
		`NERV_CSR_MRW(mhpmcounter7h)
		`NERV_CSR_MRW(mhpmcounter8h)
		`NERV_CSR_MRW(mhpmcounter9h)
		`NERV_CSR_MRW(mhpmcounter10h)
		`NERV_CSR_MRW(mhpmcounter11h)
		`NERV_CSR_MRW(mhpmcounter12h)
		`NERV_CSR_MRW(mhpmcounter13h)
		`NERV_CSR_MRW(mhpmcounter14h)
		`NERV_CSR_MRW(mhpmcounter15h)
		`NERV_CSR_MRW(mhpmcounter16h)
		`NERV_CSR_MRW(mhpmcounter17h)
		`NERV_CSR_MRW(mhpmcounter18h)
		`NERV_CSR_MRW(mhpmcounter19h)
		`NERV_CSR_MRW(mhpmcounter20h)
		`NERV_CSR_MRW(mhpmcounter21h)
		`NERV_CSR_MRW(mhpmcounter22h)
		`NERV_CSR_MRW(mhpmcounter23h)
		`NERV_CSR_MRW(mhpmcounter24h)
		`NERV_CSR_MRW(mhpmcounter25h)
		`NERV_CSR_MRW(mhpmcounter26h)
		`NERV_CSR_MRW(mhpmcounter27h)
		`NERV_CSR_MRW(mhpmcounter28h)
		`NERV_CSR_MRW(mhpmcounter29h)
		`NERV_CSR_MRW(mhpmcounter30h)
		`NERV_CSR_MRW(mhpmcounter31h)

		{csr_mcycleh_next, csr_mcycle_next} = {csr_mcycleh_next, csr_mcycle_next} + 1;

		if (!trapped && !stall) begin
			{csr_minstreth_next, csr_minstret_next} = {csr_minstreth_next, csr_minstret_next} + 1;
		end

		/* Machine Counter Setup CSRs */

//		`NERV_CSR_MRW(mcountinhibit)
		`NERV_CSR_MRW(mhpmevent3)
		`NERV_CSR_MRW(mhpmevent4)
		`NERV_CSR_MRW(mhpmevent5)
		`NERV_CSR_MRW(mhpmevent6)
		`NERV_CSR_MRW(mhpmevent7)
		`NERV_CSR_MRW(mhpmevent8)
		`NERV_CSR_MRW(mhpmevent9)
		`NERV_CSR_MRW(mhpmevent10)
		`NERV_CSR_MRW(mhpmevent11)
		`NERV_CSR_MRW(mhpmevent12)
		`NERV_CSR_MRW(mhpmevent13)
		`NERV_CSR_MRW(mhpmevent14)
		`NERV_CSR_MRW(mhpmevent15)
		`NERV_CSR_MRW(mhpmevent16)
		`NERV_CSR_MRW(mhpmevent17)
		`NERV_CSR_MRW(mhpmevent18)
		`NERV_CSR_MRW(mhpmevent19)
		`NERV_CSR_MRW(mhpmevent20)
		`NERV_CSR_MRW(mhpmevent21)
		`NERV_CSR_MRW(mhpmevent22)
		`NERV_CSR_MRW(mhpmevent23)
		`NERV_CSR_MRW(mhpmevent24)
		`NERV_CSR_MRW(mhpmevent25)
		`NERV_CSR_MRW(mhpmevent26)
		`NERV_CSR_MRW(mhpmevent27)
		`NERV_CSR_MRW(mhpmevent28)
		`NERV_CSR_MRW(mhpmevent29)
		`NERV_CSR_MRW(mhpmevent30)
		`NERV_CSR_MRW(mhpmevent31)
	end

	/************************
	 *  END OF CSR SECTION  *
	 ************************/
`endif

	always @* begin
		// advance pc
		npc = pc + 4;

		// defaults for read, write
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
		mem_rd_func = 'hx;

`ifdef NERV_CSR
		// defaults for CSR interface
		csr_mode = 0;
		csr_addr = 'hx;
		csr_rsval = 'hx;
		csr_rdval = 'hx;
`endif

		// act on opcodes
		case (insn_opcode)
			// Load Upper Immediate
			OPCODE_LUI: begin
				next_wr = 1;
				next_rd = insn[31:12] << 12;
			end
			// Add Upper Immediate to Program Counter
			OPCODE_AUIPC: begin
				next_wr = 1;
				next_rd = (insn[31:12] << 12) + pc;
			end
			// Jump And Link (unconditional jump)
			OPCODE_JAL: begin
				next_wr = 1;
				next_rd = npc;
				npc = pc + imm_j_sext;
				if (npc & 32'b 11) begin
					illinsn = 1;
					npc = npc & ~32'b 11;
				end
			end
			// Jump And Link Register (indirect jump)
			OPCODE_JALR: begin
				case (insn_funct3)
					3'b 000 /* JALR */: begin
						next_wr = 1;
						next_rd = npc;
						npc = (rs1_value + imm_i_sext) & ~32'b 1;
					end
					default: illinsn = 1;
				endcase
				if (npc & 32'b 11) begin
					illinsn = 1;
					npc = npc & ~32'b 11;
				end
			end
			// branch instructions: Branch If Equal, Branch Not Equal, Branch Less Than, Branch Greater Than, Branch Less Than Unsigned, Branch Greater Than Unsigned
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
				if (npc & 32'b 11) begin
					illinsn = 1;
					npc = npc & ~32'b 11;
				end
			end
			// load from memory into rd: Load Byte, Load Halfword, Load Word, Load Byte Unsigned, Load Halfword Unsigned
			OPCODE_LOAD: begin
				mem_rd_addr = rs1_value + imm_i_sext;
				casez ({insn_funct3, mem_rd_addr[1:0]})
					5'b 000_zz /* LB  */,
					5'b 001_z0 /* LH  */,
					5'b 010_00 /* LW  */,
					5'b 100_zz /* LBU */,
					5'b 101_z0 /* LHU */: begin
						mem_rd_enable = 1;
						mem_rd_reg = insn_rd;
						mem_rd_func = {mem_rd_addr[1:0], insn_funct3};
						mem_rd_addr = {mem_rd_addr[31:2], 2'b 00};
					end
					default: illinsn = 1;
				endcase
			end
			// store to memory instructions: Store Byte, Store Halfword, Store Word
			OPCODE_STORE: begin
				mem_wr_addr = rs1_value + imm_s_sext;
				casez ({insn_funct3, mem_wr_addr[1:0]})
					5'b 000_zz /* SB */,
					5'b 001_z0 /* SH */,
					5'b 010_00 /* SW */: begin
						mem_wr_enable = 1;
						mem_wr_data = rs2_value;
						mem_wr_strb = 4'b 1111;
						case (insn_funct3)
							3'b 000 /* SB  */: begin mem_wr_strb = 4'b 0001; end
							3'b 001 /* SH  */: begin mem_wr_strb = 4'b 0011; end
							3'b 010 /* SW  */: begin mem_wr_strb = 4'b 1111; end
						endcase
						mem_wr_data = mem_wr_data << (8*mem_wr_addr[1:0]);
						mem_wr_strb = mem_wr_strb << mem_wr_addr[1:0];
						mem_wr_addr = {mem_wr_addr[31:2], 2'b 00};
					end
					default: illinsn = 1;
				endcase
			end
			// immediate ALU instructions: Add Immediate, Set Less Than Immediate, Set Less Than Immediate Unsigned, XOR Immediate,
			// OR Immediate, And Immediate, Shift Left Logical Immediate, Shift Right Logical Immediate, Shift Right Arithmetic Immediate
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
			// ALU instructions: Add, Subtract, Shift Left Logical, Set Left Than, Set Less Than Unsigned, XOR, Shift Right Logical,
			// Shift Right Arithmetic, OR, AND
				case ({insn_funct7, insn_funct3})
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
`ifdef NERV_CSR
			OPCODE_SYSTEM: begin
				csr_mode = insn_funct3[1:0];
				if (csr_mode) begin
					csr_addr = imm_i;
					csr_rsval = insn_funct3[2] ? insn_rs1 : rs1_value;
					next_rd = csr_rdval;
					illinsn = !csr_ack;
				end else
					illinsn = 1;
			end
`endif
			default: illinsn = 1;
		endcase

		// if last cycle was a memory read, then this cycle is the 2nd part of it and imem_data will not be a valid instruction
		if (mem_rd_enable_q) begin
			npc = pc;
			next_wr = 0;
			illinsn = 0;
			mem_rd_enable = 0;
			mem_wr_enable = 0;
		end

		// reset
		if (reset || reset_q) begin
			npc = RESET_ADDR;
			next_wr = 0;
			illinsn = 0;
			mem_rd_enable = 0;
			mem_wr_enable = 0;
		end
	end

	reg reset_q;
	reg [31:0] mem_rdata;
`ifdef NERV_RVFI
	reg rvfi_pre_valid;
	reg [ 4:0] rvfi_pre_rd_addr;
	reg [31:0] rvfi_pre_rd_wdata;
`endif

	// mem read functions: Lower and Upper Bytes, signed and unsigned
	always @* begin
		mem_rdata = dmem_rdata >> (8*mem_rd_func_q[4:3]);
		case (mem_rd_func_q[2:0])
			3'b 000 /* LB  */: begin mem_rdata = $signed(mem_rdata[7:0]); end
			3'b 001 /* LH  */: begin mem_rdata = $signed(mem_rdata[15:0]); end
			3'b 100 /* LBU */: begin mem_rdata = mem_rdata[7:0]; end
			3'b 101 /* LHU */: begin mem_rdata = mem_rdata[15:0]; end
		endcase
	end

	// every cycle
	always @(posedge clock) begin
		reset_q <= reset;
		trapped_q <= trapped;

		// increment pc if possible
		if (!trapped && !stall && !reset && !reset_q) begin
			if (illinsn)
				trapped <= 1;
			pc <= npc;
`ifdef NERV_RVFI
			rvfi_pre_valid <= !mem_rd_enable_q;
			rvfi_order <= rvfi_order + 1;
			rvfi_insn <= insn;
			rvfi_trap <= illinsn;
			rvfi_halt <= illinsn;
			rvfi_intr <= 0;
			rvfi_mode <= 3;
			rvfi_ixl <= 1;
			rvfi_rs1_addr <= insn_rs1;
			rvfi_rs2_addr <= insn_rs2;
			rvfi_rs1_rdata <= rs1_value;
			rvfi_rs2_rdata <= rs2_value;
			rvfi_pre_rd_addr <= next_wr ? insn_rd : 0;
			rvfi_pre_rd_wdata <= next_wr && insn_rd ? next_rd : 0;
			rvfi_pc_rdata <= pc;
			rvfi_pc_wdata <= npc;
			if (dmem_valid) begin
				rvfi_mem_addr <= dmem_addr;
				case ({mem_rd_enable, insn_funct3})
					4'b 1_000 /* LB  */: begin rvfi_mem_rmask <= 4'b 0001 << mem_rd_func[4:3]; end
					4'b 1_001 /* LH  */: begin rvfi_mem_rmask <= 4'b 0011 << mem_rd_func[4:3]; end
					4'b 1_010 /* LW  */: begin rvfi_mem_rmask <= 4'b 1111 << mem_rd_func[4:3]; end
					4'b 1_100 /* LBU */: begin rvfi_mem_rmask <= 4'b 0001 << mem_rd_func[4:3]; end
					4'b 1_101 /* LHU */: begin rvfi_mem_rmask <= 4'b 0011 << mem_rd_func[4:3]; end
					default: rvfi_mem_rmask <= 0;
				endcase
				rvfi_mem_wmask <= dmem_wstrb;
				rvfi_mem_wdata <= dmem_wdata;
			end else begin
				rvfi_mem_addr <= 0;
				rvfi_mem_rmask <= 0;
				rvfi_mem_wmask <= 0;
				rvfi_mem_wdata <= 0;
			end
`endif
			// update registers from memory or rd (destination)
			if (mem_rd_enable_q || next_wr)
				regfile[mem_rd_enable_q ? mem_rd_reg_q : insn_rd] <= mem_rd_enable_q ? mem_rdata : next_rd;
		end

		// reset
		if (reset || reset_q) begin
			pc <= RESET_ADDR - (reset ? 4 : 0);
			trapped <= 0;
`ifdef NERV_RVFI
			rvfi_pre_valid <= 0;
			rvfi_order <= 0;
`endif
		end
	end

`ifdef NERV_RVFI
	always @* begin
		if (mem_rd_enable_q) begin
			rvfi_rd_addr = mem_rd_reg_q;
			rvfi_rd_wdata = mem_rd_reg_q ? mem_rdata : 0;
		end else begin
			rvfi_rd_addr = rvfi_pre_rd_addr;
			rvfi_rd_wdata = rvfi_pre_rd_wdata;
		end
		rvfi_valid = rvfi_pre_valid && !stall && !reset && !reset_q && !trapped_q;
		rvfi_mem_rdata = dmem_rdata;
	end
`endif

`ifdef NERV_DBGREGS
	wire [31:0] dbg_reg_x0  = 0;
	wire [31:0] dbg_reg_x1  = regfile[1];
	wire [31:0] dbg_reg_x2  = regfile[2];
	wire [31:0] dbg_reg_x3  = regfile[3];
	wire [31:0] dbg_reg_x4  = regfile[4];
	wire [31:0] dbg_reg_x5  = regfile[5];
	wire [31:0] dbg_reg_x6  = regfile[6];
	wire [31:0] dbg_reg_x7  = regfile[7];
	wire [31:0] dbg_reg_x8  = regfile[8];
	wire [31:0] dbg_reg_x9  = regfile[9];
	wire [31:0] dbg_reg_x10 = regfile[10];
	wire [31:0] dbg_reg_x11 = regfile[11];
	wire [31:0] dbg_reg_x12 = regfile[12];
	wire [31:0] dbg_reg_x13 = regfile[13];
	wire [31:0] dbg_reg_x14 = regfile[14];
	wire [31:0] dbg_reg_x15 = regfile[15];
	wire [31:0] dbg_reg_x16 = regfile[16];
	wire [31:0] dbg_reg_x17 = regfile[17];
	wire [31:0] dbg_reg_x18 = regfile[18];
	wire [31:0] dbg_reg_x19 = regfile[19];
	wire [31:0] dbg_reg_x20 = regfile[20];
	wire [31:0] dbg_reg_x21 = regfile[21];
	wire [31:0] dbg_reg_x22 = regfile[22];
	wire [31:0] dbg_reg_x23 = regfile[23];
	wire [31:0] dbg_reg_x24 = regfile[24];
	wire [31:0] dbg_reg_x25 = regfile[25];
	wire [31:0] dbg_reg_x26 = regfile[26];
	wire [31:0] dbg_reg_x27 = regfile[27];
	wire [31:0] dbg_reg_x28 = regfile[28];
	wire [31:0] dbg_reg_x29 = regfile[29];
	wire [31:0] dbg_reg_x30 = regfile[30];
	wire [31:0] dbg_reg_x31 = regfile[31];
`endif
endmodule
