module reset_assumptions(input reset);
	always @* if ($initstate) assume(reset);
endmodule

bind nerv_axi_lite reset_assumptions reset_assumptions(.reset(reset));

`ifdef NERVAXI_CHECK_DMEM
bind nerv_axi_lite amba_axi4_protocol_checker
  #(.cfg('{ID_WIDTH:          4,
	   ADDRESS_WIDTH:     32,
	   DATA_WIDTH:        32,
	   AWUSER_WIDTH:      32,
	   WUSER_WIDTH:       32,
	   BUSER_WIDTH:       32,
	   ARUSER_WIDTH:      32,
	   RUSER_WIDTH:       32,
	   MAX_WR_BURSTS:     1,
	   MAX_RD_BURSTS:     1,
	   MAX_WR_LENGTH:     1,
	   MAX_RD_LENGTH:     1,
	   MAXWAIT:           16,
	   VERIFY_AGENT_TYPE: amba_axi4_protocol_checker_pkg::SOURCE,
	   PROTOCOL_TYPE:     amba_axi4_protocol_checker_pkg::AXI4LITE,
	   INTERFACE_REQS:    1,
	   ENABLE_COVER:      1,
	   ENABLE_XPROP:      0,
	   ARM_RECOMMENDED:   1,
	   CHECK_PARAMETERS:  1,
	   OPTIONAL_WSTRB:    0,
	   FULL_WR_STRB:      1,
	   OPTIONAL_RESET:    0,
	   EXCLUSIVE_ACCESS:  1,
	   OPTIONAL_LP:       0})) dmem_axi4_checker_source
  (.ACLK(clock),
   .ARESETn(!reset),

   .AWVALID(dmem_axi_awvalid),
   .AWREADY(dmem_axi_awready),
   .AWADDR(dmem_axi_awaddr),
   .AWPROT(dmem_axi_awprot),

   .WVALID(dmem_axi_wvalid),
   .WREADY(dmem_axi_wready),
   .WDATA(dmem_axi_wdata),
   .WSTRB(dmem_axi_wstrb),

   .BVALID(dmem_axi_bvalid),
   .BREADY(dmem_axi_bready),
   .BRESP(dmem_axi_bresp),

   .ARVALID(dmem_axi_arvalid),
   .ARREADY(dmem_axi_arready),
   .ARADDR(dmem_axi_araddr),
   .ARPROT(dmem_axi_arprot),

   .RVALID(dmem_axi_rvalid),
   .RREADY(dmem_axi_rready),
   .RDATA(dmem_axi_rdata),
   .RRESP(dmem_axi_rresp));
`endif


`ifdef NERVAXI_CHECK_IMEM
bind nerv_axi_lite amba_axi4_protocol_checker
  #(.cfg('{ID_WIDTH:          4,
	   ADDRESS_WIDTH:     32,
	   DATA_WIDTH:        32,
	   AWUSER_WIDTH:      32,
	   WUSER_WIDTH:       32,
	   BUSER_WIDTH:       32,
	   ARUSER_WIDTH:      32,
	   RUSER_WIDTH:       32,
	   MAX_WR_BURSTS:     1,
	   MAX_RD_BURSTS:     1,
	   MAX_WR_LENGTH:     1,
	   MAX_RD_LENGTH:     1,
	   MAXWAIT:           16,
	   VERIFY_AGENT_TYPE: amba_axi4_protocol_checker_pkg::SOURCE,
	   PROTOCOL_TYPE:     amba_axi4_protocol_checker_pkg::AXI4LITE,
	   INTERFACE_REQS:    1,
	   ENABLE_COVER:      1,
	   ENABLE_XPROP:      0,
	   ARM_RECOMMENDED:   1,
	   CHECK_PARAMETERS:  1,
	   OPTIONAL_WSTRB:    1,
	   FULL_WR_STRB:      1,
	   OPTIONAL_RESET:    0,
	   EXCLUSIVE_ACCESS:  1,
	   OPTIONAL_LP:       0})) imem_axi4_checker_source
  (.ACLK(clock),
   .ARESETn(!reset),

   .AWVALID(1'b0),
   // .AWREADY(),
   .AWADDR(32'bx),
   .AWPROT(3'bx),

   .WVALID(1'b0),
   // .WREADY(),
   .WDATA(32'bx),
   .WSTRB(4'bx),

   // .BVALID(),
   .BREADY(1'b0),
   // .BRESP(),

   .ARVALID(imem_axi_arvalid),
   .ARREADY(imem_axi_arready),
   .ARADDR(imem_axi_araddr),
   .ARPROT(imem_axi_arprot),

   .RVALID(imem_axi_rvalid),
   .RREADY(imem_axi_rready),
   .RDATA(imem_axi_rdata),
   .RRESP(imem_axi_rresp));
`endif
