#
#
#
SETUP_SIZE = 2000

#dir
BOCHS_DIR = ../../vm_bochs/
#

#可选项
do:
	nasm -o boot.bin boot.asm -l boot.lst	
	nasm -o setup.bin setup.asm	-l setup.lst
	
clean:
	rm -f *.o *.out *.bin
	
write:
	BinWriter boot.bin 0 512 $(BOCHS_DIR)aa.img 0
	BinWriter setup.bin 0 $(SETUP_SIZE) $(BOCHS_DIR)aa.img 512	

