/* slice_control_inplace_ry_bool_stateprep.c — the bd `drbq` Inc-4 controlled
   STATE PREP with its condition written as a bare `_Bool` REGISTER (bd
   `test_C_libtooling-l4x4` sub-increment l4x4.b).

       _Bool b = 0;  int r = 7;
       b = cq_theta(b, 0.5);
       if (b) { r = cq_theta(7, 0.9); }   [`r` is classically 7 here]

   The arm's `cq_theta` has a CLASSICAL arg-0, so the hoisted gate MINTS the rail
   it rotates (`cqrt_alloc_i32(7)`) inside this region's own stream — which is
   also why R4 and R6 are SKIPPED for this class: no pre-region SSA name for that
   rail exists, so there is no wire to intersect with the condition's and no
   record that could be read after the region. Disjointness is a property of
   CONSTRUCTION here rather than of a walk.

   READ THE GOLDEN LINE BY LINE:
     1  cqrt_alloc_i1(0)   -> h0     — `b`'s rail
     2  cqrt_ry_i1(h0, 0.5)          — `b`'s own rotation
     3  cqrt_alloc_i32(7)  -> h1     — the PREPPED rail: `int r = 7`
     4  cqrt_ry_i32_controlled(h0, h1, 0.9)   — the arm, on the register itself
     5  cqrt_measure_i1(h0)
     6  cqrt_measure_i32(h1)

   Note line 3 has NO unconditional `cqrt_ry` after it: the prepped rail is
   rotated ONLY under the control. And there is no free of h1 either — it is
   FROZEN by `ChainWalk::railCarriesControlledRotation` (a controlled gate's
   adjoint needs its control, and the control here is a live user register that
   is never stripped).

   THE WITNESS IS A STATED REDUCTION against the COMPARE twin
   `slice_control_inplace_ry_stateprep.expected.log`: delete the mint, the strip
   and the flag's `cqrt_free`, rename the flag handle to the condition register's,
   and account for the condition register being a `_Bool` rather than an `int`.
   No `compare_files` gate, deliberately — the two goldens differ by a reduction,
   so byte-identity would be a FALSE assertion (the drbq Inc-4 precedent).

   ⚠ A WRONG SEED IS INVISIBLE TO STAGE 2b: `free_pairing_check.py` classifies
   `cqrt_alloc_<W>` by SYMBOL NAME and never reads the seed argument. The seed is
   pinned by this golden and by F1 in `ArmClassify`, not by a green 2b. */
int slice(void) {
    _Bool b = 0;
    int   r = 7;
    b = cq_theta(b, 0.5);
    if (b) {
        r = cq_theta(7, 0.9);      /* CLASSICAL arg-0: a controlled STATE PREP */
    }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
