TOOLCHAIN_PREFIX?=riscv64-unknown-elf-

test: firmware.hex stupidrv_tb
	vvp -N stupidrv_tb +vcd

firmware.elf: firmware.s firmware.c
	$(TOOLCHAIN_PREFIX)gcc -march=rv32i -Os -Wall -Wextra -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $^

firmware.hex: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 --reverse-bytes=4 $< $@

stupidrv_tb: stupidrv_tb.sv stupidrv.sv
	iverilog -o stupidrv_tb stupidrv_tb.sv stupidrv.sv

clean:
	rm -f firmware.elf firmware.hex stupidrv_tb
