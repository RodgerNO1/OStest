void cls();
int sub(int a,int b);

void kernel_main(void){	
	cls();
	//printInt(getTimeTick);
	asm("int $0x70;"::);
	asm("sti;"::);
	for(;;) sys_halt();
}

