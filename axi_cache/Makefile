#  NERV -- Naive Educational RISC-V Processor
#
#  Copyright (C) 2020  N. Engelhardt <nak@yosyshq.com>
#  Copyright (C) 2020  Claire Xenia Wolf <claire@yosyshq.com>
#  Copyright (C) 2023  Jannis Harder <jix@yosyshq.com> <me@jix.one>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

TOOLCHAIN_PREFIX?=riscv64-unknown-elf-

TESTBENCH_DEFINES?=-D NERV_DBGREGS
TESTBENCH_ARGS?=+vcd

RISCV_ARCH?=rv32i$(shell $(TOOLCHAIN_PREFIX)as -march=rv32i_zicsr --dump-config 2>/dev/null && echo _zicsr)

CACHE_SOURCES:=nerv_axi_cache.sv nerv_axi_cache_icache.sv nerv_axi_cache_dcache.sv

.PHONY: test_internal test_axi

test_internal: firmware.hex testbench_internal
	vvp -N testbench_internal $(TESTBENCH_ARGS)

test_axi: firmware.hex testbench_axi
	vvp -N testbench_axi $(TESTBENCH_ARGS)

firmware.elf: ../firmware.s ../vectors.s firmware.c
	$(TOOLCHAIN_PREFIX)gcc -march=$(RISCV_ARCH) -mabi=ilp32 -Os -Wall -Wextra -Wl,-Bstatic,-T,../sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $^

firmware.hex: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

testbench_internal: testbench_internal.sv ../nerv.sv $(CACHE_SOURCES)
	iverilog -stestbench -g2012 -o $@ $(TESTBENCH_DEFINES) $^

testbench_axi: testbench_axi.sv ../nerv.sv $(CACHE_SOURCES) axi_ram.v
	iverilog -stestbench -g2012 -o $@ $(TESTBENCH_DEFINES) $^

clean:
	rm -rf firmware.elf firmware.hex
	rm -rf testbench_internal testbench_internal.vcd
	rm -rf testbench_axi testbench_axi.vcd
