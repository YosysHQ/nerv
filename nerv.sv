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

`ifdef NERV_CSR
	/**********************
	 *  CSR DECLARATIONS  *
	 **********************/

	// Note: The Memory-Mapped Machine Timers (mtime and timecmp) are not
	// part of the processor core itself. It's up to the SoC to provide
	// this part of the RISC-V M-Mode Spec.

	// FIXME: Additional instructions: ECALL, EBREAK, MRET, WFI

`define NERV_MACHINE_CSRS /* Machine Information CSRs */				\
	`NERV_CSR_VAL_MRO(mvendorid,         12'h F11, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRO(marchid,           12'h F12, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRO(mimpid,            12'h F13, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRO(mhartid,           12'h F14, 31'h 0000_0000)

`define NERV_TRAP_SETUP_CSRS /* Machine Trap Setup CSRs */				\
	`NERV_CSR_REG_MRW(mstatus,           12'h 300, 31'h 0000_0000)   /* FIXME */	\
	`NERV_CSR_VAL_MRW(misa,              12'h 301, 31'h 0000_0000)   /* FIXME */	\
	`NERV_CSR_REG_MRW(medeleg,           12'h 302, 31'h 0000_0000)   /* FIXME */	\
	`NERV_CSR_REG_MRW(mideleg,           12'h 303, 31'h 0000_0000)   /* FIXME */	\
	`NERV_CSR_REG_MRW(mie,               12'h 304, 31'h 0000_0000)   /* FIXME */	\
	`NERV_CSR_REG_MRW(mtvec,             12'h 305, 31'h 0000_0000)   /* FIXME */	\
/*	`NERV_CSR_REG_MRW(mcounteren,        12'h 306, 31'h 0000_0000) */

`define NERV_TRAP_HANDLING_CSRS /* Machine Trap Handling CSRs */			\
	`NERV_CSR_REG_MRW(mscratch,          12'h 340, 31'h 0000_0000)	 		\
	`NERV_CSR_REG_MRW(mepc,              12'h 341, 31'h 0000_0000)   /* FIXME */	\
	`NERV_CSR_REG_MRW(mcause,            12'h 342, 31'h 0000_0000)   /* FIXME */	\
	`NERV_CSR_REG_MRW(mtval,             12'h 343, 31'h 0000_0000)   /* FIXME */	\
	`NERV_CSR_REG_MRW(mip,               12'h 344, 31'h 0000_0000)   /* FIXME */

`ifdef NERV_PMP
`define NERV_PMP_CFG_CSRS /* Machine Memory Protection Config CSRs */			\
	`NERV_CSR_VAL_MRW(pmpcfg0,           12'h 3A0, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpcfg1,           12'h 3A1, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpcfg2,           12'h 3A2, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpcfg3,           12'h 3A3, 31'h 0000_0000)

`define NERV_PMP_ADDR_CSRS /* Machine Memory Protection Addr CSRs */			\
	`NERV_CSR_VAL_MRW(pmpaddr0,          12'h 3B0, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr1,          12'h 3B1, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr2,          12'h 3B2, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr3,          12'h 3B3, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr4,          12'h 3B4, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr5,          12'h 3B5, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr6,          12'h 3B6, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr7,          12'h 3B7, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr8,          12'h 3B8, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr9,          12'h 3B9, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr10,         12'h 3BA, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr11,         12'h 3BB, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr12,         12'h 3BC, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr13,         12'h 3BD, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr14,         12'h 3BE, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(pmpaddr15,         12'h 3BF, 31'h 0000_0000)
`else
`define NERV_PMP_CFG_CSRS
`define NERV_PMP_ADDR_CSRS
`endif

`define NERV_COUNTER_CSRS /* Machine Counter/Timers CSRs */				\
	`NERV_CSR_REG_MRW(mcycle,            12'h B00, 31'h 0000_0000)			\
	`NERV_CSR_REG_MRW(minstret,          12'h B02, 31'h 0000_0000)			\
											\
	`NERV_CSR_VAL_MRW(mhpmcounter3,      12'h B03, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter4,      12'h B04, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter5,      12'h B05, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter6,      12'h B06, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter7,      12'h B07, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter8,      12'h B08, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter9,      12'h B09, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter10,     12'h B0A, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter11,     12'h B0B, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter12,     12'h B0C, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter13,     12'h B0D, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter14,     12'h B0E, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter15,     12'h B0F, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter16,     12'h B10, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter17,     12'h B11, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter18,     12'h B12, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter19,     12'h B13, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter20,     12'h B14, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter21,     12'h B15, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter22,     12'h B16, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter23,     12'h B17, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter24,     12'h B18, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter25,     12'h B19, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter26,     12'h B1A, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter27,     12'h B1B, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter28,     12'h B1C, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter29,     12'h B1D, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter30,     12'h B1E, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter31,     12'h B1F, 31'h 0000_0000)			\
	                        							\
	`NERV_CSR_REG_MRW(mcycleh,           12'h B80, 31'h 0000_0000)			\
	`NERV_CSR_REG_MRW(minstreth,         12'h B82, 31'h 0000_0000)			\
	                        							\
	`NERV_CSR_VAL_MRW(mhpmcounter3h,     12'h B03, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter4h,     12'h B04, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter5h,     12'h B05, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter6h,     12'h B06, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter7h,     12'h B07, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter8h,     12'h B08, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter9h,     12'h B09, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter10h,    12'h B0A, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter11h,    12'h B0B, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter12h,    12'h B0C, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter13h,    12'h B0D, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter14h,    12'h B0E, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter15h,    12'h B0F, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter16h,    12'h B10, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter17h,    12'h B11, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter18h,    12'h B12, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter19h,    12'h B13, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter20h,    12'h B14, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter21h,    12'h B15, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter22h,    12'h B16, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter23h,    12'h B17, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter24h,    12'h B18, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter25h,    12'h B19, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter26h,    12'h B1A, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter27h,    12'h B1B, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter28h,    12'h B1C, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter29h,    12'h B1D, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter30h,    12'h B1E, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmcounter31h,    12'h B1F, 31'h 0000_0000)

`define NERV_COUNTER_SETUP_CSRS /* Machine Counter Setup CSRs */			\
/*	`NERV_CSR_VAL_MRW(mcountinhibit,     12'h 320, 31'h 0000_0000) */		\
	`NERV_CSR_VAL_MRW(mhpmevent3,        12'h 323, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent4,        12'h 324, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent5,        12'h 325, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent6,        12'h 326, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent7,        12'h 327, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent8,        12'h 328, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent9,        12'h 329, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent10,       12'h 32A, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent11,       12'h 32B, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent12,       12'h 32C, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent13,       12'h 32D, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent14,       12'h 32E, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent15,       12'h 32F, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent16,       12'h 330, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent17,       12'h 331, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent18,       12'h 332, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent19,       12'h 333, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent20,       12'h 334, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent21,       12'h 335, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent22,       12'h 336, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent23,       12'h 337, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent24,       12'h 338, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent25,       12'h 339, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent26,       12'h 33A, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent27,       12'h 33B, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent28,       12'h 33C, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent29,       12'h 33D, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent30,       12'h 33E, 31'h 0000_0000)			\
	`NERV_CSR_VAL_MRW(mhpmevent31,       12'h 33F, 31'h 0000_0000)

`define NERV_CSRS			\
	`NERV_MACHINE_CSRS		\
	`NERV_TRAP_SETUP_CSRS		\
	`NERV_TRAP_HANDLING_CSRS	\
	`NERV_PMP_CFG_CSRS		\
	`NERV_PMP_ADDR_CSRS		\
	`NERV_COUNTER_CSRS		\
	`NERV_COUNTER_SETUP_CSRS
`endif

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

`ifdef NERV_CSR
`define NERV_CSR_REG_MRW(NAME, ADDR, VALUE)			\
	output reg [31:0] rvfi_csr_``NAME``_rmask,		\
	output reg [31:0] rvfi_csr_``NAME``_wmask,		\
	output reg [31:0] rvfi_csr_``NAME``_rdata,		\
	output reg [31:0] rvfi_csr_``NAME``_wdata,

`define NERV_CSR_VAL_MRW(NAME, ADDR, VALUE)			\
	`NERV_CSR_REG_MRW(NAME, ADDR, VALUE)

`define NERV_CSR_VAL_MRO(NAME, ADDR, VALUE)			\
	`NERV_CSR_REG_MRW(NAME, ADDR, VALUE)

`NERV_CSRS
`undef NERV_CSR_REG_MRW
`undef NERV_CSR_VAL_MRW
`undef NERV_CSR_VAL_MRO
`endif

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

	// components of the instruction
	wire [6:0] insn_funct7;
	wire [4:0] insn_rs2;
	wire [4:0] insn_rs1;
	wire [2:0] insn_funct3;
	wire [4:0] insn_rd;
	wire [6:0] insn_opcode;

	// rs1 and rs2 are source for the instruction
	wire [31:0] rs1_value = !insn_rs1 ? 0 : regfile[insn_rs1];
	wire [31:0] rs2_value = !insn_rs2 ? 0 : regfile[insn_rs2];

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

	reg reset_q;
	wire running = !trapped && !stall && !reset && !reset_q;

`ifdef NERV_CSR
	/*********************
	 *  CSR DEFINITIONS  *
	 *********************/

	reg        csr_ack;
	reg [31:0] csr_rdval;
	reg [31:0] csr_next;

	wire [ 1:0] csr_mode = (running && insn_opcode == OPCODE_SYSTEM) ? insn_funct3[1:0] : 2'b 00; // 00=None, 01=RW, 10=RS, 11=RC
	wire [11:0] csr_addr = imm_i;
	wire [31:0] csr_rsval = insn_funct3[2] ? insn_rs1 : rs1_value;
	wire csr_ro = csr_mode && (csr_mode != 2'b01 && !csr_rsval);

`define NERV_CSR_REG_MRW(NAME, ADDR, VALUE)				\
	wire csr_``NAME``_sel = csr_mode && csr_addr == ADDR;		\
	reg [31:0] csr_``NAME``_value;					\
	reg [31:0] csr_``NAME``_wdata;					\
	reg [31:0] csr_``NAME``_next;					\
	always @(posedge clock) begin					\
		csr_``NAME``_value <= csr_``NAME``_next;		\
		if (reset || reset_q)					\
			csr_``NAME``_value <= VALUE;			\
	end

`define NERV_CSR_VAL_MRW(NAME, ADDR, VALUE)				\
	wire csr_``NAME``_sel = csr_mode && csr_addr == ADDR;		\
	localparam [31:0] csr_``NAME``_value = VALUE;

`define NERV_CSR_VAL_MRO(NAME, ADDR, VALUE)				\
	wire csr_``NAME``_sel = csr_ro && csr_addr == ADDR;		\
	localparam [31:0] csr_``NAME``_value = VALUE;

`NERV_CSRS
`undef NERV_CSR_REG_MRW
`undef NERV_CSR_VAL_MRW
`undef NERV_CSR_VAL_MRO

`endif // NERV_CSR

	always @* begin
		// advance pc
		npc = pc + 4;

		// defaults for read, write
		next_wr = 0;
		next_rd = 0;
		illinsn = 0;

		mem_wr_enable = 0;
		mem_wr_addr = 32'hx;
		mem_wr_data = 32'hx;
		mem_wr_strb = 4'hx;

		mem_rd_enable = 0;
		mem_rd_addr = 32'hx;
		mem_rd_reg = 5'hx;
		mem_rd_func = 5'hx;

`ifdef NERV_CSR
		csr_ack = 0;
		csr_rdval = 'hx;

		case (1'b1)
`define NERV_CSR_REG_MRW(NAME, ADDR, VALUE)		\
			csr_mode && csr_``NAME``_sel: begin		\
				csr_ack = 1;				\
				csr_rdval = csr_``NAME``_value;	\
			end

`define NERV_CSR_VAL_MRW(NAME, ADDR, VALUE)		\
			csr_mode && csr_``NAME``_sel: begin		\
				csr_ack = 1;				\
				csr_rdval = csr_``NAME``_value;	\
			end

`define NERV_CSR_VAL_MRO(NAME, ADDR, VALUE)		\
			csr_ro && csr_``NAME``_sel: begin		\
				csr_ack = 1;				\
				csr_rdval = csr_``NAME``_value;	\
			end

`NERV_CSRS
`undef NERV_CSR_REG_MRW
`undef NERV_CSR_VAL_MRW
`undef NERV_CSR_VAL_MRO

			default: /* nothing */;
		endcase

		csr_next = csr_rdval;
		case (csr_mode)
			2'b 01 /* RW */: csr_next = csr_rsval;
			2'b 10 /* RS */: csr_next = csr_next | csr_rsval;
			2'b 11 /* RC */: csr_next = csr_next & ~csr_rsval;
		endcase

`define NERV_CSR_REG_MRW(NAME, ADDR, VALUE) \
		csr_``NAME``_wdata = csr_``NAME``_sel ? csr_next : csr_``NAME``_value; \
		csr_``NAME``_next = csr_``NAME``_wdata;

`define NERV_CSR_VAL_MRW(NAME, ADDR, VALUE)
`define NERV_CSR_VAL_MRO(NAME, ADDR, VALUE)

`NERV_CSRS
`undef NERV_CSR_REG_MRW
`undef NERV_CSR_VAL_MRW
`undef NERV_CSR_VAL_MRO

		{csr_mcycleh_next, csr_mcycle_next} = {csr_mcycleh_next, csr_mcycle_next} + 1;

		if (running) begin
			{csr_minstreth_next, csr_minstret_next} = {csr_minstreth_next, csr_minstret_next} + 1;
		end
`endif // NERV_CSR

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
				if (csr_ack) begin
					next_wr = 1;
					next_rd = csr_rdval;
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
		if (running) begin
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
`ifdef NERV_CSR
`define NERV_CSR_REG_MRW(NAME, ADDR, VALUE) \
			rvfi_csr_``NAME``_rmask <= 32'h ffff_ffff;	\
			rvfi_csr_``NAME``_wmask <= 32'h ffff_ffff;	\
			rvfi_csr_``NAME``_rdata <= csr_``NAME``_value;	\
			rvfi_csr_``NAME``_wdata <= csr_``NAME``_wdata;

`define NERV_CSR_VAL_MRW(NAME, ADDR, VALUE) \
			rvfi_csr_``NAME``_rmask <= 32'h ffff_ffff;	\
			rvfi_csr_``NAME``_wmask <= 32'h ffff_ffff;	\
			rvfi_csr_``NAME``_rdata <= csr_``NAME``_value;	\
			rvfi_csr_``NAME``_wdata <= csr_``NAME``_value;

`define NERV_CSR_VAL_MRO(NAME, ADDR, VALUE) \
	`NERV_CSR_VAL_MRW(NAME, ADDR, VALUE)

`NERV_CSRS
`undef NERV_CSR_REG_MRW
`undef NERV_CSR_VAL_MRW
`undef NERV_CSR_VAL_MRO
`endif
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
