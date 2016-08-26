/*
*	系统IO函数
*/

#ifndef _STDIO_H
#define _STDIO_H

#include<def.h>
void printHexD(DWORD value){

    int yi=0,result=0;
    char c[8]={'0','0','0','0','0','0','0','0'};
    if(value!=0){
        while(value!=0){
            yi=value%16;
            if(yi>9){
                yi=yi-9;
                c[result]=(char)(yi+64);
            }else{
                c[result]=(char)(yi+48);
            }
            value=value/16;
            result++;
        }
    }
    int i=0;
    for(i=7;i>=0;i--)
    sys_put_char(c[i]);
}
void printHexW(WORD value){

    int yi=0,result=0;
    char c[4]={'0','0','0','0'};
    if(value!=0){
        while(value!=0){
            yi=value%16;
            if(yi>9){
                yi=yi-9;
                c[result]=(char)(yi+64);
            }else{
                c[result]=(char)(yi+48);
            }
            value=value/16;
            result++;
        }
    }
    int i=0;
    for(i=3;i>=0;i--)
    sys_put_char(c[i]);
}
void printHexB(BYTE value){

    int yi=0,result=0;
    char c[2]={'0','0'};
    if(value!=0){
        while(value!=0){
            yi=value%16;
            if(yi>9){
                yi=yi-9;
                c[result]=(char)(yi+64);
            }else{
                c[result]=(char)(yi+48);
            }
            value=value/16;
            result++;
        }
    }
    int i=0;
    for(i=1;i>=0;i--)
    sys_put_char(c[i]);
}
void printString(char *str)
{
	while(*str!='\0'){
		printChar(*str);
		str++;
	}
}
void printInt(int a){
	int yi=0,result=0;
    char c[11];
    if(a==0){
		result=1;
		c[1]=(yi+48);
	}
    while(a!=0){
        yi=a%10;
        a=a/10;
        result++;
        c[result]=(char)(yi+48);
    }
    c[0]=(char)result;
    int i=0;
    for(i=c[0];i>0;i--)
    sys_put_char(c[i]);
}
void printChar(char value){
	sys_put_char(value);
}
#endif