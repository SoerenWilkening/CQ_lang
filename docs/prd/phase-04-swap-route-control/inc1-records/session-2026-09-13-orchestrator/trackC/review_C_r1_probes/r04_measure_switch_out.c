/* r04 — item 1: measure the %out of a 4.5 switch value/data-mux merge. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int a = 0;
    switch (q) { case 1: a = 11; break; case 2: a = 22; break; case 3: a = 33; break; default: a = 44; }
    return cq_measure(a);
}
