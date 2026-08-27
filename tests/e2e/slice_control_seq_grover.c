/* slice_control_seq_grover.c — bd hcrg e2e smoke: the CUSTOMER shape.
   One Grover iteration's worth of structure — state prep, an oracle, the
   inverse prep, and the reflection about |0> — i.e. TWO sequential
   tainted-condition regions with a NON-DIAGONAL gate (Ry) between them.

   SOURCE INTENT:
       S      q = cq_theta(q, 0.5); q += off;         state preparation
       O      if (q == 5) q = cq_phi(q, PI);          oracle: mark |5>
       S†     q -= off; q = cq_theta(q, -0.5);        un-prepare
       R0     if (q == 0) q = cq_phi(q, PI);          reflect about |0>
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

   NOT A FULL GROVER ITERATION, and the reason is narrower than it looks.
   State prep is S = `Ry(0.5)` THEN `+ off`, so re-applying S means
   `q = cq_theta(q, 0.5); q += off;` — in THAT order the theta's arg-0 is the
   same wire the reflection's condition read, `wireGainsNonDiagonalGate` (which
   is schedule-independent) sees it, and the region declines even though the flag
   was stripped and freed long before. That is bd lom0, a separate increment
   against ArmClassify.

   MEASURED, and worth stating precisely because the obvious summary is wrong:
       q += off; q = cq_theta(q, 0.5);   ->  LOWERS
       q = cq_theta(q, 0.5); q += off;   ->  DECLINES
   The first one lowers only because `cq_template_add_i32_hl` mints a FRESH
   handle, so the theta sits on a different wire than the one the condition read.
   It is NOT a workaround: `+off ∘ Ry` and `Ry ∘ +off` are different unitaries
   (Ry does not commute with the `+3` permutation), so the first spelling
   computes something that is not S. This slice therefore stops at the `q += off`
   half — the part of S that genuinely lowers — rather than reordering S to get
   past a guard. */
volatile int off = 3;

int slice(void) {
    int q = 0;
    q = cq_theta(q, 0.5);                    /* S  */
    q += off;
    if (q == 5) {                            /* O  */
        q = cq_phi(q, 3.14159265358979323846);
    }
    q -= off;                                /* S† */
    q = cq_theta(q, -0.5);
    if (q == 0) {                            /* R0 */
        q = cq_phi(q, 3.14159265358979323846);
    }
    q += off;
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
