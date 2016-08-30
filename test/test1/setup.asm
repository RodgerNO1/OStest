; ==========================================
; setup.asm
; 编译方法：nasm setup.asm -o setup.bin
; ==========================================
%include	"pm.inc"	; 常量, 宏, 以及一些说明	
;----------------------------------------

[SECTION header]
        jmp LABEL_BEGIN     ; 

; GDT 选择子
SelectorFlatC		equ	 	08h
SelectorFlatRW		equ		10h
SelectorCode		equ		18h
SelectorData		equ		20h	
SelectorVideo		equ		28h
SelectorGdt			equ		30h
SelectorTssLdt		equ		38h
SelectorIdt			equ		40h

SelectorLdt0		equ		40h
SelectorTss0		equ		40h
SelectorLdt1		equ		40h
SelectorTss1		equ		40h
; GDT 结束




[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h
	
	;移动代码段
	xor	esi, esi
	xor	edi, edi
	mov esi,LABEL_CODE
	mov eax,0x1000
	mov ds,ax
	mov eax,0
	mov es,ax
	mov edi,0
	cld
	mov ecx,Code32_len;9k
	rep movsb
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
[SECTION .code32]
[BITS	32]
LABEL_CODE:
	call show_pm	;显示pm标志
	
	mov	ax,SelectorData
	mov	ds,ax
	mov	es,ax
	mov	fs,ax
	mov	gs,ax
	mov	ss,ax
	mov esp,0fffeh
	call setIdt
    mov	ax,SelectorData
	mov	ds,ax
	mov	fs,ax
	mov	gs,ax
	mov	es,ax
	mov	ss,ax
	mov	esp,0fffeh
    call Init8259A
	call setClk		;initialize 8253/54
;-------------------------------------------------------



;-------------------------------------------------------
L6:
	jmp L6	; main should never return here
	
;------------------------------------------------------------------------------
setIdt:
        lidt [_idtr]                        ;加载中断描述符表寄存器IDTR
		ret
setClk:
	mov	al,36h
	out	43h,al
	wait
	
	mov	ax,11930;设置时钟中断频率(1193180/100)即100hz
	out	40h,al
	wait
	mov	al,ah
	out	40h,al
	wait
	ret
show_pm:
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子(目的)
	
	mov	edi, (80 * 11 + 79) * 2	; 屏幕第 11 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'P'
	mov	[gs:edi], ax
	ret
;end show_pm

; Init8259A 
Init8259A:
	mov	al, 011h
	out	020h, al	; 主8259, ICW1.
	call	io_delay

	out	0A0h, al	; 从8259, ICW1.
	call	io_delay   

	mov	al, 020h	; IRQ0 对应中断向量 0x20时钟中断
	out	021h, al	; 主8259, ICW2.
	call	io_delay

	mov	al, 028h	; IRQ8 对应中断向量 0x28
	out	0A1h, al	; 从8259, ICW2.
	call	io_delay

	mov	al, 004h	; IR2 对应从8259
	out	021h, al	; 主8259, ICW3.
	call	io_delay

	mov	al, 002h	; 对应主8259的 IR2
	out	0A1h, al	; 从8259, ICW3.
	call	io_delay

	mov	al, 001h
	out	021h, al	; 主8259, ICW4.
	call	io_delay

	out	0A1h, al	; 从8259, ICW4.
	call	io_delay

	;mov	al, 11111111b	; 屏蔽主8259所有中断
	mov	al, 11111110b	; 仅仅开启定时器中断
	out	021h, al	; 主8259, OCW1.
	call	io_delay

	mov	al, 11111111b	; 屏蔽从8259所有中断
	out	0A1h, al	; 从8259, OCW1.
	call	io_delay

	ret

io_delay:
	nop
	nop
	nop
	nop
	ret
	
; int handler ---------------------------------------------------------------
_ClockHandler:
	mov	ah, 0Ch				; 0000: 黑底    1100: 红字
	mov	al, 'C'
	mov	[gs:((80 * 0 + 70) * 2)], ax	; 屏幕第 0 行, 第 70 列。
	iretd
	
	push ds
	push eax
	mov	al, 20h
	out	20h, al				; 发送 EOI
	mov eax,SelectorData
	mov eax,1
	cmp eax,current
	je .t1
	mov eax,1
	mov dword[current],eax
;	jmp SelectorTss1:0
	jmp .t2	
.t1:
	mov eax,0
	mov dword[current],eax
;	jmp SelectorTss0:0
.t2:
	pop eax
	pop ds
	iretd

_UserIntHandler:
	
	mov	ah, 0Ch				; 0000: 黑底    1100: 红字
	mov	al, 'I'
	mov	[gs:((80 * 0 + 70) * 2)], ax	; 屏幕第 0 行, 第 70 列。
	iretd

_SpuriousHandler:
	mov	ah, 0Ch				; 0000: 黑底    1100: 红字
	mov	al, '!'
	mov	[gs:((80 * 0 + 75) * 2)], ax	; 屏幕第 0 行, 第 75 列。
	jmp $					;未知系统中断，系统死循环
	iretd
;-------------------------------------------------------------------
task0:
	push 0x65
	call put_char
	jmp task0
	
task1:
	push 0x65
	call put_char
	jmp task1
;-------------------------------------------------------------------
_sys_get_cursor:;以下取当前光标位置ax
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;高8位 
         mov ah,al

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;低8位 AX=代表光标位置的16位数
		 ret
;end _sys_get_cursor		 

put_char:                                ;显示一个字符 vl=字符ascii
		 push ds
		 push es
		 push gs
		 push ebp
		 mov ebp,esp
		 
		 mov ecx,[ebp+20]				;CX 存放字符
         ;以下取当前光标位置
		 call _sys_get_cursor
		 mov bx,ax						;BX 存放光标位置
		 
		 mov ax, SelectorVideo
		 mov gs, ax			; 视频段选择子
		 
         cmp cl,0x0d                     ;回车符？
         jnz .put_0a                     ;不是。看看是不是换行等字符 
         mov ax,bx                       ;此句略显多余，但去掉后还得改书，麻烦 
         mov bl,80                       
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

 .put_0a:
         cmp cl,0x0a                     ;换行符？
         jnz .put_other                  ;不是，那就正常显示字符 
         add bx,80
         jmp .roll_screen

 .put_other:                             ;正常显示字符
         shl bx,1
         mov [gs:bx],cl

         ;以下将光标位置推进一个字符
         shr bx,1
         add bx,1

 .roll_screen:
         cmp bx,2000                     ;光标超出屏幕？滚屏
         jl .set_cursor

         mov ax,SelectorVideo
         mov ds,ax
         mov es,ax
         cld
         mov si,0xa0
         mov di,0x00
         mov cx,1920
         rep movsw
         mov bx,3840                     ;清除屏幕最底一行
         mov cx,80
 .cls:
         mov word[gs:bx],0x0720
         add bx,2
         loop .cls

         mov bx,1920
 
.set_cursor:
		
		call local_set_cursor
		
		 pop ebp
		 pop gs
		 pop es
		 pop ds
		 ret
;end  _sys_put_char 

local_set_cursor:;参数BX
		 mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         mov al,bh
         out dx,al
         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         mov al,bl
         out dx,al
		 ret

Code32_len 	equ $-LABEL_CODE		 
;======================data========================================
LABEL_DATA:
; GDT
;                              段基址,       段界限     , 属性
LABEL_GDT:	   	Descriptor      0,		0, 			0           	; 空描述符
DESC_FLAT_C:	Descriptor      0,    	0ffffh, 	DA_CR | DA_32 | DA_LIMIT_4K	; 0 ~ 4G
DESC_FLAT_RW:	Descriptor      0,    	0ffffh, 	DA_DRW | DA_LIMIT_4K		; 0 ~ 4G
DESC_CODE: 		Descriptor 		0, 		0a0h, 		DA_CR | DA_32 | DA_LIMIT_4K; 非一致代码段
DESC_DATA:   	Descriptor 		0,  	0a0h, 		DA_DRW | DA_LIMIT_4K	    
DESC_VIDEO:  	Descriptor 0B8000h,  	0ffffh, 	DA_DRW	     	; 显存首地址
DESC_GDT:		Descriptor 080000h,		0fffh, 		DA_DRW | DA_32		
DESC_TSSLDT:	Descriptor 081000h,		0efffh, 	DA_DRW | DA_32
DESC_IDT:		Descriptor 090000h,		0ffffh, 	DA_DRW | DA_32
; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1		; GDT界限
			dd	0				; GDT基地址
			
current dd 0x0
_idtr:  dw	256*8-1		;IDT的界限
        dd	_idtr	;中断描述符表的线性地址
		
_tss0:	dd	0000h                  ;back link
		dd	0ff00h, 0030h 			;esp0,  ss0
		dd	0000h, 0000h           ;esp1,  ss1
		dd	0000h, 0000h           ;esp2,  ss2
		dd	0000h                  ;cr3
		dd	0000h                  ;eip
		dd	0200h                  ;eflags
		dd	0000h, 0000h, 0000h, 0000h
                                   ;eax,  ecx,  edx,  ebx
		dd	0ff00h            ;esp
		dd	0000h, 0000h, 0000h    ;ebp, esi, edi
		dd	0017h, 000fh, 0017h, 0017h, 0017h, 0017h
						           ;es,  cs,  ss,  ds,  fs,  gs
		dd	SelectorLdt0		       ;ldt
		dd	8000000h		       ;trace bitmap
;LDT0 for task 0,Every task must have private ldt.
_ldt0:	dd	00000000h, 00000000h   ;dummy
		dd	00000fffh, 00c0fa00h   ;task 0 code segment
		dd	00000fffh, 00c0f200h   ;task 0 data segment
		dd	00000000h, 00000000h
		
_tss1:	dd	0000h                  ;back link
		dd	0ff00h, 0030h 			;esp0,  ss0
		dd	0000h, 0000h           ;esp1,  ss1
		dd	0000h, 0000h           ;esp2,  ss2
		dd	0000h                  ;cr3
		dd	0000h                  ;eip
		dd	0200h                  ;eflags
		dd	0000h, 0000h, 0000h, 0000h
                                   ;eax,  ecx,  edx,  ebx
		dd	0ff00h            ;esp
		dd	0000h, 0000h, 0000h    ;ebp, esi, edi
		dd	0017h, 000fh, 0017h, 0017h, 0017h, 0017h
						           ;es,  cs,  ss,  ds,  fs,  gs
		dd	SelectorLdt1		       ;ldt
		dd	8000000h		       ;trace bitmap
;LDT0 for task 0,Every task must have private ldt.
_ldt1:	dd	00000000h, 00000000h   ;dummy
		dd	00000fffh, 00c0fa00h   ;task 1 code segment
		dd	00000fffh, 00c0f200h   ;task 1 data segment
		dd	00000000h, 00000000h