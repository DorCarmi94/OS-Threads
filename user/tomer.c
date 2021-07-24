#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"


#include "kernel/spinlock.h"  // NEW INCLUDE FOR ASS2
#include "Csemaphore.h"   // NEW INCLUDE FOR ASS 2
#include "kernel/proc.h"         // NEW INCLUDE FOR ASS 2, has all the signal definitions and sigaction definition.  Alternatively, copy the relevant things into user.h and include only it, and then no need to include spinlock.h .


void hello()
{
    int count=0;
    for (int i = 0; i < 50; i++)
    {
        printf("%d",count);
    }
    sigret();
    
}

void printSomething(int a)
{
    fprintf(2,"I am a good handler\n");
}

void someCode()
{
    fprintf(2,"%d",&hello);
    int newPid=fork();
    if(newPid==0)
    {
        void (*ptrFun)()=printSomething;
        fprintf(2,"printsomething address: %d\n",(unsigned char*)&ptrFun);
        struct sigaction myaction;
        myaction.sa_handler=&printSomething;
        sigaction(SIGCONT, &myaction,0);
       //Child
       fprintf(2,"I am the child\n");
       for (int i = 0; i <100; i++)
       {
           fprintf(2,"$");
       }
       kill(getpid(),SIGCONT);
       for (int i = 0; i <100; i++)
       {
           fprintf(2,"$");
       }
       sleep(5);
       exit(0);
    }
    else
    {
        //Father
        //fprintf(2,"Luke, I am your father\n");
        // sleep(5);
        // kill(newPid,SIGSTOP);
        
        // sleep(2);
        // kill(newPid,SIGCONT);
        // sleep(2);
        
        wait(&newPid);
        exit(0);
    }
}

void simpleSignalTest()
{
    int newPid=fork();
    if(newPid==0)
    {
        
        struct sigaction myaction;
        myaction.sa_handler=printSomething;
        myaction.sigmask=0;
        int ans=sigaction(20,&myaction,0);
        
        if(ans<0)
        {
             fprintf(2,"Sigaction failed");
        }
        //sleep(20);
        //Child
        //int k=0;
        for (int i = 0; i < __INT16_MAX__; i++)
        {
            fprintf(2, "$");
        }
        printf("child exiting\n");
    }
    else
    {
        sleep(10);
        
        int ans=kill(newPid,20);
        if(ans==-1)
        {
            printf("Kill failed\n");
        }
        //Father
    //     fprintf(2,"Stopping\n");
    //     kill(newPid,SIGSTOP);

    //     sleep(10);
    //     fprintf(2,"Conting\n");
    //    kill(newPid,SIGCONT);
    //     wait(&newPid);
    printf("father exits\n");
    exit(0);
    }
    
}








void tst_SpecialNum_CantBeMasked()
{
    fprintf(2,"----Test special signals can't be masked\n");
    int newPid=fork();
    if(newPid==0)
    {
        //Child
        struct sigaction mysigaction;
        mysigaction.sa_handler=(void*)SIGCONT;
        mysigaction.sigmask=(1<<SIGKILL);
        int ans=sigaction(SIGKILL,&mysigaction,0);
        if(ans<0)
        {
            fprintf(2,"Test change kill action-> should fail: OK\n");
        }
        else
        {
            fprintf(2,"Test change kill action-> should fail: Fail\n");
        }

        ans=sigaction(SIGSTOP,&mysigaction,0);

        if(ans<0)
        {
            fprintf(2,"Test change stop action-> should fail: OK\n");
        }
        else
        {
            fprintf(2,"Test change stop action-> should fail: Fail\n");
        }

        ans=sigaction(SIGCONT,&mysigaction,0);

        if(ans<0)
        {
            fprintf(2,"Test change cont action with kill and stop masked-> should fail: OK\n");
        }
        else
        {
            fprintf(2,"Test change stop with kill and stop masked-> should fail: Fail\n");
        }

        ans=sigaction(20,&mysigaction,0);

        if(ans<0)
        {
            fprintf(2,"Test change cont action with kill and stop masked-> should fail: OK\n");
        }
        else
        {
            fprintf(2,"Test change stop with kill and stop masked-> should fail: Fail\n");
        }
        int i=0;
        while (i<__INT32_MAX__)
        {
            i++;
            //do nothing
        }
        fprintf(2,"Test send SIGKILL: Fail\n");

    }
    else
    {
        //Father
        sleep(10);
        kill(newPid,SIGKILL);
        wait(&newPid);
        fprintf(2,"Test send SIGKILL: OK (if not fail one line before)\n");
    }
    
}

void printTestSucceeded()
{
    fprintf(2,"=)\n");
}


void tst_STOP()
{
    int newpid=fork();
    if(newpid==0)
    {
        //Child
        for (int i = 0; i <2000; i++)
        {
            fprintf(2,"$");
        }
        exit(0);
    }
    else
    {
        //Father
        sleep(3);
        fprintf(2,"\nStop!\n");
        kill(newpid,SIGSTOP);
        sleep(10);
        fprintf(2,"\nContinue!\n");
        kill(newpid,SIGCONT);
        wait(&newpid);
        fprintf(2,"If print stopped and than continued: OK\n");
        exit(0);
    }
    
}

void tst_SIGSTOP()
{
    int newpid=fork();
    if(newpid==0)
    {
        struct sigaction mysig;
        mysig.sa_handler=printTestSucceeded;
        sigaction(20,&mysig,0);
        //Child
        sleep(20);
        exit(0);
    }
    else
    {
        //Father
        sleep(5);
        kill(newpid,20);
        kill(newpid,SIGSTOP);
        sleep(10);
        int anscont=kill(newpid,SIGCONT);
        if(anscont<=0)
        {
            fprintf(2,"Test SIGSTOP: Fail\n");
        }
        int ans=kill(newpid,20);
        if(ans>=0)
        {
            fprintf(2,"Test SIGSTOP: OK\n");
        }
        exit(0);
    }
    
}
void printSigNum(int a)
{
    fprintf(2,"signum: %d",a);
}

void tst_NotSpecialSignal_SpecialHandler()
{
    int newpid=fork();
    if(newpid==0)
    {
        struct sigaction mysig;
        mysig.sa_handler=(void*)SIG_IGN;
        sigaction(20,&mysig,0);
        sleep(4);

        mysig.sa_handler=(void*)SIGSTOP;
        sigaction(21,&mysig,0);

        mysig.sa_handler=(void*)SIGCONT;
        sigaction(23,&mysig,0);
        for (int i = 0; i < __INT16_MAX__; i++)
        {
            fprintf(2,"$");
        }
        
        sleep(4);



        //Child
        sleep(20);
        exit(0);
    }
    else
    {
        //Father
        sleep(2);
        kill(newpid,20);
        
        sleep(8);
        fprintf(2,"\nStop!\n");
        kill(newpid,21);
        sleep(5);
        fprintf(2,"\nCont!\n");
        kill(newpid,23);

        kill(newpid,22);
        wait(&newpid);
        exit(0);
    }
}

void myTomer()
{
    // fprintf(2,"myTomer thread id: %d\n", kthread_id());
    //fprintf(2, "myTomer proc id: %d\n", getpid());
    for(int i = 0; i < 5; i++){
        fprintf(2,"Hello tomer\n");
        fprintf(2,"Hello dor\n");
    }
    // fprintf(2,"before myTomer exit\n");
    kthread_exit(0);
}


void tst_kthreadCreate()
{
    fprintf(2,"tst kthread_create\n");
    void* stack= malloc(MAX_STACK_SIZE);
    kthread_create(myTomer,stack);
    int id = kthread_id();
    fprintf(2, "test thread id: %d\n", id);
    
    
    // kthread_exit(0);
    // fprintf(2,"I should not be printed\n");
}

void tst_kthreadJoin()
{
    fprintf(2,"tst kthread_join\n");
    void* stack= malloc(MAX_STACK_SIZE);
    kthread_create(myTomer,stack);
    //int id = kthread_id();
    // fprintf(2, "test thread id: %d\n", id);
    // fprintf(2, "test proc id: %d\n", getpid());
    int status;
    fprintf(2,"Before Join\n");
    kthread_join(8, &status);
    fprintf(2,"After Join\n");
    kthread_exit(0);
    // fprintf(2,"I should not be printed\n");
}


int globalNumber=0;

void tst_CountingSemaphore()
{
    //struct counting_semaphore my_cSema;
    //csem_alloc(&my_cSema,2);
    //int countBsem= bsem_alloc();

    // printf("Now avilable: %d\n",my_cSema.value);
    // printf("S1: %d\n",my_cSema.S1_descriptor);
    // printf("S2: %d\n",my_cSema.S2_descriptor);
    int child1=fork();
    int child2;
    int child3;
    if(child1==0)
    {
        //fprintf(2,"Child 1: My name is: %d\n",getpid());
        //child1
        
        for (int i = 0; i < 100000; i++)
        {
            //csem_down(&my_cSema);
            //bsem_down(countBsem);
            globalNumber+=1;
            //bsem_up(countBsem);
            fprintf(2,"%d ",globalNumber);
            //sleep(100);
            //bsem_down(countBsem);
            globalNumber-=1;
            //bsem_up(countBsem);
            //csem_up(&my_cSema);
        }
        
        exit(0);
        

    }
    else
    {
        child2=fork();
        if(child2==0)
        {
            //child2
            //fprintf(2,"Child 2: My name is: %d\n",getpid());
            for (int i = 0; i < 1000000; i++)
            {
                //csem_down(&my_cSema);
                //bsem_down(countBsem);
                globalNumber+=1;
                //bsem_up(countBsem);
                fprintf(2,"%d ",globalNumber);
                //sleep(100);
                //bsem_down(countBsem);
                globalNumber-=1;
                //bsem_up(countBsem);
                //csem_up(&my_cSema);
            }
            exit(0);
        }
        else
        {
            
            child3=fork();
            if(child3==0)
            {
                //child 3
                for (int i = 0; i < 1000000; i++)
                {
                    //csem_down(&my_cSema);
                    //bsem_down(countBsem);
                    globalNumber+=1;
                    //bsem_up(countBsem);
                    fprintf(2,"%d ",globalNumber);
                    //sleep(100);
                    //bsem_down(countBsem);
                    globalNumber-=1;
                    //bsem_up(countBsem);
                    //csem_up(&my_cSema);
                }
                exit(0);

            }
            else
            {
                //father
                //fprintf(2,"Luke i am your father: My name is: %d\n",getpid());
                // for (int i = 0; i < 1000; i++)
                // {
                //     printf("D");
                // }
                // fprintf(2,"D finish\n");
                for (int i = 0; i < 1000000; i++)
                {
                    //csem_down(&my_cSema);
                    //bsem_down(countBsem);
                    globalNumber+=1;
                    //bsem_up(countBsem);
                    fprintf(2,"%d ",globalNumber);
                    //sleep(100);
                    //bsem_down(countBsem);
                    globalNumber-=1;
                    //bsem_up(countBsem);
                    //csem_up(&my_cSema);
                }
                  
                wait(&child2);
                wait(&child1);
                wait(&child3);
                exit(0);
            }
        }
        
    }
}


void tst_binarySemaphore()
{
    int newSemap=bsem_alloc();
    int newPid=fork();
    
    if(newPid==0)
    {
        //child
        bsem_down(newSemap);
        printf("Priniting child\n");
        bsem_up(newSemap);
        exit(0);


    }
    else
    {
        //Father
        bsem_down(newSemap);
        printf("Priniting father\n");
        bsem_up(newSemap);
        wait(&newPid);
        
    }
    bsem_free(newSemap);
    printf("Finish\n");
    exit(0);

    
}

#define print(s) printf("%s\n", s);
#define STACK_SIZE 4000
int shared = 0;
void func()
{
    //fprintf(2,"thread tid: %d, going to sleep\n",kthread_id());
    sleep(5);
    shared++;
    fprintf(2,"thread tid: %d, exiting\n",kthread_id());
    kthread_exit(7);
}

void tst_ido1()
{
    int MYNUMBER=5;
    int tids[MYNUMBER];
    void *stacks[MYNUMBER];
    for (int i = 0; i < MYNUMBER; i++)
    {
        void *stack = malloc(STACK_SIZE);
        tids[i] = kthread_create(func, stack);
        stacks[i] = stack;
    }
    for (int i = 0; i < MYNUMBER; i++)
    {
        int status;
        kthread_join(tids[i], &status);
        free(stacks[i]);    
        printf("the status is: %d\n", status);
    }
    printf("%d\n", shared);
    exit(0);
}


void printSomethingForThread()
{
    sleep(10);
    for (int i = 0; i < 1000; i++)
    {
        fprintf(2,"$");
    }

    fprintf(2,"\nchild thread exiting\n");
    kthread_exit(0);

    
}


void tst_basicThreadFunctions()
{
    void* stack= malloc(MAX_STACK_SIZE);
    int tid1=kthread_create(printSomethingForThread,stack);
    fprintf(2,"new thread id: %d\nJoining now\n",tid1);
    int status;
    fprintf(2,"trying to join thread %d\n",tid1);
    int ret=kthread_join(tid1,&status);
    if(ret==-1)
    {
        fprintf(2,"kthread join failed\n");
    }
    fprintf(2,"father thread exiting\n");
    kthread_exit(0);


}



int main(int argc, char** argv)
{
    //tst_SpecialNum_CantBeMasked();
    //tst_STOP();
    //tst_NotSpecialSignal_SpecialHandler();
    //tst_kthreadCreate();
    //simpleSignalTest();
    //tst_kthreadJoin();
    //tst_CountingSemaphore();
    //tst_ido1();
    //tst_basicThreadFunctions();
    sleep(10);
    exit(0);
}

