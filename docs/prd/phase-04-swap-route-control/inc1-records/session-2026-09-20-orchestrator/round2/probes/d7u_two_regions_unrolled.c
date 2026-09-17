#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    { bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; bool c = cq_theta((bool)0, 0.25); if (c) a += 7; }
    { bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; bool c = cq_theta((bool)0, 0.25); if (c) a += 7; }
    { bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; bool c = cq_theta((bool)0, 0.25); if (c) a += 7; }
    return cq_measure(a);
}
int main(void) { (void) run(); return 0; }
