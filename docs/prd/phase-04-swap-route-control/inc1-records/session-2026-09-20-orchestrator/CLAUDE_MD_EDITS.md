# CLAUDE.md edits owed by session 2026-09-20 (apply at the close, in the main checkout)

## EDIT 1 — §1 "What lowers today", the LOOP-CARRIED HANDLE VARIABLE row

Append to that row's mechanism cell:

> … **at EVERY integer ABI width** (bd `11qv`, 2026-09-20): the φ is RETYPED to
> the `i32` handle ABI at the promotion (`mutateType`, the `RailBankPromote`
> idiom) and its LOGICAL width is recorded in `taint.HandleWidth`, the
> side-table `logicalOperandWidth` consults BEFORE the now-laundered LLVM type.
> ⚠ The width record is the safety argument, not bookkeeping — without it a Q+Q
> compare over two retyped `i16` φs recovers `i32` from `abiWidthFromType` and
> mints an `i32` template symbol for two `i16` registers, the wrong-width class
> `CompareLowering.cpp` refuses in writing. **Reachability of that path is NOT
> claimed**: every Q+Q-under-control shape probed declines identically at both
> widths, so the record is DEFENSIVE and is written that way.

## EDIT 2 — §2 "What declines", the loop-scope bullet

The narrow-width carried handle is no longer on the decline list. Replace the
(Z3) mention with:

> ⚠ A narrow-width carried handle **no longer declines** (bd `11qv`); what still
> does is the **GUARDED / rotated** loop (bd `h1ip`, clause (Z8)) and the
> **MULTI-EXIT** carried handle (bd `h7ee` round 2, R2-3 — **a distinct shape:
> it has no guard, so `h1ip`'s filed fix does not reach it**).

## EDIT 3 — §3 standing lessons, attach to L10

> ⚠ **THE INSTRUMENT LESSON COST A SEVENTH INSTANCE ON 2026-09-20, in the
> session that was reading this paragraph.** A peel-mutation sweep reported
> **2065 movers of 2106** — a number so large it read as a catastrophic
> regression — because `rc=$?` after a pipeline captured **`grep`'s** status,
> not `cq-opt`'s, and `grep -v` returns 1 when it filters every line away. It
> was caught by a **null-tag boundary control** (peel a tag nothing uses; it
> MUST move 0), which is now run on every invocation of that sweep. **A mutation
> harness that has not been run against a no-op mutant is measuring itself.**

## EDIT 4 — §5, the open follow-ons

* bd `11qv` moves from "Over-declines" to CLOSED (2026-09-20).
* bd `h7ee` — Rule-13 rounds 2 and 3 for bd `zujr`: record the verdicts.
* NEW filings from round 2, all P3: the dead-φ promotion (FIXED in the same
  change, clause (P0)); (P1)'s stated ground is wrong — `ControlOwnedRails` is
  **not** "the record every Phase-4 merge emitter writes", Phase 7.4 puts three
  NON-merge rails in it before the promotion runs; the MULTI-EXIT over-decline;
  the un-guarded zero-trip accept, which is the ONE shipped shape where the
  promoted register is the ANSWER and it has no fixture; and the `AsLowered`
  retirement trigger, which round 1 spelled wrongly — the greppable form is
  *"the day any `BinaryOperator` enters `taint.ControlOwnedRails`"*.
* NEW filing, NOT this session's defect and NOT fixed: the **narrow-literal ABI
  attribute**. The pass emits an `_hl` template's literal operand with no
  `signext`/`zeroext`, while the runtime's C definition takes an `int8_t`/`int16_t`
  that Clang's x86-64 ABI marks `signext` — so a negative narrow literal reaches
  the callee zero-extended (`253` for `-3` at `i8`, `65533` at `i16`).
  ⚠ MEASURED ON THE ORACLE with a LOOP-FREE program and no carried handle, so it
  predates every part of this session; the lowered IR is correct (`i8 -3`) and
  the runtime is trace-only, so no shipped unitary is wrong — but the goldens
  encode it. *"Pre-existing" is true of the defect and FALSE of its population*:
  bd `11qv` makes narrow carried handles reachable and adds customers.

## EDIT 5 — "Where Things Live", the `LoopLowering.cpp` row

Append: `promoteLoopCarriedHandleSeeds` now carries **(P0)** (a `use_empty()` φ
is not promoted — the promotion was the LAST owner for a dead φ, because
`declineClassicalMuxes` skips one) and **(P4)** (every user of a φ about to be
RETYPED is one the lowering rewrites; a φ user is refused, so the invalid edge
cannot move one φ outward). ⚠ **(P4) has NO discriminating RUN line and 0 movers
over 2106 fixtures** — it is validated by the argument plus a peel sweep, it is
a CRASH-avoidance clause (Rule 1: the alternative is `opt` exit 134, not a
decline), and it is unreachable on today's corpus. Said plainly so it is not
later cited as a tested fence.
