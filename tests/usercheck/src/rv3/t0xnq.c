/* cq-t0xnq (CR rule 16 signal table): signal returns the previous handler the PROGRAM registered, SIG_DFL here; the C
   oracle runtime's own SIGSEGV handler is never it. */
#include <signal.h>
#include "CQ.h"
static int hit;
static void h(int s) { hit += s; }
int f(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    int prev = signal(SIGSEGV, h) != SIG_DFL;
    return cq_measure(x) + prev;
}
