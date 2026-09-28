/* slice_spec_clone_consumer_after_ry.c — bd test_C_libtooling-kyy1 (bd rhk5 round 2;
   Rule-13 r1B F-r1B-1, probe `b2n`). 2-TU, run_slice_multi.sh; library TU
   spec_dropped_arg_lib.c: `h(a, k) = k + 1`.

   `u` is DEAD after the kickback; `p` is read by the clone call AFTER the second Ry,
   so `p` is the program's own record across that Ry and must stay allocated. The
   pre-rhk5 compiler discharges `u` at the flag strip, before the Ry — and so does
   this golden. Round 1 of bd rhk5 LOST that discharge (clause (b′) made `p` interior,
   merged `p` and `u` into one M-B component anchored after the clone call, i.e.
   after the Ry, and clause (d) then refused the whole component; `u` stood entangled
   with `q` across the Ry — `x ↦ (x&3, x+(x&3))` is injective, so `q` fully dephased,
   warned). Round 2 plans such a component both ways and never discharges less than
   the pre-rhk5 planner.

   THE GOLDEN IS BYTE-IDENTICAL TO THE ORACLE'S TRACE (main 9a230646; measured,
   TRACK_RHK5.md round 2). There is deliberately no `*-twin-*` gate: the
   hand-inlined twin (`s = p + 1`) leaks `u` the same way on EVERY binary — `p` is
   interior there through a template consumer — a PRE-EXISTING M-B granularity
   defect that stays filed under bd `kyy1`. `m = argc + 4 = 5` (bd 46oo). */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m & 7, 0.5);
    int p = q & 3;
    int u = p + q;
    if (u == 10)
        cq_phi(3.14159);
    int q2 = cq_theta(q, 0.7);
    int s = h(m, p);
    return cq_measure(s) + cq_measure(q2);
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
