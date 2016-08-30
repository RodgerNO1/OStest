/*
*	系统保护模式设置函数
*	设置GDT,IDT等
*/
#ifndef _SYS_H
#define _SYS_H

#include<def.h>
#include<stdio.h>

/* Load tr register. */
#define ltr(SEL) asm(\
		"ltr %%ax;"\
		::"a"(SEL))
/* Load ldt register. */
#define lldt(SEL) asm(\
		"lldt %%ax;"\
		::"a"(SEL))
//标志位NT复位,NT复位后iret指令不会造成cpu执行任务切换操作
#define cl_nt()	asm("pushfl;"\
		"andl $0xffffbfff,(%esp);"\
		"popfl;")
//构造iret返回环境//将SS选择子存入栈中//将SP存入栈中//将eflags存入栈中
//将cs选择子存入栈中//将1:位置存入栈中//跳转到1:执行//开始用户态执行
#define move_to_user_mode()\
	asm volatile(\
		"movl	%%esp,%%eax;"\
		"pushl	$0x17;"\
		"pushl	%%eax;"\
		"pushfl;"\
		"pushl	$0x0f;"\
		"pushl	$0xa14;"\
		"iret;"\
		"LL:movl	$0x17,%%eax;"\
		"movw	%%ax,%%ds;"\
		"movw	%%ax,%%es;"\
		"movw	%%ax,%%fs;"\
		"movw	%%ax,%%gs;"\
		::)	
	
Descriptor creatDescriptor(DWORD baseAddr,WORD limit,BYTE type,BYTE attrGD){
	Descriptor LDestor;
	LDestor.limit=limit;	//任务代码限制4k
	LDestor.baseL=baseAddr;	
	LDestor.baseM=baseAddr>>16;
	LDestor.type=type;		//0x9a可执行可读,0x82:LDT,0x89:TSS
	LDestor.attrGD=attrGD;
	LDestor.baseH=baseAddr>>24;
	return LDestor;
}
int creatTSS(BYTE task_num,DWORD eip,DWORD esp0,DWORD esp,DWORD ldt){
   TSS tss={0x0,					//back_link:前tss选择符
			0x0,0x0,				//esp0,ss0
			0x0,0x0,0x0,0x0,0x0,	//esp1,ss1,esp2,ss2,cr3
			0x0,0x0,0x0,0x0,0x0,	//eip,eflags,eax,ecx,edx
			0x0,0x0,0x0,0x0,0x0,	//ebx,esp,ebp,esi,edi
			0x0,0x0,0x0,0x0,0x0,0x0,//es,cs,ss,ds,fs,gs
			0x0,0x0};				//ldt,trace_bitmap
	tss.eip=eip;
	tss.cs=0x8+0x4;
	tss.esp0=esp0;
	tss.ss0=SelectorData;
	tss.esp=esp;
	tss.ss=0x10+0x4;
	tss.ds=0x10+0x4;
	tss.es=0x10+0x4;
	tss.fs=0x10+0x4;
	tss.gs=0x10+0x4;
	tss.ldt=ldt;
	//写入LDT&TSS段
	DWORD offset=task_num*(3*sizeof(Descriptor)+sizeof(TSS))+3*sizeof(Descriptor);
	memcopy(&tss,offset,sizeof(TSS),0,SelectorTssLdt);
	//在GDT中注册tss
	DWORD tss_phyAddr=LDTbase+offset;
	Descriptor GDestor_tss=creatDescriptor(tss_phyAddr,sizeof(TSS)-1,0x89,0x40);
	int selector=addDesToGDT(GDestor_tss);
	return selector;//并返回其全局描述符的选择子
}
int creatLDT(BYTE task_num,DWORD code_baseAddr,DWORD data_baseAddr){//在TSS&LDT中创建ldt_num,并返回其全局描述符的选择子
	Descriptor LDestor[3];
	LDestor[0]=creatDescriptor(0x0,0x0,0x0,0x0);//空描述符
	LDestor[1]=creatDescriptor(code_baseAddr,0xffff,0x9a,0x40);	//代码段描述符
	LDestor[2]=creatDescriptor(data_baseAddr,0xffff,0x92,0x40);	//数据段描述符
	DWORD offset=task_num*(3*sizeof(Descriptor)+sizeof(TSS));
	memcopy(&LDestor,offset,3*sizeof(Descriptor),0,SelectorTssLdt);//写入LDT&TSS段
	//在GDT中注册LDT0
	DWORD ldt_phyAddr=LDTbase+offset;
	Descriptor GDestor_ldt0=creatDescriptor(ldt_phyAddr,(3*8)-1,0x82,0x40);
	int selector=addDesToGDT(GDestor_ldt0);
	return selector;//并返回其全局描述符的选择子
}
int addDesToGDT(Descriptor item){
	//取得gdtr
	GDTR gdtr;
	memcopy(GDTR_pos,&gdtr,sizeof(GDTR),SelectorFlatRW,0);
	int index=gdtr.gdtLimit+1;//ldt0选择子
	//将新desc写入gdt
	memcopy(&item,GDTbase+gdtr.gdtLimit+1,sizeof(Descriptor),0,SelectorFlatRW);
	//printHexD(sel_ldt0);
	//printChar('\n');
	//更新gdtr
	gdtr.gdtLimit=gdtr.gdtLimit+sizeof(Descriptor);
	memcopy(&gdtr,GDTR_pos,sizeof(GDTR),0,SelectorFlatRW);
	setGdt();
	return index;
}
//创建LDT,写入LDT 创建TSS,写入TSS,在GDT中注册LDT,在GDT中注册TSS
void creatTask(BYTE task_num,PLVOID func){
	int ldt0_sel=creatLDT(task_num,0x10000,0x21000);
	DWORD esp0=0xef00-0x1000*task_num;
	int tss0_sel=creatTSS(task_num,(DWORD)func,esp0,0xff0,ldt0_sel);
	//asm("lldt %%ax"::"eax"(index));	
}


#endif