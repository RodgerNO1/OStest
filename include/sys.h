/*
*	系统保护模式设置函数
*	设置GDT,IDT等
*/
#ifndef _SYS_H
#define _SYS_H

#include<def.h>
#include<stdio.h>
void set_int_handler(BYTE int_num,PLVOID func){
	DES_GATE gate;
	gate.addrL=(WORD)func;
	gate.segsel=SelectorCode;
	gate.paramCnt=0;
	gate.type=0x8e;	//32位中断门，0特权级
	gate.addrH=((WORD)(func)>>16);
	memcopy(&gate,0x20000+int_num*8,sizeof(DES_GATE),0,SelectorFlatRW);//写入中断向量表
}
//创建LDT,写入LDT 创建TSS,写入TSS,在GDT中注册LDT,在GDT中注册TSS
void creatTask(BYTE task_num,PLVOID func){
	Descriptor LDestor;		//LDT中的描述符
	LDestor.limit=0x0fff;	//任务代码限制4k
	LDestor.baseL=(WORD)func;	
	LDestor.baseM=((BYTE)(func)>>16);
	LDestor.attribute=0x4000+0x9a;	//可执行可读
	LDestor.baseH=((BYTE)(func)>>24);
	memcopy(&LDestor,0,sizeof(LDestor),0,SelectorTssLdt);//写入LDT&TSS段
	//在GDT中注册LDT0
	DWORD ldt0_phyAddr=0x40000;
	Descriptor GDestor_ldt0;
	GDestor_ldt0.limit=0x8-1;	//LDT0的长度-1
	GDestor_ldt0.baseL=(WORD)ldt0_phyAddr;	
	GDestor_ldt0.baseM=((BYTE)(ldt0_phyAddr)>>16);
	GDestor_ldt0.attribute=0x4000+0x82;	//LDT
	GDestor_ldt0.baseH=((BYTE)(ldt0_phyAddr)>>24);
	//取得gdtr
	GDTR gdtr;
	memcopy(0x30000,&gdtr,sizeof(GDTR),SelectorFlatRW,0);
	//将新desc写入gdt
	//memcopy(&GDestor_ldt0,gdtr.phyAddr+gdtr.gdtLimit+1,sizeof(GDestor_ldt0),0,SelectorFlatRW);
	memcopy(&GDestor_ldt0,0x30058,sizeof(GDestor_ldt0),0,SelectorFlatRW);
	//更新gdtr
	gdtr.gdtLimit=gdtr.gdtLimit+sizeof(GDestor_ldt0);
	memcopy(&gdtr,0x30000,sizeof(GDTR),0,SelectorFlatRW);
	
	setGdt();
}
#endif