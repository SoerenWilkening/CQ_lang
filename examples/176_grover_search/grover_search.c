#include <stdbool.h>
#include <math.h>
/* Standalone Grover search (Nielsen & Chuang 6.1) on a RUNTIME number of qubits nq: the oracle marks the runtime value
 * `target`, `iters` iterations of G = A R0 A^dag O with A = Ry(pi/2)^nq. The register is a runtime-sized bool array
 * (rule 20), every size is an input. Expected: P(target) = sin^2((2 iters + 1) theta), sin^2 theta = 1 / 2^nq.
 * The oracle compares an int built from the bools (rule 4), the phase arms kick back on the compare flag (rule 8),
 * every loop is classical (rule 14). */
static int value(int nq, const bool *x) { int v = 0; for (int i = 0; i < nq; i++) v |= x[i] << i; return v; }
int grover_search(int nq, int target, int iters) {
    bool x[nq];
    for (int i = 0; i < nq; i++) { x[i] = 0; cq_theta(&x[i], M_PI / 2); }   /* A */
    for (int r = 0; r < iters; r++) {
        if (value(nq, x) == target) cq_phi(M_PI);                           /* O */
        for (int i = 0; i < nq; i++) cq_theta(&x[i], -M_PI / 2);           /* A^dag */
        if (value(nq, x) != 0) cq_phi(M_PI);                                /* R0 */
        for (int i = 0; i < nq; i++) cq_theta(&x[i], M_PI / 2);            /* A */
    }
    int m = 0;
    for (int i = 0; i < nq; i++) m |= cq_measure(x[i]) << i;
    return m;
}
