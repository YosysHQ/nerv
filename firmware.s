li x2, 0
li x3, 0x02000000
loop:
li x1, 0x12345678
addi x1, x1, -1
addi x1, x1, -2
sb x2, 0(x3)
sw x1, 0(x3)
addi x2, x2, 1
j loop
