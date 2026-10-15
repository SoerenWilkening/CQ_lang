/* slice_rolled_dicke_n4.c — bd test_C_libtooling-01po.19 (S1-S7 + 01po.19.17,
   the in-loop eager uncompute). The reporter's general-N Dicke circuit
   (Bärtschi & Eidenbenz 2019), N=4 K=2, byte-identical below the comment to
   ~/Desktop/alg_test/dicke/dicke_n.c, ROLLED over one quantum array.

   Per trip m = 4, 3, 2: `q[m-1] ^= q[m-2]` lowers in place (`cqrt_cnot`, S5),
   `if (q[m-1]) cq_theta(&q[m-2], .)` is an in-place controlled Ry on a cell
   with a cell condition (S6), `q[m-1] ^= q[m-2]` undoes the CNOT; for l = 2
   (m >= 3) `s = 2*q[m-1] + q[m-l]` is built (select `%out` on a copy `%bf` of
   q[m-1], zext/or, `icmp eq 3`), drives the controlled Ry on q[m-1-l], and is
   reversed and freed INSIDE the trip, before the next in-place gate (per-cell
   exemption of 01po.19.17: the reads are provably different cells than the
   gates' targets in one activation, and the records are trip-local).

   ANALYTIC CHECK (scratch state-vector replay of THIS golden, regenerated
   2026-10-16 for bd dm7f.81; no simulator in the repo, owner decision
   2026-06-10): the final state of q[0..3] is
   |D^4_2> = (|0011> + |0101> + |0110> + |1001> + |1010> + |1100>) / sqrt(6):
   exactly these six strings, each amplitude +0.408248 (probability 1/6),
   every other amplitude 0, and every `cqrt_free` frees a |0> rail (stage 2b:
   6 of 6 frees verified). NO LITERAL RAILS REMAIN: since dm7f.81 the select's
   arm `2` is one `cqrt_xorc_i32_controlled(f, out, 2)` and its arm `0` emits
   no gate (and no ¬flag bracket); the two per-trip `selop` rails (|2>, |0>) of
   the previous golden are gone. Only the cells' four i1 rails stay allocated
   (the array's): 4 live qubits at the end, was 132; 8 `cqrt_alloc` calls, was
   12. The trace-only runtime measures 0, so the program prints 0000. */
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
