# Track X — IMPLEMENTATION RECORD (bd `test_C_libtooling-x5fp`)

Session 2026-09-18, orchestrated. Branch `x5fp-clobber-per-activation` in the worktree
`.claude/worktrees/agent-aacc88be824ade5ef`. **PARKED — committed, not merged.** Read
`FILE_SURFACE.md` first: it carries the witness verdict and the two corrections to the bead's own
text. Every gate line is hash-keyed in `GATES.md`.

---

## 1. THE HEADLINE, IN THE ORDER THE BRIEF ASKS FOR IT

1. **NO ACCEPT WITNESS EXISTS.** There is no program — C at `-O1`, nor hand IR — for which S-1 is
   the only wall. The deciding measurement is a ONE-OPERAND pair (`h1` versus `h2b`): removing the
   clobber does not buy an accept, it buys the wall behind it.
2. **What landed is a DIAGNOSTIC correction**, and the fence's own source comment is the authority
   for calling that a defect: *"never brand a shape information-theoretically impossible on unproven
   evidence"* (§8 review 2026-06-10, `ArmClassify.cpp`'s §3c block). A back-edge-only overlap is
   unproven evidence; it now gets the DEFERRED string instead of the PERMANENT one.
3. **Two corrections to bd `x5fp`** (both measured, `FILE_SURFACE.md` §1): the owner's program
   reaches the `:5901` TWIN, not the `diagonalAliasHit` prong the bead names; and on that program
   §3c is an ARTEFACT OF THE `i8` `_Bool` WIRE (bd `r903`) — with the wire removed the module
   declines at gate 2c (bd `drbq.12`, Track D) and never enters the value path at all.
4. **One new conjunct that is not in the bead's one-line plan** — rail disjointness (P3) — because
   the back-edge pruning alone would have REMOVED an accidental catch of bd `a3z7`'s open P1 dtzb
   shape. It is mutation-validated and is the only reason this is not an over-accept in waiting.

---

## 2. FILE SURFACE (final)

`ir-pass/src/ArmClassify.cpp` **only** — `git diff --stat`: `1 file changed, 206 insertions(+), 7
deletions(-)`, of which 141 insertions are comment. No header, no new frozen symbol, no ABI, no new
decline string, nothing under `include/`, `runtime/`, `tools/`, `tests/`.

| # | what | where |
|---|---|---|
| 1 | `condProvenanceInActivation` — NEW, file-local (the anonymous namespace opened at `:446`) | `:798` |
| 2 | `clobberHoldsPerActivation` — NEW, file-local | `:904` |
| 3 | the `diagonalAliasHit` §3c prong gains the per-activation conjunct | `:5959` (was `:5774`) |
| 4 | the hoisted/leaf `Clobber` twin gains the same conjunct, by CALLING the same predicate | `:6099` (was `:5901`) |

**The `switch` twin (`SwitchArmProve.cpp:238`) is deliberately UNTOUCHED.** It is the third emitter
of the same string, and it is unreachable in a loop: `ControlDetect.cpp:821` declines a
tainted-scrutinee `switch` on a cycle BEFORE the G-ladder runs, so a back-edge-only overlap can
never reach it. Giving it a copy of this predicate would add a second call site with no subject and
no fixture — a prediction, not a capability (Rule 12). When the in-loop `switch` is ever widened,
that is the moment to give it the SAME predicate by CALLING it (Rule 14), not a second spelling.

Fixtures, 5 new under `ir-pass/test/`:
`control_swap_reject_value_inloop_backedge_clobber.ll`,
`…_backedge_clobber_control.ll`, `…_inloop_dtzb_same_rail.ll`,
`…_inloop_mixed_evidence.ll`, `control_swap_reject_value_bool_loop_hoisted_clobber.ll`.

**Group-2 collision surface with Track D** (bd `drbq.12`, which edits `condWireDisposition`'s P4
prong `~:2844` and `RegionTreeDetect.cpp`): disjoint line ranges in one shared file, and **no
semantic coupling**, because `condProvenance` itself is untouched — Track D's P4 window and gate 2c
see the identical cone before and after this branch. The one thing Track D must know is in §7.

---

## 3. THE DESIGN

### 3.1 The question the fence asks, restated

§3c protects the flag STRIP: the flag is minted from the condition at the branch, and if the arm's
merge rewrites a register the mint read, the `icmp_inv` strip reads a different basis than the mint
did. Its SSA proxy is `Routed ∈ condProvenance(Condition)`.

Inside a loop that proxy answers a POSITION-FREE question and gets a per-activation one wrong. In
`h1` the compare is evaluated at the top of the body from the header φ `%a` and from `%q`'s own
fresh rail; the arm then writes `%r`; `%r` is in the cone only through `%a`'s LATCH incoming
(`%a` → `%m`, a `cq_measure` — the taint SINK, so nothing tainted crosses the back edge — → `%rm` →
`%r`). Within one activation the mint strictly precedes the write and the two rails are distinct
allocations.

### 3.2 The predicate, three conjuncts

* **(P1)** `Region.InLoop` and `L = LI->getLoopFor(Region.Pred)` non-null. `InLoop` is set only by
  `ControlDetect::handleBranchRegion` after `flatRegionRollableInLoop` has proved ONE reducible
  single-latch loop at one depth, so irreducible / multi-latch / NESTED loops never reach the
  pruning. Everything acyclic returns `true` on the first line — which is why no acyclic module can
  move, and the corpus sweep is the check on that claim rather than its source.
* **(P2)** the evidence is ABSENT from `condProvenanceInActivation` — `condProvenance` with one
  pruning rule: at a `PHINode`, an incoming arriving on a BACK EDGE OF `L` is not entered
  (`L->contains(IB) && L->contains(P->getParent()) && DT.dominates(P->getParent(), IB)`). Both
  `contains` are load-bearing: they keep an ENTRY edge (from a preheader, which is not in `L`) from
  ever being read as a back edge, and they keep an OUTER loop's back edge out of an inner region's
  pruning.
* **(P3)** RAIL DISJOINTNESS — `railWireClosure(Routed, BackwardOnly)` must not meet
  `⋃ railWireClosure(M, BackwardOnly)` over `M ∈ ProvAct`. Asked by CALLING the one owner of
  physical-rail identity (Rule 14), with R4's own call convention (`nullptr` arm bounds are inert
  under `BackwardOnly`).

### 3.3 Why (P3) is not belt-and-braces — the shape it keeps caught

`control_swap_reject_value_inloop_dtzb_same_rail.ll`: a loop-carried rail `%p`; the condition
`icmp sgt i32 %p, 2` at the top of the body; a dtzb IN-PLACE `%p2 = add nsw i32 %p, 1` between the
compare and the branch; the region routes `%p2`. `%p2` reaches the cone only around the back edge,
so (P1)+(P2) alone would grant — yet `%p2` names the SAME PHYSICAL RAIL as `%p`, the flag was minted
from a basis the `addc` already relabelled, and the arm relabels it again. **Gate 2c cannot cover
it**: its walker is spelled over `thetaOnPathTo`, which counts a `cq_theta` and does NOT count the
dtzb in-place `add`/`xor` — the vocabulary gap `WireWalk.h` records and bd `a3z7` (P1, open) owns.
Before this branch §3c caught the shape BY ACCIDENT, through the back-edge path.

⚠ **This is the L3-MIRROR obligation discharged explicitly.** CLAUDE.md: *"when you ADD A CALLER to
a shared predicate, read the callee's RETIREMENT TRIGGER and state which direction you are using it
in."* Here the move is the opposite one — REMOVING a fence's accidental coverage of a gap another
fence owns — and the same rule applies: I read `WireWalk.h`'s dtzb note, found the coverage was
accidental, and replaced it with a deliberate conjunct in the same change rather than letting it
lapse.

### 3.4 The L2 obligation — narrow the PRONG, not the CONE

`condProvenance` is untouched. Its header states that narrowing it makes **R4 vacuous** (an
over-ACCEPT: a flag stripped against a relabelled register, Rules 6/8) while it only SHRINKS F2's
exclusion set (an over-decline) — two consumers failing in opposite directions, plus gate 2c, the
rail ladder and `CompareLowering`'s record. So the new set is a SECOND, strictly smaller one with
exactly one consumer, used only to refuse the PERMANENT string.

**Gate 2c is deliberately NOT narrowed with it, and the reason is not symmetry-avoidance.** 2c asks
a different question — *"is there a non-diagonal GATE on the condition's wire between the read and
the mint?"* — and already owns per-activation machinery of its own (the P4/P5 prongs and
`chainedThetaBetweenDefAndBranch`, bd `hn29`/`leyd`/`52og`, landed 2026-09-15). A second,
differently-spelled per-activation reading authored from this track is the drbq Inc-3 (b′) defect.
2c's own back-edge over-decline is bd `drbq.12` — **Track D, this session, same group** — narrowed
there, in its own vocabulary, with its own Rule-13 round.

---

## 4. MUTATION VALIDATION (Rule 12(c): validate by mutation, not by re-reading prefixes)

A source mutant (`if (getenv("CQ_X5FP_MUTANT_NO_P3")) return false;` immediately before the (P3)
loop — added, built, measured, then REMOVED, and the restored tree rebuilt to the byte-identical
hash `33bba13b5886e28b`) was run over the track's probe set. Mutant `cq-opt`
`e2bee9a8ca4a7e7edf1312b92b7a6c6181e3a672921f4939ca1d0d06f9257da8`:

| probe | (P3) ON | (P3) OFF | moved? |
|---|---|---|---|
| `h6_inloop_dtzb_same_rail_backedge.ll` | `arm rewrites a condition operand` | `control flow inside a loop body` | **YES — the sole discriminator** |
| `h1_inloop_diamond_value_backedge.ll` | `control flow inside a loop body` | same | no |
| `h3_flat_diamond_value_clobber.ll` | `arm rewrites a condition operand` | same | no |
| `x01_owner_scalar.c` | `value-arm swap-route` | same | no |

⚠ **READ THE DIRECTION HONESTLY.** With (P3) removed `h6` still DECLINES, one wall later. So the
mutant is not an observable over-accept TODAY — it becomes one the day bd `3qlq.6` / bd `1dbk` item 1
lifts the in-loop VALUE fence. That is written into the fixture header and into the source, with the
retirement trigger, so the conjunct is not retired as "unreachable" by a future tidy-up.

---

## 5. RULE-13 ROUND 1 (self-adversarial) — what it attacked and found

**R1-A — THE ROUND-2 TAINT WINDOW (CLAUDE.md L1, the PREDICATE species). FINDING: there is no
subject, and the reason is structural, not a measurement.** `classifyArms` runs in BOTH detection
rounds, so a predicate that decides at round-1 taint and is never re-asked is the classic hole. This
one COMMITS NOTHING — no field, no record, no plan entry — and nothing downstream consumes its
answer. More: its `false` branch cannot produce an accept at all. (P1) forces `Region.InLoop`; the
only outer test it can open is the VALUE-arm prong, whose fall-through either declines further down
the same ladder or reaches the value ACCEPT and sets `ClassArm`/`ClassArmFalse = Value` — and
`ControlDetect::handleBranchRegion`'s "IN-LOOP SCOPE FENCE, part 2" declines exactly that pair on
the line after `classifyArms` returns. `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd
`br4a`), so round 2 never runs. **The argument is written into the source at the predicate**, so a
future widening that lifts part 2 cannot silently inherit it.

**R1-B — THE SECOND §3c SITE, and it is the one the bead does not name.** Reading the source rather
than the bead: at `:5901` both branches `declineArm(...); return Declined`, so `Clobber` chooses only
the STRING. Consequence recorded in `FILE_SURFACE.md` §1a and in the source: no narrowing THERE can
ever be an accept, and the owner's `_Bool` loop program lands there (measured by `CQ_CTRL_DBG`
anchor: `%15 = zext i1 %14 to i8`, which is `Chain.Ops`-EMPTY because `walkValueChain` follows
`BinaryOperator`s only).

**R1-C — THE `!Permanent` BRANCH WAS LEFT ALONE, deliberately.** `diagonalAliasHit` returning a hop
(a diagonal alias, or an if/else-anchored base) still declines `control flow` unconditionally. That
branch's evidence is weaker — the base was anchored heuristically from arm 1's chain — so narrowing
it would be an ACCEPT-direction change with no argument behind it. Over-declining is safe.

**R1-D — NESTED / IRREDUCIBLE / MULTI-LATCH LOOPS.** `Region.InLoop` is set only after
`flatRegionRollableInLoop`, so all three keep the full cone and their existing strings. The `contains`
pair in the pruning is a second, independent fence on the same point (an outer loop's back edge is not
pruned for an inner region).

**R1-E — `-O1` SINKING AND HOISTING (Rule 9).** The pruning is an OPERAND/EDGE question on the φ
graph, never a position one, and sinking moves a definition without rewriting its operands (the same
argument F2's φ-descendant note makes for its own walk). LICM hoisting a value OUT of the loop can
only move an overlap from back-edge-only to in-activation, which is the DECLINE direction. A
LICM-hoisted loop-INVARIANT compare yields a tiny `ProvAct` (its cone is entirely outside the loop),
so (P3) becomes the decider — and such a region declines at 2c's P4 prong regardless.

**R1-F — NULL OPERANDS.** `!Evidence || !Routed || !Region.Condition` returns `true` first, so the
predicate can never hand a null to `dyn_cast` (Release has assertions off; `condProvenance` has the
same exposure earlier in the same function and would crash first, so this adds no new surface — it
just does not add one either).

## 6. RULE-13 ROUND 2 (self-adversarial) — the attacks round 1 did not make

**R2-A — MIXED EVIDENCE: a condition that reads the routed register BOTH directly and around the
back edge.** This is the attack a "is there a back edge in the provenance?" spelling would fail.
Built as `h7_inloop_mixed_evidence.ll` (`h1` with ONE operand changed: the compare's first operand
is `%r` instead of `%q`). (P2) asks whether the evidence is ABSENT from the in-activation cone, and
here `%r` is an operand of the compare itself. **Measured `arm rewrites a condition operand` on BOTH
binaries** — repelled, and shipped as `control_swap_reject_value_inloop_mixed_evidence.ll` with the
"must never accept" trigger.

**R2-B — DOES (P3)'s `ProvAct` SEED LOSE THE BACK-EDGE RAIL MEMBERS?** It does not, and this is the
subtle half. `ProvAct` is an SSA-position-pruned set, but `railWireClosure` crosses `PHINode`
routers, so the rail closure of an in-activation member REACHES its own latch incoming. That is
exactly why `h6` is caught: `railWireClosure(%p)` reaches `%pn` and `%p2`. So (P3) is a genuine RAIL
question asked from an in-activation SEED — not an SSA-reachability question in disguise.

**R2-C — IN-PLACE (dtzb) VERSUS OUT-OF-PLACE ARM WRITES.** The in-place case is `h6` (caught by
(P3)). The out-of-place case is `h1` (a fresh template rail; `railWireClosure` stops at a
`cq_template_*` producer, so the closures are disjoint and the answer is `false`). The pair is the
discrimination, and the `x08`/`x09` C probes are the same axis in a spelling `-O1` if-converts.

**R2-D — THE WRITE REACHING A SECOND REGION IN THE SAME ACTIVATION.** Each region is classified with
its OWN `ProvAct`, seeded from its own condition, so a second region whose condition reads the first
arm's output in-activation has that value present in its cone and keeps the PERMANENT string. What
the branch cannot do is *observe* both diagnostics in one run — `LLVMContext::diagnose` EXITS on the
first — so the case is argued and not measured, and it is listed in §8 as not-claimed.

**R2-E — CONTAINMENT OF THE ACYCLIC WORLD.** (P1) returns `true` before any work for every region
that is not `InLoop`, so no acyclic module can move. The corpus sweep is the check on that claim; it
is reported in `GATES.md` and summarised in §9.

---

## 7. WHAT TRACK D MUST KNOW (Group 2, one shared file)

**`condProvenance` is NOT modified by this branch — not its body, not its signature, not any of its
call sites.** Track D's P4 prong and gate 2c see the byte-identical cone. What this branch adds is a
SECOND, file-local, strictly smaller set (`condProvenanceInActivation`) with exactly one consumer,
and a second file-local predicate over it.

Two concrete consequences for the merge:

1. **If Track D's work ends up wanting a per-activation reading of the condition's provenance, it
   must NOT call `condProvenanceInActivation`.** It is scoped to the §3c clobber question (its
   pruning is justified by "the flag is minted before the arm writes", which is a statement about
   an ARM, not about a gate on a wire), and 2c already owns
   `chainedThetaBetweenDefAndBranch` for its own per-activation question. A shared call here would
   be a second spelling of one relation in the sense Rule 14 forbids — the two predicates answer
   different questions that happen to walk the same graph.
2. **Line ranges are disjoint** (`:798`/`:904` and `:5959`/`:6099` here; `~:2844` and `RegionTreeDetect.cpp`
   there), so the textual merge should be clean. The post-merge check that matters is not textual:
   re-run `control_swap_reject_value_inloop_dtzb_same_rail.ll` and
   `control_swap_reject_value_inloop_mixed_evidence.ll` on the MERGED binary. If Track D's narrowing
   moves either one, the two per-activation readings have composed — and *a composition is not
   cleared by clearing its parts* (CLAUDE.md, filed in each of the last three sessions).

---

## 8. WHAT IS NOT CLAIMED

* **No accept is recovered**, at any site, in any spelling, on any binary. The branch is PARKED.
* **The owner's cascade is not closer to compiling.** `x01` still declines, one string later.
* **The two-region case (R2-D) is argued, not measured** — the first `DS_Error` exits, so a module
  cannot exhibit two region verdicts.
* **No e2e layer was run and no golden was added.** The e2e layer has no decline shape
  (`run_slice*.sh` runs under `set -euo pipefail` and byte-diffs a golden), and this branch adds no
  accept, so there is nothing for it to witness.
* **`negative_vacuity_check.py` is N/A for this batch and says so loudly**: five DECLINE fixtures,
  zero `CHECK-NOT` directives, so it exits 2 with `0 directive(s) evaluated, … 5 declining
  module(s)`. That is the tool correctly reporting that the batch contains nothing of its kind — a
  decline fixture's property is pinned by the `not` inversion on the RUN line (Rule 12(b)), and
  manufacturing a `CHECK-NOT` to satisfy an instrument would be the instrument-driven mistake the
  tool exists to prevent. **The injection matrix is likewise N/A**: it mutates ACCEPTS, and this
  batch has none. The mutation evidence here is §4's SOURCE mutant, which is the stronger instrument
  for a fence.
* **No independent Rule-13 round has run.** §5 and §6 are self-adversarial. The independent round is
  the Group-2 gate's.

---

## 9. GATES (verbatim lines and hashes are in `GATES.md`)

* pre-edit worktree build reproduced the ORACLE byte for byte: `cq-opt`
  `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3`, `libCQPass.so`
  `3e3dc35d471aae6b53067ffc374745f8cd9f148870a1879d971c8bdab831695d`.
* subject binaries: `33bba13b5886e28b…` (the narrowing) and `677472eb67a0b2ea…` (+ the null guard
  and the round-1/round-2 comments). Every probe verdict is identical on the two.
* `ctest -R ir-pass-lit` at `677472eb`: **`1/1 Test #8: ir-pass-lit Passed 82.53 sec — 100% tests
  passed, 0 tests failed out of 1`**, 2087 fixtures discovered (main 2082 + trackX 5).
* corpus sweep ORACLE-vs-SUBJECT at `677472eb`: `probes/corpus_677472eb.txt`, movers in §9.1.

⚠ **ONE PROTOCOL INCIDENT, REPORTED RATHER THAN BURIED.** A corpus sweep announced at `33bba13b`
was still running when the null-guard rebuild relinked `cq-opt` under it — the exact trap CLAUDE.md
records (*"never relink a binary under a running measurement"*). It was stopped by task id (not by
`pkill` pattern — the 2026-09-15 F-1 lesson), its partial output was DELETED rather than reported,
and the sweep was re-run from scratch at the final hash with no build in flight. A partial sweep
across two binaries is not a slow result; it is a wrong one.

### 9.1 Corpus sweep — what ran, what did not, and why the conclusion still holds

⚠ **THE FULL SWEEP DID NOT COMPLETE, AND THAT IS REPORTED AS AN ABSENCE, NOT A GREEN** (PROTOCOL.md:
*"record an unfinished gate as an ABSENCE, never a green or a red"*). PROTOCOL.md's corpus is
`ir-pass/test/*.ll` **plus** every session dir's `track*/probes` and `review_*_probes` — measured
here at **6446 files** (2087 fixtures + 4359 probe files). Throughput was ~37 rows/min and did not
improve at `xargs -P 6`, because the box was saturated by the session's other tracks: `uptime`
reported **load averages 639 / 692** while the sweep ran. At that rate the full corpus is ~3 h.

**What was measured, and it is enough to carry the claim this branch makes:**

1. **Every SHIPPED FIXTURE is covered, and by a stronger instrument than the sweep.**
   `ctest -R ir-pass-lit` is green at `677472eb` over all **2087** fixtures. A corpus sweep tells you
   a fixture's verdict CHANGED; lit tells you it changed *away from what the fixture pins*. Since
   every one of the 22 pre-existing fixtures that pin `arm rewrites a condition operand` is in that
   run and none went red, no shipped §3c verdict moved.
2. **A 564-row sample of the PROBE corpus, at this exact binary.** The first (serial) sweep at
   `677472eb` was read at 564 rows before it was superseded by the parallel one: **7 movers, every
   one of them `D:arm rewrites a condition operand` → `D:value-arm swap-route`**, and every one of
   them a member of the S-1 peel-ladder family the increment targets —
   `trackL/probes/s_loop_n{2,3,8}.c`, `trackL/probes/t_loop_n{2,3,8}.c`, and
   `session-2026-09-11-orchestrator/review_integration_probes/N7_loop.c` (the two-`_Bool` scalar-loop
   cascade). **Zero `A→D`, zero `D→A`, zero `A→A` md5 changes.** That is the predicted population and
   nothing else. ⚠ The file itself was deleted when the sweep was restarted; the row count and the
   mover list above are the run's own output, quoted, not reconstructed.
3. The parallel re-run (fixtures first, deliberately — see `probes/corpus_par.sh`'s note) was left
   running at hand-off; its partial output is `probes/corpus_677472eb.txt` with its row count.

**The definitive sweep is the GROUP GATE's** (PROTOCOL.md's matrix: the merge-and-gate agent runs
ONE corpus sweep on the MERGED binary, with movers attributed per track BY STRING). This track's
expected strings for that attribution are exactly two:
`arm rewrites a condition operand` → `value-arm swap-route` (the `:6099` site) and
`arm rewrites a condition operand` → `control flow inside a loop body` (the `:5959` site).
**Any other mover attributable to this branch is a FINDING.**

---

## 10. §bd — the exact text for the orchestrator to apply from the MAIN checkout

A worktree cannot write `bd` (`.beads/` is per-checkout). ⚠ `bd update --notes` REPLACES notes —
use `--append-notes`, as below.

### 10.1 bd `test_C_libtooling-x5fp` — keep OPEN, re-scope

```
bd update test_C_libtooling-x5fp --append-notes "2026-09-18 Track X (session-2026-09-18-orchestrator/trackX): SCOPED, IMPLEMENTED, PARKED on branch x5fp-clobber-per-activation (committed, NOT merged). THE WITNESS VERDICT IS NEGATIVE: there is no program, C at -O1 or hand IR, for which S-1 is the only wall. Deciding measurement is a ONE-OPERAND pair on the frozen oracle 9bd01598: h1_inloop_diamond_value_backedge.ll declines 'arm rewrites a condition operand', and h2b (the same module with the compare's 2nd operand a constant, so 3c cannot fire) declines 'control flow inside a loop body' -- ControlDetect.cpp's IN-LOOP SCOPE FENCE part 2, i.e. bd 3qlq.6 / bd 1dbk item 1, NOT bd ej5w. TWO CORRECTIONS TO THIS BEAD'S OWN TEXT, both measured with CQ_CTRL_DBG: (1) the owner's program s_loop_n2.c does NOT reach the diagonalAliasHit prong -- walkValueChain follows BinaryOperators only and the _Bool arm's merge contribution is 'zext i1 .. to i8', so Chain.Ops is EMPTY and the decline is the HOISTED/LEAF twin whose evidence is Prov.count(StraightThrough), anchored on that zext; BOTH branches of that site decline, so no narrowing there can ever be an accept. (2) On that program the 3c fence is an ARTEFACT OF THE i8 _Bool WIRE (bd r903): with the trunc/zext removed by hand the module declines 'condition predates a non-diagonal gate' (gate 2c, bd drbq.12) and never enters the value path, so x5fp is not on that program's critical path once r903 lands. WHAT THE BRANCH DOES: asks both 3c sites per activation (condProvenanceInActivation + clobberHoldsPerActivation, both file-local to ArmClassify.cpp; condProvenance ITSELF UNTOUCHED, so R4/F2/2c/the rail ladder/CompareLowering see the identical cone -- the L2 obligation is discharged by narrowing the PRONG, not the CONE). Effect is a D->D string move: h1 -> 'control flow inside a loop body', the owner's program -> 'value-arm swap-route'. A THIRD CONJUNCT NOT IN THE ONE-LINE PLAN: rail disjointness via railWireClosure, because the back-edge pruning ALONE would have removed an accidental catch of bd a3z7's open-P1 dtzb shape (2c's walker counts a cq_theta and not a dtzb in-place add). Mutation-validated: a source mutant returning before that loop flips exactly one probe (h6) and nothing else. 5 fixtures added; ctest -R ir-pass-lit 1/1 Passed 82.53s at cq-opt 677472eb; corpus sweep oracle-vs-subject recorded in trackX/GATES.md. NO accept is recovered and none is claimed."
```

### 10.2 bd `test_C_libtooling-3qlq.6` (and bd `1dbk` item 1) — record the customer

```
bd update test_C_libtooling-3qlq.6 --append-notes "2026-09-18 Track X: this is the wall BEHIND bd x5fp, measured. ControlDetect.cpp's 'IN-LOOP SCOPE FENCE, part 2' (R.InLoop && ClassArm/ClassArmFalse == Value) fires on the line after classifyArms returns, so an in-loop VALUE arm declines 'control flow inside a loop body' no matter what the 3c clobber fence says. Isolating pair on oracle 9bd01598: trackX/probes/h1 (3c) vs h2b (this fence), ONE operand apart; and h4_flat_diamond_value_noclobber.ll, the same shape with no loop, ACCEPTS (15 trace lines, STRICT 2b clean) -- so the wall is the LOOP, not the arm class. When this lands, control_swap_reject_value_inloop_backedge_clobber{,_control}.ll become ACCEPTs and must be re-derived together (their L8 headers say so), while control_swap_reject_value_inloop_{dtzb_same_rail,mixed_evidence}.ll must NOT move -- at that moment they stop being defence in depth and become real over-accept guards."
```

### 10.3 bd `test_C_libtooling-r903` — record that it subsumes x5fp for the owner's program

```
bd update test_C_libtooling-r903 --append-notes "2026-09-18 Track X, measured on oracle 9bd01598: the carried _Bool i8 wire is what routes the owner's scalar-loop cascade into the VALUE path at all. trackX/probes/h5_inloop_i1_carried_theta_arm.ll is that program with the trunc/zext pair removed by hand -- the arm becomes a bare @cq_theta_i1 call, inPlaceRotationArmTheta (R1) claims it, the 3c clobber fence is never consulted, and the module declines 'condition predates a non-diagonal gate' (gate 2c, bd drbq.12). So for that program r903 subsumes bd x5fp: landing r903 moves the wall from 3c to 2c without x5fp being involved. SCOPE_loop.md 1.2's fifth-wall note ('probe it first') was right and is now measured."
```

### 10.4 bd `test_C_libtooling-a3z7` — a second fence now names its gap deliberately

```
bd update test_C_libtooling-a3z7 --append-notes "2026-09-18 Track X: the dtzb vocabulary gap (thetaOnPathTo counts a cq_theta and not an in-place add/xor) is CROSS-REFERENCED by a second fence now. Before bd x5fp's branch, ArmClassify's 3c clobber fence caught the shape 'loop-carried rail %p; condition icmp(%p,2); dtzb in-place %p2 = add %p,1 between the compare and the branch; region routes %p2' BY ACCIDENT, through the back-edge SSA path. The per-activation narrowing would have dropped that accidental catch, so the branch adds an explicit rail-disjointness conjunct (railWireClosure, the one owner) and ships control_swap_reject_value_inloop_dtzb_same_rail.ll as its mutation-validated pin. This does not fix a3z7 and is not a second spelling of its fence; it records that a3z7's population had an accidental second guard and now has a deliberate one."
```
