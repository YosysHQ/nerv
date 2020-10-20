TOOLCHAIN_PREFIX?=riscv64-unknown-elf-

test: firmware.hex testbench
	vvp -N testbench +vcd

firmware.elf: firmware.s firmware.c
	$(TOOLCHAIN_PREFIX)gcc -march=rv32i -mabi=ilp32 -Os -Wall -Wextra -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $^

firmware.hex: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

testbench: testbench.sv nerv.sv
	iverilog -o testbench -D NERV_DBGREGS testbench.sv nerv.sv

check:
	python3 ../../checks/genchecks.py
	$(MAKE) -C checks
	bash cexdata.sh

clean:
	rm -f firmware.elf firmware.hex testbench
	rm -rf checks cexdata
