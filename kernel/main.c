#include <def.h>
#include <stdio.h>
#include <sys.h>
extern void int_0x22();
extern void task0();
extern void task1();
void kernel_main(void){	
	cls();
	char str[]="-----------welcome------------\n";
	printString(str);
	set_int_handler(0x22,int_0x22);
	//test();
	asm("int $0x70;"::);
	creatTask(0,task0);
	creatTask(1,task1);
	//sched_init();                   /* initialize task 0 and global task struct arrays */
	asm("sti;"::);
	int i=0;
//	while(1){
//		printChar('0');
//	}

	asm("ljmp %0,%1"::"i"(0x58),"i"(0x0));
	for(;;) sys_halt();
}


/*
void sched_init()
{
    int i;

    for (i=0; i<NR_TASK; i++)       // Initialize global task struct arrays 
    {
        task[i].pid = -1;           // pid=-1 repersent that the task struct is available. 
        task[i].priority = -1;
        task[i].counter = -1;
        task[i].ldt_sel = -1;
        task[i].tss_sel = -1;
    }

    process_id = 1;
    p_current = NULL;
    p_current = NULL;
    p_previous = NULL;
    p_ready = NULL;
    p_head = NULL;

	set_tss_desc(0, _tss0);
	set_ldt_desc(0, _ldt0);

	cl_nt();                       // prapre for move to user mode. 
    lldt(0);                       // load task 0 ldtr 
	ltr(0);                        // load task 0 tr 
}
*/

