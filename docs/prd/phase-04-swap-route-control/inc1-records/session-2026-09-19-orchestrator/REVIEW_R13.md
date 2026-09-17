# Rule-13 round 1 — bd `zujr` — VERDICT `CLEAR-WITH-ITEMS`

Independent reviewer, 2026-09-19, ORACLE `07d93784…` vs SUBJECT `64b0339c…`,
neither binary rebuilt under the measurement. **No P1. No P2. Six P3s.** Every
one is addressed below or filed with its bead.

## What the round corroborated that this session's own numbers did not cover

* an IR-level A/B over all 2099 fixtures comparing **exit code, stdout AND
  stderr** — the session's `sweep.py` runs `-o /dev/null`, so **a stream change
  on an ACCEPTING module was invisible to it**. Result: 11 movers, exactly the
  session's list, and **0 accepting modules whose lowered IR moved**;
* 84 further both-accept modules (19 probes + 65 twin-matrix cells): **0 stream
  moves**;
* 5/5 injected mutations KILLED on the new positive fixture;
* the owner's program moved OUT of `main` (`noinline`): 50 lines,
  **byte-identical to the committed golden**;
* K-independence re-measured at K=3 / 8 / 1000: **75 lowered lines each**.

## The six items, and their disposition

| # | finding | disposition |
|---|---|---|
| F-1 | the (L3) exemption's safety argument named `railStoredToRailBank`, which guards the **TERMINAL** partition, while the marking unlocks the **INTERIOR** one. True conclusion, wrong ground — CLAUDE.md L7's shape. | **FIXED IN SOURCE.** The ground is now stated as `isInteriorTerminalHandle`'s **(I3)** + **(I1)**, with the retirement trigger the reviewer supplied (*the day a bank cell can hold a TEMPLATE-minted rail, (I1) stops covering it*). The reviewer measured the gap EMPTY today: four constructions all die at `RailBankPromote`'s own fences on both binaries. |
| F-2 | the (L3) widening is ungated on the new predicate and had **no lit fixture of its own** — only an e2e pair. | **FIXED.** `loop_carried_handle_accept_bank_l3_isolated.ll`: a banked loop with a DERIVED per-trip condition and **no carried-handle φ anywhere**, so every conjunct of `loopCarriedHandlePhi` is vacuous and the accept is (L3)'s alone. Non-vacuous (the ORACLE declines it). |
| F-3 | the new stage's cheap prescan iterates `taint.Tainted` and dereferences each member — **the exact idiom `declineDephasingUnmarkedLoopRails` refuses in writing** thirty lines away (*"Do not 'simplify' it back"*), and the new stage sits AFTER both flattens. Latent UB; no crash constructible. | **FIXED IN SOURCE.** It walks `F`'s blocks now, with the neighbour's reason quoted at the site. |
| F-4 | *"the shape half only ever DEFERS, never accepts"* is **false at two of the four sites**: (c3) and the marking pair are GRANTS on round-1 evidence. No exploit found. | **FIXED IN SOURCE.** The comment now names which two DEFER, which two GRANT, what backstops each, and the two residual escapes from that backstop (`use_empty()`; `liftOneRegisterMergePhi` on a header φ) as where a widening must look first. |
| F-5 | **five further diagnostic degradations**, all ORACLE→SUBJECT, all DECLINE→DECLINE, all safe-direction, all to the generic `control flow under quantum control`. | **FILED on bd `8h7d.12`, not fixed.** They are other clauses' strings, and this increment already spends two conjuncts ((Z6), (Z8)) buying message accuracy. Recorded verbatim below. |
| F-6 | four of the five new reject fixtures print the **same string on the ORACLE**, so no RUN line discriminates the conjunct each names; the (Z3) `report_fatal_error` claim was **unmeasured in-tree**. | **FIXED, BY MEASUREMENT.** Four source mutants, one per conjunct, each run over the whole family: **a 1:1 kill matrix, MISSED 0** — Z3→narrow_width, Z4→tainted_seed, Z6→accumulator, Z8→guarded, each killing its own file and no other. The Z3 mutant emits `PHI node operands are not the same type as the result!` and `opt` **aborts with exit 134**. The matrix is written into all four headers. |

Plus one correction the reviewer supplied outside the numbered findings, **also
fixed in source**: clause (Z1)'s comment claimed a ROTATED loop with a zero-trip
guard *has no preheader*. That is **false** — `-O1` emits
`entry → for.body.preheader → header` and that block has one successor. (Z8) is
what handles the guarded case, which is what the session actually measured.

## F-5 verbatim, for bd `8h7d.12`

| program | ORACLE | SUBJECT |
|---|---|---|
| `d1_owner_post_ry.c` | `condition predates a non-diagonal gate` | `control flow` |
| `d2_uncond_prep_post_ry.c` | `loop-carried tainted value crosses iterations` | `control flow` |
| `e3_inloop_rot_before_arm.c` | `loop-carried tainted value crosses iterations` | `control flow` |
| `h3_bank_two_stores.c` | `control flow inside a loop body…` | `control flow` |
| `r1_postry_on_a.c`, `r2_…` | `loop-carried tainted value crosses iterations` | `control flow` |

plus the corpus mover `railbank_promote_uncond_prep.ll`.

## What the round attacked and did NOT find — with the list, because "no finding" without one is worthless

* **(a)** a 57-cell prep×arm×post matrix plus 9 hand pairs over the (L3) exemption:
  9 FLIP cells, all `DECLINE→ACCEPT`, **every one twin-equal** modulo `-O1`
  trip-1 const-folding. No in-body free of a non-`|0⟩` rail anywhere.
* **(d) Rule 8** — six spellings of a post-loop non-diagonal gate, including two
  (`r1`, `r2`) built specifically to dodge BOTH walls the session's own fixture
  names: **every one declines on the SUBJECT**, and in four the FLAT twin declines
  identically. The *"no worse than the flat form"* claim held in every shape.
* **(e) L1** — every round-2 construction is decline-direction.
* **(f) L2** — `markIfIterationLocal`'s own (L3) was **not** widened (safe: it
  falls through to the widened sibling), and `RootsOut` **was** widened alongside
  the escape set, which is the pairing L2 demands. One live nit recorded:
  `collectCarriedHandleChains` peels with `AsLowered=false` while
  `railLocalQualifies`' `onRail` consumes with `AsLowered=true`. **Unobservable
  today** — (Z6) refuses a binop latch and `peelInPlaceStep` returns null for a
  select, a phi and a `cqrt_alloc`, so the chain is always exactly `{φ, LatchVal}`
  — and it becomes live the day (Z6) admits an in-place latch step.
* **(g) structural** — two carried φs, two functions, non-`main`, nested, guarded,
  runtime seed, mixed promotable/unpromotable: all decline or accept correctly.
  Multi-latch and irreducible are structurally excluded by (Z1).
* **(h) width** — `short`, `char`, `long`, `long long` all decline loudly with no
  crash; `unsigned` (i32) accepts.

## ⚠ What this round did NOT do

It ran **no ctest entry and no full suite**, and it did not attack the promotion
under a module with a `break` loop beside a carried handle beyond two hand probes,
nor the `use_empty()` / `liftOneRegisterMergePhi` residuals it names in F-4. Per
bd `zujr`'s own budget (*"≥3 rounds: this is the shape most likely to hide a
cross-iteration dirty rail"*), **rounds 2 and 3 are OWED and are filed, not
done**.
