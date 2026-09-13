/* r19 — item 4: a classical measure inside a tainted-scrutinee switch case. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int c = 9, a = 0;
    switch (q) { case 1: a = cq_measure(c); break; case 2: a = 22; break; default: a = 44; }
    return a;
}
