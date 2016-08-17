extern void sys_halt(void);
extern void sys_write_mem8(int ds,int offset,int data);
extern int sub(int a,int b);
void kernel_main(void){	
	int i=0;
	i=sub(9,3);
	int ds=0xA000;
	for(i=0x0000;i<0xffff;i=i+2){
		sys_write_mem8(ds,i,'A');
		sys_write_mem8(ds,i+1,0x0C);
	}
	//for(;;) sys_halt();
}

