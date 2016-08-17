#
#
#
SETUP_SIZE = 104
KERNEL_SIZE= 512
#
LD = ld
CC = gcc

LDFLAGS = -Ttext 0x10000 -e _sysEntry
#dir
BOOT_DIR = boot/
KERNEL_DIR = kernel/
BOCHS_DIR = ../vm_bochs/
#

system.bin:system.out
	objcopy -I pei-i386 -O binary system.out system.bin
system.out:$(BOOT_DIR)system.o $(KERNEL_DIR)main.o  $(KERNEL_DIR)func.o
	ld $(LDFLAGS) $(BOOT_DIR)system.o $(KERNEL_DIR)main.o $(KERNEL_DIR)func.o -o system.out
$(BOOT_DIR)system.o:$(BOOT_DIR)system.asm
	nasm -f coff $(BOOT_DIR)system.asm -o $(BOOT_DIR)system.o
$(KERNEL_DIR)main.o:$(KERNEL_DIR)main.c
	gcc -c $(KERNEL_DIR)main.c -o $(KERNEL_DIR)main.o
$(KERNEL_DIR)func.o:$(KERNEL_DIR)func.c
	gcc -c $(KERNEL_DIR)func.c -o $(KERNEL_DIR)func.o

#可选项
boot.bin:$(BOOT_DIR)boot.asm
	nasm -o boot.bin $(BOOT_DIR)boot.asm	

setup.bin:$(BOOT_DIR)setup.asm
	nasm -o setup.bin $(BOOT_DIR)setup.asm	
	
clean:
	rm func.o system_main.o sysfunc.o system.out
	
write:write_boot write_system
	echo "write all finsh"
write_boot:
	BinWriter boot.bin 0 512 $(BOCHS_DIR)a.img 0
	BinWriter setup.bin 0 $(SETUP_SIZE) $(BOCHS_DIR)a.img 512
	
write_system:
	BinWriter system.bin 0 $(KERNEL_SIZE) $(BOCHS_DIR)a.img 1024
