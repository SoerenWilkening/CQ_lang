#include <stdbool.h>
#include <math.h>
/* Deutsch-Jozsa on nq qubits (nq is a RUNTIME input, 1 <= nq <= 31), phase-oracle form. f is a RUNTIME function selector:
 * 0 = constant 0, 1 = constant 1, 2 = balanced parity of all nq bits, otherwise balanced x[0].
 * H^n, phase oracle (-1)^f(x), H^n, measure: m == 0 iff f is constant. */
static bool f_eval(int sel, int nq, const bool *x) {
    switch (sel) {
        case 0: return false;
        case 1: return true;
        case 2: {
            bool p = false;
            for (int i = 0; i < nq; i++) p ^= x[i];
            return p;
        }
        default: return x[0];
    }
}
int deutsch_jozsa(int nq, int sel) {
    bool x[nq];
    for (int i = 0; i < nq; i++) { x[i] = false; cq_theta(&x[i], M_PI / 2); }
    if (f_eval(sel, nq, x)) cq_phi(M_PI);
    for (int i = 0; i < nq; i++) cq_theta(&x[i], -M_PI / 2);
    int m = 0;
    for (int i = 0; i < nq; i++) m |= cq_measure(x[i]) << i;
    return m;
}
