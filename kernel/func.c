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
	while(1)
    printChar('T');
}
void do_timer(){
	sys_inc_tick();//1tick==10ms
	if(getTimeTick()%(1000)==0)
	printInt(getTimeTick());
	
	FAR_RETURN;
}
int getTimeTick(){
	return sys_get_tick();
}