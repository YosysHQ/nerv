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

module axi_tb_fifo_stage #(
	parameter WIDTH = 8
) (
	input clock,
	input reset,

	input              in_valid,
	output             in_ready,
	input  [WIDTH-1:0] in_data,

	output             out_valid,
	input              out_ready,
	output [WIDTH-1:0] out_data
);

	reg [WIDTH-1:0] buffered;
	reg buffer_valid;

	wire in_txn = in_valid && in_ready;
	wire out_txn = out_valid && out_ready;

	assign out_data = buffer_valid ? buffered : in_data;
	assign in_ready = out_ready || !buffer_valid;
	assign out_valid = in_valid || buffer_valid;

	always @(posedge clock) begin
		if (reset) begin
			buffer_valid <= 0;
		end else begin
			if (in_txn != out_txn)
				buffer_valid = in_txn;
		end
		if (in_txn)
			buffered <= in_data;
	end

endmodule

module axi_tb_fifo #(
	parameter WIDTH = 8,
	parameter DEPTH = 3
) (
	input clock,
	input reset,

	input              in_valid,
	output             in_ready,
	input  [WIDTH-1:0] in_data,

	output             out_valid,
	input              out_ready,
	output [WIDTH-1:0] out_data,

	input              in_stall,
	input              out_stall
);

	wire [WIDTH-1:0] stage_data [0:DEPTH];
	wire [DEPTH:0] stage_valid;
	wire [DEPTH:0] stage_ready;

	genvar i;
	generate for (i = 0; i < DEPTH; i = i + 1) begin
		axi_tb_fifo_stage #(.WIDTH(WIDTH)) stage (
			.clock(clock),
			.reset(reset),
			.in_data(stage_data[i]),
			.out_data(stage_data[i+1]),
			.in_valid(stage_valid[i]),
			.out_valid(stage_valid[i+1]),
			.in_ready(stage_ready[i]),
			.out_ready(stage_ready[i+1])
		);
	end endgenerate

	axi_tb_stall #(.WIDTH(WIDTH)) in_staller (
		.clock(clock),
		.reset(reset),
		.in_valid(in_valid),
		.in_ready(in_ready),
		.out_valid(stage_valid[0]),
		.out_ready(stage_ready[0]),
		.stall(in_stall)
	);

	axi_tb_stall #(.WIDTH(WIDTH)) out_staller (
		.clock(clock),
		.reset(reset),
		.in_valid(stage_valid[DEPTH]),
		.in_ready(stage_ready[DEPTH]),
		.out_valid(out_valid),
		.out_ready(out_ready),
		.stall(out_stall)
	);

	assign stage_data[0] = in_data;

	assign out_data = out_valid ? stage_data[DEPTH] : 'x;
endmodule

module axi_tb_stall #(
	parameter WIDTH = 8
) (
	input clock,
	input reset,

	input  in_valid,
	output in_ready,

	output out_valid,
	input  out_ready,

	input  stall
);

	reg stuck;

	always @(posedge clock) begin

		if (reset) begin
			stuck <= 0;
		end else begin
			stuck <= out_valid && !out_ready;
		end
	end

	wire connect = stuck || !stall;

	assign out_valid = in_valid && connect;
	assign in_ready = out_ready && connect;
endmodule


typedef struct packed {
	logic [31:0] addr;
	logic [ 2:0] prot;
} axi_ar_record;

// Testbench helper providing a AXI4-Lite subordinate read interface
//
// Can test all allowed timings but does not handle multiple in-flight reads.
module axi_lite_s_read_tester(
	input clock,
	input reset,

	// AXI4-Lite read interface
	input             axi_arvalid,
	output            axi_arready,
	input      [31:0] axi_araddr,
	input      [ 2:0] axi_arprot,

	output            axi_rvalid,
	input             axi_rready,
	output     [31:0] axi_rdata,
	output     [ 1:0] axi_rresp,

	// test signals
	input      [ 1:0] stall,

	output            read_txn,
	output     [31:0] read_addr, // valid when read_txn is set
	output     [ 2:0] read_prot, // valid when read_txn is set
	input      [31:0] read_data, // sampled 1 cycle after read_txn was set
	input      [ 1:0] read_resp // sampled 1 cycle after read_txn was set
);

	axi_tb_fifo #(.WIDTH(32 + 3), .DEPTH(1)) arfifo (
		.clock(clock),
		.reset(reset),
		.in_valid(axi_arvalid),
		.in_ready(axi_arready),
		.in_data({axi_araddr, axi_arprot}),

		.out_valid(read_txn),
		.out_ready(1'b1),
		.out_data({read_addr, read_prot}),

		.in_stall(stall[0]),
		.out_stall(1'b0)
	);

	reg read_txn_q;

	always @(posedge clock)
		if (reset)
			read_txn_q <= 0;
		else
			read_txn_q <= read_txn;

	axi_tb_fifo #(.WIDTH(32 + 2), .DEPTH(1)) rfifo (
		.clock(clock),
		.reset(reset),
		.in_valid(read_txn_q),
		.in_data({read_data, read_resp}),

		.out_valid(axi_rvalid),
		.out_ready(axi_rready),
		.out_data({axi_rdata, axi_rresp}),


		.in_stall(1'b0),
		.out_stall(stall[1])
	);
endmodule

// Testbench helper providing a AXI4-Lite subordinate write interface
//
// Can test all allowed timings but does not handle multiple in-flight writes.
module axi_lite_s_write_tester(
	input clock,
	input reset,

	// AXI4-Lite memory interface
	input             axi_awvalid,
	output            axi_awready,
	input      [31:0] axi_awaddr,
	input      [ 2:0] axi_awprot,

	input             axi_wvalid,
	output            axi_wready,
	input      [31:0] axi_wdata,
	input      [ 3:0] axi_wstrb,

	output            axi_bvalid,
	input             axi_bready,
	output     [ 1:0] axi_bresp,

	// test signals
	input      [ 2:0] stall,

	output            write_txn,
	output     [31:0] write_addr, // valid when read_txn is set
	output     [ 2:0] write_prot, // valid when read_txn is set
	output     [31:0] write_data, // valid when read_txn is set
	output     [ 3:0] write_wstrb, // valid when read_txn is set
	input      [ 1:0] write_resp // sampled 1 cycle after read_txn was set
);

	wire awfifo_valid;
	wire wfifo_valid;

	assign write_txn = awfifo_valid && wfifo_valid;

	axi_tb_fifo #(.WIDTH(32 + 3), .DEPTH(1)) awfifo (
		.clock(clock),
		.reset(reset),
		.in_valid(axi_awvalid),
		.in_ready(axi_awready),
		.in_data({axi_awaddr, axi_awprot}),

		.out_valid(awfifo_valid),
		.out_ready(wfifo_valid),
		.out_data({write_addr, write_prot}),

		.in_stall(stall[0]),
		.out_stall(1'b0)
	);

	axi_tb_fifo #(.WIDTH(32 + 4), .DEPTH(1)) wfifo (
		.clock(clock),
		.reset(reset),
		.in_valid(axi_wvalid),
		.in_ready(axi_wready),
		.in_data({axi_wdata, axi_wstrb}),

		.out_valid(wfifo_valid),
		.out_ready(awfifo_valid),
		.out_data({write_data, write_wstrb}),

		.in_stall(stall[1]),
		.out_stall(1'b0)
	);


	reg write_txn_q;

	always @(posedge clock)
		if (reset)
			write_txn_q <= 0;
		else
			write_txn_q <= write_txn;

	axi_tb_fifo #(.WIDTH(2), .DEPTH(1)) bfifo (
		.clock(clock),
		.reset(reset),
		.in_valid(write_txn_q),
		.in_data(write_resp),

		.out_valid(axi_bvalid),
		.out_ready(axi_bready),
		.out_data(axi_bresp),

		.in_stall(1'b0),
		.out_stall(stall[2])
	);

endmodule
