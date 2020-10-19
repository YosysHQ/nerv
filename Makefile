test: firmware.hex stupidrv_tb
	vvp -N stupidrv_tb +vcd

firmware.o: firmware.s
	riscv64-unknown-elf-as -march=rv32i -o firmware.o firmware.s
	riscv64-unknown-elf-objdump -M numeric,no-aliases -d firmware.o

firmware.hex: firmware.o
	riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 \
			--reverse-bytes=4 -j .text firmware.o firmware.hex

stupidrv_tb: stupidrv_tb.sv stupidrv.sv
	iverilog -o stupidrv_tb stupidrv_tb.sv stupidrv.sv

clean:
	rm -f firmware.o firmware.hex stupidrv_tb
