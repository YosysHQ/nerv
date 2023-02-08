/*
 *  NERV -- Naive Educational RISC-V Processor
 *
 *  Copyright (C) 2020  N. Engelhardt <nak@yosyshq.com>
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

module testbench;

localparam MEM_ADDR_WIDTH = 16;
localparam TIMEOUT = (1<<10);


reg clock;
reg reset = 1'b1;
wire trap;

always #5 clock = clock === 1'b0;
always @(posedge clock) reset <= 0;

reg [7:0] mem [0:(1<<MEM_ADDR_WIDTH)-1];

initial begin
	$readmemh("firmware.hex", mem);
	if ($test$plusargs("vcd")) begin
		$dumpfile("testbench_axi.vcd");
		$dumpvars(0, testbench);
	end
end

integer stall_seed;

initial begin
	if (!$value$plusargs("stall=%d", stall_seed))
		stall_seed = 0;
end

reg stall = 1'b0;

always @(posedge clock) begin
	if (stall_seed != 0 && !reset)
		stall <= $random(stall_seed);
end

// AXI4-Lite signals

wire        imem_axi_arvalid;
wire        imem_axi_arready;
wire [31:0] imem_axi_araddr;
wire [ 2:0] imem_axi_arprot;

wire        imem_axi_rvalid;
wire        imem_axi_rready;
wire [31:0] imem_axi_rdata;
wire [ 1:0] imem_axi_rresp;

wire        dmem_axi_arvalid;
wire        dmem_axi_arready;
wire [31:0] dmem_axi_araddr;
wire [ 2:0] dmem_axi_arprot;

wire        dmem_axi_rvalid;
wire        dmem_axi_rready;
wire [31:0] dmem_axi_rdata;
wire [ 1:0] dmem_axi_rresp;

wire        dmem_axi_awvalid;
wire        dmem_axi_awready;
wire [31:0] dmem_axi_awaddr;
wire [ 2:0] dmem_axi_awprot;

wire        dmem_axi_wvalid;
wire        dmem_axi_wready;
wire [31:0] dmem_axi_wdata;
wire [ 3:0] dmem_axi_wstrb;

wire        dmem_axi_bvalid;
wire        dmem_axi_bready;
wire [ 1:0] dmem_axi_bresp;

// NERV core with an AXI4-Lite interface

nerv_axi_lite dut (
	.clock(clock),
	.reset(reset),
	.stall(stall),
	.trap(trap),

	.imem_axi_arvalid(imem_axi_arvalid),
	.imem_axi_arready(imem_axi_arready),
	.imem_axi_araddr(imem_axi_araddr),
	.imem_axi_arprot(imem_axi_arprot),
	.imem_axi_rvalid(imem_axi_rvalid),
	.imem_axi_rready(imem_axi_rready),
	.imem_axi_rdata(imem_axi_rdata),
	.imem_axi_rresp(imem_axi_rresp),

	.dmem_axi_arvalid(dmem_axi_arvalid),
	.dmem_axi_arready(dmem_axi_arready),
	.dmem_axi_araddr(dmem_axi_araddr),
	.dmem_axi_arprot(dmem_axi_arprot),
	.dmem_axi_rvalid(dmem_axi_rvalid),
	.dmem_axi_rready(dmem_axi_rready),
	.dmem_axi_rdata(dmem_axi_rdata),
	.dmem_axi_rresp(dmem_axi_rresp),

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
	.dmem_axi_bresp(dmem_axi_bresp)
);

// Testbench AXI4 memory and IO device

reg [ 1:0] imem_read_stall = 2'b00;

wire        imem_read_txn;
wire [31:0] imem_read_addr;
wire [ 2:0] imem_read_prot;
reg  [31:0] imem_read_data;
reg  [ 1:0] imem_read_resp;

axi_lite_s_read_tester test_imem_read (
	.clock(clock),
	.reset(reset),

	.axi_arvalid(imem_axi_arvalid),
	.axi_arready(imem_axi_arready),
	.axi_araddr(imem_axi_araddr),
	.axi_arprot(imem_axi_arprot),
	.axi_rvalid(imem_axi_rvalid),
	.axi_rready(imem_axi_rready),
	.axi_rdata(imem_axi_rdata),
	.axi_rresp(imem_axi_rresp),

	.stall(imem_read_stall),

	.read_txn(imem_read_txn),
	.read_addr(imem_read_addr),
	.read_prot(imem_read_prot),
	.read_data(imem_read_data),
	.read_resp(imem_read_resp)
);

reg [ 1:0] dmem_read_stall = 2'b00;
reg [ 2:0] dmem_write_stall = 3'b000;

wire        dmem_read_txn;
wire [31:0] dmem_read_addr;
wire [ 2:0] dmem_read_prot;
reg  [31:0] dmem_read_data;
reg  [ 1:0] dmem_read_resp;


wire        dmem_write_txn;
wire [31:0] dmem_write_addr;
wire [ 2:0] dmem_write_prot;
wire [31:0] dmem_write_data;
wire [ 3:0] dmem_write_wstrb;
reg  [ 1:0] dmem_write_resp;

axi_lite_s_read_tester test_dmem_read (
	.clock(clock),
	.reset(reset),

	.axi_arvalid(dmem_axi_arvalid),
	.axi_arready(dmem_axi_arready),
	.axi_araddr(dmem_axi_araddr),
	.axi_arprot(dmem_axi_arprot),
	.axi_rvalid(dmem_axi_rvalid),
	.axi_rready(dmem_axi_rready),
	.axi_rdata(dmem_axi_rdata),
	.axi_rresp(dmem_axi_rresp),

	.stall(dmem_read_stall),

	.read_txn(dmem_read_txn),
	.read_addr(dmem_read_addr),
	.read_prot(dmem_read_prot),
	.read_data(dmem_read_data),
	.read_resp(dmem_read_resp)
);

axi_lite_s_write_tester test_dmem_write (
	.clock(clock),
	.reset(reset),

	.axi_awvalid(dmem_axi_awvalid),
	.axi_awready(dmem_axi_awready),
	.axi_awaddr(dmem_axi_awaddr),
	.axi_awprot(dmem_axi_awprot),
	.axi_wvalid(dmem_axi_wvalid),
	.axi_wready(dmem_axi_wready),
	.axi_wdata(dmem_axi_wdata),
	.axi_wstrb(dmem_axi_wstrb),
	.axi_bvalid(dmem_axi_bvalid),
	.axi_bready(dmem_axi_bready),
	.axi_bresp(dmem_axi_bresp),

	.stall(dmem_write_stall),

	.write_txn(dmem_write_txn),
	.write_addr(dmem_write_addr),
	.write_prot(dmem_write_prot),
	.write_data(dmem_write_data),
	.write_wstrb(dmem_write_wstrb),
	.write_resp(dmem_write_resp)
);

localparam [1:0] AXI_RESP_OKAY = 2'b00;
localparam [1:0] AXI_RESP_SLVERR = 2'b10;
localparam [1:0] AXI_RESP_DECERR = 2'b11;

always @(posedge clock) begin : axi_testbench
	integer i;

	imem_read_data <= 'x;
	imem_read_resp <= imem_read_txn ? AXI_RESP_DECERR : 'x;
	dmem_read_data <= 'x;
	dmem_read_resp <= dmem_read_txn ? AXI_RESP_DECERR : 'x;
	dmem_write_resp <= dmem_write_txn ? AXI_RESP_DECERR : 'x;

	if (stall_seed != 0) begin
		imem_read_stall <= $random(stall_seed);
		dmem_read_stall <= $random(stall_seed);
		dmem_write_stall <= $random(stall_seed);
	end

	if (imem_read_txn) begin
		if (imem_read_addr < (1<<MEM_ADDR_WIDTH)) begin
			imem_read_resp <= AXI_RESP_OKAY;
			for (i = 0; i < 4; i++)
				imem_read_data[8 * i +: 8] <= mem[{imem_read_addr[MEM_ADDR_WIDTH-1:2], i[1:0]}];
		end else begin
			$display("Memory access out of range: imem_read_addr = 0x%08x", imem_read_addr);
		end
	end

	if (dmem_read_txn) begin
		if (dmem_read_addr < (1<<MEM_ADDR_WIDTH)) begin
			dmem_read_resp <= AXI_RESP_OKAY;
			for (i = 0; i < 4; i++)
				dmem_read_data[8 * i +: 8] <= mem[{dmem_read_addr[MEM_ADDR_WIDTH-1:2], i[1:0]}];
		end else if (dmem_write_addr == 32'h 02000000) begin
			dmem_write_resp <= AXI_RESP_SLVERR;
			$display("Read of write-only addr: dmem_read_addr = 0x%08x", dmem_read_addr);
		end else begin
			$display("Memory access out of range: dmem_read_addr = 0x%08x", dmem_read_addr);
		end
	end

	if (dmem_write_txn) begin
		if (dmem_write_addr < (1<<MEM_ADDR_WIDTH)) begin
			dmem_write_resp <= AXI_RESP_OKAY;
			for (i = 0; i < 4; i++)
				if (dmem_write_wstrb[i])
					mem[{dmem_write_addr[MEM_ADDR_WIDTH-1:2], i[1:0]}] <= dmem_write_data[8 * i +: 8];
		end else if (dmem_write_addr == 32'h 02000000) begin
			dmem_write_resp <= AXI_RESP_OKAY;
			$write("%c", dmem_write_data[7:0]);
`ifndef VERILATOR
			$fflush();
`endif
		end else begin
			$display("Memory access out of range: dmem_write_addr = 0x%08x", dmem_write_addr);
		end
	end
end

reg [31:0] cycles = 0;

always @(posedge clock) begin
	cycles <= cycles + 32'h1;
	if (trap || (cycles >= TIMEOUT)) begin
		$display("Simulated %0d cycles", cycles);
		$finish;
	end
end



endmodule
