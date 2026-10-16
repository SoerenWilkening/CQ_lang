/* slice_rolled_dicke_n6_k3.c — bd test_C_libtooling-01po.19.34 (general K,
   R11 round 1 C-F2): the reporter's general-N Dicke circuit at N=6 K=3. The
   two #defines select it; everything after them is byte-identical to the
   reporter's dicke_n.c, ROLLED over one quantum array, the inner `l` loop a
   real subloop of the `m` loop.

   It exists because slice_rolled_dicke_n5_k3 has only ONE outer trip (m = 4)
   whose two inner trips both rotate. Here, per outer trip, the controlled Rys
   (2-qubit block, inner l = 2, inner l = 3) fire as follows (replay: a control
   nonzero on some branch of the state):
     m = 6: never, never, fires     m = 5: never, fires, fires
     m = 4: fires, fires, fires     m = 3: fires, fires     m = 2: fires
   9 of the 12 rotations act, and m = 5 and m = 4 both run TWO inner trips with
   firing rotations, each inner trip's s-chain reversed and freed inside it.

   ANALYTIC CHECK (independent scratch state-vector replay of THIS golden; no
   simulator in the repo, owner decision 2026-06-10): the final state of
   q[0..5] is |D^6_3>: exactly the twenty weight-3 strings, each amplitude
   +0.223607 (1/sqrt(20)), every other amplitude 0; every `cqrt_free` frees a
   |0> rail (42 dynamic frees; stage 2b: 6 of 6 free sites verified, 0
   unproven). Only the six cell rails stay allocated. The trace-only runtime
   measures 0, so the program prints 000000. */
#define N 6
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
