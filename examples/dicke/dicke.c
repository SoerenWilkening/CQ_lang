/* Dicke state preparation, Baertschi & Eidenbenz, "Deterministic Preparation of Dicke States" (2019).
 *
 *   dicke(n, k)   1 <= n <= DICKE_MAX_N, 0 <= k <= n; prepares |D^n_k>, the equal superposition of
 *                 the C(n, k) n-bit strings of weight k, measures it and returns the outcome, qubit i
 *                 in bit i (every weight-k string with probability 1 / C(n, k)), or -1 for
 *                 arguments out of range.
 *
 * Start from |0^(n-k) 1^k> (the k top qubits set), then apply the split-and-cyclic-shift unitaries
 * SCS_{m, min(k, m-1)} for m = n down to 2. SCS_{m,l} acts on q[m-1-l .. m-1]:
 *   one two-qubit block   CNOT(q[m-2] -> q[m-1]), CRy(q[m-1] -> q[m-2], 2 acos sqrt(1/m)), CNOT;
 *   blocks j = 2 .. l     CNOT(q[m-1-j] -> q[m-1]), CCRy(q[m-1], q[m-j] -> q[m-1-j], 2 acos sqrt(j/m)), CNOT.
 * In C a CNOT is `t ^= c`, a controlled Ry is a cq_theta under an `if` on the controls. Every angle
 * is classical; only the register is quantum.
 *
 * The register is a bool array, one qubit per element (see examples/README.md). */
#include <math.h>
#include <stdbool.h>

#define DICKE_MAX_N 31

/* SCS_{m,l} on q[0 .. m-1]. */
static void split_cyclic_shift(bool *q, int m, int l) {
    q[m - 1] ^= q[m - 2];
    if (q[m - 1])
        cq_theta(&q[m - 2], 2 * acos(sqrt(1.0 / m)));
    q[m - 1] ^= q[m - 2];

    for (int j = 2; j <= l; j++) {
        q[m - 1] ^= q[m - 1 - j];
        if (q[m - 1] && q[m - j])
            cq_theta(&q[m - 1 - j], 2 * acos(sqrt((double)j / m)));
        q[m - 1] ^= q[m - 1 - j];
    }
}

int dicke(int n, int k) {
    if (n < 1 || n > DICKE_MAX_N || k < 0 || k > n)
        return -1;

    bool q[DICKE_MAX_N] = {0};
    for (int i = n - k; i < n; i++)
        q[i] = 1;
    for (int m = n; m >= 2; m--)
        split_cyclic_shift(q, m, k < m - 1 ? k : m - 1);

    int result = 0;
    for (int i = 0; i < n; i++)
        result |= cq_measure(q[i]) << i;
    return result;
}

/* Entry points for `cqcheck user`: fixed sizes, so the checker samples only the qubits. */
int dicke_3_1(void) { return dicke(3, 1); }
int dicke_3_2(void) { return dicke(3, 2); }
int dicke_4_1(void) { return dicke(4, 1); }
int dicke_4_2(void) { return dicke(4, 2); }
