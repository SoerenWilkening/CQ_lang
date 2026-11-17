#include <stdbool.h>
#include <math.h>
/* Simon's problem on nq input qubits (nq is a RUNTIME input, 1 <= nq <= 15), hidden s a RUNTIME parameter, s < 2^nq.
 * The oracle f(x) = x ^ (x_j ? s : 0), j the lowest set bit of s (j = 0 and f = identity for s = 0), satisfies
 * f(x) = f(x ^ s) and is 2-to-1 for s != 0. It is computed bit by bit INTO the output register y[nq].
 * H on the input register, oracle, H on the input register, measure x and y: every outcome m of x satisfies
 * m . s = 0 (mod 2) and is uniform over that subspace. Returns m | (f << 16). */
int simon(int nq, int s) {
    bool x[nq], y[nq];
    int j = s ? __builtin_ctz(s) : 0;
    for (int i = 0; i < nq; i++) { x[i] = false; cq_theta(&x[i], M_PI / 2); }
    for (int i = 0; i < nq; i++) y[i] = x[i] ^ (x[j] & ((s >> i) & 1));
    for (int i = 0; i < nq; i++) cq_theta(&x[i], -M_PI / 2);
    int m = 0, f = 0;
    for (int i = 0; i < nq; i++) m |= cq_measure(x[i]) << i;
    for (int i = 0; i < nq; i++) f |= cq_measure(y[i]) << i;
    return m | (f << 16);
}
