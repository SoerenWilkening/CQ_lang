/* slice_railbank_flat_twin.c — THE FLAT TWIN of the rail-bank accept, and the
   BYTE-IDENTITY PARTNER `SCOPE_L1a.md` §5 asked the capability to carry.
   bd `xdu2` / L-1a Increment W1, the SECOND HALF (Track B, session 2026-09-15).

   Three SCALAR `_Bool`s, an unconditional prep on each, three measurements — no
   array, no bank, no memory anywhere.  It compiled on the PRE-W1 binary and its
   stream is unchanged by this increment; that is exactly what makes it a
   reference rather than a second copy of the subject.

   ⚠ THE GATE IS `e2e-railbank-flat-twin-identical`, a `compare_files` of this
   golden against `slice_railbank_bool_prep_measureloop.expected.log`.  EVERY
   TRIP IS IDENTICAL BY CONSTRUCTION in both programs, which is the property
   `SCOPE_L1a.md` §5 says a byte-identity gate must be built on — so the
   comparison is meaningful rather than coincidental.  What it witnesses: the
   rail bank emits the SAME CIRCUIT as three scalar registers, with the same
   angles, the same order and the same three measurements.  What it cannot
   witness (Rule 2): that the circuit is the right unitary.

   ⚠ It also cannot witness rail IDENTITY — that is stage 2b's, and the two
   programs differ there by construction (three alloc SITES here, one rolled
   site per function in the bank).  Do not read the byte identity as a claim
   about the rails; read it as a claim about the emitted stream.

   SOURCE: `…/session-2026-09-14c-xdu2-w1/trackI/probes/w1_flat_prep_only.c`,
   code body verbatim. */
#include "CQ.h"

int slice(void) {
    _Bool b0 = 0, b1 = 0, b2 = 0;
    b0 = cq_theta(b0, 0.5);
    b1 = cq_theta(b1, 0.5);
    b2 = cq_theta(b2, 0.5);
    return (int) cq_measure(b0) + (int) cq_measure(b1) + (int) cq_measure(b2);
}

int main(void) { (void) slice(); return 0; }
