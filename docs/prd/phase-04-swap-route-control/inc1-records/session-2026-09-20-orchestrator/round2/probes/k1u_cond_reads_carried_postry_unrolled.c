#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    { bool b = 0; if (a >= 3) b = cq_theta(b, 0.5); if (b) a -= 3; }
    { bool b = 0; if (a >= 3) b = cq_theta(b, 0.5); if (b) a -= 3; }
    { bool b = 0; if (a >= 3) b = cq_theta(b, 0.5); if (b) a -= 3; }
    a = cq_theta(a, -0.5);
    return cq_measure(a);
}
int main(void) { (void) run(); return 0; }
