#include <def.h>
#include <stdio.h>
#include <sys.h>
#include <int.h>
extern void int_0x22();
extern void task1();
extern void task2();
void sched_init();
void kernel_main(void){	
	cls();
	char str[]="-----------welcome------------\n";
	printString(str);
	idt_init();
	sched_init();                   /* initialize task 0 and global task struct arrays */
	
	
//	asm("sti;"::);
//	move_to_user_mode();
	int i=0;
	asm("int $0x0;"::);
//	while(1)i++;
	//printInt(i++);

//	asm("ljmp %0,%1"::"i"(0x58),"i"(0x0));
	for(;;) sys_halt();
}



void sched_init()//创建task0
{
	Descriptor LDestor[3];
	LDestor[0]=creatDescriptor(0x0,0x0,0x0,0x0);//空描述符
	LDestor[1]=creatDescriptor(0x0,0xa0,0x9b+0x60,0xc0);	//代码段描述符,0x60:DPL3
	LDestor[2]=creatDescriptor(0x0,0xa0,0x93+0x60,0x80);	//数据段描述符,0x60:DPL3
	DWORD offset=0;
	memcopy(&LDestor,offset,3*sizeof(Descriptor),0,SelectorTssLdt);//写入LDT&TSS段
	//在GDT中注册LDT0
	DWORD ldt_phyAddr=LDTbase+offset;
	Descriptor GDestor_ldt0=creatDescriptor(ldt_phyAddr,(3*8)-1,0x82,0x40);
	int ldt0_sel=addDesToGDT(GDestor_ldt0);
	int tss0_sel=creatTSS(0,(DWORD)task1,0x7eff0,0x7cff0,ldt0_sel);
	
	cl_nt();                       // 标志寄存器nt位复位.准备切换到用户态 
	asm("lldt %%ax;"::"a"(ldt0_sel));                       // load task 0 ldtr 
	asm("ltr %%ax;"::"a"(tss0_sel));                        // load task 0 tr 
}
void idt_init(){
	set_int_handler(0,handle_int0);
	set_int_handler(1,handle_int1);
	set_int_handler(2,handle_int2);
	set_int_handler(3,handle_int3);
	set_int_handler(4,handle_int4);
	set_int_handler(5,handle_int5);
	set_int_handler(6,handle_int6);
	set_int_handler(7,handle_int7);
	set_int_handler(8,handle_int8);
	set_int_handler(10,handle_int10);
	set_int_handler(11,handle_int11);
	set_int_handler(12,handle_int12);
	set_int_handler(13,handle_int13);
	set_int_handler(14,handle_int14);
	set_int_handler(16,handle_int16);
	set_int_handler(17,handle_int17);
	set_int_handler(18,handle_int18);
	set_int_handler(19,handle_int19);
}
void set_int_handler(BYTE int_num,PLVOID func){
	DES_GATE gate;
	gate.addrL=func;
	gate.segsel=SelectorCode;
	gate.paramCnt=0;
	gate.type=0x8e;	//32位中断门，0特权级
	gate.addrH=((WORD)(func)>>16);
	memcopy(&gate,IDTbase+int_num*8,sizeof(DES_GATE),0,SelectorFlatRW);//写入中断向量表
}

