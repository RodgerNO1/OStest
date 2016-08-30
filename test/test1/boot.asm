; ==========================================
; boot.asm
; ���뷽����nasm boot.asm -o boot.bin
; ==========================================

[ORG 0]
        jmp 07C0h:start     ; ��ת����07C0

start:
        ; ���öμĴ���
        mov ax, cs
        mov ds, ax
        mov es, ax

	;��ȡsetup.bin�ļ���0800:0000
reset:                      ; ��������������
        mov ax, 0           ;
        mov dl, 0           ; Drive=0 (=A)
        int 13h             ;
        jc reset            ; ERROR => reset again


load_setup:
        mov ax, 1000h       ; ES:BX = 0800h:0000
        mov es, ax          ;
        mov bx, 0           ;

        mov ah, 2           ; ��ȡ�������ݵ���ַES:BX
        mov al, 10           ; ��ȡ1������
        mov ch, 0           ; Cylinder=0
        mov cl, 2           ; Sector=2
        mov dh, 0           ; Head=0
        mov dl, 0           ; Drive=0
        int 13h             ; Read!

        jc load_setup       ; ERROR => Try again

 
set_reg:
        ; ���öμĴ���
        mov ax, cs
        mov ds, ax
        mov es, ax

        mov si, msg     ; ��ӡ�ַ���
print:
        lodsb           ; AL=�ַ��������DS:SI

        cmp al, 0       ; If AL=0 then hang
        je SETUP

        mov ah, 0Eh     ; Print AL
        mov bx, 7
        int 10h

        jmp print       ; ��ӡ��һ���ַ�
		
SETUP:
        jmp 1000h:0000      ;ִ��setup.bin	
msg     db  'Program Loaded Succeed! Hello, myos!',13,10,'$'

times 510-($-$$) db 0
dw 0AA55h