; ==========================================
; setup.asm
; 编译方法：nasm setup.asm -o setup.bin
; ==========================================

[SECTION .code32]
[BITS	32]
CODE32:
        jmp LABEL_CODE     ; 

; GDT 选择子
SelectorCode		equ		08h
SelectorData		equ		10h	
SelectorVideo		equ		18h
SelectorLdt0		equ		20h
SelectorTss0		equ		28h
SelectorLdt1		equ		30h
SelectorTss1		equ		38h

LABEL_CODE:
	call show_pm	;显示pm标志
	
	mov	ax,SelectorData
	mov	ds,ax
	mov	es,ax
	mov	fs,ax
	mov	gs,ax
	mov	ss,ax
	mov esp,0fffeh
	call setGdt
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
;-----main---------------------------------------------
;	sti
;	int 20h
	jmp SelectorTss0:0

;-------------------------------------------------------
L6:
	jmp L6	; main should never return here
	
;------------------------------------------------------------------------------
setGdt:
		; 为加载 GDTR 作准备
		xor	eax, eax
		mov	eax, LABEL_GDT		; eax <- gdt 基地址
		mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址

		; 加载 GDTR
		lgdt	[GdtPtr]
		ret
		
setIdt:
		push eax
		;制作时钟中断门
		mov ax,_ClockHandler
		mov word[gate],ax
		mov ax,SelectorCode
		mov word[gate+2],ax
		mov al,0
		mov byte[gate+4],al
		mov al,0eeh				;中断门,0eeh:PL3,08eh:PL0
		mov byte[gate+5],al
		mov ax,0
		mov word[gate+6],ax
		;复制到中断表中
		mov eax,dword[gate]
		mov dword[idt+20h*8],eax
		mov eax,dword[gate+4]
		mov dword[idt+20h*8+4],eax
        lidt [_idtr]                       ;加载中断描述符表寄存器IDTR
		pop eax
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
	mov	al, 20h
	out	20h, al				; 发送 EOI
	mov eax,'A'
	push eax
	call put_char
	pop	eax
	iretd
;	
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
	push gs
	mov	ax, SelectorVideo
	mov	gs, ax
	mov	ah, 0Ch				; 0000: 黑底    1100: 红字
	mov	al, 'I'
	mov	[gs:((80 * 0 + 70) * 2)], ax	; 屏幕第 0 行, 第 70 列。
	pop gs
	iretd

_SpuriousHandler:
	push gs
	mov	ax, SelectorVideo
	mov	gs, ax
	mov	ah, 0Ch				; 0000: 黑底    1100: 红字
	mov	al, '!'
	mov	[gs:((80 * 0 + 75) * 2)], ax	; 屏幕第 0 行, 第 75 列。
	jmp $					;未知系统中断，系统死循环
	pop gs
	iretd
;-------------------------------------------------------------------
task0:
	int 20h
	;mov eax,'A'
	;push eax
	;call put_char
	;pop eax
	jmp task0
	
task1:
	mov eax,'B'
	push eax
	call put_char
	pop eax
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
		 mov ebx,eax						;BX 存放光标位置
		 
		 mov eax, SelectorVideo
		 mov gs, eax			; 视频段选择子
		 
         cmp cl,0x0d                     ;回车符？
         je .put_0a0d                     ;不是。看看是不是换行等字符 
		 cmp cl,0x0a
		 je .put_0a0d
         jmp .put_other

 .put_0a0d:
         mov eax,ebx                      
         mov bl,80                       
         div bl
         mul bl
         mov ebx,eax	;回到行首
		 add ebx,80	;下一行
         jmp .roll_screen

 .put_other:                             ;正常显示字符
         shl ebx,1
         mov [gs:ebx],cl

         ;以下将光标位置推进一个字符
         shr ebx,1
         add ebx,1

 .roll_screen:
         cmp ebx,2000                     ;光标超出屏幕？滚屏
         jl .set_cursor

         mov eax,SelectorVideo
         mov ds,ax
         mov es,ax
         cld
         mov esi,0xa0
         mov edi,0x00
         mov ecx,1920
         rep movsw
         mov ebx,3840                     ;清除屏幕最底一行
         mov ecx,80
 .cls:
         mov word[gs:ebx],0x0720
         add ebx,2
         loop .cls

         mov ebx,1920

	 
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

		 
;======================data======================================== 

LABEL_DATA:
			
current dd 0x0
_idtr:  dw	256*8-1		;IDT的界限
        dd	idt	;中断描述符表的线性地址
		
gate:
	dw	0000h;baseL
	dw	0000h;seletor
	db	00h;paramCnt
	db	00h;type
	dw	0000h;baseH


; GDT
LABEL_GDT:
	dw 	0000h,0000h	;limit,baseL
	db	00h			;baseM
	dw	0000h		;gran,type
	db	00h			;baseH
DESC_CODE:
	dw 	0FFFFh,0000h
	db	00h
	dw	0C09Ah
	db	00h
DESC_DATA:
	dw 	0FFFFh,0000h
	db	00h
	dw	8092h
	db	00h
DESC_VIDEO:
	dw 	0FFFFh,8000h
	db	0Bh
	dw	0092h
	db	00h
DESC_LDT0:
	dw 	001fh,_ldt0
	db	00h
	dw	0082h
	db	00h
DESC_TSS0:
	dw 	0067h,_tss0
	db	00h
	dw	0089h
	db	00h
DESC_LDT1:
	dw 	001fh,_ldt1
	db	00h
	dw	0082h
	db	00h
DESC_TSS1:
	dw 	0067h,_tss1
	db	00h
	dw	0089h
	db	00h
GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1		; GDT界限
			dd	0				; GDT基地址
; GDT 结束
		
_tss0:	dd	0000h                  ;back link
		dd	0eff0h, 0010h 			;esp0,  ss0
		dd	0000h, 0000h           ;esp1,  ss1
		dd	0000h, 0000h           ;esp2,  ss2
		dd	0000h                  ;cr3
		dd	0000h                  ;eip
		dd	0200h                  ;eflags
		dd	0000h, 0000h, 0000h, 0000h
                                   ;eax,  ecx,  edx,  ebx
		dd	0cff0h            ;esp
		dd	0000h, 0000h, 0000h    ;ebp, esi, edi
		dd	0017h, 000fh, 0017h, 0017h, 0017h, 0017h
						           ;es,  cs,  ss,  ds,  fs,  gs
		dd	SelectorLdt0		       ;ldt
		dd	8000000h		       ;trace bitmap
_ldt0:	dd	00000000h, 00000000h   ;dummy
		dw 	0FFFFh,task0
		db	00h
		dw	0C0FAh
		db	00h
		dd	00000fffh, 00c0f200h   ;task 0 data segment
		dd	00000000h, 00000000h	
		
_tss1:	dd	0000h                  ;back link
		dd	0dff0h, 0030h 			;esp0,  ss0
		dd	0000h, 0000h           ;esp1,  ss1
		dd	0000h, 0000h           ;esp2,  ss2
		dd	0000h                  ;cr3
		dd	0000h                  ;eip
		dd	0200h                  ;eflags
		dd	0000h, 0000h, 0000h, 0000h
                                   ;eax,  ecx,  edx,  ebx
		dd	0aff0h            ;esp
		dd	0000h, 0000h, 0000h    ;ebp, esi, edi
		dd	0017h, 000fh, 0017h, 0017h, 0017h, 0017h
						           ;es,  cs,  ss,  ds,  fs,  gs
		dd	SelectorLdt1		       ;ldt
		dd	8000000h		       ;trace bitmap
;LDT0 for task 0,Every task must have private ldt.
_ldt1:	dd	00000000h, 00000000h   ;dummy
		dw 	0FFFFh,task1
		db	00h
		dw	0C0FAh
		db	00h
		dd	00000fffh, 00c0f200h   ;task 1 data segment
		dd	00000000h, 00000000h
		
idt: times 256 dd 0	

Code32_len 	equ $-CODE32