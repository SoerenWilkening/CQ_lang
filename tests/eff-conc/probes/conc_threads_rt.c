#include "CQ.h"
#include <pthread.h>
#include <stdint.h>
/* cq-20fz (CR rule 24): pthread_create(t, attr, f, p) is the call f(p) (rule 19 when f is a pointer), and
   when some join of the module asks for the result, the create stores f's result in *t and the join stores
   its pthread_t operand through r.
   - p_thr_plain: the control, a known routine handed quantum memory, its result left in that memory.
   - p_thr_qresult: pthread_join of a quantum job's result (the routine returns a rail as its void *).
   - p_thr_table: a start routine read from a table at run time (rule 19, a classical pointer:
     __cq_clone_resolve).
   - p_thr_qsel: a start routine chosen by a quantum condition (rule 19, an address rail).
   - p_thr_ext: a bodiless start routine on the root list handed quantum memory (rule 27's declared
     clone; lowered with -cq-roots naming ext_job). */
struct box { int in; int out; };

__attribute__((noinline)) static void *boxjob(void *p) {
    struct box *b = p;
    b->out = b->in * 3 + 1;
    return 0;
}
int p_thr_plain(int x0, double th) {
    struct box b = {x0, 0};
    cq_theta(&b.in, th);
    pthread_t t;
    pthread_create(&t, 0, boxjob, &b);
    pthread_join(t, 0);
    return cq_measure(b.out);
}

__attribute__((noinline)) static void *qret(void *p) { return (void *)(intptr_t)(*(int *)p * 5 + 2); }
int p_thr_qresult(int x0, double th) {
    int c = x0;
    cq_theta(&c, th);
    pthread_t t;
    pthread_create(&t, 0, qret, &c);
    void *r;
    pthread_join(t, &r);
    return cq_measure((int)(intptr_t)r);
}

__attribute__((noinline)) static void *j1(void *p) { int *q = p; *q = *q + 7; return 0; }
__attribute__((noinline)) static void *j2(void *p) { int *q = p; *q = *q ^ 5; return 0; }
void *(*jtab[2])(void *) = {j1, j2};
int p_thr_table(int x0, double th, int k) {
    int c = x0;
    cq_theta(&c, th);
    pthread_t t;
    pthread_create(&t, 0, jtab[k & 1], &c);
    pthread_join(t, 0);
    return cq_measure(c);
}

int p_thr_qsel(int x0, double th) {
    int c = x0;
    cq_theta(&c, th);
    void *(*f)(void *) = (c & 2) ? j1 : j2;
    pthread_t t;
    pthread_create(&t, 0, f, &c);
    pthread_join(t, 0);
    return cq_measure(c);
}

extern void *ext_job(void *);
int p_thr_ext(int x0, double th) {
    int c = x0;
    cq_theta(&c, th);
    pthread_t t;
    pthread_create(&t, 0, ext_job, &c);
    void *r;
    pthread_join(t, &r);
    return cq_measure(c) + (r != 0);
}

/* cq-t8rox: the thread created in another function into a global pthread_t (a memory output, which rule 24
   writes with the routine's result), joined with a result here. */
pthread_t gt;
__attribute__((noinline)) static void *cjob(void *p) { return (void *)(intptr_t)(*(int *)p * 2 + 42); }
__attribute__((noinline)) void p_thr_start(int *a) { pthread_create(&gt, 0, cjob, a); }
int p_thr_global(int x0, double th, int k) {
    int c = x0;
    cq_theta(&c, th);
    int a = k;
    p_thr_start(&a);
    void *r;
    pthread_join(gt, &r);
    return cq_measure(c) + (int)(intptr_t)r;
}

/* cq-t8rox: a join whose result pointer is null at run time (rule 24 stores through r; nothing reads it). */
int p_thr_nullres(int x0, double th, int k) {
    int c = x0;
    cq_theta(&c, th);
    pthread_t t;
    pthread_create(&t, 0, qret, &c);
    void *r = 0;
    void **rp = (k & 1) ? &r : 0;
    pthread_join(t, rp);
    return cq_measure((int)(intptr_t)r);
}
