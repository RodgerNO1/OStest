/*
*系统C函数实现
*/
extern void sys_halt(void);
extern void sys_write_vga(int index,int cchar,int color);
extern void sys_cls();
extern void sys_inc_tick();
extern int  sys_get_tick();
extern void sys_put_char(int cchar);
extern int sys_get_cursor();
#define INT_HANDLER_RETURN asm("leave;retf;"::)
//==========================================================
int sub(int a,int b){
	return a-b;
}
//清屏函数
void cls(){
	/*
	int i=0,j=0;	
	for(i=0;i<25;i++){
		for(j=0;j<80;j++)
		sys_write_vga((80*i+j)*2,'0',i%16);
	}	
	*/
	sys_cls();
}
void printInt(int a){
	int yi=0,result=0;
    char c[11];
    if(a==0)c[1]=(yi+48);
	
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
void do_timer(){
	sys_inc_tick();//2500tick==1s
	if(getTimeTick()%(2500*5)==0)
	printInt(getTimeTick());
	
	INT_HANDLER_RETURN;
}
int getTimeTick(){
	return sys_get_tick();
}