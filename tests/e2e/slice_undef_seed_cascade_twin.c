/* slice_undef_seed_cascade_twin.c — bd z9t1 (owner ruling 2026-09-14). THE
   TWIN THAT MAKES THE RULE A MEASUREMENT INSTEAD OF A CLAIM.

   It is `slice_control_cascade_two_bools.c` — the owner's 2026-09-13 cascade,
   which the session before this one landed — with ONE TOKEN CHANGED:

       _Bool b1 = 0;      ->     _Bool b1;

   Nothing else differs, not a space. On the 2026-09-13 oracle that single
   deletion turned an accepted 29-line program into a LOUD DECLINE
   (`cq controlled lowering: state prep seed does not match the merge incoming`,
   F1's first sub-clause: an `UndefValue` seed is neither a `ConstantInt` nor a
   `ConstantFP`). With the z9t1 rule the two programs compile to the SAME
   CIRCUIT, and `e2e-undef-seed-cascade-twin-identical` byte-diffs this golden
   against `slice_control_cascade_two_bools.expected.log` to say so — 29 = 29.

   *** WHY THE TWIN AND NOT JUST A GOLDEN. *** A golden of its own would only
   record whatever stream this compiler happens to emit; it cannot say the stream
   is RIGHT. The twin says something a golden cannot: an uninitialized `_Bool`
   prepared under control gets the circuit the INITIALIZED program already had —
   the one that was reviewed, Rule-13-cleared and shipped — so the rule adds an
   ACCEPT and not a stream. That is the same argument the shipped
   `e2e-measure-classical-bool-twin-identical` and the 34 `*-twin-identical`
   gates make, and it is the only form of evidence available here (Rule 2: no
   simulator; the byte-diff proves the symbols resolve, the TWIN proves the
   circuit did not move).

   ⚠ RETIREMENT TRIGGER: if the cascade's stream ever legitimately changes, BOTH
   goldens move together and this gate stays green — that is the point. If only
   ONE moves, the rule has started emitting a different circuit for an
   uninitialized seed than for `= 0`, which is a defect, not a baseline to
   regenerate.

   Probe of record: `$SES/trackU/probes/u5.c` (DIAG_2026-09-14.md Q2 row v),
   measured byte-identical to the cascade golden before this file was written. */
#include "CQ.h"

int slice(void) {
    int a = 5;
    _Bool b0 = 0;
    _Bool b1;

    if (a >= 3){
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;

    if (a >= 3){
        b1 = cq_theta(b1, 0.5);
    }
    if (b1) a -= 3;

    return (int) cq_measure(b0) + (int) cq_measure(b1) + cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
