test: firmware.hex stupidrv_tb
	vvp -N stupidrv_tb

firmware.hex:
	echo 00000013 > firmware.hex
	echo 00000013 >> firmware.hex
	echo 00000013 >> firmware.hex
	echo 00000013 >> firmware.hex

stupidrv_tb: stupidrv_tb.sv stupidrv.sv
	iverilog -o stupidrv_tb stupidrv_tb.sv stupidrv.sv

clean:
	rm -f firmware.hex stupidrv_tb
