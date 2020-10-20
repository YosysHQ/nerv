TOOLCHAIN_PREFIX?=riscv64-unknown-elf-

test: firmware.hex nerv_tb
	vvp -N nerv_tb +vcd

firmware.elf: firmware.s firmware.c
	$(TOOLCHAIN_PREFIX)gcc -march=rv32i -mabi=ilp32 -Os -Wall -Wextra -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $^

firmware.hex: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

nerv_tb: nerv_tb.sv nerv.sv
	iverilog -o nerv_tb nerv_tb.sv nerv.sv

clean:
	rm -f firmware.elf firmware.hex nerv_tb
