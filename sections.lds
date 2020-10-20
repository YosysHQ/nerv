MEMORY {
	/* the memory in the testbench is 64k in size;
	 * set LENGTH=48k and leave at least 16k for stack */
	mem : ORIGIN = 0x00000000, LENGTH = 0x0000c000
}
SECTIONS {
	.memory : {
		. = 0x000000;
		start*(.text);
		*(.text);
		*(*);
		end = .;
	} > mem
}
