; ==========================================
; setup.asm
; 编译方法：nasm setup.asm -o setup.bin
; ==========================================
%include	"pm.inc"	; 常量, 宏, 以及一些说明	
;----------------------------------------
;system constants
;SETUPSEG        equ	1000h
;SETUPOFF        equ	0000h
;SYSSEG          equ	1700h
;SYSOFF          equ	0000h


[org 0000h]
[SECTION header]
        jmp LABEL_BEGIN     ; 

[SECTION .gdt]
; GDT
;                              段基址,       段界限     , 属性
LABEL_GDT:	   		Descriptor       0,		0, 			0           	; 空描述符
LABEL_DESC_NORMAL:	Descriptor	     0,     0ffffh, 	DA_DRW			; Normal 描述符
LABEL_DESC_FLAT_C:	Descriptor       0,    0fffffh, 	DA_CR | DA_32 | DA_LIMIT_4K	; 0 ~ 4G
LABEL_DESC_FLAT_RW:	Descriptor       0,    0fffffh, 	DA_DRW | DA_LIMIT_4K		; 0 ~ 4G
LABEL_DESC_CODE: 	Descriptor 010000h, 	0ffffh, 	DA_CR + DA_32	; 非一致代码段
LABEL_DESC_DATA:   	Descriptor 020000h,  	0ffffh, 	DA_DRW	     	; 显存首地址
LABEL_DESC_STACK:	Descriptor 020000h,		0ffffh, 	DA_DRWA | DA_32		; Stack, 32 位
LABEL_DESC_VIDEO:  	Descriptor 0B8000h,  	0ffffh, 	DA_DRW	     	; 显存首地址
; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1		; GDT界限
			dd	0				; GDT基地址

; GDT 选择子
SelectorNormal		equ		08h
SelectorFlatC		equ	 	10h
SelectorFlatRW		equ		18h
SelectorCode		equ		20h
SelectorData		equ		28h	
SelectorStack		equ		30h
SelectorVideo		equ		38h
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
	jmp	dword SelectorCode:0	; 执行这一句会把 SelectorCode 装入 cs,; 并跳转到 SelectorKernel:0  处
	nop
	nop
	nop
	; END of [SECTION .s16]

;;;;;;;;;;;;;;;;;;;END;;;;;;;;;;;;;;;;;;;;;;
