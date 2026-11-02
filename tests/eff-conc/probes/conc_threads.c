#include "CQ.h"
#include <pthread.h>
/* cq-lyzw (rule 24, 106): the thread calls as the sequential schedule in the IR before the final taint.
   A join asking for the result of a quantum job (formerly a stop); the run-time routine is
   conc_threads_indirect.c. The jobs act by phases (a job writing memory the caller reads again is
   mem-slots', 31, 52, 102). */
static int hi = 20;
__attribute__((noinline)) static void *qjob(void *p) {
    if (*(int *)p > 3) cq_phi(0.5);
    return &hi;
}
int p_join_qresult(int x0, double th) {
    int c = x0;
    cq_theta(&c, th);
    pthread_t t;
    pthread_create(&t, 0, qjob, &c);
    void *r;
    pthread_join(t, &r);
    return *(int *)r;   /* reading c again after the job is mem-slots' (106) */
}
