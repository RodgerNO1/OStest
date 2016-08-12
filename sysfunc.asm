[SECTION .text]; 32 位代码段
[BITS	32]

;导出函数名
global _sys_halt
global _sys_write_mem8

;函数实现

_sys_halt:
	HLT
	RET
;end _sys_halt
	
_sys_write_mem8:;void sys_write_mem8(int addr,int data);
	PUSH EBP
	MOV EBP,ESP
	;func code
	MOV ECX,[EBP+12]
	MOV AL,[EBP+8]
	MOV [ECX],AL
	;end func code
	POP EBP
	RET
;end _sys_write_mem8