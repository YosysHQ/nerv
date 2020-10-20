module stupidrv_tb (

);

localparam MEM_ADDR_WIDTH = 14;
localparam TIMEOUT = (1<<10);

reg clock;
reg reset = 1'b1;
wire stall = 1'b0;

wire [31:0] imem_addr;
reg  [31:0] imem_data;

wire        dmem_valid;
wire [31:0] dmem_addr;
wire [ 3:0] dmem_wstrb;
wire [31:0] dmem_wdata;
reg  [31:0] dmem_rdata;

always #5 clock = clock === 1'b0;
always @(posedge clock) reset <= 0;

reg [31:0] mem [0:(1<<MEM_ADDR_WIDTH)-1];

wire wr_in_mem_range = (dmem_addr[31:2] < (1<<MEM_ADDR_WIDTH));
wire wr_in_output = (dmem_addr == 32'h 02000000);

reg [31:0] out;
reg out_valid;
always @(posedge clock) begin
	if (out_valid) $display("Output: %d", out);
end

always @(posedge clock) begin
	if (imem_addr[31:2] >= (1<<MEM_ADDR_WIDTH)) begin
		$display("Memory access out of range: imem_addr = 0x%08x", imem_addr);
	end
	if (dmem_valid && !(wr_in_mem_range || wr_in_output)) begin
		$display("Memory access out of range: dmem_addr = 0x%08x", dmem_addr);
	end
end

integer i;
always @(posedge clock) begin
	out <= 32'h 0;
	out_valid <= 1'b0;
	imem_data <= mem[imem_addr[MEM_ADDR_WIDTH+1:2]];

	if (dmem_valid) begin
		dmem_rdata <= mem[dmem_addr[MEM_ADDR_WIDTH+1:2]];
		for (i=0;i<4;i=i+1) begin
			if (dmem_wstrb[i]) begin
				if (wr_in_mem_range) begin
					mem[dmem_addr[MEM_ADDR_WIDTH+1:2]][(i*8)+: 8] <= dmem_wdata[(i*8)+: 8];
				end
				if (wr_in_output) begin
					out[(i*8)+: 8] <= dmem_wdata[(i*8)+: 8];
					out_valid <= 1'b1;
				end
			end
		end
	end else begin
		dmem_rdata <= 32'h XXXX_XXXX;
	end
end

initial begin
	$readmemh("firmware.hex", mem, 0, 1<<MEM_ADDR_WIDTH - 1);
	if ($test$plusargs("vcd")) begin
		$dumpfile("testbench.vcd");
		$dumpvars(0, stupidrv_tb);
	end
end

stupidrv dut (
	.clock(clock),
	.reset(reset),
	.stall(stall),

	.imem_addr(imem_addr),
	.imem_data(imem_data),

	.dmem_valid(dmem_valid),
	.dmem_addr(dmem_addr),
	.dmem_wstrb(dmem_wstrb),
	.dmem_wdata(dmem_wdata),
	.dmem_rdata(dmem_rdata)
);

reg [31:0] cycles = 0;

always @(posedge clock) begin
	cycles <= cycles + 32'h1;
	if (cycles >= TIMEOUT) begin
		$display("Simulated %d cycles", cycles);
		$finish;
	end
end



endmodule
