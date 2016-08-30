/*
*系统C函数实现
*/
#include <def.h>
void memcopy(void *saddr,void *daddr,int size,int ds,int es){
	sys_memcpy(saddr,daddr,size,ds,es);
}
//清屏函数
void cls(){
	/*
	int i=0,j=0;	
	for(i=0;i<25;i++){
		for(j=0;j<80;j++)
		sys_write_vga((80*i+j)*2,'0',i%16);
	}	
	*/
	sys_cls();
}

void task1()
{	
	int i=0;
	while(1){
		printChar('A');
	}
    while(1)sys_halt();
}
void task2()
{	
	int i=0;
	while(1){
		printChar('B');
	}

	while(1)sys_halt();
}
void do_timer(){
	printChar('I');

	if(sys_get_tick()%(100)==1){
		//printInt(sys_get_tick());
		int pid=0;
		memcopy(0x20900,&pid,4,0x18,0);
		if(pid==0){
			pid=1;
			memcopy(&pid,0x20900,4,0,0x18);
			printChar('A');
			
		}else{
			pid=0;
			memcopy(&pid,0x20900,4,0,0x18);
			printChar('B');
		}
	}

	FAR_RETURN;
	
}
int getTimeTick(){
return sys_get_tick();
}
void handle_int0(){//除零
	char str[]="\n#DE:int-0x0!";
	printString(str);
	INT_RETURN;
}
void handle_int1(){//调试
	char str[]="\n#DB:int-0x1!";
	printString(str);
	INT_RETURN;
}
void handle_int2(){//NMI中断
	char str[]="\n#NMI:int-0x2!";
	printString(str);
	INT_RETURN;
}
void handle_int3(){//断点
	char str[]="\n#BP:int-0x3!";
	printString(str);
	INT_RETURN;
}
void handle_int4(){//溢出
	char str[]="\n#OF:int-0x4!";
	printString(str);
	INT_RETURN;
}
void handle_int5(){//边界越出
	char str[]="\n#BR:int-0x5!";
	printString(str);
	INT_RETURN;
}
void handle_int6(){//无效操作码
	char str[]="\n#UD:int-0x6!";
	printString(str);
	INT_RETURN;
}
void handle_int7(){//设备不存在
	char str[]="\n#NM:int-0x7!";
	printString(str);
	INT_RETURN;
}
void handle_int8(){//双重错误
	char str[]="\n#DF:int-0x8!";
	printString(str);
	INT_RETURN;
}
//int9 保留
void handle_int10(){//无效TSS
	char str[]="\n#TS:int-0xa!";
	printString(str);
	INT_RETURN;
}
void handle_int11(){//段不存在
	char str[]="\n#NP:int-0xb!";
	printString(str);
	INT_RETURN;
}
void handle_int12(){//堆栈段错误
	char str[]="\n#SS:int-0xc!";
	printString(str);
	INT_RETURN;
}
void handle_int13(){//一般保护性错误
	char str[]="\n#GP:int-0xd!";
	printString(str);
	INT_RETURN;
}
void handle_int14(){//页面错误
	char str[]="\n#PF:int-0xe!";
	printString(str);
	INT_RETURN;
}
//int15 保留
void handle_int16(){//FPU错误
	char str[]="\n#MF:int-0x10!";
	printString(str);
	INT_RETURN;
}
void handle_int17(){//对齐检查
	char str[]="\n#AC:int-0x11!";
	printString(str);
	INT_RETURN;
}
void handle_int18(){//机器检查
	char str[]="\n#AC:int-0x12!";
	printString(str);
	INT_RETURN;
}
void handle_int19(){//SIMD错误
	char str[]="\n#XF:int-0x13!";
	printString(str);
	INT_RETURN;
}
