/* slice_control_cascade_two_bools_uncond.c — THE PLAIN-C TWIN (probe `m17`).

   The flagship with the `b1` prep made UNCONDITIONAL, so `clang -O1` leaves the
   select's condition as a bare `cq_theta_i1` CALL instead of a merge phi — i.e.
   byte for byte the value `emitInPlaceRotationRegion`'s M-beta RAUWs the owner
   file's phi to, one pipeline stage earlier.

   ⚠ THIS SLICE LOWERED ON THE FROZEN ORACLE ALREADY (28 lines, STRICT 2b clean),
   through the Rule-13-cleared r9e5 rail-root path and with NO Track M change at
   all. That is its entire purpose: it is the TWIN GATE. Its select half — from
   `cq_template_add_i32_hl` through the second `cqrt_free` — is byte-identical to
   the flagship's lines 17-26 modulo the handle numbering that the flagship's
   extra (cancelling) prep gate shifts. So the widening reached an EXISTING
   emitter rather than adding a second spelling of the merge.

   The difference from the flagship is exactly the anti-control: here the prep is
   unconditional (one `cqrt_ry_i1` on `h5`), there it is the negated controlled
   prep (`cqrt_ry_i1` + `cqrt_ry_i1_controlled`). Nothing else moves. */
int slice(void) {
    int a = 5;
    _Bool b0 = 0;
    _Bool b1 = 0;

    if (a >= 3){
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;

    b1 = cq_theta(b1, 0.5);
    if (b1) a -= 3;

    return (int) cq_measure(b0) + (int) cq_measure(b1) + cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
