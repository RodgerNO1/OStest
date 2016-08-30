; ==========================================
; setup.asm
; 编译方法：nasm setup.asm -o setup.bin
; ==========================================
%include	"pm.inc"	; 常量, 宏, 以及一些说明	
;----------------------------------------
;system constants
GDTR        	equ	80000h
GDTbase        	equ	80008h
IDTbase        	equ	90000h
;SETUPOFF        equ	0000h
;SYSSEG          equ	1700h
;SYSOFF          equ	0000h


[org 0000h]
[SECTION header]
        jmp LABEL_BEGIN     ; 

[SECTION .gdt]
; GDT
;                              段基址,       段界限     , 属性
LABEL_GDT:	   		Descriptor      0,		0, 			0           	; 空描述符
DESC_FLAT_C:	Descriptor      0,    	0ffffh, 	DA_CR | DA_32 | DA_LIMIT_4K	; 0 ~ 4G
DESC_FLAT_RW:	Descriptor      0,    	0ffffh, 	DA_DRW | DA_LIMIT_4K		; 0 ~ 4G
DESC_CODE: 		Descriptor 		0, 		0a0h, 		DA_CR | DA_32 | DA_LIMIT_4K; 非一致代码段
DESC_DATA:   	Descriptor 		0,  	0a0h, 		DA_DRW | DA_LIMIT_4K	     	; 显存首地址
DESC_VIDEO:  	Descriptor 0B8000h,  	0ffffh, 	DA_DRW	     	; 显存首地址
DESC_GDT:		Descriptor 080000h,		0fffh, 		DA_DRW | DA_32		
DESC_TSSLDT:	Descriptor 081000h,		0efffh, 	DA_DRW | DA_32
DESC_IDT:		Descriptor 090000h,		0ffffh, 	DA_DRW | DA_32		
; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1		; GDT界限
			dd	0				; GDT基地址

; GDT 选择子
SelectorFlatC		equ	 	08h
SelectorFlatRW		equ		10h
SelectorCode		equ		18h
SelectorData		equ		20h	
SelectorVideo		equ		28h
SelectorGdt			equ		30h
SelectorTssLdt		equ		38h
SelectorIdt			equ		40h
; END of [SECTION .gdt]

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	;复制GDT到0x30008位置
	push ds
	push es
	xor	esi, esi
	mov esi,LABEL_GDT
	mov eax,0x8000
	mov es,ax
	mov edi,8
	cld
	mov eax,dword[GdtPtr]
	mov ebx,2
	div ebx
	inc eax
	mov ecx,eax
	rep movsw
	;复制GdtPtr到0x80000位置
	mov ax,word[GdtPtr]
	mov word[es:0],ax
	mov eax,GDTbase	;gdt基址
	mov dword[es:2],eax
	pop es
	pop ds
	
	;移动system.bin到0000位置
	push ds
	push es
	xor	esi, esi
	xor	edi, edi
	mov esi,0
	mov eax,0x1000
	mov ds,ax
	mov eax,0
	mov es,ax
	mov edi,0
	cld
	mov ecx,4096;4k
	rep movsb
	pop es
	pop ds

	call empty_8042
	mov al,0d1h
	out 64h,al
	call empty_8042
	mov al,0dfh
	out 60h,al
	call empty_8042
	call Init8259A
	
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
	or	eax, 1h
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorCode:0	; 执行这一句会把 SelectorCode 装入 cs,; 并跳转到 SelectorKernel:0  处
	nop
	nop
	nop
	; END of [SECTION .s16]
Init8259A:
	;well that went ok,I hope.Now we have to reprogrem the interrupts
;(20-27h is master ,28-2fh is slover
	mov al,11h
	out 20h,al		; 主8259, ICW1.
	wait
	out 0a0h,al		; 从8259, ICW1.
	wait
	mov al,20h		; IRQ0 对应中断向量 0x20时钟中断
	out 21h,al		; 主8259, ICW2.
	wait
	mov al,28h		; IRQ8 对应中断向量 0x28
	out 0a1h,al		; 从8259, ICW2.
	wait
	mov al,04h		; IR2 对应从8259
	out 21h,al		; 主8259, ICW3.
	wait
	mov al,02h		; 对应主8259的 IR2
	out 0a1h,al		; 从8259, ICW3.
	wait
	mov al,01h      ; 主8259, ICW4.normal EOI method for both
	;mov al,03h     ;automatica EOI method for both
	out 21h,al
	wait
	out 0a1h,al		; 从8259, ICW4.
	wait
	mov al,0ffh		;mask off all interrupts for now
	out 21h,al		; 主8259, OCW1.
	wait
	out 0a1h,al		; 从8259, OCW1.
	wait
	ret	
	
empty_8042:
	wait
	in al,64h
	test al,02h
	jnz empty_8042
	ret	
;;;;;;;;;;;;;;;;;;;END;;;;;;;;;;;;;;;;;;;;;;
