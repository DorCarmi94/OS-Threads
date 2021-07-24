#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[],uservec[], userret[], myfunc[], endMyFunc[];


struct semaphore semaphores[MAX_BSEM];
int isSemaphoresAllocated=0;
struct spinlock semaphores_lock;
int currentSemaphore=0;


// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}


int isStillRunning(struct thread *t)
{
  if(!t->killed && (t->state==USED || t->state==SLEEPING || t->state==RUNNABLE))
  {
    return 1;
  }
  return 0;
}

int checkIfLastThread()
{
  int isLast=1;
  struct thread *tToCheck;
  struct proc *p = myproc();
  struct thread *myT=mythread();
  //printf("---------------\n");
  for(tToCheck=p->threads; tToCheck<&p->threads[NTHREADS];tToCheck++)
  {
    //printf("pid: %d, tid: %d, idx: %d, status: %d\n",p->pid,tToCheck->tid, tToCheck->idx,tToCheck->state);
    if(tToCheck->tid!=myT->tid && isStillRunning(tToCheck))
    {
        isLast=0;
    }
  }
  //printf("---------------\n");
  return isLast;
}



// initialize the proc table at boot time.
void
procinit(void)
{
  struct proc *p;
  struct thread *t;
  
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
      for(t=p->threads;t<&p->threads[NTHREADS];t++)
      {
        initlock(&t->tlock,"tlock");
      }
      initlock(&p->tid_lock, "proc->tid_lock");
      initlock(&p->join_lock,"proc->join_lock");
      p->threads[0].kstack= KSTACK((int) (p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

struct thread*
mythread(void) {
  push_off();
  struct cpu *c = mycpu();
  struct thread *t = c->thread;
  pop_off();
  return t;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid() {
  int pid;
  
  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);
  return pid;
}

int
alloctid(struct proc *p) {
  int tid;
  acquire(&p->tid_lock);
  tid = p->nexttid;
  p->nexttid+= 1;
  release(&p->tid_lock);
  return tid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == p_UNUSED) {
      goto found;
    }     
    else {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = p_USED;
  p->nexttid=1;
  

  // Allocate a trapframe page.
//  printf("Allocate a trapframe page.\n");
  if((p->headThreadTrapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  //printf("trapframe address: %p\n",p->headThreadTrapframe);

  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

//  printf("Set all threads.\n");
  struct thread *t;
  int currThreadIdx=0;

  //printf("---- process %d ------ \n",p->pid);
  //printf("process trapframe: %p\n",p->headThreadTrapframe);
  
  for ( t = p->threads; t < &p->threads[NTHREADS]; t++)
  {
    acquire(&t->tlock);
    t->tid=alloctid(p);
    t->HasParent=0;
    t->parentThread=0;
    t->idx=currThreadIdx;
    currThreadIdx+=1;
    t->chan=0;
    t->killed=0;
    t->state=UNUSED;
    t->trapeframe=(struct trapframe*)((uint64)(p->headThreadTrapframe)+(uint64)((t->idx)*sizeof(struct trapframe)));
    //printf("idx*size of struct frame: %d\n",(uint64)((t->idx)*sizeof(struct trapframe)));
    //printf("tid: %d, idx: %d, trapframe: %p\n",t->tid,t->idx,t->trapeframe);
    //printf("tid:%d, idx: %d, trapframe: %p\n",t->tid,t->idx,t->trapeframe);
    memset(&t->context, 0, sizeof(t->context));
    t->context.sp = t->kstack + PGSIZE; //to change for multi process
    t->context.ra = (uint64)forkret;
    release(&t->tlock);
  }
  //printf("---- process %d ------ \n",p->pid);

 

  //Set all threads

  //acquire(&p->threads[0].tlock);
  //struct thread* firstThread=&p->threads[0];

  // Set up new context to start executing at forkret,
  // which returns to user space.
  // firstThread->context.ra = (uint64)forkret;
  // firstThread->context.sp = firstThread->kstack + PGSIZE;


  //release(&p->threads[0].tlock);

  for (int i = 0; i < 32; i++)
  {
    p->IsSigactionPointer[i]=0; //choose from sigactions array
    p->Sigactions[i].sa_handler=SIG_DFL;
    p->Sigactions[i].sigmask=0;
  }
  p-> SignalMask = 0;
  p-> PendingSignals = 0; 
  p->stopped=0;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  struct thread *t;
  
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
  
  
  //Free threads
  for (t=p->threads; t < &p->threads[NTHREADS]; t++)
  {
    if(t->state!=UNUSED)
    {
      acquire(&t->tlock);
      t->trapeframe = 0;
      t->chan = 0;
      // if(t->idx!=0)
      // {
      //   //printf("free kstack of pid: %d, tid: %d, idx: %d\n",p->pid,t->tid,t->idx);
      //   kfree((void *)t->kstack) ;
      // }
      //printf("After thread kstack kfree\n");
      //t->kstack=0;
      t->killed=0;
      t->tid=0;
      memset(&t->context,0,sizeof(t->context));
      t->state=UNUSED;
      t->xstate = 0;
      release(&t->tlock);
    }
  }
  //printf("Before trapframe kfree\n");
  // if(p->headThreadTrapframe)
  //     kfree((void*)p->headThreadTrapframe);
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->headThreadTrapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  //printf("user init\n");
  struct proc *p;

  p = allocproc();
  initproc = p;
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  //TODO:
  p->threads[0].trapeframe->epc = 0;      // user program counter
  p->threads[0].trapeframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  safestrcpy(p->threads[0].name, "initcode", sizeof(p->threads[0].name));
  p->cwd = namei("/");

  p->threads[0].state=RUNNABLE;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  acquire(&p->lock);

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      release(&p->lock);
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;

  release(&p->lock);
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  //printf("Calling fork\n");
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();
  struct thread *t=mythread();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }
  //printf("New procees %d\n",np->pid);
  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  
  // copy saved user registers.
  acquire(&t->tlock);
  *(np->threads[0].trapeframe) = *(t->trapeframe);
  release(&t->tlock);

  //copy parent's signals to child
  np->SignalMask = p->SignalMask;
  for (int i = 0; i < 32; i++)
  {
    np->Sigactions[i]=p->Sigactions[i];
    np->SignalHandlers[i]=p->SignalHandlers[i];
    np->IsSigactionPointer[i]=p->IsSigactionPointer[i];
  }

  // Cause fork to return 0 in the child.
  np->threads[0].trapeframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  acquire(&np->threads[0].tlock);
  np->threads[0].state = RUNNABLE;
  release(&np->threads[0].tlock);
  release(&np->lock);
  //printf("Finish fork\n");
  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

int
kthread_create(void (*start_func)(),void *stack)
{
  
  struct proc *p=myproc();
  struct thread *t;
  struct thread *myT=mythread();
  int countThreadIdx=0;
  int retTid;

  //printf("start_func: %p\n",start_func);
  acquire(&p->lock);

  for(t = p->threads; t < &p->threads[NTHREADS]; t++) {
    //printf("pid %d, tid %d, idx: %d, state: %d\n",p->pid,t->tid,t->idx, t->state);
    if(t->tid!=mythread()->tid)
    {
      //printf("before fist tlock acquire\n");
      acquire(&t->tlock);
      //printf("after first tlock acquire\n");
      if(t->state == UNUSED) {
        goto foundForThread;
      }else if(t->state==ZOMBIE) 
      {
        freethread(t);
        goto foundForThread;
      }
      else {
        release(&t->tlock);
        countThreadIdx+=1;
      }
    }
  }
  release(&p->lock);
  return -1;

foundForThread:

    release(&p->lock);
    retTid=alloctid(p);
    t->tid=retTid;
    //printf("allocating new thread: pid: %d, tid: %d, idx: %d\n",p->pid,t->tid, t->idx);
    t->chan=0;
    t->killed=0;
    t->HasParent=0;
    t->parentThread=0;
    t->state=RUNNABLE;
    memset(&t->context, 0, sizeof(t->context));
    t->kstack=(uint64)kalloc();
    //printf("pid: %d, tid: %d, idx: %d, kstack: %p\n",p->pid,t->tid,t->idx,t->kstack);
    t->context.sp = t->kstack + PGSIZE-16; //to change for multi process
    //like sigret
    t->context.ra = (uint64)forkret;

    acquire(&myT->tlock);
    *(t->trapeframe)=*(myT->trapeframe);
    release(&myT->tlock);
    //printf("new thread trapframe: %p\n", t->trapeframe);
    //printf("new thread kstack: %p\n", t->kstack);
    //printf("size of trapframe: %d\n",sizeof(struct trapframe));
    t->trapeframe->epc=(uint64)start_func;
    t->trapeframe->sp=(uint64) (stack+MAX_STACK_SIZE-16);
    
    
    
    release(&t->tlock);
    //printf("finish allocating new thread\n");
    //printf("kthread create\n");
    return retTid;
}



int waitForThreadToEnd(struct thread *t)
{
  struct thread *myT=mythread();
  struct proc *p=myproc();

  for (;;)
  {
    if(t->state==ZOMBIE)
    {
      
      
      release(&p->join_lock);
      //printf("wait for thread to end\n");
      if(checkIfLastThread(t))
      {
        release(&p->lock);
        threadExitLast(t->xstate);
      }
      else
      {
        threadExitNotLast(t->xstate);
      }
      
    }
    if(t->state==UNUSED)
    {
      release(&p->lock);
      release(&p->join_lock);
      return 1;
      
    }
    if(myT->killed)
    {
      release(&p->lock);
      release(&p->join_lock);
      return -1;
    }

    release(&p->lock);
    sleep(t,&p->join_lock);
    acquire(&p->lock);
  }
}


int
kthread_join(int thread_id, int* status){
  //printf("join for tid: %d\n",thread_id);
  struct proc *p=myproc();
  struct thread *t;

  acquire(&p->join_lock);
  acquire(&p->lock);
  
  for (t=p->threads; t < & p->threads[NTHREADS]; t++)
  {
    if(t->tid == thread_id)
    {
      
      int returnVal=waitForThreadToEnd(t);
      if(returnVal<0)
      {
        return returnVal;
      }
      if(status!=(int *)-1)
      {
        copyout(p->pagetable, (uint64) status, (char *)&t->xstate,
                                    sizeof(int));
      }
      return t->xstate;
    }
  }

  release(&p->lock);
  release(&p->join_lock);
  return -1;
}





// int
// kthread_join2(int thread_id, int* status){
//   int tid;
//   struct proc *p = myproc();
//   //struct thread *t = mythread();
//   struct thread *nt;

//   acquire(&wait_lock);

//   for(;;){
//     for (nt = p->threads; nt < &p->threads[NTHREADS]; nt++){
//       if(nt->tid == thread_id){
//         // make sure the thread isn't still in exit() or swtch().
//         acquire(&nt->tlock);

//         if(nt->state == ZOMBIE){
//           tid = nt->tid;

//           if(status != 0 && copyout(p->pagetable, (uint64)status, (char *)&nt->xstate,
//                                   sizeof(nt->xstate)) < 0) {
//             release(&nt->tlock);
//             release(&wait_lock);
//             return -1;
//           }
//           freethread(nt); 
//           release(&nt->tlock);
//           release(&wait_lock);
//           return tid;
//         }
//         release(&nt->tlock);
//         // Wait for the other thread to exit.
//         sleep(nt, &wait_lock);  //DOC: wait-sleep
//       }
//     }
//   }



void freethread(struct thread *t){
  if(t->state!=UNUSED)
      {
        //acquire(&t->tlock);
        t->trapeframe = 0;
        t->chan = 0;
        t->killed=0;
        t->tid=0;
        memset(&t->context,0,sizeof(t->context));
        t->state=UNUSED;
        t->xstate = 0;
        //release(&t->tlock);
      }
      // if(p->headThreadTrapframe)
      //   kfree((void*)p->headThreadTrapframe);
}

int thread_is_in_process(int thread_id){
  struct proc *p = myproc();
  struct thread *t;
  for (t = p->threads; t < &p->threads[NTHREADS]; t++){
    if(t->tid == thread_id){
      return 1;
    }
  }
  return 0;
}


void threadExitLast(int status)
{
  //printf("thread exit last\n");
  struct proc *p=myproc();
  struct thread *myT=mythread();
  
  
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }
  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  acquire(&p->lock);
  acquire(&myT->tlock);

  p->xstate = status;
  p->state = p_ZOMBIE;
  myT->killed=1;
  myT->xstate = status;
  
  myT->state=ZOMBIE;
  //printf("Before exit wakeup\n");
  wakeup(myT);
  //wakeup(&wait_lock);
  release(&p->lock);
  release(&wait_lock);
  

  //printf("Before exit sched\n");
  // Jump into the scheduler, never to return.
  
  sched();
  panic("zombie exit");
}

void threadExitNotLast(int status)
{
  //printf("thread exit not last: pid: %d, tid: %d\n",myproc()->pid,mythread()->tid);
  struct thread *t=mythread();
  acquire(&t->tlock);
  t->killed=1;
  t->xstate = status;
  t->state=ZOMBIE;
  wakeup(t);
  wakeup(&myproc()->join_lock);
  release(&myproc()->lock);
  //printf("sched\n");
  sched();
  panic("Kill thread");
}

void
kthread_exit(int status)
{
  //printf("kthread_exit\n");
  struct thread *myT=mythread();
  struct proc *p=myproc();
  struct thread *t;

  acquire(&p->lock);

  if(myT->killed)
  {
    freethread(myT);
    return;
  }

  if (checkIfLastThread())
  {
    release(&p->lock);
    threadExitLast(status);
  }
  else
  {
    //printf("of kthread exit\n");
    threadExitNotLast(status);
  }
  

  //Check if i am the last thread. If not-> kill me (kill the thread)
  acquire(&p->lock);
  for (t = p->threads; t < &p->threads[NTHREADS]; t++)
  {
    if(t->tid!=myT->tid && t->state!=UNUSED && t->state!=ZOMBIE)
    {
//      acquire(&t->tlock);
      //printf("killing thread: pid: %d, tid: %d, idx: %d\n",myproc()->pid,myT->tid,myT->idx);
      killThread(myT, status);
      //release(&t->tlock);
    }
    
  }
  release(&p->lock);
  //printf("pid: %d, tid: %d, idx: %d is last surviver\n",p->pid,myT->tid,myT->idx);
  // printf("kthread exit\n");
  // If I am the last thread, terminate the process:
  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }
  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);
  acquire(&myT->tlock);

  p->xstate = status;
  p->state = p_ZOMBIE;
  myT->killed=1;
  myT->xstate = status;
  myT->state=ZOMBIE;
  
  //printf("Before exit wakeup\n");
  wakeup(myT);
  //wakeup(&wait_lock);
  release(&p->lock);
  release(&wait_lock);

  //printf("Before exit sched\n");
  // Jump into the scheduler, never to return.
  
  sched();
  panic("zombie exit");

  // //exit(status)
}

//kill process
int our_kill(int pid)
{
  struct proc *p;
  struct thread *t;

  for (p = proc; p < &proc[NPROC]; p++)
  {
      if(p->pid==pid)
      {
        //printf("before acquire\n");
        acquire(&p->lock);
        //printf("after acquire\n");
        p->killed=1;
        //printf("before release\n");
        release(&p->lock);
        //printf("after release\n");
        for (t = p->threads; t < &p->threads[NTHREADS]; t++)
        {
          if(t->tid!=mythread()->tid)
          {
              acquire(&t->tlock);
              t->killed=1;
              if(t->state==SLEEPING)
              {
                t->state=RUNNABLE;
              }
              release(&t->tlock);
          }        
        }
        //release(&p->lock);
        return 0;
      }
  }
  return -1;
}







// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  //printf("exit\n");

  struct proc *p = myproc();
  struct thread *t;
  struct thread *tToCheck;
  struct thread *myT=mythread();


  if(p == initproc)
    panic("init exiting");
  //printf("A");
  //First thread gets here kills all
  acquire(&p->lock);
  for(tToCheck=p->threads; tToCheck<&p->threads[NTHREADS];tToCheck++)
  {
    if(tToCheck->tid!=myT->tid)
    {
      tToCheck->killed=1;
      if(tToCheck->state==SLEEPING)
      {
        tToCheck->state=RUNNABLE;
      }
    }
  }
//printf("B");
  for (tToCheck = p->threads; tToCheck <&p->threads[NTHREADS]; tToCheck++)
  {
    if(tToCheck->tid != myT->tid && tToCheck->tid!=0)
    {
      //printf("joinning thread: tid: %d, idx: %d\n",tToCheck->tid, tToCheck->idx);
      release(&p->lock);
      kthread_join(tToCheck->tid,(int *)-1);
      acquire(&p->lock);
    }
  }
  //printf("C");
  int isLast=checkIfLastThread();
  if(isLast)
  {
    release(&p->lock);
    threadExitLast(status);
    
  }
  else
  {
   //printf("of exit\n");
    threadExitNotLast(status);
  }
  
  
  //if reached here is last










  //each thread enters, check first if it is killed.
  //If kiiled-> exit the thread
  //If not killed (alive) continue and kill all threads in the next line
  
  if(mythread()->killed)
  {
    //printf("Killing thread that is not me: %d\n",myT->tid);
    kthread_exit(status);
  }

  //printf("mythread not killed yet, kill all threads (our kill)\n");
  
  //printf("Before kill other threads\n");
  our_kill(p->pid);

  //printf("after our kill\n");
  
  //printf("After kill other threads\n");

  //acquire process
  
  //Again check if there are other threads alive
  //If yes, kill thread and sched
  //else continue
  //printf("Again kill me if I am not last\n");
  for (t=p->threads; t < &p->threads[NTHREADS]; t++)
  {
    if(t->state!=UNUSED && t->state!=ZOMBIE)
    {
      if(t->tid!=myT->tid)
      {
        killThread(myT, status);
      }
    }
  }
  //printf("After again kill me if I am not last\n");
  
  
  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }
  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);
  acquire(&myT->tlock);

  p->xstate = status;
  p->state = p_ZOMBIE;
  myT->killed=1;
  myT->xstate = status;
  
  myT->state=ZOMBIE;
  //printf("Before exit wakeup\n");
  wakeup(myT);
  //wakeup(&wait_lock);
  release(&p->lock);
  release(&wait_lock);
  

  //printf("Before exit sched\n");
  // Jump into the scheduler, never to return.
  
  sched();
  panic("zombie exit");
}

void
killThread(struct thread *t, int status)
{
  //printf("kill thread\n");
  //printf("tid: %d is exiting\n",t->tid);
  if(t->state!=UNUSED && t->state!=ZOMBIE)
  {
    acquire(&t->tlock);
    t->killed=1;
    t->xstate = status;
    t->state=ZOMBIE;
    wakeup(t);
    // if(t->idx!=0)
    // {
    //   kfree((void *)t->kstack);
    // }
    //wakeup(t);
    //acquire(&t->tlock);
    //printf("sched\n");
    //release(&t->tlock);
    sched();
    
    panic("Kill thread");
  }
}


int all_threads_killed(void){
  struct proc *p = myproc();
  for(int i=0; i<NTHREADS; i++){
    if(p->threads[i].killed == 0){
      return 0;
    }
  }
  return 1;
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();


  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == p_ZOMBIE){
          // Found one.
          pid = np->pid;

          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          //for on threads
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || all_threads_killed()){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}



// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct thread *t;
  //int foundThread
  
  struct cpu *c = mycpu();
  
  c->proc = 0;
  c->thread=0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    for(p = proc; p < &proc[NPROC]; p++) {
      // printf("scheduler\n");
      // if(p->pid==3)
      // {
      //   printf("process 3 in state: %d\n",p->state);
      // }
      //acquire(&p->lock);
      
      if(p->state == p_USED) {
        for (t = p->threads; t < &p->threads[NTHREADS]; t++)
        {
          
          acquire(&t->tlock);
          
          if(t->state==RUNNABLE)
          {
            
            //printf("cpu %d running process %d and thread %d\n",cpuid(),p->pid,t->tid);
            //printf("process: %d, thread: %d are running\n",p->pid,t->tid);
            t->state = RUNNING;
            c->proc = p;
            c->thread=t;
            //release(&p->lock);
            //release(&t->tlock);
            swtch(&c->context, &t->context);
            //printf("back swtch\n");
            //acquire(&p->lock);

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;
            c->thread=0;
          }

          release(&t->tlock);
        }
        
      }
      //release(&p->lock);
    }
  }
}


///

void
checkSignalsForProcess(struct proc *p)
{
    checkIfStopped(p);
    if(!p->stopped)
    {
      for (int i = 0; i <= 31; i++)
      {
        
        if(!(p->SignalMask & (1<<i)))
        {
          if(p->PendingSignals & (1<<i))
          {
              handlePendingSignal(p,i);
          }
        }
      }
    }
  //}
}



void
checkIfStopped(struct proc *p)
{
  while(p->stopped)
  {
    if(p->PendingSignals & (1<<SIGCONT))
    {
      if(p->Sigactions[SIGCONT].sa_handler==SIG_DFL)
      {
        contprocess(p);
        return;
      }
      else
      {
        yield();
      }
    }
    else
    {
      yield();
    }
    
  }
  
}

void
handlePendingSignal(struct proc *p, int signum)
{
  p->TempMask=p->SignalMask;
  struct sigaction* action=&(p->Sigactions[signum]);
  p->SignalMask=action->sigmask;

  if(p->Sigactions[signum].sa_handler==(void*)SIG_IGN)
  {
    //Ignore
    return;
  }
  else{
    if(p->Sigactions[signum].sa_handler==(void*)SIG_DFL)
    {
      defaultHandlerForSignal(p, signum);
    }
    else
    {
      if(p->Sigactions[signum].sa_handler==(void*)SIGKILL)
      {
        killprocess(p);
      }
      else
      {
        if(p->Sigactions[signum].sa_handler==(void*)SIGSTOP)
        {
          stopprocess(p);
        }
        else
        {
          if(p->Sigactions[signum].sa_handler==(void*)SIGCONT)
          {
            contprocess(p);
          }
          else{     
            handldeUserHandler(p, signum);
          }
        }
      }
    }
  
  }
  p->PendingSignals = p->PendingSignals^(1<<signum);
}

void
defaultHandlerForSignal(struct proc *p, int signum)
{
  if(signum==SIGSTOP)
  {
    stopprocess(p);
  }
  else if(signum==SIGCONT)
  {
    contprocess(p);
  }
  else if (signum==SIGKILL)
  {
    killprocess(p);
  }
  else
  {
    killprocess(p);
  }
}

void handldeUserHandler(struct proc *p, int signum)
{
  struct thread *t= mythread();
  //Backup the trapefram
  memmove(&(p->UserTrapFrameBackup),t->trapeframe,sizeof(struct trapframe));
  
  //Static array holding the hex code for the following code:
  //li a7, SYS_sigret
  //ecall
  char arr[]={0x93 ,0x08 ,0x80 ,0x01 ,0x73 ,0x00 ,0x00 ,0x00 };

  //Copy the code to the user stack
  copyout(p->pagetable,t->trapeframe->sp,arr,8);  
  
  //Modify the return address to sigret on the stack
  t->trapeframe->ra=t->trapeframe->sp;
  struct sigaction* sigPtr=&(p->Sigactions[signum]);

  //Modify stack pointer
  t->trapeframe->sp-=8;  
  
  //Modify the first argument of the use handler function
  t->trapeframe->a0=signum;

  //Set the address to the user's handler
  t->trapeframe->epc= (uint64) (sigPtr->sa_handler);
  
}


void acquireSchedPanic()
{
  panic("sched t->lock");
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct thread *t = mythread();

  if(!holding(&t->tlock))
  {
    acquireSchedPanic();
  }
  if(mycpu()->noff != 1)
  {
    printf("pid: %d, tid: %d, idx: %d\n", myproc()->pid,t->tid,t->idx);
    panic("sched locks");
  }
  if(t->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&t->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
//  printf("yield\n");
  struct thread *t = mythread();
  acquire(&t->tlock);
  t->state = RUNNABLE;
  sched();
  release(&t->tlock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  //printf("forkret\n");
  static int first = 1;
  release(&mythread()->tlock);
  if (first) {
    //printf("first\n");
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }
  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  
  //struct proc *p = myproc();
  struct thread *t=mythread(); 
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.
  //acquire(&p->lock);
  
  //acquire(&t->tlock);  //DOC: sleeplock1
  
  // if(lk!=&t->tlock)
  // {
  //   acquire(&t->tlock);
  //   release(lk);
  // }

  acquire(&t->tlock);
  release(lk);
  
  // Go to sleep.
  t->chan = chan;
  t->state = SLEEPING;
  // printf("thread %d is sleeping on chan %d\n", t->tid, t->chan);
  //printf("sleeping\n");
  //release(&t->tlock);
  //printf("sleep sched of tid: %d\n",t->tid);
  sched();

  // Tidy up.
  t->chan = 0;

  // Reacquire original lock.
  
  //release(&p->lock);
  // if(lk!=&t->tlock)
  // {
  //   release(&t->tlock);
  //   acquire(lk);
  // }
  
  release(&t->tlock);
  acquire(lk);
  
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  // if(myproc()!=0 && mythread()!=0)
  //   printf("start wakeup: cpu: %d, pid: %d, tid: %d, chan: %d\n",cpuid(),myproc()->pid,mythread()->tid,chan);
  struct proc *p;
  struct thread *t;
  for(p = proc; p < &proc[NPROC]; p++) {
    //acquire(&p->lock);
    for (t = p->threads; t < &p->threads[NTHREADS]; t++)
    {
      //acquire(&p->lock);
      if(p->state==p_USED)
      {
        if(t!=mythread())
        {
          if(t->state == SLEEPING && t->chan == chan) {
            acquire(&t->tlock);
            t->state = RUNNABLE;
            release(&t->tlock);
          }
          
        }
      }
    }
    //release(&p->lock);
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid, int signum)
{
  struct proc *p;
  struct thread *t;
  
  if(signum<0 || signum>31)
  {
    return -1;
  }
  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      if(signum==SIGKILL)
      {
        p->killed=1;
        for (t = p->threads; t<&p->threads[NTHREADS]; t++)
        {
          acquire(&t->tlock);
          t->killed=1;
          release(&t->tlock);
        }
        
      }
      p->PendingSignals = p->PendingSignals | (1<<signum);
      for (t = p->threads; t<&p->threads[NTHREADS]; t++)
      {
        if(t->state == RUNNABLE){
          release(&p->lock);
          return 0;
        }
      }

      for (t = p->threads; t<&p->threads[NTHREADS]; t++)
      {
        acquire(&t->tlock);
        if(t->state == SLEEPING){
        // Wake thread from sleep().
          t->state = RUNNABLE;
          release(&t->tlock);
          release(&p->lock);
          return 0;
        }
        release(&t->tlock);
      }
      release(&p->lock);
      //printf("B");
      return -1;
    }
    release(&p->lock);
  }
  //printf("C");
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  // static char *pstates[] = {
  // [p_UNUSED]    "p_unused",
  // [p_USED]      "p_sleep ",
  // [p_ZOMBIE]    "p_runble",
  // };

  // static char *tstates[] = {
  // [UNUSED]    "unused",
  // [SLEEPING]  "sleep ",
  // [RUNNABLE]  "runble",
  // [RUNNING]   "run   ",
  // [ZOMBIE]    "zombie"
  // };
  // struct proc *p;
  // char *pstate;
  // char *tstate;

  // printf("\n");

  // for (p=proc;p<&proc[NPROC]; p++)
  // {
  //   if(p->state >= 0 && p->state < NELEM(pstate) )
  //     pstate = pstates[p->state];
  //   else
  //     pstate = "???";
  //   printf("---process %d-----\n",p->pid);
  //   printf("%d %s %s", p->pid, pstate, p->name);
  //   printf("p->sz: %d\n",p->sz);
  //   printf("p->xstate: %d\n",p->xstate);
  //   printf("p->head trapframe: %d\n", p->headThreadTrapframe);
  //   printf("p->killed\n" ,p->killed);
  //   printf("p->lock state: %d\n",p->lock.locked);
  //   printf("p->nexttid\n",p->nexttid);
  //   printf("\n");

  //   // for (size_t i = 0; i < count; i++)
  //   // {
  //   //   /* code */
  //   // }
    
  // }
  


  // for(p = proc; p < &proc[NPROC]; p++){
  //   if(p->state == p_UNUSED)
  //     continue;
  //   if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
  //     state = states[p->state];
  //   else
  //     state = "???";
  //   printf("%d %s %s", p->pid, state, p->name);
  //   printf("\n");
  // }
}

uint
sigprocmask(uint mask)
{
  struct proc *p = myproc();
  uint temp = p->SignalMask;
  if((mask & (1<<SIGSTOP)) || (mask & (1<<SIGKILL)) )
  {
    //error
  }
  else
  {
    p->SignalMask = mask;
  }
   
  return temp;
}


int sigaction(int signum, struct sigaction* act, struct sigaction* oldact)
{
  struct proc *p = myproc();
  if(signum<0 || signum>32)
  {
    return -1;
  }
  if(signum==SIGKILL || signum == SIGSTOP)
  {
    return -1;
  }
  if(oldact!=0)
  {
    char* srcptr= (char*) &(p->Sigactions[signum]);
    copyout(p->pagetable,(uint64)oldact,srcptr,sizeof(struct sigaction));
  }
  if(act != 0) //act not null
  {
    char* dstptr= (char*) &(p->Sigactions[signum]);
    struct sigaction tempAction=(p->Sigactions[signum]);
    copyin(p->pagetable,dstptr,(uint64)act,sizeof(struct sigaction));
    struct sigaction *actPtr=(struct sigaction *)&(p->Sigactions[signum]);
    if((actPtr->sigmask & (1 << SIGSTOP)) || (actPtr->sigmask & (1 << SIGKILL)))
    {
      *actPtr=tempAction;
      return -1;
    }
  }
  return 0;

}

void
sigret(void)
{
  struct thread *t= mythread();
  struct proc *p= myproc();
  memmove(t->trapeframe,&(p->UserTrapFrameBackup),sizeof(struct trapframe));
}

void
stopprocess(struct proc* p)
{
  p->stopped=1;
}

void
contprocess(struct proc* p)
{
  p->stopped=0;
}

void
killprocess(struct proc* p)
{
  p->killed=1;
  exit(0);
}


int KillOtherThreads(struct proc *p)
{
  struct thread *myT= mythread();
  struct thread *t;
  if(myT->killed==1)
  {
    return 1;
  }

  for (t= p->threads; t < &p->threads[NTHREADS]; t++)
  {
    if(t->tid!=myT->tid && t->state!=ZOMBIE && t->state != UNUSED)
    {
      t->killed=1;
      if(t->state==SLEEPING)
      {
        t->state=RUNNABLE;
      }
    }
  }
  
  return 0;
}

//Bsems
int allocBsem()
{
  int sema_id=-1;
  int found=0;
  if(!isSemaphoresAllocated)
  {
    //printf("First time allocated\n");
    initlock(&semaphores_lock,"semaphores_lock");
    acquire(&semaphores_lock);
    for (int i = 0; i < MAX_BSEM; i++)
    {
      initlock(&semaphores[i].sema_lock,"sema_lock");
      acquire(&semaphores[i].sema_lock);
      semaphores[i].available=1;
      semaphores[i].value=1;
      release(&semaphores[i].sema_lock);
      //semaphores[ i].currentProcWaiting=0;
    }
    isSemaphoresAllocated=1;
    release(&semaphores_lock);
  }

  acquire(&semaphores_lock);
  for (int i = 0; i < MAX_BSEM && found==0; i++)
  {
    acquire(&semaphores[i].sema_lock);
    if(semaphores[i].available==1)
    {
      semaphores[i].available=0;
      semaphores[i].value=1;
      found=1;
      sema_id=i;
    }
    
    release(&semaphores[i].sema_lock);
  }
  release(&semaphores_lock);
  if(found==0)
  {
    return -1;
  }
  //printf("alloc sema_id: %d, value: %d\n",sema_id,semaphores[sema_id].value);
  return sema_id;
}


void bsem_free(int bsem)
{
  if(bsem>MAX_BSEM)
  {
    panic("semaphore id not valid");
  }
  if(semaphores[bsem].available==1)
  {
    panic("BSEM not allocated");
  }
  
  acquire(&semaphores_lock);
  semaphores[bsem].available=1;
  semaphores[bsem].value=1;
  release(&semaphores_lock);
  
}


void bsem_down(int bsem)
{
  //printf("bdown\n");
  acquire(&semaphores[bsem].sema_lock);
  //printf("after bsem %d acquire, value: %d\n",bsem,semaphores[bsem].value);
  while(semaphores[bsem].value==0)
  {
    //printf("pid %d: Go to sleep on %d\n",myproc()->pid,&semaphores[bsem].value);  
    
    sleep(&semaphores[bsem].value,&semaphores[bsem].sema_lock);
    //printf("wakeup\n");
  }
  semaphores[bsem].value=0;
  release(&semaphores[bsem].sema_lock);


  // while(semaphores[bsem].value==1)
  // {
  //   printf("going to sleep\n");
  //   acquire(&semaphores_lock);
  //   sleep(&semaphores[bsem],&semaphores_lock);
  // }
  // acquire(&semaphores_lock);
  // semaphores[bsem].value=1;
  // release(&semaphores_lock);
  
}
void bsem_up(int bsem)
{
  acquire(&semaphores[bsem].sema_lock);
  if(semaphores[bsem].value==0)
  {
    //acquire(&semaphores_lock);
    semaphores[bsem].value=1;
    //release(&semaphores_lock);
    //printf("wakeup on: %d\n",&semaphores[bsem].value);
    wakeup(&semaphores[bsem].value);
  }
  release(&semaphores[bsem].sema_lock);
}


