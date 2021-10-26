#!/bin/bash

riscv64-unknown-elf-gcc -mabi=ilp32e -march=rv32e -nostdlib main.c
riscv64-unknown-elf-strip a.out
riscv64-unknown-elf-objcopy -O binary a.out ../firmware/stepper.bin
