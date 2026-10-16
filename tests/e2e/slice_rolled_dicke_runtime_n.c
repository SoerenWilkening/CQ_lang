/* slice_rolled_dicke_runtime_n.c — bd test_C_libtooling-01po.19.19 (runtime-N
   Dicke: VLA `bool q[n]`, runtime trip counts, a nested runtime `l` loop).
   Byte-identical below this comment to the reporter's dicke_rt.c. `dicke` is a
   separate function with RUNTIME n and k; the harness runs the program with no
   arguments, so main calls dicke(4, 2).

   The array is one rail window over the VLA (cells allocated by a runtime walk
   at the quantization point). Per outer trip m = 4, 3, 2: in-place `cqrt_cnot`,
   the cell-conditioned controlled Ry, the undoing CNOT; for m >= 3 the inner
   runtime loop l = 2..min(2, m-1) builds `s = 2*q[m-1] + q[m-l]`, drives the
   controlled Ry on q[m-1-l] and reverses and frees the s-chain inside the inner
   trip. Until 01po.19.19/.34 the nested runtime loop declined `control flow
   inside a loop body` (fixture railwindow_dicke_runtime_n_accept.ll, formerly
   _pending).

   ANALYTIC CHECK (independent scratch state-vector replay of THIS golden; no
   simulator in the repo, owner decision 2026-06-10): the final state of
   q[0..3] is
   |D^4_2> = (|0011> + |0101> + |0110> + |1001> + |1010> + |1100>) / sqrt(6):
   exactly these six strings, each amplitude +0.408248, every other amplitude
   0, and every `cqrt_free` frees a |0> rail (12 dynamic frees; stage 2b: 6 of
   6 free sites verified, 0 unproven). Only the four cell rails stay allocated.
   The same binary run with 1..3 extra arguments (n = 5..7), and the k = 3
   variant, replay to |D^n_k> exactly (scratch, not pinned here). The
   trace-only runtime measures 0, so dicke returns 0. */
/* dicke_n.c with RUNTIME n, k (VLA bool q[n]): the owner's runtime-N scope. */
#include <stdio.h>
#include <math.h>

int dicke(int n, int k) {
    bool q[n];
    for (int i = 0; i < n; i++) q[i] = (i >= n - k);

    for (int m = n; m >= 2; m--) {
        int kk = k < m - 1 ? k : m - 1;
        q[m - 1] ^= q[m - 2];
        if (q[m - 1]) cq_theta(&q[m - 2], 2.0 * acos(sqrt(1.0 / m)));
        q[m - 1] ^= q[m - 2];
        for (int l = 2; l <= kk; l++) {
            q[m - 1] ^= q[m - 1 - l];
            int s = 2 * q[m - 1] + q[m - l];
            if (s == 3) cq_theta(&q[m - 1 - l], 2.0 * acos(sqrt((double)l / m)));
            q[m - 1] ^= q[m - 1 - l];
        }
    }
    int r = 0;
    for (int i = 0; i < n; i++) r = 2 * r + cq_measure(q[i]);
    return r;
}

int main(int argc, char **argv) { return dicke(argc + 3, 2); }
