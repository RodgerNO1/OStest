/*
*	系统保护模式设置函数
*	设置GDT,IDT等
*/
#ifndef _SYS_H
#define _SYS_H

#include<def.h>
#include<stdio.h>
extern void sys_test();
void set_int_handler(BYTE int_num,PLVOID func){
	DES_GATE gate;
	gate.addrL=(WORD)func;
	gate.segsel=SelectorCode;
	gate.paramCnt=0;
	gate.type=0x8e;	//32位中断门，0特权级
	gate.addrH=((WORD)(func)>>16);
	memcopy(&gate,0x20000+int_num*8,sizeof(DES_GATE),0,SelectorFlatRW);//写入中断向量表
}
Descriptor creatDescriptor(DWORD baseAddr,WORD limit,BYTE type,BYTE attrGD){
	Descriptor LDestor;
	LDestor.limit=limit;	//任务代码限制4k
	LDestor.baseL=baseAddr;	
	LDestor.baseM=baseAddr>>16;
	LDestor.type=type;		//0x9a可执行可读,0x82:LDT
	LDestor.attrGD=attrGD;
	LDestor.baseH=baseAddr>>24;
	return LDestor;
}
Tss creatTss(DWORD eip,DWORD esp0,DWORD esp,DWORD ds,DWORD ldt){
   Tss tss={0x0,					//back_link:前tss选择符
			0x0,0x0,				//esp0,ss0
			0x0,0x0,0x0,0x0,0x0,	//esp1,ss1,esp2,ss2,cr3
			0x0,0x0,0x0,0x0,0x0,	//eip,eflags,eax,ecx,edx
			0x0,0x0,0x0,0x0,0x0,	//ebx,esp,ebp,esi,edi
			0x0,0x0,0x0,0x0,0x0,0x0,//es,cs,ss,ds,fs,gs
			0x0,0x0};				//ldt,trace_bitmap
	tss.esp0=esp0;
	tss.esp=esp;
	tss.ss0=ss0;
	tss.eip=eip;
	tss.ldt=ldt;
	return tss;
}
int addDesToGDT(Descriptor item){
	//取得gdtr
	GDTR gdtr;
	memcopy(0x30000,&gdtr,sizeof(GDTR),SelectorFlatRW,0);
	int index=gdtr.gdtLimit+1;//ldt0选择子
	//将新desc写入gdt
	memcopy(&item,0x30008+gdtr.gdtLimit+1,sizeof(Descriptor),0,SelectorFlatRW);
	//printHexD(sel_ldt0);
	//printChar('\n');
	//更新gdtr
	gdtr.gdtLimit=gdtr.gdtLimit+sizeof(Descriptor);
	memcopy(&gdtr,0x30000,sizeof(GDTR),0,SelectorFlatRW);
	setGdt();
	return index;
}
//创建LDT,写入LDT 创建TSS,写入TSS,在GDT中注册LDT,在GDT中注册TSS
void creatTask(BYTE task_num,PLVOID func){
	Descriptor LDestor=creatDescriptor(0x10000,0xffff,0x9a,0x40);		
	memcopy(&LDestor,0,sizeof(Descriptor),0,SelectorTssLdt);//写入LDT&TSS段
	//在GDT中注册LDT0
	DWORD ldt0_phyAddr=0x40000;
	Descriptor GDestor_ldt0=creatDescriptor(ldt0_phyAddr,0x8-1,0x82,0x40);
	int ldt0_sel=addDesToGDT(GDestor_ldt0);
	Tss tss0=creatTss((DWORD)func,esp0,esp,ss0,ldt0_sel)
	//asm("lldt %%ax"::"eax"(index));
	//asm("ljmp %0,%1"::"i"(0x4),"i"(0xa1d));

}
#endif