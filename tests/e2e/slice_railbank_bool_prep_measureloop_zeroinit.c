/* slice_railbank_bool_prep_measureloop_zeroinit.c — THE D1 / R2 TWIN.
   bd `xdu2` / L-1a Increment W1, the SECOND HALF (Track B, session 2026-09-15).

   A bounded rail BANK: a local `bool` array whose cells each hold one quantum
   rail, written once per trip of a classically-bounded loop and read back after
   it.  Until 2026-09-15 this program declined
       cq taint escape: tainted value stored to memory
   at every N — the ONE wall bd `xdu2` exists to remove.

   ⚠ WHAT THE GOLDEN IS FOR, AND WHAT IT STRUCTURALLY CANNOT SEE.  The three
   `cqrt_measure_i1` lines are the point of this file.  With the type rewrite and
   the D5 allow-list but WITHOUT the taint rule, this exact program gives `opt`
   exit 0, STRICT stage 2b `0 violation(s), 0 unproven`, and a plausible SIX-line
   trace — the three `cq_measure(b0[i])` calls emitting NOTHING, because
   `MeasureLowering`'s classical split on an UNTAINTED operand emits no gate, no
   symbol and no trace line.  A GOLDEN BYTE-DIFF CANNOT SEE A MEASUREMENT THAT
   WAS NEVER EMITTED.  This golden can only see it because the three lines are
   IN it; that is why the three W1 pieces are one commit and not three.

   ⚠ STAGE 2B COUNTS `cqrt_alloc` SITES, NOT DYNAMIC MINTS, so the ROLLED per-trip
   allocation reads as ONE rail PER SITE.  MEASURED here: `2 rail mint(s) of
   which 2 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s),
   0 unproven` — TWO because `-O1` keeps both `@slice` (external linkage) and the
   copy it inlines into `@main`, each with one rolled site; the RUN emits three
   rails from one of them.  The rails are LEFT ALLOCATED on purpose: a measured
   rail gets no adjoint and no free (Rule 6), exactly as the flat twin's do.

   ⚠ THIS IS THE ZERO-INIT HALF OF THE D1 / R2 TWIN.  Its partner
   `slice_railbank_bool_prep_measureloop.c` writes `bool b0[3];` with no
   initializer; this one writes `= {0}`.  Owner ruling D1 admits the
   uninitialised spelling by C6 TOTALITY alone, and the byte-identity of the two
   TRACES is what makes that a measurement rather than an assertion — gated by
   `e2e-railbank-uninit-zeroinit-twin-identical`.
   The original note, verbatim:
   ⚠ THE BANK IS UNINITIALISED and that is owner ruling D1, carried by C6
   TOTALITY alone — NOT by bd `z9t1`, whose `normalizeUndefRotationSeed` does not
   reach a MEMORY seed.  The obligation that the uninitialised and written-`= {0}`
   spellings emit the same stream is discharged by
   `e2e-railbank-uninit-zeroinit-twin-identical` beside this entry, on the
   TRACES — the zero-init twin carries an extra `llvm.memset` that an IR diff
   would report and a trace cannot see.  MEASURED: byte-identical, equal sha256.

   ⚠ AND THE STREAM BELOW IS BYTE-IDENTICAL TO THE FLAT TWIN'S.  Track I's
   `w1_flat_prep_only.c` — three scalar `_Bool`s, three preps, three measures,
   no array anywhere — produces exactly these 9 lines on the pre-W1 binary.  The
   bank reproduces them at identical trip count, which is the byte-identity
   witness `SCOPE_L1a.md` §5 asked the capability to carry. */
#include "CQ.h"

int slice(void) {
    bool b0[3] = {0};
    int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}

int main(void) { (void) slice(); return 0; }
