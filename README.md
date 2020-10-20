NERV - Naive Educational RISC-V
===============================

NERV is a simple single-stage RV32I processor.


Running the simulation testbench
--------------------------------

```
git clone https://github.com/SymbioticEDA/nerv.git
cd nerv
make
```


Running the riscv-formal testbench
----------------------------------

```
git clone https://github.com/SymbioticEDA/riscv-formal.git
cd riscv-formal/cores/
git clone https://github.com/SymbioticEDA/nerv.git
cd nerv
make -j8 check
cat cexdata-*/status.txt
```
