/*
 *  NERV -- Naive Educational RISC-V Processor
 *
 *  Copyright (C) 2023  Jannis Harder <jix@yosyshq.com> <me@jix.one>
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

 module nerv_axi_lite_adapter (
	input clock,
	input reset,

	// AXI4-Lite instruction memory interface
	output            imem_axi_arvalid,
	input             imem_axi_arready,
	output reg [31:0] imem_axi_araddr,
	output     [ 2:0] imem_axi_arprot,

	input             imem_axi_rvalid,
	output            imem_axi_rready,
	input      [31:0] imem_axi_rdata,
	input      [ 1:0] imem_axi_rresp,

	// AXI4-Lite data memory interface
	output reg        dmem_axi_awvalid,
	input             dmem_axi_awready,
	output reg [31:0] dmem_axi_awaddr,
	output     [ 2:0] dmem_axi_awprot,

	output reg        dmem_axi_wvalid,
	input             dmem_axi_wready,
	output reg [31:0] dmem_axi_wdata,
	output reg [ 3:0] dmem_axi_wstrb,

	input             dmem_axi_bvalid,
	output            dmem_axi_bready,
	input      [ 1:0] dmem_axi_bresp,

	output reg        dmem_axi_arvalid,
	input             dmem_axi_arready,
	output reg [31:0] dmem_axi_araddr,
	output     [ 2:0] dmem_axi_arprot,

	input             dmem_axi_rvalid,
	output            dmem_axi_rready,
	input      [31:0] dmem_axi_rdata,
	input      [ 1:0] dmem_axi_rresp,

	// NERV memory interface
	output            mem_stall,

	input             stall,

	input      [31:0] imem_addr,
	output reg [31:0] imem_data,

	input             dmem_valid,
	input      [31:0] dmem_addr,
	input      [ 3:0] dmem_wstrb,
	input      [31:0] dmem_wdata,
	output reg [31:0] dmem_rdata
);

	reg reset_q;

	always @(posedge clock)
		reset_q <= reset;

	// === imem read ===

	// AXI4 requries no valid signals in the first post-reset cycle, NERV
	// starts an imem read in that cycle. We implement this by operating on
	// imem_axi_arvalid_internal and imem_axi_arready_internal instead of the
	// AXI signals. They are the same as the AXI signals except for the first
	// post-reset cycle where imem_axi_arvalid is 0 even when
	// imem_axi_arvalid_internal is 1 and imem_axi_arready_internal is 0 even
	// when imem_axi_arready is 1.
	reg imem_axi_arvalid_internal;
	reg imem_axi_arvalid_internal_q;

	wire imem_axi_arready_internal;
	reg imem_axi_arready_internal_q;

	assign imem_axi_arready_internal = imem_axi_arready && !reset_q;
	assign imem_axi_arvalid = imem_axi_arvalid_internal && !reset_q;

	reg [31:0] imem_axi_araddr_q;
	reg [31:0] next_imem_data;

	assign imem_axi_arprot = 3'b111;
	assign imem_axi_rready = 1;

	reg next_imem_rstall;
	reg imem_rstall;

	always @* begin
		imem_axi_araddr = imem_axi_araddr_q;
		imem_axi_arvalid_internal = imem_axi_arvalid_internal_q;
		next_imem_rstall = imem_rstall;
		next_imem_data = imem_data;

		// reset valid when ready was active in the last cycle
		if (imem_axi_arready_internal_q)
			imem_axi_arvalid_internal = 0;

		// perform an imem read after reset or when the imem addr changed
		if (!next_imem_rstall && !imem_axi_arvalid_internal &&
				(reset_q || imem_addr != imem_axi_araddr)) begin
			imem_axi_araddr = imem_addr;
			imem_axi_arvalid_internal = 1;
			next_imem_rstall = 1;
		end

		// imem read response
		next_imem_data = imem_data;
		if (imem_axi_rready && imem_axi_rvalid) begin
			// TODO handle imem_axi_rresp?
			next_imem_data = imem_axi_rdata;
			next_imem_rstall = 0;
		end

		// stop active reads when in reset
		if (reset) begin
			imem_axi_arvalid_internal = 0;
			next_imem_rstall = 0;
		end
	end

	always @(posedge clock) begin
		imem_rstall <= next_imem_rstall;
		imem_data <= next_imem_data;

		imem_axi_arvalid_internal_q <= imem_axi_arvalid_internal;
		imem_axi_arready_internal_q <= imem_axi_arready_internal;
		imem_axi_araddr_q <= imem_axi_araddr;
	end

	// === dmem read ===
	reg dmem_axi_arvalid_q;
	reg dmem_axi_arready_q;

	reg [31:0] dmem_axi_araddr_q;
	reg [31:0] dmem_rdata_q;

	assign dmem_axi_arprot = 3'b011;
	assign dmem_axi_rready = 1;

	reg next_dmem_rstall;
	reg dmem_rstall;

	always @* begin
		dmem_axi_araddr = dmem_axi_araddr_q;
		dmem_axi_arvalid = dmem_axi_arvalid_q;
		next_dmem_rstall = dmem_rstall;

		// reset valid when ready was active in the last cycle
		if (dmem_axi_arready_q)
			dmem_axi_arvalid = 0;

		// perform a dmem read when requested by NERV
		if (!next_dmem_rstall && !dmem_axi_arvalid &&
				!stall && dmem_valid && !dmem_wstrb) begin
			dmem_axi_araddr = dmem_addr;
			dmem_axi_arvalid = 1;
			next_dmem_rstall = 1;
		end

		// dmem read response
		dmem_rdata = dmem_rdata_q;
		if (dmem_axi_rready && dmem_axi_rvalid) begin
			// TODO handle imem_axi_rresp?
			dmem_rdata = dmem_axi_rdata;
			next_dmem_rstall = 0;
		end

		// stop active reads when in reset
		if (reset) begin
			dmem_axi_arvalid = 0;
			next_dmem_rstall = 0;
		end
	end

	always @(posedge clock) begin
		dmem_rstall <= next_dmem_rstall;
		dmem_rdata_q <= dmem_rdata;

		dmem_axi_arvalid_q <= dmem_axi_arvalid;
		dmem_axi_arready_q <= dmem_axi_arready;
		dmem_axi_araddr_q <= dmem_axi_araddr;
	end

	// === dmem write ===
	reg dmem_axi_awvalid_q;
	reg dmem_axi_awready_q;
	reg [31:0] dmem_axi_awaddr_q;
	reg dmem_axi_wvalid_q;
	reg dmem_axi_wready_q;
	reg [31:0] dmem_axi_wdata_q;
	reg [3:0] dmem_axi_wstrb_q;

	assign dmem_axi_awprot = 3'b011;
	assign dmem_axi_bready = 1;

	reg next_dmem_wstall;
	reg dmem_wstall;

	always @* begin
		dmem_axi_awaddr = dmem_axi_awaddr_q;
		dmem_axi_awvalid = dmem_axi_awvalid_q;
		dmem_axi_wdata = dmem_axi_wdata_q;
		dmem_axi_wstrb = dmem_axi_wstrb_q;
		dmem_axi_wvalid = dmem_axi_wvalid_q;
		next_dmem_wstall = dmem_wstall;

		// reset valid when ready was active in the last cycle
		if (dmem_axi_awready_q)
			dmem_axi_awvalid = 0;

		if (dmem_axi_wready_q)
			dmem_axi_wvalid = 0;

		// perform a dmem write when requested by NERV
		if (!next_dmem_wstall && !dmem_axi_awvalid && !dmem_axi_wvalid &&
				!stall && dmem_valid && dmem_wstrb) begin
			dmem_axi_awaddr = dmem_addr;
			dmem_axi_awvalid = 1;
			dmem_axi_wdata = dmem_wdata;
			dmem_axi_wstrb = dmem_wstrb;
			dmem_axi_wvalid = 1;
			next_dmem_wstall = 1;
		end

		// dmem write response
		if (dmem_axi_bready && dmem_axi_bvalid) begin
			// TODO handle imem_axi_bresp?
			next_dmem_wstall = 0;
		end

		// stop active writes when in reset
		if (reset || reset_q) begin
			dmem_axi_awvalid = 0;
			dmem_axi_wvalid = 0;
			next_dmem_wstall = 0;
		end
	end

	always @(posedge clock) begin
		dmem_wstall <= next_dmem_wstall;

		dmem_axi_awvalid_q <= dmem_axi_awvalid;
		dmem_axi_awready_q <= dmem_axi_awready;
		dmem_axi_awaddr_q <= dmem_axi_awaddr;
		dmem_axi_wvalid_q <= dmem_axi_wvalid;
		dmem_axi_wready_q <= dmem_axi_wready;
		dmem_axi_wdata_q <= dmem_axi_wdata;
		dmem_axi_wstrb_q <= dmem_axi_wstrb;
	end

	// === stall logic ===

	assign mem_stall = !reset_q && (imem_rstall || dmem_wstall || dmem_rstall);

endmodule

module nerv_axi_lite #(
	parameter [31:0] RESET_ADDR = 32'h 0000_0000,
	parameter integer NUMREGS = 32
) (
	input clock,
	input reset,
	input stall,
	output stalled,
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

	// AXI4-Lite instruction memory interface
	output            imem_axi_arvalid,
	input             imem_axi_arready,
	output     [31:0] imem_axi_araddr,
	output     [ 2:0] imem_axi_arprot,

	input             imem_axi_rvalid,
	output            imem_axi_rready,
	input      [31:0] imem_axi_rdata,
	input      [ 1:0] imem_axi_rresp,

	// AXI4-Lite data memory interface
	output            dmem_axi_awvalid,
	input             dmem_axi_awready,
	output     [31:0] dmem_axi_awaddr,
	output     [ 2:0] dmem_axi_awprot,

	output            dmem_axi_wvalid,
	input             dmem_axi_wready,
	output     [31:0] dmem_axi_wdata,
	output     [ 3:0] dmem_axi_wstrb,

	input             dmem_axi_bvalid,
	output            dmem_axi_bready,
	input      [ 1:0] dmem_axi_bresp,

	output            dmem_axi_arvalid,
	input             dmem_axi_arready,
	output     [31:0] dmem_axi_araddr,
	output     [ 2:0] dmem_axi_arprot,

	input             dmem_axi_rvalid,
	output            dmem_axi_rready,
	input      [31:0] dmem_axi_rdata,
	input      [ 1:0] dmem_axi_rresp
);

	wire mem_stall;
	assign stalled = stall || mem_stall;

	wire [31:0] imem_addr;
	wire [31:0] imem_data;

	// the other is data memory
	wire dmem_valid;
	wire [31:0] dmem_addr;
	wire [3:0] dmem_wstrb;
	wire [31:0] dmem_wdata;
	wire [31:0] dmem_rdata;

	nerv #(.RESET_ADDR(RESET_ADDR), .NUMREGS(NUMREGS)) nerv (
		.clock(clock),
		.reset(reset),
		.stall(stalled),
		.trap(trap),

`ifdef NERV_RVFI
		.rvfi_valid(rvfi_valid),
		.rvfi_order(rvfi_order),
		.rvfi_insn(rvfi_insn),
		.rvfi_trap(rvfi_trap),
		.rvfi_halt(rvfi_halt),
		.rvfi_intr(rvfi_intr),
		.rvfi_mode(rvfi_mode),
		.rvfi_ixl(rvfi_ixl),
		.rvfi_rs1_addr(rvfi_rs1_addr),
		.rvfi_rs2_addr(rvfi_rs2_addr),
		.rvfi_rs1_rdata(rvfi_rs1_rdata),
		.rvfi_rs2_rdata(rvfi_rs2_rdata),
		.rvfi_rd_addr(rvfi_rd_addr),
		.rvfi_rd_wdata(rvfi_rd_wdata),
		.rvfi_pc_rdata(rvfi_pc_rdata),
		.rvfi_pc_wdata(rvfi_pc_wdata),
		.rvfi_mem_addr(rvfi_mem_addr),
		.rvfi_mem_rmask(rvfi_mem_rmask),
		.rvfi_mem_wmask(rvfi_mem_wmask),
		.rvfi_mem_rdata(rvfi_mem_rdata),
		.rvfi_mem_wdata(rvfi_mem_wdata),
`endif

		.imem_addr(imem_addr),
		.imem_data(imem_data),
		.dmem_valid(dmem_valid),
		.dmem_addr(dmem_addr),
		.dmem_wstrb(dmem_wstrb),
		.dmem_wdata(dmem_wdata),
		.dmem_rdata(dmem_rdata)
	);

	nerv_axi_lite_adapter nerv_axi_lite_adapter (
		.clock(clock),
		.reset(reset),

		.imem_axi_arvalid(imem_axi_arvalid),
		.imem_axi_arready(imem_axi_arready),
		.imem_axi_araddr(imem_axi_araddr),
		.imem_axi_arprot(imem_axi_arprot),

		.imem_axi_rvalid(imem_axi_rvalid),
		.imem_axi_rready(imem_axi_rready),
		.imem_axi_rdata(imem_axi_rdata),
		.imem_axi_rresp(imem_axi_rresp),

		.dmem_axi_awvalid(dmem_axi_awvalid),
		.dmem_axi_awready(dmem_axi_awready),
		.dmem_axi_awaddr(dmem_axi_awaddr),
		.dmem_axi_awprot(dmem_axi_awprot),

		.dmem_axi_wvalid(dmem_axi_wvalid),
		.dmem_axi_wready(dmem_axi_wready),
		.dmem_axi_wdata(dmem_axi_wdata),
		.dmem_axi_wstrb(dmem_axi_wstrb),

		.dmem_axi_bvalid(dmem_axi_bvalid),
		.dmem_axi_bready(dmem_axi_bready),
		.dmem_axi_bresp(dmem_axi_bresp),

		.dmem_axi_arvalid(dmem_axi_arvalid),
		.dmem_axi_arready(dmem_axi_arready),
		.dmem_axi_araddr(dmem_axi_araddr),
		.dmem_axi_arprot(dmem_axi_arprot),

		.dmem_axi_rvalid(dmem_axi_rvalid),
		.dmem_axi_rready(dmem_axi_rready),
		.dmem_axi_rdata(dmem_axi_rdata),
		.dmem_axi_rresp(dmem_axi_rresp),

		.imem_addr(imem_addr),
		.imem_data(imem_data),
		.dmem_valid(dmem_valid),
		.dmem_addr(dmem_addr),
		.dmem_wstrb(dmem_wstrb),
		.dmem_wdata(dmem_wdata),
		.dmem_rdata(dmem_rdata),

		.stall(stalled),
		.mem_stall(mem_stall)
	);

endmodule
