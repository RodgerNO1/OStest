; ==========================================
; boot.asm
; 编译方法：nasm boot.asm -o boot.bin
; ==========================================

[ORG 0]
        jmp 07C0h:start     ; 跳转到段07C0

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
        je SETUP

        mov ah, 0Eh     ; Print AL
        mov bx, 7
        int 10h

        jmp print       ; 打印下一个字符
		
SETUP:
        jmp 1000h:0000      ;执行setup.bin	
msg     db  'Program Loaded Succeed! Hello, myos!',13,10,'$'

times 510-($-$$) db 0
dw 0AA55h