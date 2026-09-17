# Track D2 — bd `test_C_libtooling-drbq.12` — FILE SURFACE (STEP 1, written before the first edit)

Branch `drbq12-hoisted-compare-p4`. Worktree
`/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ad7349188dd3b67bd`.

ORACLE verified at session open: `build/ir-pass/cq-opt`
`9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3`,
`libCQPass.so` `3e3dc35d…` — and the worktree's **own** clean build reproduces BOTH hashes
byte-for-byte (`GATES.md` line 1). So every "ORACLE" measurement below is reproducible in this
worktree and no cross-checkout binary was used for a subject/oracle diff.

---

## 1. FILE:FUNCTION SURFACE — the orchestrator's Group-2 question first

**`WireWalk.{h,cpp}` is NOT touched.** No group-topology change. Neither is
`RegionTreeDetect.cpp`, `SelectClassify.cpp`, `AngleSelectEmit.cpp` (see §5 — filed, not built).

**One pass-source file: `ir-pass/src/ArmClassify.cpp`.** Five hunks, all inside two regions of the
file, both far from Track X's declared surface (`condProvenance` ≈ `:231-261`, the §3c clobber prong
≈ `:5774`):

| # | anchor (HEAD line) | what |
|---|---|---|
| D2-1 | ≈ `:2785`, inside the anonymous namespace `2453…2956` | NEW file-local helpers: `anyInstructionInGap` (the CFG-bounded gap walk, EXTRACTED from `chainedThetaBetweenDefAndBranch` verbatim), `condRailMembers`, `crossBlockCompareMintable` |
| D2-2 | `chainedThetaBetweenDefAndBranch` body, ≈ `:2785-2843` | re-expressed as ONE call to `anyInstructionInGap`. Behaviour-preserving; no caller changes |
| D2-3 | `condWireDisposition` P4, `:2871` | the cross-block prong: `!ShareCondFlag && crossBlockCompareMintable(...)` admits; everything else keeps the unconditional decline |
| D2-4 | `classifyPhaseKickback` step 5a, `:6454` (`Leaf->getParent() != Region.Pred`) | same predicate for a TREE's compare leaf |
| D2-5 | `classifyPhaseKickback` step 6 `scanForward`, ≈ `:6980` | DELETED and replaced by `chainedThetaBetweenDefAndBranch` — **this is not my choice, it is the L8 RETIREMENT TRIGGER written into that block in Track P′'s own words**: *"the day step 5a's cross-block compare-leaf decline is widened, delete `scanForward` and give BOTH loops this helper — a single window must not survive as the weaker of two spellings of one question (L2)"*. Byte-identical for an in-`Pred` leaf, which every leaf reaching that loop is today |

No header changes: every symbol I add is file-local (the anonymous namespace at `2453`), and
`chainedThetaBetweenDefAndBranch` / `condWireDisposition` / `railCondWireDisposition` are already
file-local there.

Other files: `ir-pass/test/*.ll` (new fixtures + two pinned over-decline fixtures converted),
`tests/e2e/slice_*.c` + `.expected.log` + the ONE tail anchor in `tests/e2e/CMakeLists.txt`, and
`$SES/trackD2/` records.

**What Track X must know** (⚠ **CORRECTED — this paragraph said the opposite in its narrowing half
until the independent Rule-13 round F-2; the false text is quoted in §6 E4 so the correction can be
scored, and it is fixed HERE, in the paragraph Track X actually reads**): I do not read or write
`condProvenance`'s body, and I do not touch the §3c clobber prong. I *call* `condProvenance`
(unchanged) from a new helper at `:~2800`.

`condRailMembers` builds a **GATE** set — the SSA names that may denote the condition's rail, against
which an instruction in the gap is scored as evidence. So the directions are **NOT** symmetric and
**NOT** both safe:

* **NARROWING `condProvenance` is the ACCEPT direction and is an OVER-ACCEPT RISK for this prong.**
  Fewer seeds ⇒ a smaller `Members` ⇒ fewer gap instructions count as evidence ⇒ more modules are
  admitted. That is exactly the direction CLAUDE.md already calls a Rule-13 change to **R4**
  (*"NARROWING `condProvenance` IS A RULE-13 CHANGE TO R4 … would make R4 VACUOUS with every fixture
  still green"*), and after this landing that cone has a FOURTH consumer with the same exposure.
* **WIDENING it is the DECLINE direction for this prong** (a bigger rail set means more gap gates
  count) — which is safe here and is the direction that is an **over-ACCEPT for F2**, whose exclusion
  set fails the other way.

So the cone's three consumers now fail in different directions and no single sentence covers them:
narrowing endangers R4 **and this prong**, widening endangers F2. `IMPL_D2b.md` §2 already carried the
corrected reading; §1 did not, which is what F-2 found.

⚠ **Composition with Track X as parked (`99269301`), measured by the reviewer and not by me:** Track X
leaves `condProvenance` untouched and adds a file-local narrower sibling
(`condProvenanceInActivation`, used only by `clobberHoldsPerActivation`), so the two compose today
with no shared-cone change. The hazard is the NEXT agent, not this merge.

⚠ **OWED, and deliberately NOT taken in this commit:** the reviewer's F-2 fix also asks for one
sentence at `condRailMembers`' own header, whose comment is correct about *widening* and SILENT about
*narrowing*. This follow-up commit is records-and-headers only — `ir-pass/src` must stay byte-frozen
so the gates cited at `cq-opt 5ee9d144…` remain citable — so that edit is recorded here as an
ABSENCE with its exact text, to be applied by the next change that touches this file:
*"⚠ NARROWING `condProvenance` is the ACCEPT direction for THIS caller (a smaller Members set scores
fewer gap instructions as evidence) and is therefore a Rule-13 change to this prong exactly as
CLAUDE.md already says it is to R4 — the same cone, the opposite direction from F2's."*

---

## 2. THE MECHANISM, in one paragraph, because the surface only makes sense with it

P4 is the line `if (!CondIsClaimedRailPhi && Cond->getParent() != R.Pred) return DeclineNow;`
(`ArmClassify.cpp:2871`). Its own header says why it exists: the P5 positional scan
(`chainedThetaBetweenDefAndBranch`) *"walks off the end of `Def`'s block and returns `false`
VACUOUSLY"* everywhere but `Pred`, *"which is precisely why the callers paired it with an
unconditional `getParent() != Pred → DeclineNow`"*. **Track P′ (bd `hn29`/`leyd`/`52og`, 2026-09-15)
already made that scan a real CFG-bounded walk** — but flipped the pairing off for exactly ONE
species, a claimed prep merge φ, and left every COMPARE on the unconditional decline. This track
flips it for a compare, and pays the price P′ deliberately did not: P′'s cross-block walk is
WIRE-BLIND, and the gap for a hoisted loop-invariant compare contains **the arm's own `cq_theta` on a
disjoint rail** (measured: without a wire filter the 16 row-W cells trade a P4 decline for a P5
decline and move ZERO). So the new prong is the PRD §13.10 Q1 remedy verbatim — *"admit a compare
that DOMINATES `Pred` when nothing on the CONDITION's wire stands between it and `BI`"*.

⚠ **CORRECTED — §6 E3 and E5.** The sentence that stood here said the gap walk's *"vocabulary
[is] **widened** to the dtzb in-place `add`/`sub`/`xor`"*. That fence was BUILT, MEASURED as a pure
over-decline and REMOVED; the shipped ground for the `add` is the **G6/G7 ORDER interlock**, with its
own retirement trigger. §4 below is corrected by E3 and this paragraph by E5 — read both before
quoting §4.

---

## 3. THE CUSTOMER LIST — measured on the ORACLE, not predicted

Pipeline: `$SES/PROTOCOL.md` per-probe, `-O1 -g`, `cq-opt` `9bd01598`. Sources regenerated READ-ONLY
from `tools/loop_twin_matrix.py`'s `sources(..., surface="void")`; the matrix itself was NOT run and
its tables were NOT touched (Track V owns them, ROUTING R14).

### 3a. The 16 `DECLINE-BOTH` row-W twin cells — ALL 16 CONFIRMED, both halves

Every one prints, on BOTH the rolled and the unrolled side,
`cq controlled lowering: condition predates a non-diagonal gate under quantum control`:

```
m_none_req_none_none_{none,rypost,rypre,rzpost,addpost}      (5)
m_none_req0_none_none_{none,rypost}                          (2)
m_none_rne_none_none_{none,rypost}                           (2)
m_none_rrange_none_none_{none,rypost}                        (2)
m_none_rder_none_none_{none,rypost,rypre,rzpost,addpost}     (5)
```

⚠ **This widening moves ACYCLIC programs, and that is not a side effect — it is HALF THE
POPULATION.** The `.unrolled` half of each of those 16 is a FLAT, loop-free module. Measured on the
`-O1` IR of `m_none_req_none_none_none.unrolled` (dumped in `probes/`): `clang -O1` CSEs the two
`if (a == 5)` compares into ONE `%3 = icmp eq i32 %1, 5` in the entry block, region 1's `Pred` IS the
entry block (so region 1 passes P4 today) and region 2's `Pred` is region 1's merge `%6` — so **the
flat customer is the SECOND of two sequential regions sharing a CSE'd compare**, not a loop at all.
32 modules, 16 rolled + 16 flat.

### 3b. The `binv` i1 cell — a customer of the OTHER spelling, and it declines a DIFFERENT string

`m_none_ablphi_none_none_binv` (bd `drbq.12` note 2026-09-14, Track T / bd `uq96`):
`for (…) { if (b && a == 5) cq_phi(M_PI); }` with `_Bool b`.

* rolled: `exit=1`, **`cq controlled lowering: control flow under quantum control`** — NOT the P4
  string. It is `classifyPhaseKickback` step 5a's `Leaf->getParent() != Region.Pred`, the TREE
  spelling of the same fence (D2-4).
* unrolled: **`exit=0`, ACCEPT** — the LIVE FLAT TWIN the bd note names.

### 3c. The two shipped fixtures pinned as OVER-DECLINES KEPT (both become ACCEPTs)

* `ir-pass/test/control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll` — the Ry stem, PRD §13.2
  row W. Its header is my L8 trigger and names this bead.
* `ir-pass/test/control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll` — **the Rz stem**, the
  "identical over-decline exists for the shipped Rz stem" the bead and the PRD both promise. Its own
  header: *"THIS IS bd `drbq.12`'s OVER-DECLINE ARRIVING AT THE PHASE STEM"*.

### 3d. TARGET STREAMS, read off the ORACLE from the spelling that already accepts

PRD §13.2 records that the matrix uses `if (a == off)` (a `volatile int off`) because it defeats both
LICM and CSE. `m_none_oeq_none_none_none` is `ACCEPT-IDENTICAL` in
`tools/loop_twin_matrix.expected.txt`, and it is the literal-for-opaque twin of
`m_none_req_none_none_none`. Measured on the ORACLE (`probes/target_oeq_rolled.txt`), STRICT stage 2b
`2 rail mint(s) of which 2 left allocated, 1 template rail mint(s) of which 0 left dirty, 2
cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`:

```
cqrt_alloc_i32(0) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cqrt_alloc_i32(0) -> h1
cqrt_ry_i32(h1, 0x1.3333333333333p-2)
cq_template_icmp_eq_i32_hl(h0, 3) -> h2          <- PER TRIP: mint at BI, in the loop
cqrt_ry_i32_controlled(h2, h1, 0x1.ccccccccccccdp-1)
cq_template_icmp_eq_i32_hl_unc(h2, h0, 3)
cqrt_free(h2)
cq_template_icmp_eq_i32_hl(h0, 3) -> h3          <- trip 2
cqrt_ry_i32_controlled(h3, h1, 0x1.ccccccccccccdp-1)
cq_template_icmp_eq_i32_hl_unc(h3, h0, 3)
cqrt_free(h3)
cqrt_measure_i32(h0) -> 0
cqrt_measure_i32(h1) -> 0
```

**The target for `m_none_req_none_none_none` is this stream with `3` replaced by the literal `5`**,
because the ONLY difference between the two C programs is `off` (a `volatile` load) vs `5`. The
increment is therefore an **ACCEPT-only widening onto an already-Rule-13-cleared stream** — the
2026-09-13 method — and the witness is a byte-comparison against that stream, not a new argument.

⚠ **The flag is minted at `BI`, hence PER TRIP, even though the compare is hoisted and evaluated
ONCE.** That is the right circuit and the reason is the hoist's own precondition: LICM hoists only a
loop-invariant compare, so the compared SSA name does not change across trips; and if the *rail*
changed under an invariant name, the wire walk's position-aware prong declines it (a body gate can
reach `BI` around the back edge, so `provablyBefore(BI, T)`'s second conjunct fails). Both halves are
probed in `IMPL_D2b.md` §5.

---

## 4. THE RE-DERIVATION THIS TRACK OWES BEFORE IT WRITES A LINE (and it is written into the callee)

`chainedThetaBetweenDefAndBranch`'s header carries an explicit trigger:

> ⚠ AND THE AVAILABILITY HALF HAS A TRIGGER OF ITS OWN: it is an argument about what can be SPELLED
> in the gap, so **the day this helper gains a caller whose `Def` is NOT a region merge φ — a plain
> compare leaf, say, if step 5a's cross-block decline is ever widened — re-derive it.** A compare is
> a snapshot, not a register, and neither half of the argument above transfers unexamined.

I am that caller. Both halves of P′'s ground fail for a compare and I do not use either:

* P′'s half (1) — *"the only names of the condition rail available in the gap are the φ itself and
  values derived from it"* — is **FALSE for a compare**. A compare's tainted operand is an ordinary
  register that dominates the compare, so `%q2 = add i32 %q, 1` in the gap is perfectly valid SSA.
* P′'s half (2) — M-C's G6 refusing the in-place conversion because the φ *"is ALWAYS READ LATER"* —
  does not transfer either: the compare reads `%q` BEFORE the gap, and the branch reads the
  *compare*, not `%q`.

So instead of inheriting the argument I **widen the gap walk's vocabulary** to cover exactly what the
argument used to excuse: an `add`/`sub`/`xor` with a single tainted operand **on the condition's rail**
is evidence, alongside a chained `cq_theta` on the condition's rail. That is a FENCE, not an
argument, and it is strictly stronger than what `wireGainsNonDiagonalGate` can see, because
`WireWalk`'s forward walk deliberately does NOT cross an in-place self-update
(`WireWalk.cpp:~790`, a measured decision) while `railWireClosure` DOES.

⚠ **`condRailMembers` is a THIRD caller of `railWireClosure` and it is deliberately NOT the F2/R4
`CondRails`/`CondWire` spelling.** It uses `WireDir::BothWays`, they use `BackwardOnly`. That is not
drift, and it does not fire CLAUDE.md §4's *"`railWireClosure` as called by F2 diverges from R4's
`CondRails`"* trigger, because **I do not touch either of those two call sites** and the three ask
different questions with opposite failure directions: widening F2's set is an **over-ACCEPT** (21
recorded confirmed miscompiles), widening mine is an **over-DECLINE**. A gate test wants the whole
rail; an exclusion set wants the provable core. Folding all three into one helper would make the
strictly-safe direction of one of them govern the strictly-unsafe direction of the others, so it is
refused **in writing** here rather than left to a later tidy-up.

---

## 5. WHAT IS FILED AND NOT BUILT — the other three of the "four callers"

PRD §13.10 Q1 calls this *"a sibling-spelling change shared by four callers (this path, the 4.4
select's gate 2c, 2b's S6, and the `RegionTreeDetect` nest)"*. I build **two** spellings of the
`Pred`-residency question (`condWireDisposition` P4 and `classifyPhaseKickback` step 5a) because
those are the two with measured customers in front of me. The other three are measured, recorded and
filed with their exact line numbers in `IMPL_D2b.md` §9 and a bd text in §bd:

* `SelectClassify.cpp:1174` — gate 2c, `Leaf->getParent() != Sel->getParent()`. A **select** has no
  `Pred`/`BI` pair; its mint point is the select itself, so the walk's `Pred` argument has no subject
  without first deciding what the region's mint block is. Different question, not a sibling spelling.
* `AngleSelectEmit.cpp:135-136` and `:358` — S6 requires `T`, `Cond` and `Sel` in ONE block; same
  objection, and the Ry stem additionally subtracts two angles.
* `RegionTreeDetect.cpp:380` — `Cond->getParent() != BI->getParent()` for the depth-2 nest. This one
  IS a true sibling and would take the same call; it is out because a nest has TWO conditions and two
  `Pred`s and its accept class was never measured for this family.

⚠ Leaving three spelled differently is exactly what bd `sibling-predicate-spelling-is-the-hole` is
about, and I am recording that rather than pretending otherwise. The mitigation is that all three
remain on the STRICTER side (an unconditional decline), so the hole is an over-decline, not an
over-accept.

---

## 6. ERRATA — written AFTER the work, against this file's own STEP-1 claims

This section exists because a scoping document that is quietly overwritten stops being
a prediction anyone can score (L7-with-a-twist: a correction that is not applied where
the claim lives is not a correction). Three of §1–§5's statements were wrong.

**(E1) The customer list in §3 was INCOMPLETE — it named 2 shipped fixtures and the
true number is 4.** The `ctest -R ir-pass-lit` run turned up two MORE pre-existing decline
fixtures that this widening flips, neither predicted here:

* `control_phase_kickback_reject_tree_cross_block_leaf.ll` — a tree with a cross-block
  COMPARE LEAF. Its own header already said *"IT IS AN OVER-DECLINE AND A KNOWN ONE …
  transferring it is a change to a Rule-13 positional fence and belongs to a round with
  its own probe family."*
* `control_swap_reject_seq_shared_cond.ll` — two sequential PHASE regions on one CSE'd
  compare, i.e. §3a's acyclic shape in its purest form.

Both were converted with arguments in `IMPL_D2b.md` §6–§7. The lesson is the one PRD
§13.11 worry 7 already records one level up: **a probe set chosen from the customer
program shares the customer program's accidental properties.** The customer here was
an in-place-Ry arm; both missed fixtures are PHASE arms.

**(E2) §5's claim that `SelectClassify.cpp:1174` is a sibling still on the
unconditional decline is HISTORY, and the correction was found in a fixture header
rather than by my scoping read.** `control_phase_kickback_reject_tree_cross_block_leaf.ll`
records that *"the 4.4 select LIFTED the equivalent blanket cross-block decline (bd
`9ymx`, owner decision 2026-07-03)."* So PRD §13.10 Q1's "four callers" line is stale
in at least one of its four, and the residue §5 files is smaller than §5 claims.

**(E4) §1's "What Track X must know" stated `condProvenance`'s NARROWING direction BACKWARDS, and
§6 did not correct it** — found by the independent Rule-13 round (F-2), which calls it
L7-with-a-twist *"in its exact shape: a record correction that is not applied where the claim lives
is not a correction."* The false sentence was:

> *"a narrowing is an over-DECLINE for me (safe) … My prong is the one consumer of that cone whose
> failure direction is decline-safe in BOTH directions."*

`condRailMembers` is a **GATE** set, so a NARROWING shrinks it, scores fewer gap instructions as
evidence, and is the **ACCEPT** direction — an over-accept risk, exactly as for R4. `IMPL_D2b.md` §2
already said so (catching itself mid-sentence); §1 did not, and §1 is the paragraph Track X and the
orchestrator read. **§1 is now fixed in place**, not merely errata'd. The reviewer's companion ask —
one sentence at `condRailMembers`' own header — is recorded in §1 as an explicit ABSENCE with its
exact text, because this follow-up is records-and-headers only.

**(E5) §2 carried the same stale dtzb claim E3 corrects in §4**, and the round (F-3) found it in two
shipped fixture headers as well. All three are rewritten to the G6/G7 ORDER interlock, with a
retirement trigger naming what would break the ORDER: control emission ceasing to precede
`lowerOps`, or a pre-loop `taint.InPlaceRailOps` commitment reaching the gap.

**(E3) §4's shipped answer is NOT the fence §4 describes.** §4 said the availability
re-derivation would be answered by *"WIDEN[ing] the gap walk's vocabulary … to the
dtzb in-place `add`/`sub`/`xor`"*. That fence was built and MEASURED to be a pure
over-decline (`probes/dtzb_flat_red.ll` — the add lowers OUT of place), and it was
REMOVED. The shipped answer is the ORDER INTERLOCK, which is measured rather than
argued: control emission runs before `lowerOps`, so an in-place candidate in the gap
is exactly a candidate M-C's G6 refuses. `IMPL_D2b.md` §3 carries it, and the two
shipped fixtures `control_inplace_ry_crossblock_cond_{outofplace_add_in_gap,
inplace_add_after_loop}.ll` carry both halves of the measurement.

⚠ **What §4 got RIGHT and is worth keeping:** the `add` still has to be crossed in the
MEMBERS closure, and that half survives — it is what makes
`control_inplace_ry_reject_crossblock_cond_theta_behind_add.ll` the one fixture that
individually pins the gap scan, and it costs exactly one measured over-decline.
