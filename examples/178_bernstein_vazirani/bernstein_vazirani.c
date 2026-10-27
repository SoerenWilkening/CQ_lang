#include <stdbool.h>
#include <math.h>
/* Bernstein-Vazirani on nq qubits (nq is a RUNTIME input, 1 <= nq <= 31): the hidden string s is a RUNTIME parameter; the
 * phase oracle is (-1)^{popcount(x & s) & 1}; the measured value equals s mod 2^nq with probability 1. */
int bernstein_vazirani(int nq, int s) {
    bool x[nq];
    for (int i = 0; i < nq; i++) { x[i] = false; cq_theta(&x[i], M_PI / 2); }
    int v = 0;
    for (int i = 0; i < nq; i++) v |= x[i] << i;
    if (__builtin_popcount(v & s) & 1) cq_phi(M_PI);
    for (int i = 0; i < nq; i++) cq_theta(&x[i], -M_PI / 2);
    int m = 0;
    for (int i = 0; i < nq; i++) m |= cq_measure(x[i]) << i;
    return m;
}
