/* slice_control_inplace_ry_bool_diamond.c — THE FLAGSHIP SHAPE of bd
   `test_C_libtooling-l4x4` sub-increment l4x4.b: the drbq Inc-1 control-in-place
   Ry arm with its condition written as a bare `_Bool` REGISTER instead of a
   compare.

       _Bool b = 0;  int r = 7;
       b = cq_theta(b, 0.5);
       r = cq_theta(r, 0.25);
       if (b) { r = cq_theta(r, 0.9); }

   `clang -O1` gives every natural `bool` spelling `br i1 %b` with NO COMPARE at
   all, and until l4x4.b every such program declined `bare i1 register condition`
   at `classifyArms`' first gate. The register IS the flag: `classifyArms` admits
   the rail leaf, runs PRD §13.3's rail ladder on it (tainted · not measured
   before the branch · the wire question), and `emitInPlaceRotationRegion` sets
   `Flag = Cond`.

   READ THE GOLDEN LINE BY LINE, against the analytic stream:
     1  cqrt_alloc_i1(0)   -> h0     — `b`'s rail, seeded from the classical 0
     2  cqrt_ry_i1(h0, 0.5)          — `b`'s own (UNCONTROLLED) rotation
     3  cqrt_alloc_i32(7)  -> h1     — `r`'s rail, a SECOND disjoint register
     4  cqrt_ry_i32(h1, 0.25)        — `r`'s own rotation
     5  cqrt_ry_i32_controlled(h0, h1, 0.9)
                                     — THE ARM, with the USER'S REGISTER h0 as
                                       the control. A read-only control is the
                                       one class of gate on a user register
                                       Inc 1b already emits (the 4.3 nest's node
                                       controls).
     6  cqrt_measure_i1(h0)          — `b`
     7  cqrt_measure_i32(h1)         — `r`

   ⚠ WHAT IS **NOT** THERE IS THE WHOLE INCREMENT. No `cq_template_icmp_*_hl`
   (nothing is minted — the register is its own flag), no `_hl_unc` (nothing to
   strip), NO `cqrt_free` AT ALL, no `cqrt_x`, no route, no work rail.

   THE WITNESS IS A STATED REDUCTION, NOT A `compare_files` GATE, and it is the
   drbq Inc-4 precedent: the two goldens differ by a REDUCTION, so a byte-identity
   gate would assert something FALSE. Against the COMPARE twin
   `slice_control_inplace_ry.expected.log` (committed, `q == 5` instead of `b`),
   this golden is that file with THREE LINES DELETED and ONE RENAME:

       delete  cq_template_icmp_eq_i32_hl(h0, 5) -> h2      (the mint)
       delete  cq_template_icmp_eq_i32_hl_unc(h2, h0, 5)    (the strip)
       delete  cqrt_free(h2)                                (the flag's free)
       rename  h2 -> h0   in the controlled gate's arg 0

   plus the difference in the condition register's own type and rotation
   (`alloc_i32(3); ry_i32(h0, 0.5)` becomes `alloc_i1(0); ry_i1(h0, 0.5)`,
   because `b` is a `_Bool`). Ten trace lines become seven. A reviewer can
   re-derive that from two files in the tree.

   ⚠ WHAT THE GOLDEN DOES NOT WITNESS. No trace label answers a STATE question,
   so "h0 is still coherent when the controlled gate fires" is invisible to it;
   and `free_pairing_check.py` (stage 2b, STRICT here) witnesses rail PAIRING,
   not `|0⟩`-ness. The reason h0 is never freed is Rule 6 and is argued in the
   emitter, not measured here: after `Ry(0.5)|0⟩` the register is not `|0⟩`, so a
   free would be a hidden measurement. It is LEFT ALLOCATED — the same
   Rule-6-safe leak the compare form already gives its own condition register. */
int slice(void) {
    _Bool b = 0;
    int   r = 7;
    b = cq_theta(b, 0.5);          /* the CONDITION register — its own flag    */
    r = cq_theta(r, 0.25);         /* a SECOND, disjoint rail                  */
    if (b) {                       /* `br i1 %b` — NO compare, NO mint         */
        r = cq_theta(r, 0.9);      /* the arm Ry — CONTROLLED and IN PLACE     */
    }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
