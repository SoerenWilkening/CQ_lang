#include "CQ.h"
#include <pthread.h>
/* Rule 24: a thread-local object is the one thread's object at its address; a mutex is a no-op, init and destroy
   included, and its operand no user for rule 20 (b). */
_Thread_local int tcell = 3;
int p_tls(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    tcell = c;
    tcell += x;
    return cq_measure(tcell);
}
int p_mutex_init(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    pthread_mutex_t m;
    pthread_mutex_init(&m, 0);
    pthread_mutex_lock(&m);
    int y = x + 1;
    pthread_mutex_unlock(&m);
    pthread_mutex_destroy(&m);
    return cq_measure(y);
}
