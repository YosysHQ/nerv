TOOLCHAIN_PREFIX?=riscv64-unknown-elf-

test: firmware.hex testbench
	vvp -N testbench +vcd

firmware.elf: firmware.s firmware.c
	$(TOOLCHAIN_PREFIX)gcc -march=rv32i -mabi=ilp32 -Os -Wall -Wextra -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $^

firmware.hex: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

testbench: testbench.sv nerv.sv
	iverilog -o testbench -D STALL -D NERV_DBGREGS testbench.sv nerv.sv

check:
	python3 ../../checks/genchecks.py
	$(MAKE) -C checks
	bash cexdata.sh

show:
	gtkwave testbench.vcd testbench.gtkw >> gtkwave.log 2>&1 &

clean:
	rm -rf firmware.elf firmware.hex testbench testbench.vcd gtkwave.log
	rm -rf disasm.o disasm.s checks/ cexdata-*.zip cexdata-*/
