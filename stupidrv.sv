module stupidrv #(
	parameter [31:0] RESET_ADDR = 32'h 0000_0000
) (
	input clock,
	input reset,
	input stall,

	output        imem_valid,
	output [31:0] imem_addr,
	input  [31:0] imem_data,

	output        dmem_valid,
	output [31:0] dmem_addr,
	output [ 3:0] dmem_wstrb,
	output [31:0] dmem_wdata,
	input  [31:0] dmem_rdata
);
endmodule
