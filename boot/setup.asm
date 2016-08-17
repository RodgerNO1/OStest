; ==========================================
; setup.asm
; 编译方法：nasm setup.asm -o setup.bin
; ==========================================

;----------------------------------------
;system constants
;SETUPSEG        equ	1000h
;SETUPOFF        equ	0000h
;SYSSEG          equ	1700h
;SYSOFF          equ	0000h
	
[org 0000h]
[SECTION header]
        jmp LABEL_BEGIN     ; 

;----------------------------------------------------------------------------
; 在下列类型值命名中：
;       DA_  : Descriptor Attribute
;       D    : 数据段
;       C    : 代码段
;       S    : 系统段
;       R    : 只读
;       RW   : 读写
;       A    : 已访问
;       其它 : 可按照字面意思理解
;----------------------------------------------------------------------------

; 描述符类型
DA_32		EQU	4000h	; 32 位段

DA_DPL0		EQU	  00h	; DPL = 0
DA_DPL1		EQU	  20h	; DPL = 1
DA_DPL2		EQU	  40h	; DPL = 2
DA_DPL3		EQU	  60h	; DPL = 3

; 存储段描述符类型
DA_DR		EQU	90h	; 存在的只读数据段类型值
DA_DRW		EQU	92h	; 存在的可读写数据段属性值
DA_DRWA		EQU	93h	; 存在的已访问可读写数据段类型值
DA_C		EQU	98h	; 存在的只执行代码段属性值
DA_CR		EQU	9Ah	; 存在的可执行可读代码段属性值
DA_CCO		EQU	9Ch	; 存在的只执行一致代码段属性值
DA_CCOR		EQU	9Eh	; 存在的可执行可读一致代码段属性值

; 系统段描述符类型
DA_LDT		EQU	  82h	; 局部描述符表段类型值
DA_TaskGate	EQU	  85h	; 任务门类型值
DA_386TSS	EQU	  89h	; 可用 386 任务状态段类型值
DA_386CGate	EQU	  8Ch	; 386 调用门类型值
DA_386IGate	EQU	  8Eh	; 386 中断门类型值
DA_386TGate	EQU	  8Fh	; 386 陷阱门类型值

;----------------------------------------------------------------------------
; 选择子类型值说明
; 其中:
;       SA_  : Selector Attribute

SA_RPL0		EQU	0	; ┓
SA_RPL1		EQU	1	; ┣ RPL
SA_RPL2		EQU	2	; ┃
SA_RPL3		EQU	3	; ┛

SA_TIG		EQU	0	; ┓TI
SA_TIL		EQU	4	; ┛
;----------------------------------------------------------------------------


; 宏 ------------------------------------------------------------------------
;
; 描述符
; usage: Descriptor Base, Limit, Attr
;        Base:  dd
;        Limit: dd (low 20 bits available)
;        Attr:  dw (lower 4 bits of higher byte are always 0)
%macro Descriptor 3
	dw	%2 & 0FFFFh				; 段界限1
	dw	%1 & 0FFFFh				; 段基址1
	db	(%1 >> 16) & 0FFh			; 段基址2
	dw	((%2 >> 8) & 0F00h) | (%3 & 0F0FFh)	; 属性1 + 段界限2 + 属性2
	db	(%1 >> 24) & 0FFh			; 段基址3
%endmacro ; 共 8 字节
;
; 门
; usage: Gate Selector, Offset, DCount, Attr
;        Selector:  dw
;        Offset:    dd
;        DCount:    db
;        Attr:      db
%macro Gate 4
	dw	(%2 & 0FFFFh)				; 偏移1
	dw	%1					; 选择子
	dw	(%3 & 1Fh) | ((%4 << 8) & 0FF00h)	; 属性
	dw	((%2 >> 16) & 0FFFFh)			; 偏移2
%endmacro ; 共 8 字节
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


[SECTION .gdt]
; GDT
;                              段基址,       段界限     , 属性
LABEL_GDT:	   		Descriptor       0,		0, 			0           	; 空描述符
LABEL_DESC_KERNEL: 	Descriptor 010000h, 	0ffffh, 	DA_C + DA_32	; 非一致代码段
LABEL_DESC_DATA:   	Descriptor 020000h,  	0ffffh, 	DA_DRW	     	; 显存首地址
LABEL_DESC_VIDEO:  	Descriptor 0B8000h,  	0ffffh, 	DA_DRW	     	; 显存首地址
; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1		; GDT界限
			dd	0				; GDT基地址

; GDT 选择子
SelectorKernel		equ	LABEL_DESC_KERNEL	- LABEL_GDT
SelectorData		equ	LABEL_DESC_DATA		- LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; END of [SECTION .gdt]

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址

	; 加载 GDTR
	lgdt	[GdtPtr]

	; 关中断
	cli

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorKernel:0	; 执行这一句会把 SelectorKernel 装入 cs,; 并跳转到 SelectorKernel:0  处
	nop
	nop
	nop
	; END of [SECTION .s16]

;;;;;;;;;;;;;;;;;;;END;;;;;;;;;;;;;;;;;;;;;;
