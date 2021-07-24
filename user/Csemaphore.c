#include "user/Csemaphore.h"
#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/param.h"


void csem_down(struct counting_semaphore *sem)
{
    bsem_down(sem->S2_descriptor);
    bsem_down(sem->S1_descriptor);
    sem->value-=1;
    if(sem->value>0)
    {
        bsem_up(sem->S2_descriptor);
    }
    bsem_up(sem->S1_descriptor);
}
void csem_up(struct counting_semaphore *sem)
{
    bsem_down(sem->S1_descriptor);
    sem->value+=1;
    if(sem->value==1)
    {
        bsem_up(sem->S2_descriptor);
    }
    bsem_up(sem->S1_descriptor);

}
int csem_alloc(struct counting_semaphore *sem, int initial_value)
{
    sem->S1_descriptor=bsem_alloc();
    sem->S2_descriptor=bsem_alloc();
    sem->value=initial_value;
    if(sem->S1_descriptor<0 ||sem->S2_descriptor<0 || initial_value<=0)
    {
        return -1;
    }
    return 0;
}
void csem_free(struct counting_semaphore *sem)
{
    bsem_free(sem->S1_descriptor);
    bsem_free(sem->S2_descriptor);
}

