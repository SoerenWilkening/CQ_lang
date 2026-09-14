# Track W — FIX record for adversarial review round 1 (bd `test_C_libtooling-wx8g`)

Worktree `/Users/sorenwilkening/Desktop/CQ_wx8g`, branch `inloop-bool-prep`.
Pre-fix tip `11fc1b3c`, pre-fix `cq-opt` `daeb93a36bdc57b3…`.
**Post-fix `cq-opt` `40edde36678c7dd4937b63b017700804fad90feeb33263742d3e1b29170b994d`,
`libCQPass.so` `e82fe15c6aae983ef397873e7c344c72730aba3f213e248ca1c52267e2d07bd0`.**
Every gate line is in `GATES.md` under "Review round 1 — the FIX agent", marked `ran:` or `cited:`.

⚠ **Every gate recorded against `daeb93a3` is VOID for this binary** and was re-run, except the
ORACLE-vs-SUBJECT corpus sweep, which is **`cited:` for the pre-fix binary only** — one sweep per
session belongs to the merge gate.

---

## F-W1-1 — over-ACCEPT / silent miscompile (dangling `Loop *`). **FIXED.**

**Reproduced first, independently, on the pre-fix binary**, from the review's own artefacts:
`b1_twofn` ACCEPT 40 lines, `b6_noattr` (no attributes, two ordinary kernels) ACCEPT 40 lines,
`b1_twofn_rev` / `b2_norecord` / `b3_failfail` / `ctl_wj` DECLINE. Module order was the only variable.

**The fix is BOTH halves of the shape the tree already owned one function away** (Rule 14):

* the set is declared **inside** the `for (Function &F : M)` body, beside the `DominatorTree`/`LoopInfo`
  that owns the `Loop` objects;
* and it is keyed on `L->getHeader()` — a `BasicBlock *`, which lives as long as the module — so the
  key is stable even if someone hoists the declarations again. The per-function scope is the fix; the
  header key is the defence in depth, in the style of the two "STRUCTURALLY UNREACHABLE, kept as
  defence in depth" notes in the same R7 block.

**And it is TWO sets, not one, which is not tidiness.** Conjunct 1 is now asked only of clause-(c)
entries (see F-W1-2), so a single "already diagnosed this loop" set would let a (b′) entry that passed
conjunct 2 suppress a (c) entry's conjunct 1 — *the same suppression defect one level down*.
`AskedEscape` and `AskedMarking` dedup independently.

| control | pre-fix `daeb93a3` | post-fix `40edde36` |
|---|---|---|
| `ctl_wj` alone | DECLINE | DECLINE |
| **`b1_twofn`** (pass-then-fail) | **ACCEPT, 40 lines** | **DECLINE** |
| `b1_twofn_rev` (reversed) | DECLINE | DECLINE |
| `b2_norecord` (1st fn writes no record) | DECLINE | DECLINE |
| `b3_failfail` | DECLINE | DECLINE |
| `b4_variant`, `b5_threefn` | ACCEPT 37 / ACCEPT 40 | DECLINE / DECLINE |
| **`b6_noattr`** (no `noinline`, ordinary C) | **ACCEPT, 40 lines** | **DECLINE** |

---

## F-W1-2 — over-ACCEPT / silent miscompile (the halves do not cover the same set). **FIXED, in the non-declining direction.**

`d3_invariant_read.c` pre-fix: **ACCEPT 30** against a hand-unrolled twin at **34**, missing one
`cq_template_and_i32_hl_unc` + `cqrt_free` per activation. Post-fix: **DECLINE**.

**The fix is the record site, not a predicate, and it is structural rather than disciplined.** The
`push_back` moved **out of the clause-(c) branch and onto the far side of `if (!Rollable) { decline;
return; }`**, carrying a per-entry bit (`TaintSet::RolledLoopGrant{Gate, IterationLocal}`). A new grant
clause sets `Rollable` and falls through the record; the only way to miss it is to return early, which
is a decline. That is CLAUDE.md's L1 — *"the record must be at EVERY emission site"* — encoded in
control flow instead of in a comment.

**Conjunct coverage, and why it is asymmetric:**

* **conjunct 1** (the (c3) escape re-ask) — clause-(c) entries **only**. ⚠ **ERRATUM (round 2,
  F-W2-2): the reason given here was MEASURABLY FALSE and is superseded by `FIX_W_R2.md` §3.** The
  retracted sentence read *"(c3) refuses when anything tainted defined in `L` is read outside `L`, and
  a loop-**carried** rotated register is read outside `L`: that is what 'carried' means."*
  `w2b_sameloop_mixed.c` — one loop carrying BOTH a (b′) and a (c) grant — **ACCEPTS at 22 lines,
  twin-identical**, which requires (c3) to have held while its (b′) carried register is measured only
  INSIDE the loop. The TRUE reason is about **premises**: conjunct 1 re-asks a clause only (c) ever
  asserted, and (b′)'s own round-2 re-ask is the rail collapse's `kMsgCrossIter`. What survives
  unfalsified: asking it of a (b)/(b′) entry would **also** decline every shipped drbq Inc-3 in-loop arm.
* **conjunct 2** (the marking postcondition) — **every R7-loop** entry. The leak does not care which
  clause let the region through. ⚠ **SCOPE CORRECTION (round 2, F-W2-3): read "every" as "every
  **R7-loop** grant", never as "every in-loop grant".** The leak class is REGION-INDEPENDENT
  (`markIfRailLocal`'s "accumulating loop-invariant tainted input" refusal fires with no tainted control
  flow at all), so the R7 slice this covers is a STRICT SUBSET; the rest is pre-existing and filed.

**The field was renamed** `RolledIterLocalGates` → **`RolledLoopRegionGates`**, because a name saying
"IterLocal" over a container that now holds (b′) entries is exactly the drift this project punishes
(L7). `declineUnmarkedRolledIterLocal` **keeps its name**: "IterLocal" there names the *marking* it
checks (`taint.IterationLocalBlocks`), not the grant clause, and that is still accurate.

⚠ **IMPL_W §2.1's load-bearing sentence was WRONG and is corrected there** (§2.1 now carries the
measurement and the retraction; see also §2.1a).

### What this widening cost, measured and disclosed

Extending conjunct 2 to (b′) grants turned **one shipped fixture red**:
`control_inplace_ry_inloop_offset.ll`, a drbq Inc-3 accept. That is recorded in `GATES.md` rather than
hidden, and it is what led to the F-W1-3 investigation below — the two findings are **one fix**, exactly
as the review predicted (*"Land the two together"*). `d4_noRailRegion` also moves ACCEPT 28 → DECLINE:
it is a **pre-existing** leak (28 vs 34 on the ORACLE too, bd `1m5p` class A plus a per-trip `and`) that
the new conjunct now refuses; the safe direction, and reported rather than netted.

---

## F-W1-3 — the over-DECLINE family. **ONE of the three is real; the other two are CORRECT declines.** The prescribed fix is implemented — and it turned out to be load-bearing for a different reason.

**The exclusion asked for is implemented, by CALLING the M-C record (Rule 14):**
`bodyHasSpineDischargeCandidate` now skips an instruction in `taint.InPlaceRailOps`. Re-derived against
`lowerOps` as that predicate's own retirement trigger demands: a member is routed to
`rewriteInPlaceValueRail`, which emits `cqrt_{addc,xorc}_<W>(handle, imm)` — a mutation of an existing
handle, no `cqrt_alloc`, no `cq_template_*`, nothing for the spine to place. The disposition is
**total**: a member whose marking went stale is **not** silently lowered out of place — `lowerOps`'
two tripwires re-ask under FINAL taint and **decline loudly** (*"NEVER A SILENT FALLBACK TO
OUT-OF-PLACE … Rule 1 — no third path"*, in that site's own words). The set is also final in this
window: its only `erase` is `invariantRegisterRoots`' rollback, inside `lowerLoops`, which runs earlier
in both entry points.

**But it does not close `od2`/`od3`, and those two are NOT over-declines.** Measured with a scratch
debug build (discarded, never committed):

| probe | `InPlaceRailOps` at the re-ask | conjunct 2 forced OFF: rolled vs hand-unrolled twin | verdict |
|---|---|---|---|
| `od3_inplace_cand` (`r ^= 3`) | **0** | **DIVERGES** — `cq_template_xor_i32_hl(h1,3) -> h2` (a FRESH rail per trip, never `_unc`-ed, never freed) vs the twin's in-place `cqrt_xorc_i32(h1,3)`, twice | the decline is **CORRECT** |
| `od2_measured_cand` (`cq_measure(r+1)`) | **0** | **DIVERGES** — `cq_template_add_i32_hl(h1,1) -> h2` vs `cqrt_addc_i32(h1,1)`, twice | the decline is **CORRECT** |
| `od4_measured_template` (`cq_measure(r & 3)`) | 0 | **BYTE-IDENTICAL, 16 = 16** | a **GENUINE over-decline**, filed |

**Why the review read it the other way, and it is worth carrying:** it inferred the ROLLED form's
lowering from the TWIN's stream. The twin is straight-line, so M-C fires and lowers in place; the rolled
site is inside a natural loop, where **M-C's G5 refuses outright** and no `lowerLoops` writer claims a
rail that has no header φ. Same source line, two lowerings. *A twin's stream is evidence about the
twin.*

**What the exclusion DOES close is the regression F-W1-2 created.** The debug dump showed
`control_inplace_ry_inloop_offset.ll`'s loop holds exactly one candidate — `%qn = add i32 %q, 3`,
`InPlaceRailOps` = 1 — which is the same fact the fixture's own
`CHECK: call void @cqrt_addc_i32` has always pinned. The exclusion restores that shipped accept.

**Also measured and recorded in the predicate's header:** the region's own condition compare needs no
exclusion — `emitInPlaceRotationRegion` mints the flag from it and **erases** it, so by this stage it is
not in `L`'s blocks at all (`offset.ll`'s `%c = icmp eq i32 %q, 5` is simply gone from the dump).

**ACCEPT-direction change ⇒ its own retirement trigger, written:** the predicate's header now says a
**sixth** kind is a new claim to be re-derived against `lowerOps`, and names a second trigger — a
`markInPlaceRailOp`/`erase` site added *after* `lowerLoops` would make this read a set that is still
moving.

---

## F-W1-4 — record hygiene (the `runOnFunction` mirror). **Stated plainly in IMPL_W §3.**

No parity is claimed. The shim never calls the round-1 `collapseFlattenedLoopRails` and round 2 skips
the preds it flattened, so in the shim a clause-(c) loop can **never** be marked and conjunct 2 would
fire on every one that has a candidate. It has **zero callers**; filed against the shim, not papered over.

---

## The three upheld judgements — recorded, not re-litigated

* **(c3) survives L4.** The retirement trigger is **widened** as the review asked: it now names the
  **closure** (L2's half) as well as the exemption set — `L->blocks() × taint.Tainted`, either of which
  moving re-opens the question (`LoopPlan.h`, `iterationLocalTaintEscape`'s contract).
* **H-3 is unreachable on a stronger ground**, and that ground is now the recorded one (`ArmClassify`
  clause (c2)): `peelInPlaceStep` **stops at** a `cq_phi` — it steps through a `GateCalls` member only
  when arg-0 is TAINTED, and `cq_phi`'s arg-0 is the untainted ANGLE — so a `cq_phi` can only be
  *returned* if it was the input `V`, and both callers pass register-typed values. Still no fixture: a
  vacuous negative is a defect (PROTOCOL S3).
* **Retirement argument 1 ("wrong twin") is sound.** Re-verified on this binary: 8/8 twin pairs
  byte-identical, plus the review's `a1`/`a2` and the new `w_l`.

---

## The meta-finding: the two-function axis now has PINS, not a lesson

Both over-accepts were invisible to 1937 fixtures, 15 e2e entries, a complete corpus sweep, a 0-MISSED
injection matrix and 328 twin cells. ⚠ And the reason is **sharper than "one function per module"**:
several fixtures in this tree *do* carry two `define`s (`-O1` inlines `slice` into `main`) — but they
give both copies the **SAME disposition**, so the suppression had nothing to bite on. **The axis that
was missing is a module whose two loops want DIFFERENT verdicts.** Three fixtures now pin it:

| fixture | verdict | pins |
|---|---|---|
| `control_inplace_ry_reject_inloop_iterlocal_twofn.ll` | DECLINE | F-W1-1 — `b6_noattr`'s module, **no attribute of any kind**; ACCEPTED at 40 lines on `daeb93a3` with `and_hl` ×2 / `and_hl_unc` ×0 |
| `control_inplace_ry_reject_rail_inloop_carried_invariant_read.ll` | DECLINE | F-W1-2 — the clause-(b′) rail region with no record; ACCEPTED at 30 vs twin 34 on `daeb93a3`; ORACLE refused it |
| `control_inplace_ry_inloop_twofn_mixed_clauses.ll` | **ACCEPT** | the positive control — clause (c) and clause (b′) in one module, both still lowering; ORACLE DECLINE → 22 lines, twin-identical |

Each carries a retirement trigger (L8) and the decline pair says in its own header that a `DS_Error`
writes 0 bytes to stdout, so the property is pinned by the `not` inversion plus a
character-for-character string, never by an IR-text `CHECK-NOT` (Rule 12 hygiene (b)).

---

## Filed, not guessed at

* **`od4` — the measured-terminal template rail.** A per-trip `cq_template_*` rail whose **only**
  consumer is a `cq_measure` is never uncomputed and never freed, so the marking is irrelevant to it.
  Byte-identical twin at 16 = 16 with conjunct 2 forced off. It needs its own predicate ("is every
  consumer of this rail a measurement?"), which is an ACCEPT-direction fence and owes a Rule-13 round;
  guessing it here would be the wrong trade (the review's own judgement, and I agree).
* **The `runOnFunction` shim** (F-W1-4), zero callers.
* **`d4`'s pre-existing leak** — now refused rather than mis-lowered, but the underlying
  rolled-vs-unrolled divergence of a loop-invariant tainted read is bd `1m5p`'s class-A neighbourhood
  and is not fixed here.

## What I did NOT do

* **No re-narrowing of half 1.** The owner has ruled an over-decline a defect; the record-at-every-grant
  design was buildable and is built (Rule 17).
* **No corpus sweep, no full suite, no `^e2e-` ctest layer, no equivalence sweep, no twin matrix.** The
  one e2e-shaped measurement I ran is a **targeted golden byte-diff over the 33 loop-bearing
  `slice_control_*.c`**, run directly rather than through ctest, precisely because the (b′) widening
  could in principle move a shipped golden. 32 matched; the 33rd is a pre-existing expected decline,
  verified identical on the ORACLE.
* **H-1** (a clause-(c) loop whose second tainted branch appears only at round 2) remains un-probed by
  both the implementer and the reviewer, and by me. It is still the sharpest residual.

---

## Two housekeeping notes for the merge-and-gate agent

1. **The reviewer's `review_r1_probes/` is NOT committed on this branch.** I ran every one of its `.c`
   probes verbatim through its own `rv.sh`, but I deliberately did not commit a copy: my artefacts are
   POST-fix and the reviewer's are PRE-fix, and one directory carrying two generations of `.sub.trace`
   under the same names is L8's "one module under two names with contradictory verdicts" exactly. The
   probes stay in the reviewer's directory in the main checkout; the numbers they produced on the fixed
   binary are in `GATES.md`. Only `probes/w_l_twofn_mixed_clauses{,_unrolled}.c` and their traces — which
   are mine — are added.
2. **Duplicate-body scan run (L8), after the three additions:** sha-256 over each fixture's non-comment
   lines finds **7 duplicate-body groups, all pre-existing pairs** (`control_swap_ifelse{,_derived}`,
   `control_inplace_ry_reject_stale_diag_alias_{forward,backward}`, and five others) and **none
   involving the three new files**. The pre-existing pairs look deliberate (same IR, different prefixes
   and headers) and are not this increment's to adjudicate; recorded so the post-merge scan has a
   baseline rather than a surprise.
3. **The eight `probes/*.trace` files re-generated identically** — `git status` shows no modification to
   any of them after the sweep, which is an independent byte-for-byte confirmation of the twin table.
