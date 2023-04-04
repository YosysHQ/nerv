# Caches for NERV using an AXI interface


## Contents

### Cache Implementation

Split across [`nerv_axi_cache.sv`](./nerv_axi_cache.sv), [`nerv_axi_cache_icache.sv`](./nerv_axi_cache_icache.sv) and [`nerv_axi_cache_dcache.sv`](./nerv_axi_cache_dcache.sv).

The top-level module for the cache is `nerv_axi_cache` in [`nerv_axi_cache.sv`](./nerv_axi_cache.sv).
Module parameters are documented in the comment above that module.

### Testbenches

The testbenches were tested using `iverilog`, use `make test_axi` and `make test_internal` for running them.
There is [`testbench_internal.sv`](./testbench_internal.sv) which uses the cache-internal bus instead of the AXI interface and [`testbench_axi.sv`](./testbench_axi.sv) which uses the full AXI-interfacing cache together with a third-party open-source AXI4 memory implementation in [`axi_ram.v`](./axi_ram.v) (Taken from [Alex Forencich's "Verilog AXI Components"](https://github.com/alexforencich/verilog-axi)).

These testbenches also uses a different firmware than the top-level NERV testbench to actually exercise the cache a bit.
