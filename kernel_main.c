extern void sys_halt(void);
extern void sys_write_mem8(int addr,int data);
extern int sub(int a,int b);
void kernel_main(void){	
	int i=0;
	i=sub(9,3);
//	for(i=0xa0000;i<0xaffff;i++){
		sys_write_mem8(0xa0000,10);
//	}
	//for(;;) sys_halt();
}
