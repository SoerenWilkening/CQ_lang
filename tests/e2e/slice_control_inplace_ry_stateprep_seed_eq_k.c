/* slice_control_inplace_ry_stateprep_seed_eq_k.c — the `seed == k` STATE PREP
   at `i32`, the second half of the 2026-09-11 owner ruling (bd `drbq.14`; F2's
   `CondWire` narrowing).

       int r = 5;  if (q == 5) r = cq_theta(5, 0.9);

   Before the ruling this declined `state prep seed is proven equal to the
   condition register`, and PRD §14.11 Q1 recorded it as a GENUINE over-decline
   whose workaround was ONE CHARACTER — any seed other than the compare literal.
   The owner's words were *"I dont see the need for the over-decline"*. It is
   gone for a seed on the condition's own wire; it is NOT gone for one off it.

   THE PAIR THAT MAKES THIS SLICE WORTH COMMITTING is with
   `slice_control_inplace_ry_stateprep.c` (seed 0, `k` 5, ACCEPTED since drbq
   Inc 4). MEASURED: `diff` of the two goldens is **exactly one line** —

       4c4
       < cqrt_alloc_i32(0) -> h2
       > cqrt_alloc_i32(5) -> h2

   — so the ruling's effect at `i32` is *precisely* "the alloc literal may now
   equal the compare literal". No new symbol, no new shape, no new gate, not one
   extra or reordered trace line. That one-line diff IS the witness, and it is
   why this slice carries no `compare_files` twin gate (there is no
   byte-identical twin to compare it to — the drbq Inc-4 precedent: the witness
   is a stated, re-derivable relation between two committed goldens, not a
   script).

   READ THE GOLDEN LINE BY LINE:
     1  cqrt_alloc_i32(3)             — `q`'s rail
     2  cqrt_ry_i32(h0, 0.3)          — `q`'s own rotation
     3  cq_template_icmp_eq_i32_hl(h0, 5) — the FLAG, minted at the compare
     4  cqrt_alloc_i32(5)             — the PREPPED rail, seeded 5 == k
     5  cqrt_ry_i32_controlled(h1, h2, 0.9) — the arm gate
     6  cq_template_icmp_eq_i32_hl_unc(h1, h0, 5) — the STRIP
     7  cqrt_free(h1)                 — the flag, and the ONLY free
     8  cqrt_measure_i32(h2)          — `r`
     9  cqrt_measure_i32(h0)          — `q`, untouched by the region
   No route, no work rail, no reverse-play, no `cqrt_x`, and NO free of h2 (the
   freeze). Line 4 carrying `5` rather than `0` is the entire delta the ruling
   buys at this width.

   ⚠ THE TRADE, disclosed rather than fenced (SCOPE H-1): after `-O1` this module
   is BYTE-IDENTICAL to `int r = 5; if (q == 5) r = cq_theta(q, 0.9);` — an
   in-place Ry on the CONDITION's own register — measured on the sibling pair
   `probes/a_prep.c` / `probes/a_self.c`, where `diff` over the two `-O1`
   slice bodies is EMPTY. That rival now compiles as this prep, silently. It is
   admissible because the rival has never had a lowering: `RotBase ∈ CondRails ⇒
   R4 declines`, and every spelling that survives `-O1` intact declines today on
   the NARROWED binary (19/19 in `probes/alt/`, plus 13 plain-C in `probes/`).

   ⚠ WHAT THIS GOLDEN DOES NOT WITNESS: the SEED. `free_pairing_check.py`
   classifies `cqrt_alloc_<W>` by symbol name and never reads its argument, and
   no trace label answers a state question — so line 4's `5` is pinned by the
   byte-diff of this golden and by F1, not by stage 2b. 2b runs STRICT here for
   what it does cover.

   (Every `probes/...` reference above is relative to this increment's scoping
   record, `docs/prd/phase-04-swap-route-control/inc1-records/session-f2-i1/`.) */
int slice(void) {
    int q = cq_theta(3, 0.3);      /* the condition register                    */
    int r = 5;                     /* seed == the compare literal: F2's subject */
    if (q == 5) {
        r = cq_theta(5, 0.9);      /* CLASSICAL seed 5: alloc + controlled Ry   */
    }
    return (int) cq_measure(r) + (int) cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
