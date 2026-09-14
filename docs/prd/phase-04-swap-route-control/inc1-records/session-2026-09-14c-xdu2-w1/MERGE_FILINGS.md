# MERGE FILINGS — session 2026-09-14c, the group gate

Findings the group gate produced that no single track could have produced, plus the obligations it
hands on. Each is written so it can be `bd`-filed verbatim. **None is a miscompile**, and the one
safety property that outranks every gate — no program goes DECLINE → ACCEPT — was measured at **0 over
6311 corpus rows** plus a direct pin on the owner's own file (`MERGE_REPORT.md` §3).

Binary for every measurement: `cq-opt` `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`.

---

## F-1 — **A RULE-13 OPINION ON THE A×B COMPOSITION IS OWED.** Priority: the highest here.

`MERGE_BRIEF` §2 states it and this gate confirms it: **Track A cleared a binary on which Track B's
promoter does not exist, Track B cleared a binary on which Track A's classifier does not exist, and the
composition has been reviewed by nobody.** What this gate added is MEASUREMENT, not review:

* the two predicates agree on **all 63 `Bank` rows**, verdict and all seven `RailBankShape` fields;
* they disagree on 20 rows and the real one is **stricter on every one**, with **zero** rows where
  real = `Bank` and shim ≠ `Bank`;
* the owner's own file goes `Bank` → promoted → **declined at the same `!dbg`**.

Rule 2 is explicit that this is *necessary and not sufficient*. The specific thing a reviewer must ask,
which no measurement here answers: **the promoter's soundness now rests on conjuncts that live in
another file and were cleared for a different purpose.** Track A added `getParentLoop()`,
`isStaticAlloca()` and `hasNoSelfWrap()` to protect the *carve's* reasoning; three of them are load-
bearing for the *promoter's* rewrite, and only the first has a cross-seam trigger (added at this gate).
A reviewer should re-derive C2′, C4 and C6 **as preconditions of `applyBank`**, not as clauses of a
classifier. The F × P precedent of 2026-09-14 is the model: *a composition is not cleared by clearing
its parts.*

## F-2 — the promoter's multi-store `SSAUpdater` path is now **UNREACHABLE**, not merely untested

Track A's C4 second half refuses `Stores.size() != 1` unconditionally, and B6 (the carve call,
`RailBankPromote.cpp:268`) runs before every other B-clause. So `applyBank`'s several-stores-per-
activation path cannot be entered on the merged binary. **Direction: safe.** But it is dead code
carrying an `SSAUpdater` merge that nothing exercises, and the day C4 is widened to admit a two-writer
bank that path becomes live **with no test behind it**. Either delete it, or land it with the widening
and a red-green pair — not before. (Track B filed it as "untested"; the merge makes it "unreachable",
which is a different maintenance fact.)

## F-3 — **three Track-B refuse fixtures stopped isolating their clause, and Track B's injection matrix stopped measuring the shipped binary for them**

`railbank_promote_reject_two_cells` (B2), `…reject_store_outside_loop` (B5) and
`…reject_inloop_other_read` (the *"nothing non-rewritable inside `L`"* clause) were **`Bank` to the
shim** and are **`Reject*` to the real carve** (measured: `AB_DIFF … shim=Bank`). Since B6 precedes
B5/B1/B8/B3/B2/B7, the carve now refuses them first.

⚠ **Two of those three are precisely the fixtures Track B rewrote in injection rounds 2 and 3 so the B
clause would be the SOLE refuser** (`IMPL_B.md` §9.2 — `two_cells` re-spelled to store `b[i]` and read
`b[2-i]`; `store_outside_loop` re-spelled to a second writing loop plus a dedicated preheader). The
merge undoes exactly that work. The 22-mutant matrix that reported **MISSED 0** mutated the SHIM's
clauses; for these three cells it is now a measurement of a binary that no longer exists.
**What is owed:** re-run the matrix against the real carve, and expect to re-spell these three again —
this time so the *B* clause refuses a module the *real* carve calls `Bank`. ~22 rebuilds; the
implementation row's gate, not this one's.

## F-4 — a tripwire that **cannot fire** was counted three times

`RailBankCarve.h`, `IMPL_B.md` §8 and `MERGE_BRIEF` §2 all carry Track B's claim that Track A declaring
the enum in `QramLowering.h` would be *"a REDEFINITION compile error in any TU that sees both"*, plus a
hard error on the duplicated default argument. **Measured: it did not fire, and no TU includes both
headers.** The fail-loud property is carried entirely by the link error, which did fire, in both
binaries. Harmless here because one real tripwire is enough — filed because *"it is not possible to
forget, and that is the design rather than a hope"* was a three-part argument of which two parts were
inert, and a future stand-in built to the same recipe may have only the inert parts.

## F-5 — **bd `s82e`'s D4 population is 6 record programs, not 3** (found only by closing R3)

Three programs outside every track's corpus move ACCEPT → DECLINE on D4's string:

* `docs/prd/phase-04-swap-route-control/inc1-records/c1-round3/z21_preadd_volatile_imm.c`
* `docs/prd/phase-04-swap-route-control/inc1-records/c1-round4/c2_m11d_two_loops_no_preadd.c`
* `docs/prd/phase-04-swap-route-control/inc1-records/session-adc5590a/c1_reproducers/r5_short_inv.c`

Read rather than inferred, all three are the `*_leak_control.ll` shape verbatim — a rolled
`for(i<3){ if((q>>i)&1) cq_phi(…); r=cq_theta(r,…); }` over a `q` that is **re-rotated
`cq_theta(q,0.9)` after the loop and measured**. Genuine instances of D4's divergent sub-case; the
direction is correct. `IMPL_S.md` §18's *"7 movers, every one attributed"* is true of a 2013-row corpus
and must not be re-quoted as a fact about the tree. ⚠ This is R3's own warning coming true: Track A's
structural immobility argument for the residue would have lost (L5).

## F-6 — two record files kept "so the program is on record" **do not compile**

`tests/e2e/slice_control_select_{bool,cmp}_round2_window.c` (unregistered at the 2026-09-14 gate, bd
`3d8q`) nest `/*` inside their conversion header's block comment, so the prose leaks into the code and
`clang` reports `expected identifier or '('`. **Pre-existing on `main`, harmless** (both are
unregistered and both goldens were deleted), but a file kept *"as the record of a program that used to
lower and now loudly declines"* should be compilable by the next reader who wants to see it decline.
One `*/` each.

## F-7 — the four twin cells Track S requested: **measured, adjudicated, NOT added** — with the data the adding increment needs

`MERGE_REPORT.md` §7 carries the verdicts. Handing them on:

| cell | verdict on `0e280fc6` | what it needs |
|---|---|---|
| `m_noregion_invread_dead` | **TRACE-DIVERGENCE** 16/20, tool `divergence_signature` **`07ae35c484747c29`**, first rolled `cq_template_and_i32_hl(h0, 1) -> h1`, first unrolled `cqrt_alloc_i32(6) -> h1`, counts rolled (0,0,8) / unrolled (2,2,8) | a quarantine block, once the cell can be generated |
| `m_noregion_invread_live` | **`UNROLLED-ONLY`** (rolled declines D4, unrolled accepts 14 lines) | an expected-table row |
| `m_region_derivedbase_live` | **`UNROLLED-ONLY`** (rolled declines D4, unrolled accepts 25 lines) | an expected-table row |
| `m_region_rootmint_live` | **`ACCEPT-IDENTICAL` 22 == 22** | an expected-table row (the positive control) |

Not added because `cells_of_matrix()` is a closed axis product with **asserted** sub-grid sizes
(120/36/118/14/50 = 338) and these are bespoke sources: the increment is a new cell family with its own
generator, its own red-green and its own mutant validation. Dropping a hand-written quarantine row for
a cell the generator cannot produce would leave the quarantine's boundary controls unable to evaluate
it — stale by construction, the exact failure those controls exist to catch.

⚠ **And two corrections the measurement forces, which are worth more than the cells.**
**(a) Track S predicted `DECLINE-BOTH-SIDES` for the two `_live` cells and that is FALSE**: D4's
decline is **asymmetric** — it refuses the ROLLED spelling while the hand-unrolled twin of the same
source still compiles and emits 14 / 25 correct lines with STRICT 2b clean. That is D4's accepted cost
with a measured witness instead of an argument, and the honest matrix verdict is `UNROLLED-ONLY`.
**(b) The `dead` cell's counts (0,0,8) vs (2,2,8) are the SAME structural signature as the `_live`
cells the fence now refuses.** D4 calls one benign because its entangled partner is dead after the trip
— and **that distinction is invisible in the trace; the twin matrix cannot make it, only a fence can.**
`CLAUDE.md` L10's `m_none_pbitd_none_premark_rypost` lesson, arriving from the other side. The `dead`
cell must never be cited as evidence about the `live` ones.

## F-8 — Track I's new `adjudicate_memory` rules have **no customer in the merged tree**

bd `21re` closes a real hole: `free_pairing_check.py`'s `provably_not_a_rail` rested on *"a tainted
store is a loud decline long before lowering, so a load result is not a rail"*, which bd `xdu2` exists
to falsify. Measured on the merged binary: **every rail bank still dies at `declineTaintEscapes`**, far
above lowering, so no `!cq.railbank` load can reach stage 2b and the new rules fire on nothing but
Track I's six hand-built subjects. Sound and correct to land now (the alternative is landing the
checker *after* the door opens). Recorded so nobody reads the merged suite's green as evidence that the
rules work on emitted IR — **their subject does not exist yet**, which is Rule 12 hygiene defect (c)
seen from the useful side.

## F-9 — a header clause that contradicted its own `.cpp`, corrected at the gate (L7-with-a-twist)

`RailBankPromote.h` shipped a **clause B9** — *"NOT ALREADY PROMOTED (`isRailBankAlloca` — the
`!cq.railbank` record this stage MINTS)"* — while `RailBankPromote.cpp`'s `applyBank` tail says in
capitals that **no metadata is minted**, B8 is what terminates the fixpoint, and `isRailBankAlloca` is
not shipped at all (`trackA/SIGNATURE.md` deviation (2)). Track B's own injection round 4 confirms the
correction (mutant M13, *"re-add the mint"*, CAUGHT by all seven accept fixtures through their `NOMD`
prefix). B9 is deleted and replaced by the correct statement plus B8's termination trigger. The header
also named a fixture that does not exist, `railbank_promote_o1_shape.ll`; corrected to
`railbank_promote_reject_already_ssa.ll`.
⚠ `IMPL_B.md` §2.3, §7, §8 and §10.1 still carry the old wording and are now history. **A record
correction applied to the .cpp and not to the .h is the same defect as L7-with-a-twist wearing the
other shoe** — and that defect was ruled wrong three times on one sentence before it landed.

---

## Carried, unchanged, for the record

* **R1 stays refused and its measurement stays deferred** — and the reason is now measured rather than
  argued: the bank population dies at `declineTaintEscapes`, above `lowerLoops`, and
  `LLVMContext::diagnose` EXITS on the first `DS_Error`. Round 1 must be told that a "does not reach
  the fence" answer is true of the binary and **false of the capability**.
* **R2 stays owed.** No accept path ⇒ D1's byte-identity measurement cannot be taken here.
* **`MERGE_BRIEF` §6's three no-touch items were not touched**: the three `*_leak_control.ll`
  ACCEPT → DECLINE rows are the increment (and three more like them were found, F-5); Track B's `i8`-vs-
  `i1` φ residual is unchased; `isRailBankAlloca` / `railStoredToRailBank` were not added.
