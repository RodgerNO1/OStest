; ==========================================
; boot.asm
; 编译方法：nasm boot.asm -o boot.bin
; ==========================================
; GDT 选择子
SelectorCode		equ		08h
SelectorData		equ		10h	
SelectorVideo		equ		18h

[ORG 0h]
        jmp 7c0h:start     ; 跳转到段07C0

start:
        ; 设置段寄存器
        mov ax, cs
        mov ds, ax
        mov es, ax

	;读取setup.bin文件到0800:0000
reset:                      ; 重置软盘驱动器
        mov ax, 0           ;
        mov dl, 0           ; Drive=0 (=A)
        int 13h             ;
        jc reset            ; ERROR => reset again


load_setup:
        mov ax, 1000h       ; ES:BX = 0800h:0000
        mov es, ax          ;
        mov bx, 0           ;

        mov ah, 2           ; 读取磁盘数据到地址ES:BX
        mov al, 10           ; 读取1个扇区
        mov ch, 0           ; Cylinder=0
        mov cl, 2           ; Sector=2
        mov dh, 0           ; Head=0
        mov dl, 0           ; Drive=0
        int 13h             ; Read!

        jc load_setup       ; ERROR => Try again

 
set_reg:
        ; 设置段寄存器
        mov ax, cs
        mov ds, ax
        mov es, ax

        mov si, msg     ; 打印字符串
print:
        lodsb           ; AL=字符串存放在DS:SI

        cmp al, 0       ; If AL=0 then hang
        je LABEL_BEGIN

        mov ah, 0Eh     ; Print AL
        mov bx, 7
        int 10h

        jmp print       ; 打印下一个字符

LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h
	
	;移动代码段
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
	mov ecx,2000h;9k
	rep movsb
	pop es
	pop ds
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
;======================data======================================== 
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

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1		; GDT界限
			dd	0				; GDT基地址
			
msg db  'Program Loaded Succeed! Hello, myos!',13,10,'$'

times 510-($-$$) db 0
dw 0AA55h