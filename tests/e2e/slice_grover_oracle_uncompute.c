/* slice_grover_oracle_uncompute.c — ⚠ THE OWNER'S OWN PROGRAM, TRACKED AT LAST.
 *
 * This is example/grover/grover_oracle_uncompute.c, verbatim except for the
 * `slice` wrapper. bd test_C_libtooling-5zwz records that `example/` is excluded
 * via .git/info/exclude, so NOTHING IN ANY GATE HAS EVER COMPILED IT — which is
 * how it came to be reported three times as "the script fails again" while no
 * suite could see it. It is committed here so that a regression is a red test
 * rather than an owner bug report.
 *
 * IT IS THE EXHIBIT FOR bd test_C_libtooling-fn1q, and at the start of the
 * 2026-09-24 session it sat behind THREE PredMux gates:
 *   E2-cycle     — the region lies inside the `for` loop        (increment 3)
 *   E4-gep       — `z[i]`/`p[i]`, classical tables at the loop counter (increment 4)
 *   E6-condtree  — `if (b0[i])`, the `_Bool` bank cell rail φ    (increment 5a)
 * All three now admit it.
 *
 * WHAT IT COMPILES TO, and every part of it is a shipped idiom: per trip a
 * controlled state prep (`icmp_slt_hl` flag -> `cqrt_x` bracket ->
 * `cqrt_ry_i1_controlled` -> `_unc` -> free), then the arm's chain hoisted and run
 * unconditionally on the ORIGINAL registers (`sub_i32_hl` / `add_i32_hl` with the
 * CLASSICAL table values in the `_hl` LITERAL slot), then two ordinary value
 * merges, each a CNOT-copy of the rail root onto a fresh ancilla, two X-bracketed
 * `cqrt_copy_i32_controlled` into a fresh |0> rail, the CNOT restored and the
 * ancilla freed at a proven |0>. No new runtime symbol.
 *
 * ⚠ THE LOOP STAYS ROLLED, and that is checked by more than this golden: the
 * lowered IR is K-INDEPENDENT at 117 lines for n = 3, 8, 64 and 1000 (measured
 * with the tables scaled to n — bumping `n` alone makes `z[i]` read out of bounds
 * and E4's proof then correctly refuses it, which is a probe bug and not a
 * K-dependence, bd `46oo`'s class).
 */
#include "CQ.h"

static int slice(void) {
    int Z = 5;
    int P = 0;
    int n = 3;
    int p[] = {3, 2, 1};
    int z[] = {1, 2, 3};
    bool b0[n];
    for (int i = 0; i < n; ++i) {
        if (Z >= z[i]) cq_theta(&b0[i], 0.5);
        if (b0[i]) {
            Z -= z[i];
            P += p[i];
        }
    }
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2])
         + cq_measure(Z) + cq_measure(P);
}

int main(void) { (void)slice(); return 0; }
