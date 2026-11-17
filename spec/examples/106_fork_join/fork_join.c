#include <pthread.h>
struct job { int in; int out; };
static void *worker(void *p) {
    struct job *j = p;
    j->out = j->in * j->in + 1;
    return 0;
}
int fork_join(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    struct job a = {x, 0}, b = {c, 0};
    pthread_t ta, tb;
    pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
    pthread_create(&ta, 0, worker, &a);              /* quantum job: the clone of worker */
    pthread_create(&tb, 0, worker, &b);              /* classical job: the original */
    pthread_join(ta, 0);
    pthread_join(tb, 0);
    pthread_mutex_lock(&m);                          /* no contention after the joins: no-ops */
    int s = a.out + b.out;
    pthread_mutex_unlock(&m);
    return cq_measure(s);
}
