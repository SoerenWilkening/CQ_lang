/* slice_control_stateprep_bool_under_int_compare_fused.c — bd
   `test_C_libtooling-rb9x`, increment R-1: a `_Bool` controlled STATE PREP under
   an `int` COMPARE condition, in a diamond `clang -O1` has FUSED so that the
   merge carries TWO phis.

       int   a  = 5;
       int   b0 = 0;
       _Bool b1 = 0;
       if (a >= 3) { cq_theta(&b0, 0.5); }   [a is classically 5 -> folded]
       if (b0 == 1) a -= 3;                      [the `a` mux]
       if (a >= 3) { cq_theta(&b1, 0.5); }   [the `_Bool` prep]

   ⚠ WHY THIS PROGRAM EXISTS AS A SLICE. It is the bd `rb9x` defect, and it was
   an OVER-DECLINE of a valid circuit (owner ruling 2026-09-11: *"our end-goal is
   to not decline any code that will lead to a valid quantum circuit"* — an
   over-decline is a DEFECT to remove, not a safety margin). Two shipped,
   independently Rule-13-cleared features collided:

     * bd `b6ap`'s multi-phi merge peel NORMALISES the `a` mux into a `select` on
       a CLONE of the region's own compare, so the fused diamond has the one
       merge phi `ControlDetect::soleMergePhi` can read; and
     * the drbq Inc-4 state-prep fence F2 (`f2SeedPinnedByLiveRegister`) read
       that clone as a live tainted `i1` PINNED to the seed on one branch edge,
       and declined `state prep seed is proven equal to the condition register`.

   Write `int b1` and it compiles (`probes/b_C_intb0_intb1.c`, 22 lines); write
   `_Bool b1` and it did not. R-1's repair is a RECORD (`TaintSet::PeelClones`,
   written where the clone is manufactured) consulted at F2's equality TEST, on
   the PREIMAGE ground: a value this pass MANUFACTURES did not exist in the
   module `clang` produced, so no source program can have passed it to the arm's
   `cq_theta` and there is no rival for F2 to protect against.

   READ THE GOLDEN LINE BY LINE (22 lines; MEASURED on the R-1 binary, not
   composed-and-committed):
      1  cqrt_alloc_i32(0) -> h0            — b0's rail
      2  cqrt_ry_i32(h0, 0.5)               — b0's own rotation (the `a>=3`
                                              guard was classically true, so
                                              `-O1` deleted that region)
      3  cq_template_icmp_eq_i32_hl(h0,1) -> h1    — the flag for `b0 == 1`
      4  cqrt_x(h1)                         — the prep fires on the FALSE edge
      5  cqrt_alloc_i1(0) -> h2             — the PREPPED `_Bool` rail
      6  cqrt_ry_i1_controlled(h1,h2,0.5)   — the arm, under the flag
      7  cqrt_x(h1)                         — the bracket closes
      8  cq_template_icmp_eq_i32_hl_unc(h1,h0,1)   — the flag's strip
      9  cqrt_free(h1)                      — a PROVEN-|0> free
     10  cq_template_icmp_eq_i32_hl(h0,1) -> h3    — the peeled mux's own flag
     11  cqrt_alloc_i32(0) -> h4            — the mux OUT-rail
     12  cqrt_alloc_i32(2) -> h5            — arm value `a = 2`
     13  cqrt_copy_i32_controlled(h3,h5,h4)
     14  cqrt_x(h3)
     15  cqrt_alloc_i32(5) -> h6            — straight-through value `a = 5`
     16  cqrt_copy_i32_controlled(h3,h6,h4)
     17  cqrt_x(h3)
     18  cq_template_icmp_eq_i32_hl_unc(h3,h0,1)
     19  cqrt_free(h3)
     20  cqrt_measure_i32(h0)
     21  cqrt_measure_i1(h2)                — the `_Bool` rail, at `i1` width
     22  cqrt_measure_i32(h4)

   ⚠ THE FREEZE (Rule 6), and it is what stage 2b witnesses here: `h2` is NEVER
   freed. `Ry(0.5)|0> != |0>`, so the prepped rail is LEFT ALLOCATED and measured;
   likewise the mux out-rail `h4` and its two operand rails `h5`/`h6`. The only
   two frees are the two condition flags, each preceded by its own `_unc` strip.
   STRICT stage 2b reports `10 rail mint(s) of which 10 left allocated, 4
   cqrt_free site(s): 4 verified, 0 violation(s), 0 unproven` — DOUBLE the six
   mints and two frees the trace shows, because `slice()` has external linkage
   and `-O1` ALSO inlines it into `main`, so the lowered module carries the
   stream twice while only `main`'s copy runs. Do not read that as six rails.

   ⚠ THE WITNESS IS A STATED REDUCTION, NOT A `compare_files` GATE. This golden
   is byte-identical to `probes/b_C_intb0_intb1.c`'s (the `int b1` twin that
   already compiled on the ORACLE) EXCEPT on the b1 rail, where
   `cqrt_alloc_i32(0)` / `cqrt_ry_i32_controlled` / `cqrt_measure_i32` become
   `cqrt_alloc_i1(0)` / `cqrt_ry_i1_controlled` / `cqrt_measure_i1`. Same shape,
   `i1` widths — which is exactly the claim "the width was the over-decline, not
   the circuit". The `int` twin is not committed as a slice (it has no defect to
   pin); the comparison is recorded in `trackR/IMPL_R1.md` §5.

   ⚠ WHAT A GREEN RUN HERE DOES **NOT** PROVE (Rule 2): the byte-diff proves every
   emitted symbol resolves and signature-matches and that the angles and seeds are
   the ones written; it does not prove the unitary. The unitary argument for this
   file is the state-prep one drbq Inc 4 cleared, unchanged — R-1 removed a
   collider from a fence, it did not add an emitter.

   The lit twins are `control_peel_stateprep_bool_seed_int_cond.ll` (this shape,
   stage-1 IR, with the full CHECK stream and the counts) and
   `control_peel_stateprep_bool_seed_true.ll` (the other seed edge). */
int slice(void) {
    int   a  = 5;
    int   b0 = 0;
    _Bool b1 = 0;
    if (a >= 3) { cq_theta(&b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { cq_theta(&b1, 0.5); }
    return cq_measure(b0) + (int) cq_measure(b1) + cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
