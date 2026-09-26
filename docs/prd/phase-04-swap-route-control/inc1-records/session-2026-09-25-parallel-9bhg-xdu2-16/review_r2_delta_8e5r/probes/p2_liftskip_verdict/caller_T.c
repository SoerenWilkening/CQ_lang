/* p2 (T): the SAME program with the lift's consumer also read by a PURE op (`q ^ 1`,
   measured), so a lifted consumer SURVIVES specialize(). Twin of caller_C.c. */
#include <stdlib.h>
double h(int a, int k);
__attribute__((noinline)) int slice(void) {
    int a = 0;
    a = cq_theta(a, 0.5);
    for (int i = 0; i < 2; ++i) {
        if (a > 5 && a < 20) {
            cq_phi(3.14159265358979323846);
        }
        a = cq_theta(a, -0.5);
    }
    return cq_measure(a);
}
int main(int c, char **v) {
    int m = atoi(v[1]);
    int q = cq_theta(m, .5);
    if (m > 3) q = cq_theta(q, .2);
    double d = h(q, m);
    return (int)cq_measure(d) + slice() + cq_measure(q ^ 1);
}
