# Track P — IMPLEMENTATION brief: the prep merge-φ as a PHASE leaf (bd `3qps`) + the ROOT-ONLY widening (bd `4aiu`)

Worktree: `/Users/sorenwilkening/Desktop/CQ_phiphase`, branch `mergephi-phase-leaf` (already created off
`main` 607b6fe4). Records: `$SES/trackP/` **inside your worktree**. `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/`;
`$PREV` = `…/session-2026-09-13-orchestrator/`.

**READ FIRST:** `$SES/PROTOCOL.md` (binding), `CLAUDE.md` (Prime Directive; Rules 1, 7, 12, 13, 14, 17, 19;
CORRECTNESS RISK §1 the shape table, §2 the fences, §3 L1/L2/L3, §4b the Track-M landing paragraph),
`bd show 3qps`, `bd show 4aiu`, `bd show boi6`, and — as the design of record for the predicate you are
reusing — `$PREV/trackM/SCOPE_M.md` (§0.3 and §4) plus the Track M landing commit `59ac5b7`.

---

## 1. What this increment is — ONE grammar, two consumers

Track M (`59ac5b7`, bd `boi6` D-B / `8xaw`) landed the **region-merge-φ RAIL LEAF** for the 4.4 **DATA
SELECT** consumer: `CondTree::RailPhiLeaves` + `AllowRailPhi` (default `false`; `true` ONLY from
`classifySelectRegion`), ROOT-ONLY, rung 0 admitting the φ **iff** it is the `Merge` of a region already in
the plan as `BranchRegion` with `ClassArm`/`ClassArmFalse == InPlaceRotation` and a non-empty `Shadow` — **by
CALLING `classifyArms`' committed verdict, never re-deriving it** (Rule 14); rung (ii) over
`condProvenance(φ)`; rung (iii) = gate 2c seeded from the φ.

Two consumers were left off that grammar. Both are OVER-DECLINES of valid circuits (owner ruling 2026-09-11:
*"our end-goal is to not decline any code that will lead to a valid quantum circuit"*), and both are the SAME
predicate:

**(a) bd `3qps` — the PHASE consumer.** `if (b1) cq_phi(θ);` where `b1` is a preceding controlled-Ry /
state-prep region's merge φ (SOURCE arm theta + constant seed) declines **`branch phase on a bare i1
condition`** at `classifyPhaseKickback` step 5, while its `int` COMPARE twin lowers (measured on `e96f89c`:
`$PREV/trackM/probes` m26 ACCEPT 25 lines / m08 DECLINE). `condProvenance` gives `{φ, source theta}`;
`walkNonDiagonalWireGates`' backward closure stops at a source theta's classical arg-0 and marks it
on-ancestry exempt, so gate 2c / `railCondWireDisposition` answer **CLEAN** — the blocker is purely the leaf
grammar (`isCondRailLeaf` admits a `cq_theta_i1` CALL; a `PHINode` is off-grammar). Fix = the Track-M
predicate at `classifyPhaseKickback` step 5b with the same three rungs; the kickback emitter needs **zero**
lines (a φ is just another `Value*` control, and after M-β it is the theta call).
⚠ **`p5`/`m20` — the CHAINED arm theta, both incomings one wire — is NOT yours.** That is bd `drbq.7`, a
genuine wire fence. `SCOPE_boi6` §0.3's "the wire fence is the second blocker" transfers ONLY to the chained
shape; the owner-file shape's wire is clean. **Keep `p5`/`m20` declining and pin that.**

**(b) bd `4aiu` — the ROOT-ONLY widening.** A prep merge φ as an **INTERIOR** leaf of a compound condition
(`(b1 && q == 5) ? 2 : 5`) declines `control flow` at `SelectClassify`'s grammar (`V == Root`) — **not** at
the rail ladder (rung 0 passes: its diamond is a claimable state prep). `SCOPE_M.md` §4's stated fence for
m31 was wrong; re-derive it. Widen from ROOT-ONLY to "any leaf of the `and`/`or`/`xor` tree", for the
consumers the ladder already clears.

Ship them as **ONE increment with ONE grammar** — that is the point. Two spellings of the same predicate is
the drbq Inc-3 (b′) defect (Rule 14).

---

## 2. Hazards, named — these bit Track M and will bit you

* **H-1 (measured, cost a counterfactual to find).** The plan's raw `ControlRegion::Condition` **DANGLES**
  after the prep's flatten erased the φ. `SelectMergeEmit` survives only because it **re-reads**
  `cast<SelectInst>(R.Merge)->getCondition()`. Your phase emitter must do the equivalent — read the condition
  from a live anchor at emit time, not from a stale plan field. **Never "fix" it with a `WeakTrackingVH`**
  (that was tried and is wrong: the value is legitimately replaced, not deleted).
* **F-M1 (Track M review r1).** A `SelectRegion` was INERT in `lowerControlRegions`' `hcrg` precedence graph,
  so a following region whose `Pred` is the prep's merge block could push the prep to emit LAST. Fixed by
  recording `PrepRegionIdx` at rung 0 and adding ONE edge "prep before select" **by calling that record**.
  **A phase-kickback consumer needs the same edge** — `reorderable()` currently admits `BranchRegion` /
  `PhaseKickback`; check what your new customer does to the graph and pin it with a probe that puts a second
  region after the phase consumer.
* **L1 — the round-2 window.** Detection+lowering run TWICE. Your rung-0 lookup consults a COMMITTED verdict
  from the plan; state in writing whether that verdict exists at round 1, at round 2, or both, and what
  happens if a region enters the plan only in round 2. Re-ask in BOTH entry points if the answer is "both".
* **L2 — when you WIDEN a set, ask what OTHER set was computed over the same closure.** You are widening the
  leaf grammar in two places. Enumerate every predicate that enumerates leaves (`isCondRailLeaf`,
  `RailLeaves`, `RailPhiLeaves`, the `Specialization::mintCondNetwork` third copy) and say for each whether
  it must widen too — **the answer is not always yes** (L3).
* **The TYPE is the enforcement.** Track M deliberately did NOT retype `RailLeaves` and did NOT widen
  `isCondRailLeaf`. Preserve that discipline or argue explicitly why it must change.
* **Rule 7.** A phase arm is a register-free KICKBACK onto the flag. Nothing non-diagonal touches a user
  register under control. You are changing WHICH values may be a control, never WHAT is emitted on them.

---

## 3. Rule 12 — red-green, fixtures FIRST

lit fixtures for: (P1) the `3qps` accept, `if (b1) cq_phi(θ)` on a prep φ — positive stream CHECKs;
(P2) the same with the state-prep (`StatePrep` kind) rather than the in-place-Ry arm; (P3) the `4aiu`
interior-leaf accept for the SELECT consumer; (P4) the interior-leaf accept for the PHASE consumer;
(P5) **NEGATIVE** — `p5`/`m20`, the CHAINED arm theta, keeps declining with its string mirrored
character-for-character; (P6) **NEGATIVE** — a φ that is NOT a claimed prep region's merge (no committed
`InPlaceRotation` verdict) keeps declining; (P7) **NEGATIVE** — the in-place-**ARM** φ (Track M's pinned
F-M3 decline, whose retirement trigger is "land the `3d8q` fence, then re-derive `condProvenance`'s seed")
keeps declining — **do not retire it, this increment is not `3d8q`**; (P8) a second region AFTER the phase
consumer (the F-M1 ordering probe).

Fixture hygiene (§3 of PROTOCOL, and CLAUDE.md Rule 12's three shipped defects): counts in their own
whole-file prefix, negatives pure, a decline fixture's property is pinned by the `not` inversion on the RUN
line, and run `$PREV/trackM/probes/impl/vacuity.py` over the accept batch.

e2e slices + goldens for at least the `3qps` customer and one interior-leaf customer, STRICT stage 2b.

**Must stay byte-identical:** `slice_control_cascade_two_bools.expected.log` (29 lines), `va` (19),
`slice_control_stateprep_bool_under_int_compare_fused` (22), every `control_peel_*` and
`control_inplace_ry_*` fixture, and every 4.4 select fixture Track M landed.

---

## 4. Gates you own — PROTOCOL §matrix, do not exceed it

Configure + build ONCE per edit batch (`cmake -S . -B build -DLLVM_DIR=$(brew --prefix
llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release`; `cmake --build build -j8`; **never `--target CQPass`
alone**); record `shasum -a 256 build/ir-pass/cq-opt` in `$SES/trackP/GATES.md` after every rebuild. Inner
loop = `lit --filter` + single slices. ONCE at hand-off: `ctest -R ir-pass-lit`, one ORACLE-vs-SUBJECT corpus
sweep → `$SES/trackP/probes/corpus_<hash16>.txt`, one injection matrix over the new accepts with MISSED
reported. **Never** `^e2e-`, the full suite, or the equivalence sweep.

⚠ **Expected corpus movers, for the group gate's attribution:** rows whose ORACLE verdict was
`branch phase on a bare i1 condition` on a region-merge φ, and rows whose ORACLE verdict was `control flow`
at the interior-leaf grammar. **Any other mover is a FINDING.**

---

## 5. Deliverables

`$SES/trackP/{IMPL_P.md, GATES.md, probes/}` in your worktree. `IMPL_P.md` carries: the predicate as
actually spelled (and the proof it is ONE spelling, not two), the L1 answer, the L2 enumeration of every
leaf-enumerating predicate with a per-row verdict, the H-1 / F-M1 dispositions with the probe that pins each,
the fixture table, the corpus movers, the mutation MISSED count, and every gate line as `ran:`/`cited:`.

Commit on your branch (no push, never touch `main`), message `feat(control): bd 3qps + bd 4aiu — …` with the
two `CLAUDE.md` trailers. Then report to the orchestrator: branch tip, binary hash, gate lines, fixture
table, open questions. **Rule 17** — if the real lowering proves hard, bring the question back rather than
shipping a decline. **Rule 19** — report only what you ran.
