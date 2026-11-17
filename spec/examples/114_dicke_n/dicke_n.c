/* Dicke state |D^n_k> for runtime n, k, Bärtschi & Eidenbenz (2019): start |0^{n-k} 1^k>, then SCS_{m, min(k, m-1)}
 * for m = n down to 2. Qubits q[0..n-1] in a runtime-sized register; SCS_m acts on q[0..m-1] with q[m-1] as its last
 * qubit. Plain C gates as in 113 (the fixed-size N = 4, K = 2 instance). The result is the measured bits, q[0] in
 * bit 0 (n <= 31). */
#include <math.h>
int dicke_n(int n, int k) {
    bool q[n];
    for (int i = 0; i < n; i++) q[i] = (i >= n - k);
    for (int m = n; m >= 2; m--) {
        int kk = k < m - 1 ? k : m - 1;
        /* 2-qubit block on (q[m-2], q[m-1]) */
        q[m - 1] ^= q[m - 2];
        if (q[m - 1]) cq_theta(&q[m - 2], 2.0 * acos(sqrt(1.0 / m)));
        q[m - 1] ^= q[m - 2];
        /* 3-qubit blocks l = 2..kk on (q[m-1-l], q[m-l], q[m-1]) */
        for (int l = 2; l <= kk; l++) {
            q[m - 1] ^= q[m - 1 - l];
            int s = 2 * q[m - 1] + q[m - l];
            if (s == 3) cq_theta(&q[m - 1 - l], 2.0 * acos(sqrt((double)l / m)));
            q[m - 1] ^= q[m - 1 - l];
        }
    }
    int r = 0;
    for (int i = 0; i < n; i++) r |= cq_measure(q[i]) << i;
    return r;
}
