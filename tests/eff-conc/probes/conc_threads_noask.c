#include "CQ.h"
#include <pthread.h>
/* cq-20fz (CR rule 24): no join of the module asks for a result, so no create writes its pthread_t; a global
   pthread_t is a memory output the C oracle must leave as the lowered program does. */
pthread_t gtn;
__attribute__((noinline)) static void *njob(void *p) { int *q = p; *q = *q * 3 + 1; return 0; }
int p_thr_noask(int x0, double th) {
    int c = x0;
    cq_theta(&c, th);
    pthread_create(&gtn, 0, njob, &c);
    pthread_join(gtn, 0);
    return cq_measure(c);
}
