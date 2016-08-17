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


show_pm:
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子(目的)
	
	mov	edi, (80 * 11 + 79) * 2	; 屏幕第 11 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'P'
	mov	[gs:edi], ax
	ret



;导出函数名
global _sys_halt
global _sys_write_vga

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
	mov	gs, ax			; 视频段选择子(目的)
	
	MOV edi,[EBP+8];index
	MOV ecx,[EBP+12];cchar
	MOV ebx,[EBP+16];color
	mov ah,bl
	mov al,cl
	mov	[gs:edi], ax
	;end func code
	POP EBP
	RET
;end _sys_write_mem8