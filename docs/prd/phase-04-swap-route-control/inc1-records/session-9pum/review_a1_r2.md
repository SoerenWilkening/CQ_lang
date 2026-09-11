# Rule-13 review, ROUND 2 — Track A.1, reviewing the round-1 FIX (`FIX_A1_R1.md`)

Independent adversarial review of the round-1 fix on branch `compare-select-parity`
(worktree `/Users/sorenwilkening/Desktop/CQ_trackA`, checkpoint commit `b439944` on top of
`main` 0c7380c). Subject binary `CQ_trackA/build/ir-pass/{cq-opt,libCQPass.so}` (built 17:43,
sources 17:43 — current). ORACLE `CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}` at `main`
0c7380c, read-only. **Nothing was rebuilt; nothing in `ir-pass/`, `include/`, `tests/` or
`tools/` was edited in any checkout; nothing was committed.** Every probe is committed beside
this file in `review_a1_r2_probes/` with a runner (`run.sh`) that re-derives every table below
on both binaries.

## VERDICT — **CLEAR-WITH-ITEMS**

**The round-1 BLOCKER is genuinely closed.** `k7`/`o3_kick` ACCEPT → DECLINE; `k8`/`k9`/`k6`
unchanged; `k10` (the S† accept control) still ACCEPT on both; the corpus is byte-clean. I
re-derived the set-difference argument from the source and attacked it six ways.

**What I found is the residual the fix's own Q-1 says it could not find a program for — and
there is one.** Two CONFIRMED silent miscompiles, single-TU plain `clang -O1`, `opt` exit 0,
verify-clean, STRICT stage-2b `0 violation(s)`, at two consumers whose classifier never asks
the wire question at all, kept open by the `Covered` exemption on a written ground that is
false for them. **Both are PRE-EXISTING on `main` (byte-identical streams), so this is not a
regression and not a BLOCK** — but it is the measured member of Q-1, it is one line of plain C,
and the fix's own stage would close it if the exemption were keyed on whether a round-1 ruling
exists.

| # | grade | one line |
|---|---|---|
| **F-A1R2-1** | **CONFIRMED-MISCOMPILE (plain C ×2), PRE-EXISTING — FILE + narrow the exemption** | `Covered` exempts every taint-blind-visible gate on the ground that "the classifier ruled on it"; for the 7.6 controlled I/O sink and the 7.5 guarded Shadow store there is no classifier wire clause and no ruling — Q-1 is NOT empty |
| **F-A1R2-2** | **DOC (corrects Q-3, in the fix's favour)** | the `InPlaceRailOps` crossing in `railWireNamesBackward` is NOT untested insurance: `f4f.c` is a single-TU plain-C program that declines **only** because of it (bd `r903`(b) through an in-place `cqrt_xorc`). Q-3 should be answered "keep it" |
| **F-A1R2-3** | **DOC** | F-A1-2's corrected monotonicity sentence names *two programs*; the accept class has at least **five** plain-C members (`b1`,`b2`,`r3`,`b3`,`b4`) and should be stated as a class |
| **F-A1R2-4** | **DOC** | the containment written at the call site (`blind ⊆ round-1 ⊆ final`, "exempts no more than the classifier actually saw") is wrong in two independent ways; both are derived below, one of them is F-A1R2-1's cause |
| **F-A1R2-5** | **DOC (trivial)** | `FIX_A1_R1.md` / `IMPL_A1.md` say "Not committed, not pushed"; the tree is committed as `b439944` |

**Q-1 outcome: NOT empty — F-A1R2-1 is a member, plain C, single TU, two consumers.**
**Containment outcome: `blind ⊆ round-1` does not hold as written** — see F-A1R2-4 — but the
direction of its failure is toward *over-accept*, not over-decline, which is why Q-2's "0
movers" measurement is right and its *reason* is not. I found **0 over-declines** in 70 probe
programs.

## What was re-verified of the fix's own claims (all hold)

* corpus diff, re-run independently over the 1776 `git ls-tree 0c7380c` fixtures, rc + stdout +
  stderr, oracle vs subject: **`FIXTURES=1776 MISSING=0 RCDIFF=0 DIAGDIFF=0 OUTDIFF=0`**
  (61 s at 8 threads, `scratchpad/trackA_review2/corpus_diff.py`);
* `ctest --test-dir build -R ir-pass-lit --output-on-failure` → **Passed, 38.99 s, 0 failed**;
* counts, measured: `ls ir-pass/test/*.ll | wc -l` → **1803**; `ls tests/e2e/*.expected.log |
  wc -l` → **345**; `ctest -N` → **392**, `-R '^e2e-'` → **382**;
  `git diff --name-status 0c7380c -- ir-pass/test` → **27 A, 0 M, 0 D**;
* `git status --porcelain tests/ ir-pass/ include/ runtime/ tools/` → **empty** (no
  pre-existing golden or fixture modified);
* the round-1 probe verdicts all reproduce: `k7` DECLINE, `k8` DECLINE, `k9` DECLINE, `k6`
  DECLINE, `k10` ACCEPT, `o3_kick` DECLINE, `b1`/`b2` ACCEPT, `c1`/`c10` ACCEPT, `c2`/`c9`
  DECLINE, `c3`/`c4`/`c7`/`c8` ACCEPT, `o7a`/`g2`/`g3` DECLINE, `o7c` ACCEPT, `sw1` ACCEPT,
  `sw2` DECLINE.

---

## F-A1R2-1 — CONFIRMED SILENT MISCOMPILE ×2 (plain C, single TU). Q-1's missing member.

### The programs (`review_a1_r2_probes/io3.c`, `gs1.c`)

```c
/* io3.c — the 7.6 CONTROLLED I/O SINK */              /* gs1.c — the 7.5 GUARDED SHADOW STORE */
#include <stdio.h>                                      static int guarded_local(int seed) {
void emit(int seed) {                                     int arr[8] = {0};
  int q  = cq_theta(seed, 0.5);                           int q  = cq_theta(seed, 0.5);
  int r  = cq_theta(seed, 0.25);                          int q2 = cq_theta(q, 0.9);
  int r2 = cq_theta(r, 0.9);   /* staler on r's wire */   int i  = cq_theta(seed + 1, 0.5);
  if (r > 5) printf("%d", q);                             if (q < 3) { arr[i] = 7; }
  (void) cq_measure(q);                                   int v = arr[q2];
  (void) cq_measure(r2);                                  return cq_measure(v);
}                                                       }
```

| probe | ORACLE (`main` 0c7380c) | SUBJECT | stream |
|---|---|---|---|
| `io3.c` | ACCEPT | **ACCEPT** ✘ | byte-identical to the oracle's |
| `gs1.c` | ACCEPT | **ACCEPT** ✘ | byte-identical to the oracle's |
| `io4.c` — the SAME wire shape at the phase kickback | DECLINE `condition predates a non-diagonal gate` | DECLINE ✔ | — |

### The emitted stream (`io3`, SUBJECT; `opt` rc 0, verify-clean, stage 2b `0 violation(s), 0 unproven`)

```
  %h1 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)      ; r  = Ry(.25)|seed>
  call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)      ; r2 = Ry(.9) on the SAME rail
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h1, i32 5)   ; THE FLAG
  %2 = call i32 @cqrt_tape_write_i32_controlled(i32 %h_cmp, i32 %tape, i32 %h)
```

and `gs1`: `ry(%h,.5); ry(%h,.9); %h_cmp = icmp_slt_hl(%h, 3); cqrt_qram_store_i32_controlled(%h_cmp, …)`.

State-vector argument (Rule 2). Write the register as `Σ_x α_x|x⟩`. The source gates on
`r = Ry(0.25)|x⟩ > 5`; the circuit gates on `Ry(0.9)Ry(0.25)|x⟩ = Ry(1.15)|x⟩ > 5`. The
predicate selects a different subspace, so the controlled tape write (resp. the controlled
Shadow store) lands on a different set of amplitudes — a different unitary. This is bd
`9pum`/`6j1`'s defect at two more consumers, and the project's own verdict on the shape is
`io4`: the identical wire at the kickback declines on **both** binaries.

### Root cause — the exemption's written ground is false for exactly these consumers

`ArmClassify.cpp:2440-2447`, at the `Covered` call site:

> "Such a gate was visible to the classifier at round-1 taint too … and the classifier applied
> its own disposition to it — `condWireDisposition` could still DT-prove it post-region …
> RESPECT THAT ANSWER, gate by gate"

For these two consumers no classifier applied any disposition, because neither ever reaches a
wire walk. Measured / grepped:

1. **`IOSinkLowering.cpp` and `GuardedStoreArmEmit.cpp` contain no `findNonDiagonalWireGate`,
   no `condWireDisposition`, no `railMeasured*`, no `condCmp*`** (`grep -n` over both files
   returns nothing). `lowerControlledIOSinks` runs at `CQLoweringPass.cpp` *before*
   `detectControlRegions`; `classifyGuardedStoreArm` is a **pre-peel** in `ControlDetect.cpp:518`
   that `Plan.Regions.push_back(R); return;`s **before** the generic `recoverRegion` path that
   eventually reaches `condWireDisposition` at `ArmClassify.cpp:2879`.
2. `declineStaleRecordOps` cannot cover them either, and says so: `inLowerOpsScope`
   (`OpcodeLowering.cpp:110-116`) admits a `CmpInst` only when `isDataPositionCompare(Cmp)` —
   "branch/select-condition compares excluded (Phase 4's — **ArmClassify owns their stale
   check**)". For these two consumers ArmClassify does not.
3. The A.1 record and stage DO reach them — this is the part that makes it this review's
   finding and not merely a pre-existing gap. `io1.c` (the same sink, condition register
   *measured* before) is **ACCEPT on the oracle, DECLINE on the subject** with `condition
   measured before the control route`, and `condCmpMeasuredBeforeReadPoint` is called from
   nowhere but `classifySelectRegion` and `classifyPhaseKickback` — so that decline can only
   come from `reverifyCmpCondReads`' ungated rung (ii) over the `lowerCompareToFlag` record.
   `gs2.c` is the same at the guarded store.
4. And rung (iii) reaches them too. **`multi/io5.c`** is `io3` with one change — the sibling's
   parent is a 6.5 `%out` derivative, so the gate is reachable only through the F-1b-1
   crossing and is therefore **not** in the taint-blind set: **ORACLE ACCEPT → SUBJECT DECLINE
   `condition predates a non-diagonal gate`**. Same consumer, same defect, same stage; the only
   difference is whether the gate is blind-visible, i.e. whether `Covered` holds it.

That pair — `io5` DECLINE, `io3m` ACCEPT (the two-TU spelling of `io3`, both binaries
byte-identical) — is the discriminator. The counterfactual is mechanical: with `Covered`
empty, the position-free taint-aware walk over `Seeds = {%r}` returns `r2` (its arg-0 **is**
`%r`, it is not on `%r`'s backward ancestry so not `Exempt`), and the position-aware prong then
fails at its first conjunct, `DT.dominates(EmitPoint, T)` — `r2` *precedes* the mint — so
`gateIsHarmless` is `false` and the entry declines.

### Which consumers do and do not catch it (all single-TU plain C, `review_a1_r2_probes/c_*.c`)

| consumer | probe | verdict (BOTH binaries) |
|---|---|---|
| 4.4 data select | `c_sel` | DECLINE `condition predates a non-diagonal gate` |
| flat phase kickback | `c_kick` | DECLINE, same |
| 4.3 depth-2 nest | `c_nest` | DECLINE, same |
| angle select | `c_angle` | DECLINE, same |
| 6.5 classical-call arm | `c_call` | DECLINE `control flow` |
| value arm | `c_val` | DECLINE `cq opcode lowering: operand predates a non-diagonal gate` |
| 7.2 abort park | `c_abort` | DECLINE `control flow` |
| **7.6 controlled I/O sink** | **`io3`** | **ACCEPT** ✘ |
| **7.5 guarded Shadow store** | **`gs1`** | **ACCEPT** ✘ |

### Disposition

It is **pre-existing** and outside A.1's declared scope (the source comment names these two
among "the consumers that get no classifier clause" and says only rung (ii) backstops them), so
it is a **FILE**, in the same class as F-A1-4 / bd `lo7u` — *not* a regression and not, in my
judgement, a BLOCK. But two things should change:

* **file it** (a new bd issue: "the 7.6 controlled I/O sink and the 7.5 guarded Shadow store
  mint their control flag from a staled condition wire; nothing asks the wire question"), with
  `io3.c`/`gs1.c` as reproducers and `io4.c` as the discriminator;
* **key the exemption on whether a ruling exists.** The exemption is computed per record entry,
  so the narrowing is local: record a per-entry "a round-1 wire disposition was taken" bit at
  the mint (the emitters that do run `condWireDisposition` / gate 2c set it), and pass
  `Covered` only when it is set. For an entry with no ruling the blind set is `{}` and rung
  (iii) asks about everything — which is the correct question there and cannot cost the twelve
  in-loop accepts, all of which are `ArmClassify` consumers. This is strictly smaller than the
  full "record the classifier's disposition per compare" closure O-3/Q-1 proposes.

---

## F-A1R2-2 — Q-3 is answered the other way: the `InPlaceRailOps` crossing IS a live fence

FIX_A1_R1 §F-A1-3 says *"For the DECLINE face I could not build a program that reaches the
crossing: every spelling I tried is pre-empted ONE STAGE EARLIER by
`LoopLowering::staleRailRecordRead`"*, and Q-3 asks whether to delete it as untested insurance.
**There is a reachable decline face, from single-TU plain `clang -O1` C.**

`review_a1_r2_probes/f4f.c`:

```c
int slice(int u) {
    int q = cq_theta(u, 0.5);  int acc = 0;
    for (int i = 0; i < 3; ++i) { acc += cq_measure(q); q = q ^ 9; if (q > 5) cq_phi(0.3); }
    return acc;
}
```

ORACLE **ACCEPT**, SUBJECT **DECLINE** `condition measured before the control route`. The
oracle's emitted body is bd `r903` item (b) verbatim, through the in-place relabelling:

```
  %m = call i32 @cqrt_measure_i32(i32 %h)          ; the register COLLAPSES
  call void @cqrt_xorc_i32(i32 %h, i32 9)          ; IN-PLACE: same physical register, new name
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)   ; flag from the collapsed register
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !cq.branchphase
```

The compare's **direct** operand is the post-`xor` name `%10`; the measure names the pre-`xor`
phi `%7`. Without the crossing `railWireNamesBackward(%10)` yields the singleton `{%10}`, which
has no `cq_measure` user, and rung (ii) accepts. The crossing is the sole reason it declines.

Why the fix's own probes missed it: `ip1`/`ip3` use `add`, and `clang -O1` rewrites
`(q+1) > 5` **sideways** onto the pre-`add` value (`icmp sgt i32 %7, 4` — measured,
`f4a.c` stage-1), so the measured register lands directly in the compare and the crossing is
never needed. `xor` does not distribute over the compare, so the post-op name survives. The
same asymmetry is visible straight-line: `x1.c` (`q ^ 9`) keeps `%t`, `x2.c` (`q + 7`) does not.

Discriminating ACCEPT control: `f4h.c` — the identical loop with a **different** register
measured — ACCEPT on both. **Recommendation: keep the crossing, and replace Q-3 with
`f4f.c` + `f4h.c` as a lit pair** (`f4f` is RED on the oracle).

---

## F-A1R2-3 — the rail-path accept class is wider than the two programs it is recorded as

BRIEF §1's ERRATA and IMPL §5's correction both read *"A.1 is decline-monotone on the COMPARE
path, and has exactly these two rail-path ACCEPT movers, **by name**"*. The class — an
iteration-local register whose SOURCE-theta origin re-executes on every path from the
measurement back to the read — has at least five plain-C members, all `DECLINE → ACCEPT`, all
correct:

| probe | shape | why the accept is right |
|---|---|---|
| `b1`,`b2` | the fix's two, constant seed | `cqrt_alloc_i1` inside the body (measured) |
| `r3.c` | the seed is a **loop-carried classical** expression (`(_Bool)(s & 1)`, `s` from `cq_measure`) | `%h = cqrt_alloc_i1(%6)` **inside** the body — verified in the lowered IR |
| `b3.c` | the seed is **loop-invariant but non-constant** (`(_Bool)(u & 1)`) | `-O1` does **not** LICM the mint out; `cqrt_alloc_i1(%3)` is inside the body — verified |
| `b4.c` | the mint is inside a **guarded sub-block** of the body, with the read and measure in the same block | every path re-executes the origin (the `o7c` argument) |

Nothing is wrong here; the sentence is. Say the class, and keep `b1`/`b2` as its pins —
otherwise the next reader takes "exactly two, by name" as an exhaustive claim about programs
and it is not one.

---

## F-A1R2-4 — the containment `blind ⊆ round-1 ⊆ final` is wrong in two ways

The call-site argument is *"the F-1b-1 crossing only ADDS values to the backward closure, so
blind ⊆ round-1 ⊆ final — exempting the blind set exempts no more than the classifier actually
saw, and is therefore conservative toward DECLINE"*. Both halves fail, and the failures point
the same way: **`Covered` is a SUPERSET of what round 1 examined, not a subset.**

**(a) "the classifier actually saw" presumes a classifier walk.** F-A1R2-1: for two of the five
consumers this same file names as having no classifier clause, the round-1 set is `∅` while
`Covered` is not. That is the measured one.

**(b) the two walks are built by three different rules, not one.** The comment at the
enumerating branch says the gate is pushed forward *"so a gate reachable only behind another
one is enumerated too (the two sets of the difference must be built by the same rule)"*. The
sets of the *difference* are indeed built by one rule — but the set round 1 actually examined
is built by a **third**: `walkNonDiagonalWireGates` in return-first mode **never pushes a
staling gate onto `Work`** — it `return`s it, or (when `gateIsHarmless` proves it harmless)
`continue`s **without** pushing. So a gate `B` whose only route is *behind* a gate `A` that
round 1 proved harmless was never examined at round 1 and is nevertheless in `Covered`.

I could not turn (b) into a program, and I believe it is safe, by a derivation worth recording
because the code does not have it. With `A` harmless and `B` a forward user with
`B->getArgOperand(0) == A`:

* `DT.dominates(EmitPoint, A)` and `A` dominates `B` ⟹ `DT.dominates(EmitPoint, B)`;
* leg 1: any path `B ⇝ EmitPoint` extends a path `A → B ⇝ EmitPoint`, so
  `!isPotentiallyReachable(A, EmitPoint)` ⟹ `!isPotentiallyReachable(B, EmitPoint)`;
* leg 2 is the only seed-dependent one and is the only place transitivity could break (the
  barrier could sit on the `A → B` segment). It cannot here: reaching `B` from `A` across a
  barrier requires the wire to cross a back edge, and a value crossing a back edge arrives as a
  **phi** — which `CrossValueRouting` pushes in *every* mode, round 1 included, so `B` is not
  behind-only.

**Why Q-2's "0 movers" is right for a different reason than stated.** `round1 \ blind` is
(near-)empty *by construction*, not by luck: the recorded `Seeds` is the `condProvenance`
CONE — every tainted ancestor — so the value the F-1b-1 crossing would reach backward is
already its own seed in the blind walk, and the blind forward walk from it finds the same
gates. The crossing adds gates only when the ancestor was **not tainted at round 1**, and in
that case the blind walk cannot see them either. 70 probe programs, 0 over-declines.

**Suggested replacement wording** (for `ArmClassify.cpp` and Q-2): *"`Covered` is the set of
gates reachable with no taint-dependent crossing. Where a classifier ran a wire walk it is a
superset of what that walk examined, and the extra members are transitively post-emission (see
the derivation). Where NO classifier ran one — the controlled I/O sink and the guarded Shadow
store — it exempts gates nobody ruled on, and that is bd `<new id>`."*

---

## The attacks that did NOT land (so the next round can skip them)

* **Q-1 at a fenced consumer.** `w3` (S† *before* the sibling), `w6` (a gate behind the round-2
  sibling), `w9` (6.5 arm), `w10` (value arm), `w11` (angle select) — every one DECLINES on the
  subject or on both. The set difference does what it claims wherever a ruling exists.
* **The exempt gate's own chained-ness changing at round 2** (brief §1's second shape). A gate
  is enumerated by the forward walk on `CI->getArgOperand(0) == V`, which is taint-independent,
  and `Exempt` is monotone in the closure — so a gate that is evidence at final taint was
  evidence at round 1 whenever it was blind-reachable. I could not construct the asymmetry.
* **A round-1 DT/leg-2 proof invalidated by the flatten.** The flatten linearizes into `Pred`;
  a merge-block gate stays after the emitted stream, and an arm-block gate that the emitters
  hoist is refused earlier (`c_val` declines at `declineStaleRecordOps`). Nothing moved.
* **Q-4 (empty `OperandSeeds`, non-empty `Seeds`).** `multi/q4a.c`/`q4b.c` — a compare whose
  right operand is a 6.5 `%out` (classical at round 1, a rail at round 2) — decline earlier on
  both binaries with `no template for opcode 'icmp i1' in tainted context`. No witness either
  way; the fix's structural argument stands unrefuted.
* **Q-5 (Q+Q).** Both operands *are* seeded and both faces fire: `f4c.c` (left measured) and
  `f4d.c` (right measured) are ACCEPT → DECLINE at the select; the `br` spelling `f4e.c`
  declines earlier on `quantum-quantum compare condition` on both. Q-5 is answered; a lit pin
  for the two select faces would be cheap.
* **Brief §6, the rail side.** `r1.c` (origin in the preheader, register loop-carried through
  the header phi, `cq_measure` in the body) DECLINES on both — the back-edge path never crosses
  the preheader, so no barrier is granted. `r2.c` (a CHAINED in-body theta — refreshes nothing)
  DECLINES on both. `d3a.c` (the drbq Inc-3 in-loop controlled-Ry arm with the condition
  measured in the body, condition register loop-variant) is ACCEPT → **DECLINE**, correctly:
  trip 1's measure collapses a register trips 2–3 mint from. Its control `d3b.c` (no in-body
  measure) accepts on both.
* **Over-declines (brief §7).** 0 found in 70 programs. The nearest miss is `od1.c` — a measure
  taken only on the LAST trip, which path-based reachability still refuses — and its `_Bool`
  twin `od1b.c` declines **on `main` too**, with the same string: that is the shipped rail
  ladder's policy, not a new refusal. Every decline I produced is a post-measure control or a
  compare whose `-O1` direct operand IS the measured register (`c2`, `c9`, `f4b` — verified in
  the stage-1 IR, e.g. `long long t = (long long)q` narrows to `icmp eq i32 %2, 5`).
* **The abort park.** `ab1.c` (blind-visible staler) declines `control flow` on both, so 7.2 is
  not a member of F-A1R2-1's population at that spelling; `ab2.c` (condition measured before)
  is ACCEPT → DECLINE, i.e. rung (ii) backstops it as designed.

## `-O1` reachability, per finding

F-A1R2-1 **plain C, single TU** (`io3`, `gs1`; two-TU discriminators `multi/io5`, `multi/io3m`);
F-A1R2-2 **plain C, single TU** (`f4f`, control `f4h`); F-A1R2-3 **plain C, single TU**
(`r3`, `b3`, `b4`); F-A1R2-4 (a) measured as F-A1R2-1, (b) derived, no witness.

## What I ran

```
python3 scratchpad/trackA_review2/corpus_diff.py   # FIXTURES=1776 MISSING=0 RCDIFF=0 DIAGDIFF=0 OUTDIFF=0
ctest --test-dir build -R ir-pass-lit --output-on-failure   # Passed, 38.99 s, 0 failed
docs/.../session-9pum/review_a1_r2_probes/run.sh            # every table above, both binaries
python3 tools/free_pairing_check.py <io3|io3m|gs1 lowered>  # 0 violation(s), 0 unproven
/usr/local/opt/llvm@19/bin/opt -passes=verify -disable-output <io3|io3m lowered>   # clean
git status --porcelain tests/ ir-pass/ include/ runtime/ tools/   # empty
ls ir-pass/test/*.ll | wc -l = 1803 ; ls tests/e2e/*.expected.log | wc -l = 345 ; ctest -N = 392
```
I did not run the full `ctest` (the brief says it is already run) and I rebuilt nothing.
