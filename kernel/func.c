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
void int_0x22()
{
	char str[]="int 0x22!\n";
	printString(str);
	
	INT_RETURN;
}

void task0()
{	
	int i=0;
	while(1){
		printChar('A');
	}
    while(1)sys_halt();
}
void task1()
{	
	int i=0;
	while(1){
		printChar('B');
	}

	while(1)sys_halt();
}
void do_timer(){
	printChar('I');
/*
	if(sys_get_tick()%(50)==1){
		printInt(sys_get_tick());
		int pid=0;
		memcopy(0x20900,&pid,4,0x18,0);
		if(pid==0){
			pid=1;
			memcopy(&pid,0x20900,4,0,0x18);
			printChar('A');
			//asm("ljmp %0,%1"::"i"(0x68),"i"(0x0));
		}else{
			pid=0;
			memcopy(&pid,0x20900,4,0,0x18);
			printChar('B');
			//asm("ljmp %0,%1"::"i"(0x58),"i"(0x0));
		}
	}
*/
	FAR_RETURN;
	
}
int getTimeTick(){
return sys_get_tick();
}