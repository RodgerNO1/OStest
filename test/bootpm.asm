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


read:
        mov ax, 0800h       ; ES:BX = 0800h:0000
        mov es, ax          ;
        mov bx, 0           ;

        mov ah, 2           ; ��ȡ�������ݵ���ַES:BX
        mov al, 1           ; ��ȡ1������
        mov ch, 0           ; Cylinder=0
        mov cl, 2           ; Sector=2
        mov dh, 0           ; Head=0
        mov dl, 0           ; Drive=0
        int 13h             ; Read!

        jc read             ; ERROR => Try again
 
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
        jmp LABEL_BEGIN      ;ִ��setup.bin	
msg     db  'Program Loaded Succeed! Hello, myos!',13,10,'$'

;----------------------------------------------------------------------------
; ����������ֵ�����У�
;       DA_  : Descriptor Attribute
;       D    : ���ݶ�
;       C    : �����
;       S    : ϵͳ��
;       R    : ֻ��
;       RW   : ��д
;       A    : �ѷ���
;       ���� : �ɰ���������˼���
;----------------------------------------------------------------------------

; ����������
DA_32		EQU	4000h	; 32 λ��

DA_DPL0		EQU	  00h	; DPL = 0
DA_DPL1		EQU	  20h	; DPL = 1
DA_DPL2		EQU	  40h	; DPL = 2
DA_DPL3		EQU	  60h	; DPL = 3

; �洢������������
DA_DR		EQU	90h	; ���ڵ�ֻ�����ݶ�����ֵ
DA_DRW		EQU	92h	; ���ڵĿɶ�д���ݶ�����ֵ
DA_DRWA		EQU	93h	; ���ڵ��ѷ��ʿɶ�д���ݶ�����ֵ
DA_C		EQU	98h	; ���ڵ�ִֻ�д��������ֵ
DA_CR		EQU	9Ah	; ���ڵĿ�ִ�пɶ����������ֵ
DA_CCO		EQU	9Ch	; ���ڵ�ִֻ��һ�´��������ֵ
DA_CCOR		EQU	9Eh	; ���ڵĿ�ִ�пɶ�һ�´��������ֵ

; ϵͳ������������
DA_LDT		EQU	  82h	; �ֲ��������������ֵ
DA_TaskGate	EQU	  85h	; ����������ֵ
DA_386TSS	EQU	  89h	; ���� 386 ����״̬������ֵ
DA_386CGate	EQU	  8Ch	; 386 ����������ֵ
DA_386IGate	EQU	  8Eh	; 386 �ж�������ֵ
DA_386TGate	EQU	  8Fh	; 386 ����������ֵ

;----------------------------------------------------------------------------
; ѡ��������ֵ˵��
; ����:
;       SA_  : Selector Attribute

SA_RPL0		EQU	0	; ��
SA_RPL1		EQU	1	; �� RPL
SA_RPL2		EQU	2	; ��
SA_RPL3		EQU	3	; ��

SA_TIG		EQU	0	; ��TI
SA_TIL		EQU	4	; ��
;----------------------------------------------------------------------------


; �� ------------------------------------------------------------------------
;
; ������
; usage: Descriptor Base, Limit, Attr
;        Base:  dd
;        Limit: dd (low 20 bits available)
;        Attr:  dw (lower 4 bits of higher byte are always 0)
%macro Descriptor 3
	dw	%2 & 0FFFFh				; �ν���1
	dw	%1 & 0FFFFh				; �λ�ַ1
	db	(%1 >> 16) & 0FFh			; �λ�ַ2
	dw	((%2 >> 8) & 0F00h) | (%3 & 0F0FFh)	; ����1 + �ν���2 + ����2
	db	(%1 >> 24) & 0FFh			; �λ�ַ3
%endmacro ; �� 8 �ֽ�
;
; ��
; usage: Gate Selector, Offset, DCount, Attr
;        Selector:  dw
;        Offset:    dd
;        DCount:    db
;        Attr:      db
%macro Gate 4
	dw	(%2 & 0FFFFh)				; ƫ��1
	dw	%1					; ѡ����
	dw	(%3 & 1Fh) | ((%4 << 8) & 0FF00h)	; ����
	dw	((%2 >> 16) & 0FFFFh)			; ƫ��2
%endmacro ; �� 8 �ֽ�
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


[SECTION .gdt]
; GDT
;                              �λ�ַ,       �ν���     , ����
LABEL_GDT:	   Descriptor       0,                0, 0           ; ��������
LABEL_DESC_CODE32: Descriptor       0, SegCode32Len - 1, DA_C + DA_32; ��һ�´����
LABEL_DESC_VIDEO:  Descriptor 0B8000h,           0ffffh, DA_DRW	     ; �Դ��׵�ַ
; GDT ����

GdtLen		equ	$ - LABEL_GDT	; GDT����
GdtPtr		dw	GdtLen - 1	; GDT����
		dd	0		; GDT����ַ

; GDT ѡ����
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; END of [SECTION .gdt]

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	; ��ʼ�� 32 λ�����������
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

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
	or	eax, 1
	mov	cr0, eax

	; �������뱣��ģʽ
	jmp	dword SelectorCode32:0	; ִ����һ���� SelectorCode32 װ�� cs,
					; ����ת�� Code32Selector:0  ��
; END of [SECTION .s16]


[SECTION .s32]; 32 λ�����. ��ʵģʽ����.
[BITS	32]

LABEL_SEG_CODE32:
	mov	ax, SelectorVideo
	mov	gs, ax			; ��Ƶ��ѡ����(Ŀ��)

	mov	edi, (80 * 11 + 79) * 2	; ��Ļ�� 11 ��, �� 79 �С�
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	mov	al, 'P'
	mov	[gs:edi], ax

	; ����ֹͣ
	jmp	1000h:0000

SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]


;times 510-($-$$) db 0
;dw 0AA55h