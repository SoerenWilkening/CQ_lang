/* slice_control_cascade_select_in_loop_outside_prep_unrolled_twin.c — the
   HAND-UNROLLED twin of `..._outside_prep.c`, written by a programmer instead of
   rolled by the compiler. Same program, three explicit trips.

   THE GATE (`e2e-cascade-select-in-loop-twin-identical`): the two goldens must be
   BYTE-IDENTICAL. The rolled form emits the loop body ONCE and executes it three
   times; the unrolled form emits three copies executed once each. If the rolled
   lowering ever mints something per-iteration that it should hoist, drops a gate
   on the back edge, or reuses an ancilla across trips, the traces diverge.

   ⚠ IT IS AN INTERNAL-CONSISTENCY GATE, NOT AN ORACLE GATE: both halves need bd
   `boi6` D-B to lower at all (the frozen ORACLE declines both with `control flow`
   at the first select). Labelled as such here and in the CMake comment, per the
   l4x4 precedent. It is nevertheless the ONLY instrument for this cell — the
   loop twin matrix has no `_Bool` axis. */
int slice(void) {
    int a = 5; int acc = 0;
    _Bool b0 = 0;
    _Bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    { int t = b1 ? 0 : 5; acc += cq_measure(t); }
    { int t = b1 ? 1 : 5; acc += cq_measure(t); }
    { int t = b1 ? 2 : 5; acc += cq_measure(t); }
    return (int) cq_measure(b0) + (int) cq_measure(b1) + acc;
}
int main(void) { (void) slice(); return 0; }
