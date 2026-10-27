/* Quantum counting = QPE on the Grover iterate (Brassard, Hoyer, Tapp; Nielsen & Chuang 6.3), textbook form, general size.
 *   A = Ry(pi/2)^nq (A|0> = |s>), O = I - 2 sum_{marked} |x><x|, R = 2|0><0| - I, G = A R A^dag O.
 *   H^t on c; controlled G^(2^j) on c[j]; QFT^-1 on c; measure m; M~ = 2^nq sin^2(pi m / 2^t).
 * `if (c[j]) grover(...)` is a CONTROLLED COMPOSITE U: a helper with loops, rotations and phases under one control.
 * Sizes and problem data are inputs: nq search qubits, t counting qubits, the marked list `marked[0..nmark)`.
 * Driver instances: nq = 3, t = 4, marked {3, 5}: P(round(M~) = 2) = 0.69; nq = 3, t = 3, marked {1}. */
#include <stdbool.h>
#include <math.h>

static int value(const bool x[], int nq) {
    int v = 0;
    for (int i = 0; i < nq; i++) v |= x[i] << i;
    return v;
}
static bool is_marked(int v, const int *marked, int nmark) {
    for (int k = 0; k < nmark; k++)
        if (v == marked[k]) return true;
    return false;
}
__attribute__((noinline)) static void grover(bool x[], int nq, const int *marked, int nmark) {  /* G = A R A^dag O */
    if (is_marked(value(x, nq), marked, nmark)) cq_phi(M_PI);    /* O */
    for (int i = 0; i < nq; i++) cq_theta(&x[i], -M_PI / 2);    /* A^dag */
    if (value(x, nq) != 0) cq_phi(M_PI);                         /* R */
    for (int i = 0; i < nq; i++) cq_theta(&x[i], M_PI / 2);     /* A */
}
int qpe_counting(int nq, int t, const int *marked, int nmark) {
    bool c[t], x[nq];
    for (int j = 0; j < t; j++) c[j] = false;
    for (int i = 0; i < nq; i++) x[i] = false;
    for (int j = 0; j < t; j++) cq_theta(&c[j], M_PI / 2);      /* H^t */
    for (int i = 0; i < nq; i++) cq_theta(&x[i], M_PI / 2);     /* A */
    for (int j = 0; j < t; j++)                                 /* controlled G^(2^j) */
        for (int k = 0; k < (1 << j); k++)
            if (c[j]) grover(x, nq, marked, nmark);
    for (int j = t - 1; j >= 0; j--) {                          /* QFT^-1 without the final swaps */
        for (int k = t - 1; k > j; k--)
            if (c[k] && c[j]) cq_phi(-M_PI / (1 << (k - j)));
        if (c[j]) cq_phi(M_PI);
        cq_theta(&c[j], M_PI / 2);
    }
    int m = 0;
    for (int j = 0; j < t; j++) m |= (int)cq_measure(c[j]) << (t - 1 - j);
    return m;
}
