//****coff ��ʽ��Ϊpe-i386��ʽ****
nasm -f coff a.asm -o a.o

//gcc -S:����.s �ļ� -c������.o�ļ�
gcc -S a.c -o a.s
//ar ���� ��̬���ӿ�
ar -r -s libfunc.a func.o
//
as a.s -o a.o1
//objcopy Ŀ���ļ��ĸ�ʽת��
objcopy -I pe-i386 -O elf32-i386 a.o1 a.o


//ld -s:"strip all" 
