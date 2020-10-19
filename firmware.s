li x1, 0x00000100
li x2, 0x02000000
sw x0, 0(x1)
loop:
lw x3, 0(x1)
addi x3, x3, 1
sw x3, 0(x1)
sw x3, 0(x2)
j loop
