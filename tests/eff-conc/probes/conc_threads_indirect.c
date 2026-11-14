#include "CQ.h"
#include <pthread.h>
/* cq-lyzw (rule 24, 106): a start routine chosen at run time handed quantum memory: the call f(p) with
   rule 19's dispatch (a classical pointer: __cq_clone_resolve). In the runner since cq-20fz (the flat memory
   model removed mem-slots' internal error, cq-o42w). */
__attribute__((noinline)) static void *j1(void *p) { if (*(int *)p & 1) cq_phi(0.25); return 0; }
__attribute__((noinline)) static void *j2(void *p) { if (*(int *)p < 0) cq_phi(0.75); return 0; }
int p_runtime_qjob(int x0, double th, int k) {
    int c = x0;
    cq_theta(&c, th);
    void *(*f)(void *) = k ? j1 : j2;
    pthread_t t;
    pthread_create(&t, 0, f, &c);
    return pthread_join(t, 0);
}
