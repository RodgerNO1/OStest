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
