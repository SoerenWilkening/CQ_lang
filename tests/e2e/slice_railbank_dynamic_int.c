/* slice_railbank_dynamic_int.c — bd test_C_libtooling-xdu2.4.
 *
 * C-level red/green witness for a runtime-sized stack rail bank.  `argc` keeps
 * `n` genuinely dynamic in the -O1 IR; the harness's ordinary no-extra-argument
 * invocation takes the deterministic n=1 path.  The n<=0 branch preserves the
 * C VLA source precondition deliberately: the VLA is formed only when n>0.
 *
 * The cells are `int`, whose i32 storage already is the runtime handle ABI.
 * This increment must not claim `_Bool b[n]` (dynamic i8 storage needs a
 * separate rewrite), must not mint any cqrt_qram_* operation, and must leave the
 * parked cell rails allocated for their explicit measurements.  The companion
 * classical `p[n]` / `z[n]` arrays preserve the primary Grover arm: `p[i]` is
 * speculated only after its runtime extent is proved equal to the exact loop
 * trip count, while `z[i]` is loaded before quantum control.
 */
#include "CQ.h"

__attribute__((noinline)) static void run_bank(int n) {
    if (n <= 0) return;

    int p[n];
    int z[n];
    for (int i = 0; i < n; ++i) {
        p[i] = i + 3;
        z[i] = i + 2;
    }

    int b[n];
    int P = 0;
    int Z = 4 * n;
    for (int i = 0; i < n; ++i) {
        if (Z >= z[i]) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) {
            P += p[i];
            Z -= z[i];
        }
    }
    for (int i = 0; i < n; ++i) (void)cq_measure(b[i]);
    (void)cq_measure(P);
    (void)cq_measure(Z);
}

int main(int argc, char **argv) {
    (void)argv;
    run_bank(argc - 1);  /* zero-trip control under the normal argc=1 run */
    run_bank(argc);      /* nonzero runtime-sized bank under the same run */
    return 0;
}
