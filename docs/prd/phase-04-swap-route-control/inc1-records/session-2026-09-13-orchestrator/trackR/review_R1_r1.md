# Rule-13 REVIEW, round 1 — Track R increment R-1 (bd `rb9x`): F2 excludes the peel's compare CLONES

Independent adversarial review, 2026-09-13, model opus. Subject worktree
`/Users/sorenwilkening/Desktop/CQ_rb9x` (branch `rb9x-f2-clones`, base `main` `81956a2`); ORACLE
`/Users/sorenwilkening/Desktop/CQ_lang/build` (read-only, never written). PROTOCOL.md row **review**:
NO build, NO suite, ONE `lit --filter` spot-check. Probes + runner:
`review_R1_r1_probes/run.sh` (re-runs every row below; it prints both binary hashes first).

## VERDICT: **CLEAR-WITH-ITEMS**

No over-accept found. The three items the brief flagged as able to hide one (1 = the clone's consumer
count, 3 = the two-diamond reach, 4 = `WeakTrackingVH` lifetime) are each answered below with a
measurement or a code fact, and item 3 turned out to have a **second, independent soundness
argument** the implementer did not have — which is a finding in its own right because the record
currently rests on a *structural* unreachability (L6: a structural guard wearing a semantic label).

## The one build-side obligation

```
shasum -a 256 build/ir-pass/cq-opt
221c1caa465db61e3e96ce530fbd51afd25b9cd257b25ceb7966d6d747ee3577   (subject, 2026-09-13 12:38)
fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661   (oracle,  2026-09-11 22:23)
```
Both match what `GATES.md` / `PROTOCOL.md` name. **No finding.** Every `GATES.md` row is therefore a
fact about the binary on disk and is CITED, not re-run:
`cited: ir-pass-lit 1900 discovered / 1899 Passed / 1 XFAIL / 0 Failed @ 221c1caa (impl-R1, 13:06)`;
`cited: injection matrix fixtures=2 mutations=10 MISSED=0 @ 221c1caa (impl-R1, 12:50)`;
`cited: corpus rows=2949 movers=12 accept-with-different-IR=0 @ 221c1caa (impl-R1, 13:02)`.
`ran: lit --filter control_peel_stateprep_bool_seed_int_cond` → **1/1 PASS, 0.49 s** (my one
spot-check, Rule 11).

---

## The three items the brief asked to be answered explicitly

### Item 1 — can the clone acquire a SECOND consumer before F2 asks?

**No, and the question is the safe-direction one anyway.**

*Code fact.* `MergePhiPeel.cpp:483-520` makes **one clone per peeled φ** inside
`for (PHINode *Phi : S.Phis)`, resets `CondV` each iteration, and the clone's only use is the
`SelectInst::Create(CondV, …)` on the next line. `taint.PeelClones.push_back(Clone)` (`:516`) is the
**single** write site in the tree (`grep -rn PeelClones ir-pass/` → one push, one read at
`ArmClassify.cpp:1683`). `Seeds.push_back(Clone)` (`:517`) feeds `propagateFromSeeds` (`:613`), which
only *inserts into `Tainted`* — it creates no instruction.

*The window.* Peel → last F2 query is `{adjudicateTaintDelta (:452/:939), detectControlRegions (:455),
lowerControlRegions (:456), repropagateControlMerges (:489) — which re-peels, re-detects and re-lowers
to a fixpoint}`. Nothing in it manufactures a user of a `CmpInst`: `adjudicateTaintDelta` runs
`foldIdentityBitcasts` / `replanReseedSpecialization` / `detectSpecializations` /
`declineTaintEscapes` / `declineStaleRecordOps`, and the only instruction-creating RAUWs reachable
there target a `PHINode`, a `SelectInst` (`SelectMergeEmit.cpp:310`), a `BitCastInst`
(`TaintPropagation.cpp:491`), a `FreezeInst` (`:939`) or a call (`Specialization.cpp:745`). I
re-derived that list from `grep -rn replaceAllUsesWith ir-pass/src/*.cpp` and the stage order in
`CQLoweringPass.cpp:114-646`; the implementer's §1e claim reproduces.

*Direction.* Even a hypothetical second consumer is an **over-DECLINE** risk, not an over-accept: a
derived value (a `zext`, say) is **not** excluded by R-1, so it collides and F2 declines — which is
exactly what `probes/zext_sel_hand.ll` measures (below). The preimage argument does not depend on
consumer count; retirement trigger (a) in `TaintPropagation.h` is the right place for it.

*The brief's sub-question — a peeled SELECT over `i1`s.* The select is **NOT** excluded, correctly:
`PeelClones` receives `Clone` only; `Sel` goes to a different vector (`Seeds`). Its preimage is the
source φ, so the rival "the author rotated the merged value" is a well-formed program and the decline
is right. I could not build a module where a peeled `i1` select is the *deciding* collider, and the
reason is structural and worth recording: `f2Model`'s select arm (`ArmClassify.cpp:1211-1220`)
**unions** the two arm ranges, so the select pins only when every tainted arm pins to the same
constant — and then that arm is itself an un-excluded collider. My two attempts each hit an earlier
fence (`probes/sel_i1_pinned.ll` → `condition data use neither escaped nor measured`, both binaries).
Reported as an unmeasured cell, not as a clearance.

### Item 3 — the two-diamond composition `reorderable()` admits, and whether R-1 excluding a FOREIGN clone is correct

**(a) Reachability.** `sequentialChainAlias`'s `reorderable()` (`SwapRouteEmit.cpp:2494`) is only
consulted when two regions **alias blocks** (`A.Pred == B.MergeBB`). Two diamonds separated by a
padding block never ask it. I built that (`probes/td2_pad.ll`, `probes/td3_valueB.ll`):

| probe | ORACLE | SUBJECT |
|---|---|---|
| `td2_pad.ll` (B = a 2-φ diamond whose arm is itself a prep) | `control flow` @ `br i1 %g` | `control flow` |
| `td3_valueB.ll` (B = a 2-φ **value** region; padding block; no alias) | **ACCEPT** | **ACCEPT**, byte-identical |

So the composition IS reachable past `reorderable()` — the implementer's "unreachable at HEAD" is
true of the `hcrg` chain shape (`td1.ll`) and **not** of the general two-diamond shape. But in
`td3_valueB` F2 never fires (the `zext`+`icmp eq` between the two conditions breaks the fold chain),
so it is not yet an instance of the §3b hazard either.

**(b) And the hazard is SEMANTICALLY DOMINATED, which is a stronger statement than the bisect.**
Whenever a foreign clone is pinned on this region's edge, its **ORIGINAL** is reached by the same
walk and folds to the same constant:

* the clone is a bit-copy of the original (`S.CondCmp->clone()`), so the two have the *same operands*
  — if the clone is visited as a user of a popped `V`, the original is a user of `V` too;
* the original is **tainted**: `MergePhiPeel.cpp:304` gates the whole peel on
  `taint.Tainted.count(BI->getCondition())`, so `:1623`'s `if (!Taint.Tainted.count(I)) continue;`
  does not skip it;
* they fold identically: `f2Model`'s `ICmpInst` arm (`:1198-1208`) reads only the operand ranges and
  the predicate, and **`f2Refine` passes `CxtI = nullptr` at all four of its calls**
  (`ArmClassify.cpp:982-996`), so it is position-insensitive — the merge-block clone and the
  pred-block original cannot diverge.

Therefore exactly one of two things is true of a foreign clone: either the original is **not** in
`CondWire`, in which case it still collides and F2 declines **with or without R-1** (R-1's exclusion is
a no-op); or the original **is** in `CondWire`, in which case the value the clone computes is already
blessed as a non-collider **on this very edge** by the shipped 2026-09-11 narrowing, and excluding its
copy adds nothing. **R-1 cannot produce an accept the shipped `CondWire` exclusion does not already
license.** Grade: the §3b accept is **correct**, by an argument that does not need the preimage one.

**(c) The fixture's retirement trigger — right file, overstated claim.**
`control_peel_reject_stateprep_two_region_foreign_clone.ll` says *"the day bd `35t0` is closed this
file becomes an ACCEPT, and at that moment the preimage-vs-wire distinction becomes load-bearing
rather than theoretical."* The first half is a good L8 trigger and should stay. The second half is
what I would change: by (b) the distinction is **not** load-bearing for soundness, and leaving the
record saying it is invites a future agent to BLOCK the `35t0` widening on a hazard that does not
exist (the L6 shape — a structural guard read as a semantic one). Graded **DOC**; the fix is two
sentences in the fixture header and in `TaintPropagation.h`'s preimage paragraph, recording the
domination argument *beside* the preimage one, not instead of it. ⚠ I am not asking for the preimage
argument to be weakened: it is the one that covers a clone whose original is neither in `CondWire`
nor reachable, and it is the honest ground for the one-diamond case.

### Item 4 — `WeakTrackingVH` lifetime

**Nulls on delete; follows RAUW; neither is a live over-accept.** `llvm/IR/ValueHandle.h:198-201`
(LLVM 19, the header this build links against): *"tries hard to point to a Value, even across RAUW
operations, but will null itself out if the value is destroyed"*; `CallbackVH::deleted()`'s docstring
at `:403-419` states that `WeakTrackingVH` would `setValPtr(NULL)` on destruction and
`setValPtr(new_value)` on RAUW.

* **Address reuse cannot produce a false positive.** The entry becomes **null**, not stale, and
  `isPeelClone` (`TaintPropagation.h:344-351`) tests `P && P == V`. A new instruction at the same
  address compares against a null entry and does not match.
* **RAUW is the real hazard and it is correctly named as retirement trigger (c).** I re-derived the
  measurement: the only `CmpInst` RAUW in the pass is `rewriteCompare`
  (`CompareLowering.cpp:488,530`), which runs in `lowerOps` (`CQLoweringPass.cpp:646`) — **after both
  control rounds**, i.e. after the last F2 query. Every RAUW reachable in the peel→F2 window targets a
  φ / select / bitcast / freeze / call (item 1 above).
* **Container safety, not in the record and worth one line.** `SmallVector<WeakTrackingVH,4>` growth
  and `TaintSet`'s by-value return from `propagate` (`CQLoweringPass.cpp:114,755`) both go through
  `WeakTrackingVH`'s copy constructor — `ValueHandleBase` declares one and declares no move
  constructor, so the handle re-registers in the use-list and the moved-from entry is destroyed
  properly. This is standard LLVM usage and it holds here; no finding.

---

## Findings

| # | grade | finding | reproducer |
|---|---|---|---|
| R1r1-1 | **DOC** | §3b's foreign-clone reach is **semantically dominated**, not merely structurally unreachable (item 3b). The two-diamond fixture's retirement trigger overstates the residual, and the padded composition (`td3_valueB.ll`) shows `reorderable()` is NOT the only wall the bisect thought it was. | `review_R1_r1_probes/td3_valueB.ll`, `td2_pad.ll` |
| R1r1-2 | **OVER-DECLINE** | The `zext` of a **peeled select** is a live collider and is not excluded, so an `i1` mux read as an `int` beside an `i32` prep declines `state prep seed is proven equal to the condition register` on BOTH binaries. This is §3e's class one level out from `r_R4`, it is the conservative direction, and it has **no bd** — under the owner's 2026-09-11 ruling an over-decline of a valid circuit is a defect to file. | `review_R1_r1_probes/zext_sel_hand.ll` (DECLINE / DECLINE) |
| R1r1-3 | **DOC** | IMPL §7.4 confirmed by measurement: `control_peel_stateprep_datamux_peeled_control.ll`'s `CPCNT-COUNT-3: @cqrt_copy_` matches **2 calls + 1 `declare`**. It is a MIS-LABELLED count, not a dead check (4 occurrences would trip the `-NOT`, 2 would fail the COUNT), and it hides nothing R-1 changes — the fixture's lowered IR is byte-identical on both binaries. The new R-1 accept fixtures already spell their counts `call void @…`, which is the right form. | `grep -c @cqrt_copy_` on the lowered IR = 3, of which 2 are calls |
| R1r1-4 | **DOC** | One probe of mine **measured a different program** and is reported as such (Rule 19): `zext_of_peeled_select.c` — `-O1` const-folds `b0 > 7` on the `b0 == 1` edge, deleting the mux, so it ACCEPTS on both binaries and says nothing about the `zext` reach. The hand-IR spelling (R1r1-2) is the real measurement. This is the L5 lesson in miniature. | `review_R1_r1_probes/zext_of_peeled_select.c` |
| R1r1-5 | **OVER-DECLINE (pre-existing, not created by R-1)** | `R2_p80_window` → `control flow`; `R4_p80_measured` → `condition measured before the control route`; `b_HP_b_orig` → `condition data use neither escaped nor measured` (unchanged on both binaries, so the "region's own compare given a data use" cell is still untested against R-1, as IMPL §7.9 says). All three are second fences behind F2. | runner rows |

**Nothing graded CONFIRMED-MISCOMPILE, OVER-ACCEPT-ARGUED or LEAK.**

---

## Item-by-item on the rest of the brief

**Item 2 — `O3_mux_quantum_incomings` and `R1_p80_bool`, the customers the scope did not measure.**
Both re-derived from their stage-1 IR and both are **correct**.

*O3* (`bool c` from an `i32` theta ⇒ the condition is `icmp eq i32 %3, 0`, so the peel DOES clone; the
arm is the `c == 0` / else arm). Emitted on the SUBJECT, 23 lines, STRICT 2b `5 mints, 5 left
allocated, 2 frees: 2 verified, 0 violation(s), 0 unproven`: `alloc/ry` for `p`,`q`,`c`; flag
`icmp_eq(h2,0)`; `alloc_i1(0)→h4` + `ry_i1_controlled(h3,h4,.5)` (the prep, fired on the else
polarity, **no** `cqrt_x` needed because `-O1` already inverted the compare); strip + free; then the
mux as the ordinary 4.4 merge `copy_i32_controlled(h5,h1,h6)` / `x` / `copy_i32_controlled(h5,h0,h6)`
/ `x` / strip / free, with `p` and `q` **kept live and measured** — Rule 8's keep-sources-live
additive copy, not a clone. F2's only pre-R-1 collider was the clone: on the FALSE edge the region's
own condition is `false` = the `i1` seed but is in `CondWire`, and the clone is the same value one SSA
name over.

*R1_p80_bool* — the **round-2** customer, and the one §1f's line-number argument needed an end-to-end
witness for. 33 lines, STRICT 2b `8 mints, 8 left allocated, 3 frees: 3 verified, 0 violation(s), 0
unproven`. Read as a circuit: `h0 = Ry(.5)|0>` (`q`); flag `h1 = (h0==1)`; the 6.5 `%out` rail `h2`
gets `13` under the flag and `0` under `x(h1)`; strip + free `h1`; flag `h5 = (h2==13)`, **`x`-
bracketed** so the prep fires on `¬(r==13)` — which is exactly `a >= 3`, since `a = (r==13) ? 2 : 5`;
`alloc_i1(0)→h6` + `ry_i1_controlled(h5,h6,.5)`; strip + free; then the `a` mux on a third flag. The
prep reads the predicate off `r` directly rather than off the `a` rail, so the prep region and the `a`
region are block-diagonal in `h2`'s basis and act on **disjoint** targets (`h6` vs `h8`) — they
commute, which is why emitting the prep before the mux (opposite to source order) is the same unitary,
the same argument the 2026-09-11 landing records.

*The direction argument of SCOPE §3b, measured for both.* I built the nearest UNPEELED twin of each
(`tw_O3.c`: the `a` mux deleted; `tw_R1p80.c`: the `a` mux deleted and the guard spelled as the
predicate `-O1` folds `a>=3` into) and **both ACCEPT on the ORACLE**, byte-identically on both
binaries. R-1 moves the peeled form *towards* its already-shipped twin, not past it.

**Item 5 — the `zext` reach and the `i1`-only claim.** `r_R4_i32seed_i1clone.ll` and the committed
`control_inplace_ry_reject_stateprep_zext_flag_i32seed.ll` both still DECLINE on the SUBJECT, by
design (§3e). The extension the brief asked for — the SELECT (not the clone) zexted and pinned — also
declines on both: **R1r1-2**, `zext_sel_hand.ll`. Correct behaviour, filed as an over-decline.

**Item 6 — the fp fixture, on the SUBJECT, with its own anchor.**
```
CQ_CTRL_DBG=1 … control_peel_reject_fp_stateprep.ll
CQ_CTRL_DBG: decline [state prep seed is proven equal to the condition register] at:   %3 = icmp eq i32 %2, 1
```
Same string, same anchor, on the R-1 binary — the red-green witness for "at the TEST, never pruning
the walk" holds. The header's retirement-trigger paragraph is accurate as written.

**Item 7 — see R1r1-3.**

**Item 8 — over-declines met in passing — see R1r1-5.**

**Item 9 — every accept's `-O1` reachability and state vector; every decline's validity.**
The R-1 slice was re-measured end to end on the SUBJECT against its committed golden: **22 lines,
byte-clean diff**, STRICT 2b `10 mints / 10 left allocated / 4 frees: 4 verified, 0 violation(s), 0
unproven` (the doubling is the `-O1` inline of `slice()` into `main`, as the slice header says). The
two `cqrt_x` are on the compiler-minted flags `h1`/`h3`, never on a user register (Rule 7), each
bracket closed before its `_unc` strip and its proven-`|0>` free; the prepped rail `h2` and the mux
out-rail `h4` with its two operand rails are **left allocated** (Rule 6, `Ry(.5)|0> != |0>`).
`control_peel_stateprep_datamux_peeled_control.ll` (the hand-written `%cq.peel.cond`) and
`control_peel_reject_stateprep_handwritten_clone_i1.ll` are **byte-unchanged / still declining** on
both binaries — the RECORD-not-a-name property SCOPE §2 spelling (ii) turns on.

**One probe of the disclosed absorption, because CLAUDE.md §4 is the paragraph R-1 lands next to.**
The β shape (*the straight-through incoming is the live condition register `(b0 == 1)`, which `-O1`
folds to the seed*) in its **peeled** spelling declines at `condition data use neither escaped nor
measured` on BOTH binaries, as does its unpeeled twin (`beta_alias_peeled.c` /
`beta_alias_unpeeled.c`). So in that spelling R-1 does not extend the disclosed α/β absorption to a
new population. ⚠ One spelling, not a theorem (L5).

## What I did NOT run, and what that leaves open

No build, no `ctest`, no corpus sweep of my own, no injection matrix (PROTOCOL.md's review row). I
read `probes/impl/corpus_221c1caa.txt`'s summary and `injection_matrix.txt` rather than re-running
them, and I verified **5 of the 12 movers by hand** (the two new fixtures via the slice and the lit
spot-check, plus `O3`, `R1_p80_bool`, `R2_p80_window`, `R4_p80_measured`). The seven I did not open
are the three duplicated `b_A`/`b_P2`/`b_P2t` pairs IMPL §7.8 already reduces to three distinct
programs. Unmeasured cells named above: a peeled `i1` **select** as the deciding collider (item 1),
and the §3b hazard as an actual F2 instance rather than as the dominance argument (item 3).
