/*
* �ʼ�
*/

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

//VGA �Դ�
EGA��ʾ��׼(32k):(0xa0000-0xa8000)
MDA��ʾ��׼(8k) :(0xb0000-0xb2000)�ı�ģʽ:(80x25)
CGA��ʾ��׼(16k):(0xb8000-0xbc000)�ı�ģʽ:(80x25),����ʾ4֡��Ϣ,
ÿ֡4k,ż�ֽ�Ϊ�ַ����룬���ֽ���ʾ���ԣ�0x0c:0����ɫCǰ��ɫ����

//������lcall ��Ӧlret,C����Ĭ�ϵķ�����ʽ������Ϊ�����ú���������C������ʹ�ã�asm("leave;retf;"::);���Զ���void���ͷ���
