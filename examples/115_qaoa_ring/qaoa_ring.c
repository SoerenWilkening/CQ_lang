/* QAOA for MaxCut (Farhi, Goldstone, Gutmann 2014) on a graph given at run time: n vertices, ne edges (eu[e], ev[e]),
 * p layers with angles gamma[l], beta[l]:
 *   |psi> = prod_l U_B(beta_l) U_C(gamma_l) |+>^n,  U_C = exp(-i gamma C),  C = sum_e [x_eu[e] != x_ev[e]],
 *   U_B = prod_i Rx(2 beta) = prod_i Rz(-pi/2) Ry(2 beta) Rz(pi/2)  (up to a global phase).
 * Sizes and problem data are inputs, never compile-time constants. Returns the measured bits x0 | x1<<1 | ... */
#include <math.h>
int qaoa_ring(int n, int ne, const int *eu, const int *ev, int p, const double *gamma, const double *beta) {
    bool x[n];
    for (int i = 0; i < n; i++) {
        x[i] = 0;
        cq_theta(&x[i], M_PI / 2);                                 /* |+>^n */
    }
    for (int l = 0; l < p; l++) {
        for (int e = 0; e < ne; e++)                               /* cost layer */
            if (x[eu[e]] != x[ev[e]]) cq_phi(-gamma[l]);
        for (int i = 0; i < n; i++) {                              /* mixer layer: Rx(2 beta) */
            if (x[i]) cq_phi(M_PI / 2);
            cq_theta(&x[i], 2 * beta[l]);
            if (x[i]) cq_phi(-M_PI / 2);
        }
    }
    int m = 0;
    for (int i = 0; i < n; i++) m |= cq_measure(x[i]) << i;
    return m;
}
