#ifndef _DEF_H
#define _DEF_H

//数据类型
typedef void* PLVOID;

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned long DWORD;

// GDT 选择子
#define SelectorNormal	0x08
#define SelectorFlatC	0x10
#define SelectorFlatRW	0x18
#define SelectorCode	0x20
#define SelectorData	0x28	
#define SelectorStack	0x30
#define SelectorVideo	0x38
#define SelectorGdt		0x40
#define SelectorTssLdt	0x48

//汇编函数接口
extern void sys_halt(void);
extern void sys_write_vga(int index,int cchar,int color);
extern void sys_cls();
extern void sys_inc_tick();
extern int  sys_get_tick();
extern void sys_put_char(int cchar);
extern int sys_get_cursor();
extern void sys_memcpy(int s,int d,int size,int ds,int es);
#define INT_HANDLER_RETURN asm("leave;retf;"::)


//结构体
typedef struct gate_struct{             /*trap descriptor struct*/
	WORD	addrL;                  /*base address low 16bits*/
	WORD	segsel;                 /*default is 0x08*/
	BYTE	sitems;                 /*call gate stack items*/
	BYTE	type;                   /*gate descriptor type*/
	WORD	addrH;                  /*base address high 16bits*/
}DES_GATE;


typedef struct desc_struct{                     /*descriptor struct,gdt or ldt*/
	WORD	limit;                  /*segment limit*/
	WORD	baseL;                  /*base address low 16bits*/
	BYTE 	baseM;                  /*base address middle 8bits*/
	BYTE	access;                 /*access type*/
	BYTE	gran;                   /*gran*/
	BYTE	baseH;                  /*address high 8bits*/
}DES_GDT;
typedef struct tss_struct{
	DWORD	back_link;
	DWORD	esp0;
	DWORD	ss0;
	DWORD	esp1;
	DWORD	ss1;
	DWORD	esp2;
	DWORD	ss2;
	DWORD	cr3;
	DWORD	eip;
	DWORD	eflags;
	DWORD	eax;
	DWORD	ecx;
	DWORD	edx;
	DWORD	ebx;
	DWORD	esp;
	DWORD	ebp;
	DWORD	esi;
	DWORD	edi;
	DWORD	es;
	DWORD	cs;
	DWORD	ss;
	DWORD	ds;
	DWORD	fs;
	DWORD	gs;
	DWORD	ldt;
	DWORD	trace_bitmap;
}Tss;
typedef struct task_struct{
    DWORD pid;                   //4B
    BYTE pname[16];             //16B
    DWORD priority;              //4B
    DWORD counter;               //4B
    DWORD ldt_sel;               //4B
    DWORD tss_sel;               //4B
    struct desc_struct ldt[4];  //32B
    struct tss_struct tss;      //68B
    struct task_struct *next;   //4B
    BYTE stack_krn[116];        // kernel mode stack area.
    BYTE stack_user[256];       // user mode stck area.
}Task;
#endif