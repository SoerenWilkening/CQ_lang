/* slice_control_inplace_ry_loop_derived.c — the in-loop Ry arm under a DERIVED condition
   (`(q & 6) == 4`).

   THE PREDICATE IS `(q & 6) == 4`, AND IT IS THE THIRD ONE TRIED — MEASURE, NEVER
   ASSUME (the DER lesson; PRD §13.8 demanded a SATISFIABLE predicate and that turned
   out to be necessary but not sufficient). `q * 3 == 5` is unsatisfiable under `nsw`
   and `clang -O1` DELETES the region outright. `q * 3 == 6` IS satisfiable and still
   fails: `-O1` canonicalizes it to `icmp eq i32 %q, 2` and the `mul` is gone, so the
   slice would have tested a DIRECT condition while claiming a derived one — a
   vacuous accept that looks exactly like a capability. `(q & 6) == 4` survives as a
   real `and` + `icmp` pair, so the golden below genuinely carries
   `cq_template_and_i32_hl` and its in-body `_unc` + `cqrt_free`.

   WHAT ONLY THIS SLICE CAN SEE. The derived condition mints a TEMPLATE RAIL inside
   the body, one per activation. It lives on `q`'s rail, which carries NO
   controlled rotation (R4 guarantees it), so it is NOT frozen and must still be
   uncomputed and freed IN BODY every trip — the discharge `markIfRailLocal` grants
   the spine. If that marking is ever lost, the rolled trace leaks one rail per trip
   while the hand-unrolled twin discharges its own, and the twin `cmp` is what says
   so. The golden must show `cq_template_mul_i32_hl_unc` + `cqrt_free` of the
   derived rail once per activation.

   THE POINT OF THIS SLICE IS THE TWIN. Its golden must be BYTE-IDENTICAL to
   slice_control_inplace_ry_loop_derived_unrolled.expected.log, which is the SAME body written out
   with no loop at all — the flat shape Increment 1 shipped and an adversarial
   round already cleared. Byte-identity is the strongest witness available to a
   project with no simulator (Rule 2): it says the ROLLED form emits the same
   unitary, gate for gate and handle for handle. The `cmp` is wired into ctest
   (e2e-inplace-ry-loop-derived-twin-identical), so the two cannot drift apart silently.

   ⚠ THE MATRIX'S OWN BLIND SPOT APPLIES HERE TOO AND IS WORTH QUOTING WITH IT:
   the oracle IS the Increment-1 flat lowering, so a defect the flat and rolled
   paths SHARE (a wrong controlled-rotation polarity, a missed R4 aliasing, a
   freeze that should have fired on both sides) is byte-identical on both and this
   gate reports success. The flat side's own witnesses are the Inc-1 lit family and
   tests/e2e/slice_control_inplace_ry.c; nothing here replaces them.

   STRICT stage 2b (no `--allow-unproven`): the flag is the region's only ancilla
   and it is minted, stripped and freed inside its own iteration, so nothing dirty
   crosses the back edge. The rotated register is FROZEN by Increment 1's
   structural freeze — never reverse-played, never freed — and is left allocated,
   which is Rule 6's sanctioned fallback and is identical in the twin. */

int slice(void) {
    int q = 0;
    int r = 7;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);

    for (int i = 0; i < 2; ++i) {
        if ((q & 6) == 4) {
            r = cq_theta(r, 0.9);
        }
        q = cq_theta(q, 0.1);
    }

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
