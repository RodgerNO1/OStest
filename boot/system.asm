%include	"pm.inc"	; 常量, 宏, 以及一些说明

[SECTION .text]; 32 位代码段
[BITS	32]
	global	_sysEntry			;system kernel entry
	extern _kernel_main
	
	;导出函数名
	global _sys_halt
	global _sys_write_vga
	global _sys_cls
	global _sys_put_char
	global _sys_get_cursor
	global _sys_inc_tick
	global _sys_get_tick
	extern _do_timer
	
;----------------------------------------------------------------

; GDT 选择子
SelectorNormal		equ		08h
SelectorFlatC		equ	 	10h
SelectorFlatRW		equ		18h
SelectorCode		equ		20h
SelectorData		equ		28h	
SelectorStack		equ		30h
SelectorVideo		equ		38h
SelectorGdt			equ		40h
SelectorTssLdt		equ		48h

stack_ptr			equ		0ff00h

TSS0_SEL	equ	50h
LDT0_SEL	equ	58h
TSS1_SEL	equ	60h
LDT1_SEL	equ	68h

;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^	
;ok,kernel start at here
_sysEntry:	;系统入口
	call show_pm	;显示pm标志
	
	mov	ax,SelectorData
	mov	ds,ax
	mov	es,ax
	mov	fs,ax
	mov	gs,ax
	mov	ss,ax
	mov esp,stack_ptr
;call	set_base
	call setIdt
	call setGdt
    mov	ax,SelectorData
	mov	ds,ax
	mov	fs,ax
	mov	gs,ax
	mov	es,ax
	mov	ss,ax
	mov	esp,stack_ptr
    call Init8259A
	call setClk		;initialize 8253/54

;	call setPdt


GO_MAIN:
	;寄存器清零
	xor	eax,eax
	mov ebx,eax
	mov ecx,eax
	mov edx,eax
	mov esi,eax
	mov edi,eax
	mov ebp,eax
	mov esp,eax
	;设置寄存器
	mov ax,SelectorData
	mov ds,ax
	mov es,ax
	mov ax,SelectorStack
	mov ss,ax
	mov esp,stack_ptr
	mov fs,ax
	mov	ax, SelectorVideo; 视频段选择子
	mov	gs, ax	
	
	;goto main()
	xor	eax,eax	; These are the parameters to main :-)
	push eax
	push eax
	push eax
	push L6	; return address for main, if it decides to.
	push _kernel_main
	ret			;进入main函数
	;never return

L6:
	jmp L6	; main should never return here
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;---------------------------------------------------------
;				本地调用函数
;---------------------------------------------------------
make_gate_descriptor:                       ;构造门的描述符（调用门等）
                                            ;输入：EAX=门代码在段内偏移地址
                                            ;       BX=门代码所在段的选择子 
                                            ;       CX=段类型及属性等（各属
                                            ;          性位都在原始位置）
                                            ;返回：EDX:EAX=完整的描述符
         push ebx
         push ecx
      
         mov edx,eax
         and edx,0xffff0000                 ;得到偏移地址高16位 
         or dx,cx                           ;组装属性部分到EDX
       
         and eax,0x0000ffff                 ;得到偏移地址低16位 
         shl ebx,16                          
         or eax,ebx                         ;组装段选择子部分
      
         pop ecx
         pop ebx
      
         retf   
		
setIdt:
         ;创建中断描述符表IDT
         ;前20个向量是处理器异常使用的
         mov eax,_SpuriousHandler  ;门代码在段内偏移地址
         mov bx,SelectorCode       ;门代码所在段的选择子
         mov cx,0x8e00                      ;32位中断门，0特权级
         call SelectorCode:make_gate_descriptor

         xor esi,esi
		 mov cx,SelectorData
		 mov ds,cx
  .idt0:
         mov [esi*8],eax
         mov [esi*8+4],edx
         inc esi
         cmp esi,19                         ;安装前20个异常中断处理过程
         jle .idt0

         ;其余为保留或硬件使用的中断向量
         mov eax,_UserIntHandler  ;门代码在段内偏移地址
         mov bx,SelectorCode       ;门代码所在段的选择子
         mov cx,0x8e00                      ;32位中断门，0特权级
         call SelectorCode:make_gate_descriptor

  .idt1:
         mov [esi*8],eax
         mov [esi*8+4],edx
         inc esi
         cmp esi,255                        ;安装普通的中断处理过程
         jle .idt1

         ;设置实时时钟中断处理过程
         mov eax,_ClockHandler  ;门代码在段内偏移地址
         mov bx,SelectorCode       ;门代码所在段的选择子
         mov cx,0x8e00                      ;32位中断门，0特权级
         call SelectorCode:make_gate_descriptor

         mov [0x20*8],eax	;0x20实时时钟中断
         mov [0x20*8+4],edx

         ;准备开放中断
         lidt [cs:_idtr]                        ;加载中断描述符表寄存器IDTR
		
		ret
setGdt:
		mov ax,SelectorGdt
		mov fs,ax
		lgdt [fs:0]
		ret
;----------------------------------------------------------	
;end setIdt
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
	call SelectorCode:_do_timer
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
; ---------------------------------------------------------------------------


	
;=============================================================
;							系统API
;=============================================================

;系统函数实现
_sys_halt:
	HLT
	RET
;end _sys_halt
	
_sys_write_vga:;void sys_write_vga(int index,int cchar,int color);
	PUSH EBP
	MOV EBP,ESP
	;func code
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子
	
	MOV edi,[EBP+8];index
	MOV ecx,[EBP+12];cchar
	MOV ebx,[EBP+16];color
	mov ah,bl
	mov al,cl
	mov	[gs:edi], ax
	;end func code
	POP EBP
	RET
;end _sys_write_vga

;-------------------------------------------------------------------------------
_sys_cls:;void sys_cls();
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子
	
	xor edi,edi
	mov cx,2000			;清空2000字符
	mov bx,0x0720
.clsloop:
	mov	word[gs:edi],bx
	add edi,2
	loop .clsloop
	mov bx,0
	call local_set_cursor
	ret
;end _sys_cls

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
_sys_inc_tick:
		mov ax,SelectorData
		mov ds,ax 
		inc dword[ds:0x800]
		ret
_sys_get_tick:
		mov ax,SelectorData
		mov ds,ax 
		mov eax,dword[ds:0x800]
		ret
_sys_put_char:                                ;显示一个字符 vl=字符ascii
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
;======================data========================================
_idtr:  dw	256*8-1		;IDT的界限
        dd	0x00020000	;中断描述符表的线性地址
;----------------------------------------------
;TSS0 for task 0,when it is used,the cpu is running
;user mode,we must have a TSS for save cpu status
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
		dd	LDT0_SEL		       ;ldt
		dd	8000000h		       ;trace bitmap
;LDT0 for task 0,Every task must have private ldt.
_ldt0:	dd	00000000h, 00000000h   ;dummy
		dd	00000fffh, 00c0fa00h   ;task 0 code segment
		dd	00000fffh, 00c0f200h   ;task 0 data segment
		dd	00000000h, 00000000h