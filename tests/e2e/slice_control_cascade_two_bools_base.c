/* slice_control_cascade_two_bools_base.c — THE DISCRIMINATOR.

   `slice_control_cascade_two_bools.c` with the owner's line 99 (`if (b1) a -= 3;`)
   REMOVED, and nothing else changed. It ACCEPTED BEFORE bd `boi6` D-B / Track M
   and it must keep emitting the IDENTICAL 19 lines after it: this slice is the
   program one construct away from the widening, and its job is to prove the
   widening did not disturb it.

   ⚠ ITS GOLDEN IS ALSO THE FIRST 16 LINES OF THE FLAGSHIP'S, BYTE FOR BYTE (the
   last three lines here are the measurements, which move to 27-29 there). That
   is the strongest available statement of "an ACCEPT, not a STREAM": adding a
   consumer of `b1` changed nothing about how `b0`, `b1` and the `a`-mux are
   emitted. If these two goldens ever disagree on lines 1-16, one of them is
   wrong — re-derive BOTH from the pass output rather than editing either to
   match (L8). */
int slice(void) {
    int a = 5;
    _Bool b0 = 0;
    _Bool b1 = 0;

    if (a >= 3){
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;

    if (a >= 3){
        b1 = cq_theta(b1, 0.5);
    }

    return (int) cq_measure(b0) + (int) cq_measure(b1) + cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
