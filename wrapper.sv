module rvfi_wrapper (
	input         clock,
	input         reset,
	`RVFI_OUTPUTS
);
	(* keep *) `rvformal_rand_reg stall;
	(* keep *) `rvformal_rand_reg [31:0] imem_data;
	(* keep *) `rvformal_rand_reg [31:0] dmem_rdata;

	(* keep *) wire [31:0] imem_addr;

	(* keep *) wire        dmem_valid;
	(* keep *) wire [31:0] dmem_addr;
	(* keep *) wire [ 3:0] dmem_wstrb;
	(* keep *) wire [31:0] dmem_wdata;

	stupidrv uut (
		.clock      (clock    ),
		.reset      (reset    ),
		.stall      (stall    ),

		.imem_addr  (imem_addr ),
		.imem_data  (imem_data ),

		.dmem_valid (dmem_valid),
		.dmem_addr  (dmem_addr ),
		.dmem_wstrb (dmem_wstrb),
		.dmem_wdata (dmem_wdata),
		.dmem_rdata (dmem_rdata),

		`RVFI_CONN
	);

`ifdef STUPIDRV_FAIRNESS
	reg [2:0] stalled = 0;
	always @(posedge clock) begin
		stalled <= {stalled, stall};
		assume (~stalled);
	end
`endif
endmodule
