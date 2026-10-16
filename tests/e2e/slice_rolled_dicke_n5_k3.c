/* slice_rolled_dicke_n5_k3.c — bd test_C_libtooling-01po.19.34 (general K:
   a quantum-controlled region inside a NESTED classically-bounded loop). The
   reporter's general-N Dicke circuit (Bärtschi & Eidenbenz 2019) at N=5 K=3:
   the two #defines below select it, and everything after them is
   byte-identical to the reporter's dicke_n.c (and to slice_rolled_dicke_n4.c's
   body), ROLLED over one quantum array.

   Per outer trip m = 5, 4, 3, 2: `q[m-1] ^= q[m-2]` lowers in place
   (`cqrt_cnot`), `if (q[m-1]) cq_theta(&q[m-2], .)` is an in-place controlled
   Ry with a cell condition, and the CNOT is undone. For m >= 3 the INNER loop
   l = 2..min(3, m-1) runs (TWO trips at m = 5 and m = 4, one at m = 3): per
   inner trip `s = 2*q[m-1] + q[m-l]` is built (select `%out` on a copy `%bf`
   of q[m-1], zext/or, `icmp eq 3`), drives the controlled Ry on q[m-1-l], and
   is reversed and freed INSIDE that inner trip. Until 01po.19.34 the outer
   loop's quantum subloop kept the outer body unmarked and the module declined
   `control flow inside a loop body` (fixture
   railwindow_dicke_n5k3_nested_accept.ll).

   ANALYTIC CHECK (independent scratch state-vector replay of THIS golden; no
   simulator in the repo, owner decision 2026-06-10): the final state of
   q[0..4] is
   |D^5_3> = (|00111> + |01011> + |01101> + |01110> + |10011> + |10101>
              + |10110> + |11001> + |11010> + |11100>) / sqrt(10):
   exactly these ten strings, each amplitude +0.316228 (probability 1/10),
   every other amplitude 0, and every `cqrt_free` frees a |0> rail (30 dynamic
   frees; stage 2b: 6 of 6 free sites verified, 0 unproven). Only the five cell
   rails stay allocated (the array's). The trace-only runtime measures 0, so
   the program prints 00000. */
#define N 5
#define K 3
/* Dicke state |D^N_K> for arbitrary N, K — Bärtschi & Eidenbenz (2019).
 * Start |0^{N-K} 1^K>, then apply SCS_{m, min(K, m-1)} for m = N down to 2.
 * Qubits are q[0..N-1]; SCS_m acts on q[0..m-1] with q[m-1] as its last qubit. */
#include <stdio.h>
#include <math.h>

#ifndef N
#define N 4
#endif
#ifndef K
#define K 2
#endif

int main(void) {
    bool q[N];
    for (int i = 0; i < N; i++) q[i] = (i >= N - K);

    for (int m = N; m >= 2; m--) {
        int kk = K < m - 1 ? K : m - 1;

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

    for (int i = 0; i < N; i++) printf("%d", cq_measure(q[i]));
    printf("\n");
    return 0;
}
