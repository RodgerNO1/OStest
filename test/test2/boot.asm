; ==========================================
; boot.asm
; ���뷽����nasm boot.asm -o boot.bin
; ==========================================
; GDT ѡ����
SelectorCode		equ		08h
SelectorData		equ		10h	
SelectorVideo		equ		18h

[ORG 0h]
        jmp 7c0h:start     ; ��ת����07C0

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
        je LABEL_BEGIN

        mov ah, 0Eh     ; Print AL
        mov bx, 7
        int 10h

        jmp print       ; ��ӡ��һ���ַ�

LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h
	
	;�ƶ������
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
	; Ϊ���� GDTR ��׼��
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt ����ַ
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt ����ַ

	; ���� GDTR
	lgdt	[GdtPtr]
	; ���ж�
	cli
	; �򿪵�ַ��A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; ׼���л�������ģʽ
	mov	eax, cr0
	or	eax, 1h
	mov	cr0, eax

	; �������뱣��ģʽ
	jmp	dword SelectorCode:0	; ִ����һ���� SelectorCode װ�� cs,; ����ת�� SelectorKernel:0  ��
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

GdtLen		equ	$ - LABEL_GDT	; GDT����
GdtPtr		dw	GdtLen - 1		; GDT����
			dd	0				; GDT����ַ
			
msg db  'Program Loaded Succeed! Hello, myos!',13,10,'$'

times 510-($-$$) db 0
dw 0AA55h