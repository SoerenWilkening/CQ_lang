# DECISIONS — session 2026-09-19 (bd `zujr`)

## Owner rulings this session RELIED ON (none new were sought)

* **2026-09-17, bd memory `owner-ruling-loop-carried-handle-2026-09-17`** —
  (1) trip-1 PROMOTION accepted (materialise `cqrt_alloc_<W>(entry value)` in the
  preheader; *"slightly less efficient is fine"*); (2) BYTE-IDENTITY with the
  hand-unrolled twin is an **INSTRUMENT, not the target**; (3) *"compile
  everything that is not forbidden by physics"*. All three were load-bearing and
  all three are cited at the code that depends on them.
* **2026-09-11** — an over-decline is a **defect to remove**, not a free safety
  margin. This is what makes (c3)'s widening (bd `8h7d.11`) obligatory rather
  than optional.

## DECISIONS TAKEN IN-SESSION, with their grounds

**D1 — the predicate is ONE function asked at four slots, not four predicates.**
Rule 14. Two slots run at round-1 taint where `taint.ControlOwnedRails` is
necessarily empty, so clause (Z6) asks the record where it exists and the
emitters' SHAPE where it cannot. ⚠ The first wording said the shape half *"only
ever defers"*; Rule-13 round 1 (F-4) measured that **two of the four GRANT**, and
the comment now says which and what backstops each.

**D2 — the promotion NEVER declines.** Every refusal is a SKIP, and an unpromoted
carried-handle φ is refused by `declineClassicalMuxes` one stage later. That is
what makes all four analysis sites decline-SAFE. Adding a second loud owner would
give one module two diagnostics for one defect, and `LLVMContext::diagnose` EXITS
on the first `DS_Error` anyway (bd `br4a`), so the second would be dead text.

**D3 — (Z3) is an `i32` gate and the narrow widths DECLINE.** Rule 15: a runtime
handle is always `i32`. MEASURED: the mutant that deletes it aborts `opt` with
**exit 134** on `PHI node operands are not the same type as the result!`. The
`mutateType` widening is filed (bd `11qv`), not smuggled in — it is an
accept-direction change to a value every later stage reads.

**D4 — (Z8) refuses the GUARDED loop, and it is a DIAGNOSTIC decision, not a
capability one.** The module declines either way; without (Z8) the mux guard
speaks about the EXIT φ instead of the loop. Filed as bd `h1ip`.

**D5 — the (L3) rail-bank-store exemption is NOT gated on the predicate, and that
is stated rather than hidden.** Without it no banked loop could ever be MARKED and
conjunct 2 could never be met. It got its own isolating lit fixture (Rule-13 round
1, F-2) and its own e2e twin pair.

**D6 — bd `x5fp` stays PARKED.** Measured: the §3c clobber never fires on the
owner's program. The previous session parked it for want of a first accept; this
session did not supply one.

**D7 — bd `zujr` stays OPEN.** The headline is delivered but the bd's DONE-MEANS
asks for ≥3 Rule-13 rounds and ONE ran. Closing it on one round would be exactly
the *"NOT 'the decline moved'"* the charter warns against, one level up.

## OWNER QUESTIONS TO BATCH AT THE NEXT OPEN

**Q1 — bd `h1ip`, the GUARDED loop.** Hoisting the promotion's `cqrt_alloc` above
a rotated loop's zero-trip guard makes a RUNTIME trip bound lower, at the cost of
**allocating a register a zero-trip loop never uses**. Harmless in the
qubits-not-scarce regime, but it is an allocation the program did not ask for and
it is the owner's call.

**Q2 — bd `11qv`, the NARROW-WIDTH carried handle.** A `_Bool` carried handle is
the shape the owner's own programs are full of, and it declines today. The fix is
the `RailBankPromote` `mutateType(i32)` idiom. Worth a round of its own?

**Q3 — bd `3slt`.** The owner's cascade plus a post-loop S† declines today ONLY at
the 4.4 select. The FLAT twin already compiles that circuit with the ruled warning
(bd `lyyf`). When bd `r903`/`fg9k` moves the select wall, does the rolled form get
the same warning, or does bd `s82e`'s fence refuse both?
