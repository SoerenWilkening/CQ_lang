/* slice_control_inplace_ry_bool_negated_twin.c — THE MANUAL TWIN of
   `slice_control_inplace_ry_bool_negated.c`: the SAME circuit, spelled by hand as
   an unconditional rotation plus a cancelling one under the un-negated
   condition.

       r = cq_theta(r, 0.9);              [fires on BOTH branches]
       if (b) { r = cq_theta(r, -0.9); }  [cancels it when b = 1]

   `Ry(0.9)·Ry(-0.9) = I`, so this program and its subject compute the same
   unitary; the gate to check (`e2e-inplace-ry-bool-negated-twin-identical`) is
   that they also emit the same GATE STREAM, byte for byte.

   ⚠ IT IS AN INTERNAL-CONSISTENCY GATE. Both halves need l4x4.b to lower at all
   (the condition is a bare rail in both), so this pair is not an oracle
   comparison against an older compiler — it is the statement that the compiler's
   anti-control and the programmer's own cancellation agree. The ORACLE
   comparison for the un-negated shape is the stated reduction in
   `slice_control_inplace_ry_bool_diamond.c`'s header.

   The un-negated `if (b)` here is NOT an accident of convenience: it is what
   makes the twin exercise the ordinary rail accept path, so the only thing
   differing between the two programs is which of them the COMPILER had to
   synthesize. */
int slice(void) {
    _Bool b = 0;
    int   r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    r = cq_theta(r, 0.9);          /* the unconditional half, by hand          */
    if (b) {
        r = cq_theta(r, -0.9);     /* the cancellation, by hand                */
    }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
