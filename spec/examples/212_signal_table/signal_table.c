#include <signal.h>
/* Rule 16: signal and raise through the cells of __cq_sig; no handler is tracked at compile time. */
static int hit;
static void on_usr1(int s) { hit += s; }
int signal_table(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    signal(SIGUSR1, on_usr1);                 /* the host call, then a store of the handler address in its cell */
    if (x > k)
        raise(SIGUSR1);                       /* the cell is loaded and called through, under the flag */
    return cq_measure(x) + cq_measure(hit);
}
