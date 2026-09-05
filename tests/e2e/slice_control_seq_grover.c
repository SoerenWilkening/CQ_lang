/* 3qlq Inc 1: migrated to register-free cq_phi -- every oracle / reflection arm's `q = cq_phi(q, PI)` -> `cq_phi(PI)`.

   FINDING (PRD S1, measured 2026-09-05 at HEAD 52d7764): the PRE-3qlq golden of
   this slice encoded a CONTROLLED TENSORED Rz, which is the IDENTITY on q --
   `cqrt_rz_<W>` is "Rz on each qubit", so the marked phase is (-1)^popcount(target)
   (= +1 for |5>) and a per-qubit diagonal gate FIXES |0..0>, so the |0> reflection
   can never put -1 there. Any claim in the prose below that the oracle marks |5>,
   or that the reflection reflects about |0>, was TRUE OF THE SOURCE and FALSE OF
   THE EMITTED CIRCUIT. It becomes true only from 3qlq Inc 1 on, where the phase is
   a BRANCH phase by kickback (rz_i1 on the minted flag), not a register Rz. The
   older prose is left verbatim rather than silently corrected; read it with this.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_seq_grover.c — bd hcrg e2e smoke: the CUSTOMER shape.
   One Grover iteration's worth of structure — state prep, an oracle, the
   inverse prep, and the reflection about |0> — i.e. TWO sequential
   tainted-condition regions with a NON-DIAGONAL gate (Ry) between them.

   SOURCE INTENT:
       S      q = cq_theta(q, 0.5); q += off;         state preparation
       O      if (q == 5) cq_phi(PI);          oracle: mark |5>
       S†     q -= off; q = cq_theta(q, -0.5);        un-prepare
       R0     if (q == 0) cq_phi(PI);          reflect about |0>
       M      measure q

   WHY THIS SLICE EXISTS BESIDE slice_control_seq_regions.c: that one is two
   adjacent diamonds on an untouched wire. This one puts real work BETWEEN the
   regions — a reversible sub, and an in-place Ry that ROTATES THE BASIS the
   second region's condition reads. Region 2's flag is minted from region 1's
   merge phi after region 1's emit has RAUW'd it to the live handle, so this is
   the shape where a stale flag would show up as a wrong unitary. The gate stream
   below is the byte-level record that region 1 is fully torn down — flag
   stripped and freed — before the sub, the Ry, and region 2's mint.

   WHY `off` IS `volatile`, and it is load-bearing (Rule 9): written as a literal
   pair, `q += 3; ... q -= 3;` is reassociated by clang -O1 and cancelled on the
   straight-through edge — the `+ 3` disappears into the compare (which becomes
   `icmp eq %q, 2`) and the `- 3` is SUNK INTO THE ORACLE ARM. MEASURED, this
   exact slice with literal 3s declines with
       cq controlled lowering: condition predates a non-diagonal gate
   at the folded `icmp eq i32 %1, 2`. (The neighbouring `arm rewrites a condition
   operand` string belongs to the SHORTER variant with no `cq_theta` after the
   sub — a different shape; an earlier draft of this comment named it here and
   was wrong. In a project whose defence is that decline messages are mirrored
   character-for-character, a rationale that names the wrong string is a defect.)
   Two volatile loads are two values LLVM cannot prove equal, so the pair
   survives canonicalization and reaches the pass as a real add/sub on the
   quantum register.

   NOT A FULL GROVER ITERATION — AND SINCE bd lom0 INCREMENT 4 THAT IS A CHOICE
   THIS SLICE MAKES, NOT A WALL IT HITS. Read the next two paragraphs as history.

   WHAT WAS TRUE UNTIL 2026-08-28. State prep is S = `Ry(0.5)` THEN `+ off`, so
   re-applying S means `q = cq_theta(q, 0.5); q += off;` — in THAT order the
   theta's arg-0 is the same wire the reflection's condition read,
   `wireGainsNonDiagonalGate` (then schedule-independent) saw it, and the region
   declined even though the flag was stripped and freed long before. MEASURED
   then (and re-measured after M-C batch 2b, unchanged at that point):
       q += off; q = cq_theta(q, 0.5);   ->  LOWERS
       q = cq_theta(q, 0.5); q += off;   ->  DECLINED
                                             "cq controlled lowering: condition
                                              predates a non-diagonal gate"

   WHAT CHANGED, 2026-08-28. Increment 4 made that walk POSITION-AWARE for a flat
   PHASE region that does not share its flag with a data use: a gate the region's
   entire emitted stream provably precedes (`DT.dominates(BI, T) &&
   !isPotentiallyReachable(T, BI)`) is harmless. BOTH spellings above now lower,
   and the full two-iteration program is the e2e customer
   tests/e2e/slice_control_grover_2iter.c. THIS SLICE IS DELIBERATELY LEFT AT THE
   ONE-REGION-PAIR SHAPE and its golden is byte-identical across Increment 4: its
   job is bd hcrg's SEQUENTIAL-REGION emission-ORDER claim, and a minimal witness
   for that claim is worth more than a second copy of the Grover customer.

   WHY THE `+ off` SPELLING ALWAYS LOWERED — and an earlier draft of this
   comment got the mechanism wrong, so read this instead of it. It used to say
   that spelling lowers "only because `cq_template_add_i32_hl` mints a FRESH handle, so the
   theta sits on a different wire". That was a claim about the LOWERED RAIL, and
   M-C falsified it: since batch 2b `q -= off` lowers IN PLACE, the S† theta acts
   on the very register the oracle's condition read — and the slice still lowers,
   byte-identically to the analysis's expectation.

   The real reason is that the accept/decline is decided by `ArmClassify` on
   PRE-LOWERING SSA, before `lowerRotations`/`lowerOps` have chosen a rail at all.
   `wireGainsNonDiagonalGate` walks `cq_phi`/`cq_theta` arg-0 hops; an ordinary
   `add`/`sub` result is a DISTINCT SSA value that the walk never crosses, so the
   theta's arg-0 is not on the condition's provenance wire. The rail the
   reassignment ends up on is chosen later and never feeds back into the decision.
   That the emitted circuit is nevertheless sound is visible in the golden rather
   than assumed: region 1's flag is `_unc`-stripped AND freed two lines before the
   `cqrt_addc_i32(h0, -3)` and the S† `cqrt_ry_i32(h0, -0x1p-1)`, so no record of
   the condition is live when the non-diagonal gate fires. (Generalising that
   observation into an accept predicate WAS bd lom0's job; Increment 4 did it,
   and the predicate is stated over IR POSITIONS rather than over rail identity —
   see ArmClassify::condWireDisposition.)

   Stopping here was NOT a workaround: `+off ∘ Ry` and `Ry ∘ +off` are different
   unitaries (Ry does not commute with the `+3` permutation), so the first
   spelling computes something that is not S. This slice stopped at the
   `q += off` half — the part of S that genuinely lowered — rather than reordering
   S to get past a guard, and it still stops there because that is the minimal
   sequential-region witness. The reordering trap itself has NOT gone away: it is
   still true that the two spellings are different circuits, and the reason to
   prefer one is the algorithm, never the guard. */
/* GOLDEN STATE AFTER M-C INCREMENTS 2a + 2b (bd test_C_libtooling-6uqc,
   2026-08-28). THIS GOLDEN IS THE FIX FOR bd test_C_libtooling-nepx, and the
   regeneration IS the fix — not a consequence of it.

   THE ONE-RAIL READING. Every one of the three reassignments in the source now
   lowers to the IN-PLACE `cqrt_addc_i32`, so NO ancestor rail is ever minted and
   the whole program runs on a single data register `h0`:

       cqrt_alloc_i32(0) -> h0            allocate the wire
       cqrt_ry_i32(h0, 0x1p-1)            S      : state prep
       cqrt_addc_i32(h0, 3)               S      : q += off, IN PLACE
       ... region 1 (the oracle) on h0, flag h1 + work rail h2, both freed ...
       cqrt_addc_i32(h0, -3)              S-dag  : q -= off, IN PLACE, NEGATED imm
       cqrt_ry_i32(h0, -0x1p-1)           S-dag  : the reflection's un-prep
       ... region 2 (reflect about |0>) on h0, flag h3 + work rail h4, freed ...
       cqrt_addc_i32(h0, 3)               re-prep
       cqrt_measure_i32(h0)

   `cqrt_alloc_i32` appears exactly three times — the wire and one work rail per
   region — and every `cqrt_free` pairs with one of the two flags or two work
   rails. There is NOTHING else allocated, so when the S-dagger `cqrt_ry_i32(h0,
   -0x1p-1)` fires there is no live entangled basis record of the wire beside it,
   and the reflection composition this slice exists to demonstrate is coherent.
   That is precisely the property bd nepx said the shipped golden did not have.

   WHAT CHANGED IN 2b, AND WHY IT IS THE LAST STEP. 2a converted the two `q +=
   off` sites and left the middle `q -= off` alone (batch 2a admitted `add`
   only), so ONE out-of-place `cq_template_sub_i32_hl(h0, 3) -> h3` still stood,
   keeping `h0` alive as a record while the S-dagger rotated `h3`. The slice and
   the golden both said nepx stayed open for exactly that reason. Batch 2b
   admits handle-LHS `sub`, emitting the SAME frozen `cqrt_addc_i32` with the
   immediate NEGATED in classical IR (`%cq_negimm = sub i32 0, %off`, which emits
   no trace line — the golden shows only the negated runtime value `-3`). The
   diff is: one `cq_template_sub_i32_hl` line removed, one `cqrt_addc_i32(h0,
   -3)` added, and every handle after it renumbered down by one because an
   allocation disappeared. Free and alloc COUNTS are unchanged.

   The disposition was approved on the analytic dephasing argument (owner ruling,
   bd nepx thread) rather than by a simulation — Rule 2 puts no simulator in the
   gate.

   Its sibling tests/e2e/slice_control_seq_regions.c is NOT affected and its
   golden is NOT regenerated — it has no chained theta and no out-of-place
   add/sub at all (bd nepx's own correction comment, 2026-08-27). MEASURED
   byte-identical across both increments. */
volatile int off = 3;

int slice(void) {
    int q = 0;
    q = cq_theta(q, 0.5);                    /* S  */
    q += off;
    if (q == 5) {                            /* O  */
        cq_phi(3.14159265358979323846);
    }
    q -= off;                                /* S† */
    q = cq_theta(q, -0.5);
    if (q == 0) {                            /* R0 */
        cq_phi(3.14159265358979323846);
    }
    q += off;
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
