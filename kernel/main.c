void cls();
int sub(int a,int b);

void kernel_main(void){	
	int i=0,j=0;
	i=sub(9,3);
	cls();
	print();
	asm("int $0x70;"::);
	//for(;;) sys_halt();
}

