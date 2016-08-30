#include <def.h>
#include <stdio.h>
#include <sys.h>
extern void int_0x22();
extern void task0();
extern void task1();
void sched_init();
void kernel_main(void){	
	cls();
	char str[]="-----------welcome------------\n";
	printString(str);
	set_int_handler(0x22,int_0x22);
	//sched_init();                   /* initialize task 0 and global task struct arrays */
	asm("int $0x70;"::);
	asm("int $0x20;"::);
	
	asm("sti;"::);
//	move_to_user_mode();
//	int i=0;


//	asm("ljmp %0,%1"::"i"(0x58),"i"(0x0));
	for(;;) sys_halt();
}



void sched_init()
{
	//creatLDT(0,0x10000,0x10000);
	
	cl_nt();                       // 标志寄存器nt位复位.准备切换到用户态 
//   lldt(0);                       // load task 0 ldtr 
//	ltr(0);                        // load task 0 tr 
}


