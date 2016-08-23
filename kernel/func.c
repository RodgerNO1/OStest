/*
*系统C函数实现
*/
#include <def.h>
#include<stdio.h>

void test(){
	DES_GDT desc;
	memcopy(0x30010,&desc,sizeof(DES_GDT),SelectorFlatRW,0);
	/*
	desc.limit=0x01;
    desc.baseL=0x02;
    desc.baseM=0x03;
    desc.access=0x04;
    desc.gran=0x05;
    desc.baseH=0x06;*/
	memcopy(&desc,0x30100,sizeof(DES_GDT),0,SelectorFlatRW);
	
	printHexW(desc.limit);
	printHexW(desc.baseL);
	printHexB(desc.baseM);
	printHexB(desc.access);
	printHexB(desc.gran);
	printHexB(desc.baseH);
	
	printHexD(&desc);
}

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

void do_timer(){
	sys_inc_tick();//1tick==10ms
	if(getTimeTick()%(1000)==0)
	printInt(getTimeTick());
	
	INT_HANDLER_RETURN;
}
int getTimeTick(){
	return sys_get_tick();
}