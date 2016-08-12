kernel.bin:kernel.out
	objcopy -I pei-i386 -O binary kernel.out kernel.bin
kernel.out:kernel_main.o sysfunc.o func.o
	ld -b elf32-i386 -e 0x10000 kernel_main.o sysfunc.o func.o -o kernel.out
sysfunc.o:sysfunc.asm
	nasm -f coff sysfunc.asm -o sysfunc.o
kernel_main.o:kernel_main.c
	gcc -c kernel_main.c -o kernel_main.o
func.o:func.c
	gcc -c func.c -o func.o

clean:
	rm	func.oo kernel_main.oo func.o kernel_main.o sysfunc.o
write_boot:
	BinWriter boot.bin 0 510 ../vm_bochs/a.img 0
	
write_kernel:
	BinWriter kernel.bin 0 512 ../vm_bochs/a.img 512
