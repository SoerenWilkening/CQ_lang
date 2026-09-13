/* slice_control_cascade_select_in_loop_outside_prep.c — a 4.4 DATA SELECT INSIDE
   a bounded loop whose condition is the merge phi of a prep region OUTSIDE it.
   bd `boi6` D-B / Track M, round-1 finding F-M6 (probe
   `r22_inloop_select_outside_prep.c`). DECLINED on the frozen ORACLE
   (`control flow` at the select); lowers ROLLED here.

   ⚠ WHY THIS IS ADMITTED WHILE `m30` IS NOT, because the two look alike.
   `m30` is the LOOP-CARRIED shape: its phi is a loop HEADER phi, the tainted
   value crosses iterations, and the LOOP LAYER declines it BEFORE detection runs
   (`cq loop lowering: loop-carried tainted value crosses iterations`) — a
   different cell, unchanged on both binaries. Here `b1`'s phi is defined OUTSIDE
   the loop and is LOOP-INVARIANT, so nothing crosses the back edge and the
   ordinary flat ladder applies.

   READ THE GOLDEN AS 1 + 3 x 12 + 4:
     1-6    the cascade prologue, ONCE, outside the loop — `b0`'s rail and Ry,
            then the `b1` prep as the Ry-additivity anti-control (`ry_i1(h1,.5)`
            then `ry_i1_controlled(h0,h1,-.5)`), then the a-mux's first two allocs.
     then   THREE identical 12-line iterations, each: a fresh |0> copy ancilla,
            `cnot(h1, bf)` reading the PREPPED REGISTER as a control, a fresh |0>
            out rail, the trip's `i` and the constant 5 as copy sources, the two
            X-bracketed `copy_i32_controlled`, the un-copy and ONE `cqrt_free`.
     last   the two register measurements.

   THE INVARIANTS, per iteration: `h1` is read ONLY at arg 0 of `cqrt_cnot` —
   never `cqrt_x`-bracketed, never freed (`Ry(t)|0> != |0>`, Rule 6) — and the
   trip's ancilla returns to `x ^ x = 0` before its free, so the ONE static free
   site is a proven-|0> one on every iteration.

   ⚠ ROLLED, NOT UNROLLED, and it is measured rather than asserted: the lowered
   IR is K-INDEPENDENT at 78 lines / 19 gate calls for BOTH `i < 3` and `i < 1000`
   (`clang -O1`, no `-g`). The trace below is 3 trips of a 12-line body against 6
   STATIC rail mints and ONE static `cqrt_free` site. Its hand-unrolled twin
   `..._unrolled_twin.c` must produce the IDENTICAL trace (`compare_files`), which
   is the only instrument this cell has — the loop twin matrix has no `_Bool`
   axis. */
int slice(void) {
    int a = 5; int acc = 0;
    _Bool b0 = 0;
    _Bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    for (int i = 0; i < 3; ++i) { int t = b1 ? i : 5; acc += cq_measure(t); }
    return (int) cq_measure(b0) + (int) cq_measure(b1) + acc;
}
int main(void) { (void) slice(); return 0; }
