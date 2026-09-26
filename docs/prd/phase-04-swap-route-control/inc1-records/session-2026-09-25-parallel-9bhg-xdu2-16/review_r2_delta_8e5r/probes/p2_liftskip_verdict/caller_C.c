/* p2 (C): the Grover range-oracle loop (shipped ACCEPT, e2e-slice-control-grover-loop-range-oracle)
   in `slice`, plus in `main` a one-register merge-phi LIFT whose ONLY direct consumer is an
   fp-return spec site (`h`), which specialize() REBUILDS (retargetSite erases the old call). */
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
    return (int)cq_measure(d) + slice();
}
