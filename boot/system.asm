[SECTION .text]; 32 位代码段
[BITS	32]
	global	_sysEntry			;system kernel entry
	extern _kernel_main

;----------------------------------------
;system constants
;SETUPSEG        equ	1000h
;SETUPOFF        equ	0000h
;SYSSEG          equ	1700h
;SYSOFF          equ	0000h
SelectorKernel		equ	08h
SelectorData		equ	10h
SelectorVideo		equ	18h
	
;ok,kernel start at here
_sysEntry:	;系统入口
	;设置寄存器
	xor	eax,eax
	mov ebx,eax
	mov ecx,eax
	mov edx,eax
	mov esi,eax
	mov edi,eax
	mov ebp,eax
	mov esp,eax
	mov esp,0ff00h
	
	mov ax,SelectorData
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov fs,ax
	mov	ax, SelectorVideo; 视频段选择子
	mov	gs, ax
	
	call show_pm	;显示pm标志


	xor	eax,eax	; These are the parameters to main :-)
	push eax
	push eax
	push eax
	push L6	; return address for main, if it decides to.
	push _kernel_main
	ret
	;never return

L6:
	jmp L6	; main should never return here

;=============================================================
;系统函数
;=============================================================

show_pm:
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子(目的)
	
	mov	edi, (80 * 11 + 79) * 2	; 屏幕第 11 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'P'
	mov	[gs:edi], ax
	ret
;end show_pm

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
;导出函数名
global _sys_halt
global _sys_write_vga
global _sys_cls
global _sys_put_char
global _sys_get_cursor

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
	



