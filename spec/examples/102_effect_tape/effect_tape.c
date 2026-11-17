#include <signal.h>
#include <stdio.h>
static volatile sig_atomic_t hit;
static void h(int s) { hit = s; }
int raise_handled(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    signal(SIGUSR1, h);                      /* classical: installs the handler (known in the module) */
    if (x > k)
        raise(SIGUSR1);                      /* delivered under a quantum condition: runs h, sets hit */
    return cq_measure(x) + cq_measure(hit);
}
int raise_default(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    if (x > k)
        raise(SIGABRT);                      /* no handler: the process aborts, the abort arm of 45 */
    return cq_measure(x);
}
int remove_cond(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    if (x > k)
        remove("/tmp/cq_x");                 /* a host effect under a quantum condition: a tape entry */
    return cq_measure(x);
}
