/*
*系统C函数实现
*/
extern void sys_halt(void);
extern void sys_write_vga(int index,int cchar,int color);


//==========================================================
int sub(int a,int b){
	return a-b;
}
//清屏函数
void cls(){
	int i=0,j=0;	
	for(i=0;i<25;i++){
		for(j=0;j<80;j++)
		sys_write_vga((80*i+j)*2,'0',0x00);
	}	
}