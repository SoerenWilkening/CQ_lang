#include "CQ.h"
#include <pthread.h>
#include <stdint.h>
/* cq-py5f (rule 24): pthread_join's result is the start routine's (the sequential schedule ran it at
   pthread_create); a volatile atomic access is both, classical here (the host performs it). */
volatile int vcell;                       /* observable, accessed volatile and atomic */

static void *job(void *p) { return (void *)(intptr_t)(*(int *)p * 3 + 1); }

int p_join_result(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    pthread_t t;
    pthread_create(&t, 0, job, &c);
    void *r;
    pthread_join(t, &r);
    return cq_measure(x) + (int)(intptr_t)r;
}

int p_vol_atomic(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    __atomic_store_n(&vcell, c, __ATOMIC_SEQ_CST);
    int v = __atomic_load_n(&vcell, __ATOMIC_SEQ_CST);
    return cq_measure(x) + v;
}

static void *job2(void *p) { return (void *)(intptr_t)(*(int *)p + 7); }

int p_runtime_routine(int x0, double th, int c) {   /* a classical job whose routine is chosen at run time */
    int x = x0;
    cq_theta(&x, th);
    void *(*f)(void *) = (c & 1) ? job : job2;
    pthread_t t;
    pthread_create(&t, 0, f, &c);
    void *r;
    pthread_join(t, &r);
    return cq_measure(x) + (int)(intptr_t)r;
}
