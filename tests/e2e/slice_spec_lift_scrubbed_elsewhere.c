/* slice_spec_lift_scrubbed_elsewhere.c — bd test_C_libtooling-d88e, the
   SPEC-CLASSICAL ACCEPT end to end (2-TU, run_slice_multi.sh; library TU
   spec_lift_classical_lib.c: `h(a, k) = k + 1`, with `a` stored to a volatile
   local since bd vsfp — an `a` with no uses is now dropped before the specializer
   ever sees the call, and this golden would scrub nothing; see the lib's header).

   `specialize()` DOES scrub here: `h`'s clone returns the classical `k + 1`, so
   `t` loses the conservative taint `propagate` gave it. But the one-register lift
   of `r = phi(q, cq_theta(q, .2))` is over `q`, a `cq_theta` result — a
   never-scrub keep root — so its recorded premise holds at FINAL taint and the
   re-ask (`declineFalsifiedMergePhiLifts`) must say nothing. The CORRECT circuit
   is the hand-inlined twin's (slice_spec_lift_scrubbed_elsewhere_twin.c, `int t =
   m + 1;`), and `e2e-spec-lift-scrubbed-elsewhere-twin-identical` pins the two
   goldens BYTE-IDENTICAL: Ry(.5) on `q`, Ry(.2) on the SAME handle, one
   measurement, `t` added as classical data (the clone emits no gate).

   ⚠ THAT GATE COMPARES TRACES ONLY (bd d88e Rule-13 r1B F-DB-6). This 2-TU side's
   `opt` stderr carries `cq rotation lowering: non-diagonal gate over a live
   derived record`, and the twin's does not: the classical-verdict clone call
   `__cq_q_h_01(h_q, m)` is classified as a RECORD by M-A's name-based
   `isCloneCallHop` although it returns plain data (the same misclassification
   makes stage 2b's census count a dirty template rail here). The warning is
   spurious on this stream, which is byte-identical to the twin's, and no gate in
   this family can see the difference. (bd vsfp removed the other half of bd hgwx's
   reading — M-C no longer counts a call that never reads `q` as a prior user of
   it, arm (d0) — and filed this one as bd jr8q.)

   `m` is `slice`'s parameter, passed `argc + 4` (argc = 1 under the harness, so
   m = 5 and the arm runs); `noinline` keeps `clang -O1` from folding the
   classical condition away (bd 46oo). `main` discards the result so the slice
   exits 0 under the harness's `pipefail`. */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int t = h(q, m);
    int r = q;
    if (m > 3) r = cq_theta(q, 0.2);
    return cq_measure(r) + t;
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
