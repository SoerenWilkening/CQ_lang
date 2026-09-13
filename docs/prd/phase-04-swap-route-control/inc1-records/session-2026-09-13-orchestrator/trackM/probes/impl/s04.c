/* s04 — the SHIPPED S-dagger rail-leaf accept, as CLAUDE.md/r9e5 state it:
   `if (b) a -= 3; b = cq_theta(b, -0.5);` on a bare _Bool register. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b = 0;
    b = cq_theta(b, 0.5);
    if (b) a -= 3;
    b = cq_theta(b, -0.5);
    return cq_measure(b) + cq_measure(a);
}
