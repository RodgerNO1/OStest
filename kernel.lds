OUTPUT(kernel.out) 				/*输出文件*/
INPUT(sysfunc.o kernel_main.o)	/*输入文件*/

/*ENTRY(_kernel_main)				入口*/
STARTUP(kernel_main.o)			/*第一个输入文件*/
TARGET(elf32-i386)				/*输入文件文件格式*/
OUTPUT_FORMAT(pei-i386)			/*输出文件文件格式*/
/*
 SECTIONS
 {
   . = 0x10000;
   .text : { *(.text) }
   . = 0x8000000;
   .data : { *(.data) }
   .bss : { *(.bss) }
 }
 */