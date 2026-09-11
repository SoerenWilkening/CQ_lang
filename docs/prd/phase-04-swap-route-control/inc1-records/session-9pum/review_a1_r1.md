# Rule-13 review, ROUND 1 — Track A.1, the compare-select fence parity (bd `9pum` + `r10v` + `r903`(b))

Independent adversarial review of branch `compare-select-parity` (worktree
`/Users/sorenwilkening/Desktop/CQ_trackA`, from `main` 0c7380c). Subject binary
`CQ_trackA/build/ir-pass/{cq-opt,libCQPass.so}` (built 12:39, sources 12:37 — current). ORACLE
`CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}` at `main` 0c7380c, read-only. Nothing in
`ir-pass/`, `include/`, `tests/` or `tools/` was edited in any checkout; nothing was rebuilt;
nothing committed. Every probe is committed beside this file in `review_a1_r1_probes/` with a
runner (`run.sh`) that re-derives every verdict table below on both binaries.

## VERDICT — **BLOCK**

`reverifyCmpCondReads`' rung-(iii) suppression re-opens bd `9pum` for every consumer whose
round-1 wire question is `condWireDisposition` (the flat kickback, the value arm, the 6.5
classical-call arm, the in-place-Ry arm). **Two TUs of plain C at `-O1`**, `opt` exit 0,
verify-clean, STRICT stage-2b `0 violation(s)`, emitted stream byte-identical to the oracle's —
and the program is the increment's own decline plus ONE line. That is O-3 realized, not a residual.

| # | grade | one line |
|---|---|---|
| **F-A1-1** | **CONFIRMED-MISCOMPILE (plain C, BLOCKER)** | the rung-(iii) taint-blind suppression discards a live round-2 obligation whenever ANY gate is visible taint-blind — bd `9pum`, unfixed, one line from the fix's own decline |
| **F-A1-2** | **OVER-ACCEPT-ARGUED / scope** | O-7's per-activation barrier silently widens the SHARED rail helper: two plain-C `DECLINE → ACCEPT` movers on the RAIL ladder (both accepts CORRECT), in an increment that declares itself decline-monotone, pinned by no rail fixture |
| **F-A1-3** | **OVER-DECLINE (plain C ×4)** | the O-2 cone refuses valid circuits `main` compiles, and the class is ASYMMETRIC: the exact mirror accepts on both binaries |
| **F-A1-4** | **OVER-ACCEPT-ARGUED, PRE-EXISTING — FILE** | O-4 answered by measurement: the same program declines as `icmp`+`br` and ACCEPTS as a `switch`, minting two eq-flags from a collapsed register |
| **F-A1-5** | **DOC ×3** | the silent `Seeds.empty()` skip (the one place that fails toward ACCEPT); O-5's measured ground; the compare ladder is strictly weaker than its rail twin and nothing says so |

**O-7 outcome:** the barrier is SOUND within a taint round (attacked six ways, below) and its
round-2 blind spot is genuinely closed by the ungated rung (ii) — MEASURED, `o7a`. Its real cost
is F-A1-2, which is not a wrong unitary but is an unreviewed accept-direction change to a
Rule-13-cleared predicate. **O-3 outcome:** NOT empty — F-A1-1 is a member, plain-C reachable.

## What was re-verified of the implementer's own claims (all hold)

* corpus diff, re-run independently over the 1776 `git ls-tree 0c7380c` fixtures, rc+stdout+stderr,
  oracle vs subject: **`FIXTURES=1776 RCDIFF=0 DIAGDIFF=0 OUTDIFF=0`** (`scratchpad/trackA_review/corpus_diff.py`);
* `ctest -R ir-pass-lit` on the subject build: **Passed, 48.94 s, 0 failed**;
* `git status --porcelain tests/` = `M tests/e2e/CMakeLists.txt` + the 5 new untracked files only —
  **no pre-existing golden changed** (stronger than the 10-golden spot check the brief asked for);
* `ls ir-pass/test/*.ll | wc -l` → **1796**; `ls tests/e2e/*.expected.log | wc -l` → **343**;
* all 14 `session-9pum/probes` verdicts reproduce character-for-character, the three headline
  reproducers included (`r10v`, `r903b`, `9pum`: ACCEPT → DECLINE).

---

## F-A1-1 — CONFIRMED SILENT MISCOMPILE (plain C, two TUs). **THE BLOCKER.**

### The programs (`review_a1_r1_probes/k{7,8,9}_caller.c` + `lib3.c`)

```c
int ext_f(int a); int opaque(void); int ext(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5; if (q > 5) y = ext_f(7);       /* 6.5 classical-call arm  -> %out */
    int z = 0; if (opaque()) z = ext(1);      /* a classical diamond, to split the block */
    int b  = cq_theta(y, 0.25);
    int b3 = cq_theta(y, 0.9);                /* the round-2 sibling: ONE rail with b */
    if (b > 1) cq_phi(0.3);                   /* the control read */
    int b2 = cq_theta(b, -0.25);              /* k7 ONLY — the S-dagger, post-region   */
    return cq_measure(b3) + cq_measure(b2) + z;
}
```

| probe | difference | ORACLE | SUBJECT |
|---|---|---|---|
| `k8` | no `b2` | ACCEPT | **DECLINE** `condition predates a non-diagonal gate` ✔ the fix working |
| `k7` | `+ int b2 = cq_theta(b, -0.25);` | ACCEPT | **ACCEPT** ✘ — byte-identical to the oracle |
| `k9` | that line on ANOTHER register (`cq_theta(q, …)`) | ACCEPT | **DECLINE** ✔ |
| `o3_kick.ll` | the increment's OWN fixture `control_phase_kickback_reject_cmp_round2_sibling_theta.ll` + one `cq_theta(%b,·)` in `join` | ACCEPT | **ACCEPT** ✘ |

`k9` is the discriminator that pins the mechanism: the fence is defeated by making the condition
wire **dirtier**, which is the inverse of a safety property.

### The emitted stream (k7, SUBJECT — byte-identical to the oracle; STRICT stage 2b `0 violation(s)`)

```
  call void @cqrt_ry_i32(i32 %out, double 2.500000e-01)          ; b  = Ry(.25)|y>
  call void @cqrt_ry_i32(i32 %out, double 9.000000e-01)          ; b3 = Ry(.9) on the SAME rail
  %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %out, i32 1)   ; THE FLAG
  call void @cqrt_rz_i1(i32 %h_cmp2, double 3.000000e-01), !cq.branchphase
```

State-vector argument (Rule 2). Write the post-merge register as `Σ_x α_x |x⟩`. The source marks
the branches where `b > 1`, `b = Ry(0.25)|x⟩`; the circuit marks the branches where
`Ry(0.9)Ry(0.25)|x⟩ = Ry(1.15)|x⟩ > 1`. The predicate selecting the marked subspace differs, so the
kicked-back `P(0.3)` lands on a different set of amplitudes — a different unitary, not a global
phase and not a convention. This is bd `9pum` verbatim; `k8` proves the increment declines it and
`k7` proves one line takes it back.

### Root cause — one line, and it is the Prime Directive inverted

`ArmClassify.cpp:2343` (`reverifyCmpCondReads`):

```cpp
if (findNonDiagonalWireGate(Seeds, /*Cross=*/true, nullptr, nullptr, nullptr))
  continue;  // "visible WITHOUT the crossing — the classifier's, not ours."
```

Two independent facts make the comment false:

1. **`findNonDiagonalWireGate` returns ONE gate, not a set.** "Some gate is visible taint-blind"
   and "THIS gate is visible taint-blind" are different propositions; the code tests the first and
   the comment asserts the second. In `k7` the blind walk returns `b2`; the round-2 gate is `b3`,
   which the blind walk cannot reach (its backward closure stops at `%out`, untainted at round 1)
   and which nothing then examines. I verified mechanically that the implementer's isolation claim
   itself is right — `Taint` is consulted in exactly one place in `WireWalk.cpp`, the F-1b-1 arg-0
   crossing, and in zero places in `gateIsHarmless` / `phiTracksWire` / `reachesWithoutBarrier`
   (measured by `awk`+`grep` over each function body). The defect is not the isolation, it is
   collapsing a set difference into a boolean.
2. **"The classifier ruled on it" does not mean "the classifier declined."** For the SELECT, the
   NEST and the SWITCH the round-1 rung (iii) is POSITION-FREE (`SelectClassify.cpp:963`,
   `ArmClassify.cpp:4947`, `SwitchClassify.cpp:316/557`), so taint-blind DIRTY ⟹ round-1 DIRTY ⟹
   the program already declined and the suppression is harmless — which is why `k6` (the select
   spelling of `k7`) declines on both binaries. But `condWireDisposition` (`ArmClassify.cpp:1722`)
   has a **DT prong**: position-free DIRTY + `wireGainsNonDiagonalGate(Prov, BI, DT)` CLEAN ⇒
   `ProvenPostRegion` ⇒ **ACCEPT**. That is the shipped S† shape. Its consumers are
   `ArmClassify.cpp:2724` (the whole region classifier — value arms, the 6.5 classical-call arm,
   the in-place-Ry arm) and `:4595` (`classifyPhaseKickback`). For every one of them the round-1
   answer can be an accept, so the suppression discards an obligation nobody ever discharged.

Note also that the twin `reverifyRailCondReads` (`:2202`) has **no** suppression — it asks
position-free then position-aware, unconditionally. The compare ladder is therefore strictly
weaker than the rail ladder it claims to mirror, at exactly the rung that carries `9pum`.

### Fix sketch (not a request to weaken anything)

Compare **gate sets**, not booleans: collect every gate the taint-blind walk reaches (an
`Exempt`/`Skip` set parameter on `findNonDiagonalWireGate`, or a `collectNonDiagonalWireGates`
sibling), then run the taint-aware position-free walk ignoring that set and re-ask the
position-aware prong only about what remains. That keeps the twelve in-loop accepts the
implementer measured (their gates ARE in the blind set, so they are exempted individually rather
than by suppressing the whole entry) and closes `k7` — `b3` is not in `k7`'s blind set.
The alternative the implementer proposed (record the classifier's own disposition per compare)
is strictly larger and can wait for A.2; this one is local to `ArmClassify.cpp:2340-2350`.
Whichever is chosen, `k7`/`k9`/`o3_kick` are the red-green pair plus its discriminator.

---

## F-A1-2 — O-7's barrier reaches the RAIL ladder: two plain-C `DECLINE → ACCEPT` movers

`railMeasuredBeforeReadPoint` is SHARED with the 1b/1b-B.1 rail ladder (`classifyPhaseKickback`
step 5b, `classifySelectRegion`'s rail loop, `reverifyRailCondReads`). The barrier therefore
changes the rail path too, and the corpus diff could not see it because no fixture has the shape:

| probe | program | ORACLE | SUBJECT |
|---|---|---|---|
| `b1.c` | `for(i<3){ _Bool b = cq_theta(0,.5); if (b) cq_phi(.3); acc += cq_measure(b) + ext(i); }` | DECLINE `condition measured before the control route` | **ACCEPT** |
| `b2.c` | the same with the 4.4 data select `int a = b ? i : 5;` | DECLINE, same string | **ACCEPT** |

**Both accepts are CORRECT**, and I checked the physical premise rather than assuming it: the
lowered `b1` keeps `%h = call i32 @cqrt_alloc_i1(i1 false)` INSIDE the loop body, so each trip is
a fresh register and the body measurement owns only its own trip. So this is an expressiveness
GAIN. What it is not is in scope: BRIEF §1 says "No program that declines on `main` may accept on
this branch", IMPL §5 reports "0 DECLINE→ACCEPT", and both are true of the 1776 fixtures and false
of the program set. Nothing pins the rail half — the barrier's only fixture,
`control_swap_select_cmp_inloop_iterlocal_measure_after.ll`, is a COMPARE. Owed: two rail accept
fixtures (`b1`, `b2` as `.ll`), and a corrected monotonicity sentence that says which direction
moved and why it is right.

**The barrier itself survived six attacks** (Rule 2 arguments, each measured where a program
existed):

1. *origin in the preheader, register loop-carried* — `bd r10v` itself: the back-edge path never
   crosses the preheader, `everyPathReExecutes` is false, the rung still refuses. DECLINE ✔
2. *conditional re-mint in the body* (`o7b.c`) — the seed becomes a header phi, `Names.back()` is
   not a `CallInst`, no barrier is granted. (Pre-empted earlier here by `cq loop lowering:
   loop-carried tainted value crosses iterations` on both binaries; the analysis holds either way.)
3. *guarded-only mint* (`o7c.c`) — origin, read and measure all inside one guarded block; every
   path re-executes the origin. ACCEPT on both, correct.
4. *nested loops* — an inner-loop read with an outer-loop origin: the inner back edge gives a path
   that skips the origin, so the rung refuses. Conservative by construction.
5. *irreducible cycles* — `everyPathReExecutes` is `reachesWithoutBarrier`, an exact instruction-level
   CFG walk with no `LoopInfo` anywhere, so the drbq S7 lesson does not bite here.
6. *the round-2 window on the barrier itself* — **the attack I expected to land**: at round-1 taint a
   `cq_theta(y, ·)` whose `y` is a 6.5 `%out` derivative reads as a SOURCE theta, so the barrier is
   granted and the in-body measure skipped, while at FINAL taint it is a CHAINED in-place Ry that
   re-mints nothing. `o7a_caller.c` is that program: ORACLE **ACCEPT** (the r10v miscompile),
   SUBJECT **DECLINE**. The ungated rung (ii) in `reverifyCmpCondReads` catches it, because at final
   taint `railWireNamesBackward` walks on to `y`, `Names.back()` is no longer a theta, and no barrier
   is granted. **This is the increment's strongest single design decision** (rung (ii) ungated,
   rung (iii) gated) and it is worth saying so: had rung (ii) been gated the same way as rung (iii),
   O-7 would have been a wrong unitary rather than a scope item.

---

## F-A1-3 — the O-2 cone over-declines valid circuits, and the class is asymmetric

`condCmpMeasuredBeforeReadPoint` seeds from `condProvenance`, which collects **every tainted
ancestor** of the condition, not the register the compare reads. Four plain-C programs that
`main` compiles into clean circuits now decline:

| probe | program (abridged) | ORACLE | SUBJECT |
|---|---|---|---|
| `c1.c` | `int t = q + 3; int m = cq_measure(q); int a = (t == 5) ? 2 : 5;` | ACCEPT | **DECLINE** |
| `c2.c` | the same with `long long t = (long long) q;` | ACCEPT | **DECLINE** |
| `c9.c` | the `br` twin: `… if (t > 3) cq_phi(.3);` | ACCEPT | **DECLINE** |
| `c10.c` | the same with `short t = (short) q;` | ACCEPT | **DECLINE** |

`c1` on the ORACLE emits — and stage 2b verifies —

```
%h_op  = call i32 @cq_template_add_i32_hl(i32 %h, i32 3)      ; t: a FRESH rail
%m     = call i32 @cqrt_measure_i32(i32 %h)                   ; q collapses
%h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 5)   ; the flag reads t, NOT q
…  free_pairing_check: 4 rail mints, 1 free site: 1 verified, 0 violation(s), 0 unproven
```

The control read is on `%h_op`, a register the program never measures. `q`'s measurement fixes
`t` through their entanglement, so the flag is deterministic and the unitary is exactly what the
source asks for. Nothing here is the `r903(b)` defect, which mints from the **same** handle the
measurement collapsed.

And the class is not symmetric, which is the part that makes it a defect rather than a policy:

| probe | program | ORACLE | SUBJECT |
|---|---|---|---|
| `c7.c` | `int t = q + 3; int m = cq_measure(t); int a = (q == 5) ? 2 : 5;` | ACCEPT | **ACCEPT** |
| `c8.c` | the same with `int t = q * 5;` | ACCEPT | **ACCEPT** |

`c1` and `c7` are the same two entangled rails with the same one measurement; the verdicts are
opposite. If the ground is "the measurement collapses the pair" then `c7`/`c8` are over-accepts;
if the ground is "the register the control reads was collapsed" then `c1`/`c2`/`c9`/`c10` are
over-declines. It cannot be both. Under the owner's expressiveness ruling for this session the
over-decline is the defect, and the narrowing is the brief's own §1.1 wording — *"for each TAINTED
operand"* — which IMPL §1c measured as costing **0 movers** over 1776 fixtures and 114 probes.
Controls that must stay: `c3` (a DIFFERENT register measured) and `c4` (measure-after) — both
ACCEPT on both binaries, verified.

---

## F-A1-4 — O-4 answered: the `switch` keeps the hole, measured (PRE-EXISTING → FILE)

`review_a1_r1_probes/sw{1,2}.ll` are the same program written two ways.

| probe | spelling | ORACLE | SUBJECT |
|---|---|---|---|
| `sw1.ll` | `%md = cq_measure(%q); switch i32 %q [0 → phase, 1 → phase]` | ACCEPT | **ACCEPT** |
| `sw2.ll` | `%md = cq_measure(%q); %c = icmp eq %q, 0; br …` | ACCEPT | **DECLINE** |

`sw1` on the SUBJECT emits `%m2 = cqrt_measure_i32(%h)` followed by
`cq_template_icmp_eq_i32_hl(%h, 0)` and `cq_template_icmp_eq_i32_hl(%h, 1)` — two eq-flags minted
from a collapsed register: bd `r903`(b) verbatim, at the fourth consumer. The implementer wrote
"no measured evidence either way" because their probe was pre-empted by an earlier gate; this is
the evidence. It is **pre-existing** (identical on the oracle) so it is a FILE, not a blocker —
but it is now a *parity* gap that A.1 itself widens, and O-4's ~5-line extension of the record to
`emitEqFlag` (seed = the scrutinee) should be scoped with its own decline partition.
Hand IR: the phase `switch` has no plain-C `-O1` customer (CLAUDE.md OQ-4/OQ-11).

---

## F-A1-5 — DOC (three)

**(a) The one place the increment fails toward ACCEPT.** `reverifyCmpCondReads` drops nulled and
foreign seeds and then `if (Seeds.empty()) continue;` — an entry whose whole cone was erased is
skipped with NO rung (ii) and NO rung (iii), silently. Everywhere else the increment fails toward
a decline (the `recordCondRead` default, the missing-barrier refusal). `WeakTrackingVH` follows
RAUW, so the common case (`SelectMergeEmit` RAUW-ing a cone member to `%out`) is fine — but the
skip deserves the written argument the rest of the stage gets, or a decline.

**(b) O-5's measured ground.** I could not reach `Specialization::mintCondNetwork` with a control
read at all: `sp1.c` (a select inside a lifted callee) declines
`cq specialization: callee contains tainted control flow under quantum lift` and `sp2.c` (a branch
phase inside it) declines `callee contains a quantum primitive (cq_*)`, both on both binaries.
"Out by construction" is right; this is the measurement that says so, and it belongs in §7 O-5
beside the two structural reasons.

**(c) Say where the two ladders diverge.** `railMeasuredBeforeReadPoint`'s new header says the two
rungs are "two rungs of one ladder, one modality". At rung (iii) they are not: `reverifyRailCondReads`
asks both prongs unconditionally, `reverifyCmpCondReads` gates the position-aware prong behind the
taint-blind suppression. That asymmetry is the ground of F-A1-1 and is currently only discoverable
by diffing the two functions.

---

## Coverage the increment earns beyond its stated scope (verified, and worth keeping)

The ungated rung (ii) in the backstop is a real backstop, not a claim: consumers with no classifier
clause pick it up for free, measured —

| probe | consumer | ORACLE | SUBJECT |
|---|---|---|---|
| `g2_caller.c` | 6.5 classical-call arm, condition register measured before | ACCEPT | **DECLINE** ✔ |
| `g3.c` | value arm, same | ACCEPT | **DECLINE** ✔ |
| `g1.c` | angle select, same | DECLINE `rotation angle` | DECLINE, earlier rung |

## `-O1` reachability, per finding

F-A1-1 **plain C, two TUs** (`k7`) and hand IR (`o3_kick`); F-A1-2 **plain C, single TU**
(`b1`,`b2`); F-A1-3 **plain C, single TU** (`c1`,`c2`,`c9`,`c10`,`c7`,`c8`); F-A1-4 **hand IR**
(no plain-C `-O1` phase-switch customer exists); F-A1-5(b) **plain C** (`sp1`,`sp2`).

## What I ran

```
python3 scratchpad/trackA_review/corpus_diff.py        # FIXTURES=1776 RCDIFF=0 DIAGDIFF=0 OUTDIFF=0
ctest --test-dir build -R ir-pass-lit --output-on-failure   # Passed, 48.94 s, 0 failed
docs/.../session-9pum/review_a1_r1_probes/run.sh       # the tables above, both binaries
python3 tools/free_pairing_check.py <k7|c1 lowered>    # 0 violation(s), 0 unproven
git status --porcelain tests/                          # only the increment's additions
```
I did not run the full `ctest` (the brief says it is already run) and I rebuilt nothing.
