/*
* 笔记
*/

//****coff 格式即为pe-i386格式****
nasm -f coff a.asm -o a.o

//gcc -S:生成.s 文件 -c：生成.o文件
gcc -S a.c -o a.s
//ar 生成 静态链接库
ar -r -s libfunc.a func.o
//
as a.s -o a.o1
//objcopy 目标文件的格式转换
objcopy -I pe-i386 -O elf32-i386 a.o1 a.o

//ld -s:"strip all" 

//VGA 显存
EGA显示标准(32k):(0xa0000-0xa8000)
MDA显示标准(8k) :(0xb0000-0xb2000)文本模式:(80x25)
CGA显示标准(16k):(0xb8000-0xbc000)文本模式:(80x25),可显示4帧信息,
每帧4k,偶字节为字符代码，奇字节显示属性（0x0c:0背景色C前景色））

//长调用lcall 对应lret,C函数默认的方法方式不能作为长调用函数，需在C函数中使用（asm("leave;retf;"::);）自定义void类型返回
