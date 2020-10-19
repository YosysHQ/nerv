module stupidrv_tb (

);

localparam MEM_ADDR_WIDTH = 10;
localparam TIMEOUT = (1<<10);

wire clock;
wire reset;
wire stall;

wire [31:0] imem_addr;
reg  [31:0] imem_data;

wire        dmem_valid;
wire [31:0] dmem_addr;
wire [ 3:0] dmem_wstrb;
wire [31:0] dmem_wdata;
reg  [31:0] dmem_rdata;


reg [31:0] mem [0:(1<<MEM_ADDR_WIDTH)-1];

integer i;
always @(posedge clock) begin
	imem_data <= mem[imem_addr[MEM_ADDR_WIDTH+1:2]];

	if (dmem_valid) begin
		dmem_rdata <= mem[dmem_addr[MEM_ADDR_WIDTH+1:2]];
		for (i=0;i<4;i=i+1) begin
			if (dmem_wstrb[i]) begin
				mem[dmem_addr[MEM_ADDR_WIDTH+1:2]][(i*8)+: 8] <= dmem_wdata[(i*8)+: 8];
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

reg [31:0] cycles;

always @(posedge clock) begin
	cycles <= cycles + 32'h1;
	if (cycles > TIMEOUT) begin
		$display("Simulated %d cycles", cycles);
		$finish;
	end
end



endmodule
