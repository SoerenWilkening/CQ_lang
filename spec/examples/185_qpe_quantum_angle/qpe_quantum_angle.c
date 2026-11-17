#include <stdbool.h>
#include <math.h>
/* Rules 15, 8, 2: QPE whose phase comes from a QUANTUM angle register, general size. The eigenphase register k (nk bits,
 * k[i] prepared by Ry(tk[i])) drives the controlled phases: on counting qubit c[j] the unitary applies phase
 * 2^j * (2*pi*kv/2^nk) when c[j] is 1, kv = sum k[i] << i. The angle is computed into an f64 register from k by ordinary
 * templates and consumed by ONE primitive, cqrt_rz_qangle_controlled(c[j], A) (rule 15; precision N is the compiler
 * flag); then QFT^-1 on c and measure c and k. The sizes nk, t and the preparation angles tk[0..nk) are inputs.
 * Expected: for each basis value kv the counting register reads kv * 2^(t-nk) exactly when t >= nk. */
int qpe_quantum_angle(int nk, int t, const double *tk) {
    bool k[nk], c[t];
    for (int i = 0; i < nk; i++) k[i] = false;
    for (int j = 0; j < t; j++) c[j] = false;
    for (int i = 0; i < nk; i++) cq_theta(&k[i], tk[i]);           /* eigenstate preparation */
    int kv = 0;
    for (int i = 0; i < nk; i++) kv |= k[i] << i;
    for (int j = 0; j < t; j++) cq_theta(&c[j], M_PI / 2);          /* H^t */
    for (int j = 0; j < t; j++) {                                   /* controlled U^(2^j), U = diag(e^{i 2 pi kv/2^nk}) */
        double phi = (double)kv * (2.0 * M_PI / (double)(1 << nk)) * (double)(1 << j);
        if (c[j]) cq_phi(phi);
    }
    for (int j = t - 1; j >= 0; j--) {                              /* QFT^-1 without the final swaps */
        for (int m = t - 1; m > j; m--)
            if (c[m] && c[j]) cq_phi(-M_PI / (1 << (m - j)));
        if (c[j]) cq_phi(M_PI);
        cq_theta(&c[j], M_PI / 2);
    }
    int out = 0;
    for (int j = 0; j < t; j++) out |= cq_measure(c[j]) << (t - 1 - j);
    for (int i = 0; i < nk; i++) out |= cq_measure(k[i]) << (t + i);
    return out;
}
