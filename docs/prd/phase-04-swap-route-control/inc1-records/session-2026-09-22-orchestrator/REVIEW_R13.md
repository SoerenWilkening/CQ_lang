# Rule-13 independent review — bd `test_C_libtooling-fn1q` increment 1 (the value arm's classical cone)

Reviewer: independent (did not write this code). Date 2026-09-18.
Workdir `/private/tmp/claude-501/r13fn1q` — every reproducer named below is committed there.

## Binaries, hash-checked before any measurement

```
$ shasum -a 256 /private/tmp/claude-501/cqoracle/build/ir-pass/cq-opt \
                /Users/sorenwilkening/Desktop/Projects/CQ_lang/build/ir-pass/cq-opt
3368af1262695d7e4c573d3958f0a9aa48e604bf5248e1b85a52362ac76f69dc  …/cqoracle/…/cq-opt   (ORACLE)
3497126f3528e8ea4727c39be5e4d7cec610afc3c0853c43e101b17ed496513f  …/CQ_lang/…/cq-opt    (SUBJECT)
```
Both match the brief. **No rebuild, no ctest, no lit suite was run.** Harness: `run.sh`
(stage 1 `clang -O1 [-g]`, then both binaries on the same stage-1 file, exit + first
diagnostic + md5 of the lowered function body).

## VERDICT: **CLEAR-WITH-ITEMS** — 0 P1, 2 P2, 6 P3.

The hoist mechanics are sound. Attacks A, B, C, E and F all failed to produce a wrong
circuit, and I could not construct any over-accept reachable from `clang -O1` on a CQ.h
program. Attack D **succeeded in the direction the increment wanted**: I constructed the
L1 round-2 shape the record says it could not exhibit, and `declineRound2TaintedArmCone`
is the predicate that fires. The two P2s are both "right answer, wrong or stale stated
argument" — one of them is a **measured** claim elsewhere in the tree that this increment
falsifies and did not re-prove.

---

## Findings

| id | sev | claim | reproducer | ORACLE | SUBJECT |
|---|---|---|---|---|---|
| F-1 | **P2** | A front-end intrinsic call that takes no tainted operand — `cq_phi`, `__cq_invert_begin/_end` — or `cq_measure` (skipped as a taint sink) is admitted as a CONE MEMBER **in a value arm** and hoisted: the branch phase is then silently DELETED and the measurement fires unconditionally. The only thing containing them is `speculatable` on an opaque declaration — not a predicate. | `probes/Q5_phi_spec.ll`, `probes/K6_measure_spec.ll`, `probes/U2_invertbegin_spec.ll` (controls: `probes/Q6_phi_const_only.ll`, `probes/K7_measure_const_only.ll`, `probes/Q4_theta_spec.ll`, `probes/U1_invert_spec.ll`) | `impure value arm`, exit 1 (all seven) | Q5/K6/U2 **exit 0**; Q6/K7/Q4/U1 exit 1 |
| F-2 | **P2** | The increment falsifies a **measured** claim in `SwapRouteEmit.cpp`'s cross-region `select` pre-flight — "EVERY region kind that erases an arm constrains that arm to a shape a `select` cannot satisfy (… `valueArmIsPureChain` …)" — and did not re-prove it, although that comment's own trigger demands it. | `probes/P1_untainted_select_cone.ll` (and `probes/P2_tainted_select_cone.ll` as the control) | P1 `impure value arm` exit 1 | P1 **exit 0** (select hoisted); P2 exit 1 |
| F-3 | P3 | `emitValueRegion`'s own header still describes the arm as holding only the chain ("no memory and no call"); the (B) memory argument lives only in `ArmClassify`. | source read, `ir-pass/src/SwapRouteEmit.cpp:232` and `:249` | — | — |
| F-4 | P3 | **The source on disk post-dates the pinned SUBJECT binary.** `ArmClassify.cpp` mtime 14:59:09 > `build/ir-pass/cq-opt` 14:55:01. | `stat -f "%Sm %N" -t "%F_%T" ir-pass/src/ArmClassify.cpp build/ir-pass/cq-opt` | — | — |
| F-5 | P3 | The session record carries **no `GATES.md` and no corpus result file**; `probes/corpus_ab.sh` exists but no `corpus_<hash16>.txt`. The "0 A→D / 0 stream moves over 2117" claim is unevidenced in the record. | `ls docs/prd/…/session-2026-09-22-orchestrator/` | — | — |
| F-6 | P3 | `corpus_ab.sh`'s decline-string regex `'cq [a-z]* lowering: …'` **cannot match `cq taint escape: …`**, so a decline→decline move into or out of that family scores `SAME`. The PROTOCOL's own S3 lesson, repeated. | `probes/corpus_ab.sh` line 11–12 | — | — |
| F-7 | P3 | The **if/else** shape is NOT byte-identical to its pre-hoisted twin — only the single-arm diamond is. The increment's stated correctness instrument degrades to gate-stream identity for a two-arm region, and no fixture pins the two-cone shape at all. | `probes/A_ifelse_two_cones.ll` vs `probes/A_twin.ll` | both `impure value arm` | both exit 0, lowered bodies differ by 2 lines, **gate streams identical** |
| F-8 | P3 | `declineRound2TaintedArmCone`'s comment "a freed pointer is not a finding" is imprecise: the walk never *dereferences* a stale pointer, but a **recycled address** occupied by a live tainted instruction would produce a false decline. Safe direction; not reproduced. | source read, `ir-pass/src/ArmClassify.cpp:3714-3720` | — | — |

### F-1, in detail (the one I would act on first)

```
$ ./run.sh probes/Q5_phi_spec.ll
--- ORACLE exit=1   cq controlled lowering: impure value arm under quantum control
--- SUBJECT exit=0  lines=29
```
The module is the shipped accept fixture with one line added to the arm:
`call void @cq_phi(double 3.000000e+00)`, and `@cq_phi` declared
`#9 = { nounwind willreturn speculatable memory(none) }`. The SUBJECT's lowered stream
contains **no `cqrt_rz_i1` at all** — the cone hoists the `cq_phi` into the pred, where it
is uncontrolled, and `deleteGlobalPhases` deletes it as a global phase. The user's branch
phase — the whole quantum answer for that arm — vanishes at `opt` exit 0. That is the exact
hazard the stray rule's own comment names: *"a stray op is silently DROPPED (a vanishing
user measurement, Rule 5)"*.

`probes/K6_measure_spec.ll` is the same shape with `cq_measure_si32` so attributed; the
SUBJECT emits `%m3 = call i32 @cqrt_measure_i32(i32 %h2)` **unconditionally in the pred**,
where the source wrote it inside a quantum-controlled arm. `probes/U2_invertbegin_spec.ll`
does it with `__cq_invert_begin()` — CQ.h's real inversion marker — which is also hoisted.

**Why this is the increment's to own, and why it is P2 and not P3.** Pre-increment, ANY
non-chain arm instruction declined, whatever its attributes — the containment was
structural. The widening replaces that with four conjuncts, and **none of them mentions
CQ's own intrinsics**. I measured which conjunct actually contains each family:

| in a value arm | contained by | attribute-dependent? |
|---|---|---|
| `cq_theta` | **(K1)** — the call is the taint SOURCE, so it is in `Taint.Tainted` | **no** (`Q4_theta_spec.ll` still declines with `speculatable`) |
| `cq_measure` | **(K4)** only — `isMeasureSink` stops taint at the call, so (K1) passes; (K2) passes on `memory(none) nounwind willreturn` | **yes** |
| `cq_phi` | **(K4)** only — same | **yes** |
| `__cq_invert_begin/_end` | **(K4)** only — void, no tainted operand, so (K1) passes | **yes** |
| `cq_invert_<sfx>` | **(K1)** — takes the tainted handle, so `propagateWorklist` taints the call | **no** (`U1_invert_spec.ll` still declines) |

So the fence is one attribute deep on a declaration the compiler does not own, and it is
**inconsistent across the families**. The population is exactly characterisable, which is
the reason to fix it by membership rather than by enumeration: `propagateWorklist` taints
every user of a tainted value, so any intrinsic that *consumes* a quantum handle is caught
by (K1) — what escapes is precisely the intrinsics that take **no** tainted operand
(`cq_phi`, `__cq_invert_begin/_end`) plus the one that is explicitly **skipped**
(`isMeasureSink`). This is the mirror of the (P4) P1 CLAUDE.md
records from Rule-13 round 4 on bd `11qv`: *"the second list trusted what the first merely
tolerated."* Here the cone rule trusts a declaration's attributes for exactly the three
callees `declineTaintEscapes` exempts by name.

**Why P2 and not P1.** Not reachable from `clang -O1` on a CQ.h program. Measured: clang
lowers `__attribute__((const))` to `nounwind willreturn memory(none)` and **never**
`speculatable` —
```
$ clang -O1 -emit-llvm -S probes/attrtest.c -o - | grep '^attributes #2'
attributes #2 = { nounwind willreturn memory(none) }
```
and that attribute set still declines (`probes/K7_measure_const_only.ll`,
`probes/Q6_phi_const_only.ll`, both exit 1 on both binaries). It is reachable from
hand-written `.ll`, which is this tree's primary fixture surface, so a future fixture
author can create it unknowingly. **If the owner treats hand-IR as in-scope input, this is
a P1.**

**Fix direction (one line, the same repair (P4) got):** refuse a cone member by
MEMBERSHIP of `taint.ThetaCalls` / `taint.PhiCalls` / `taint.MeasureCalls` rather than by
its declaration's attributes — asked as *"is this one of the front-end intrinsics the
lowering owns?"*, not *"did someone mark it speculatable?"*. Owes a red-green pair
(`…_reject_arm_cone_phi_call.ll`, `…_reject_arm_cone_measure_call.ll`).

Secondary note inside F-1: a `cq_phi` beside the chain is a **MIXED arm**, which
`walkValueChain`/`classifyArms` have a dedicated disposition for (`Chain.MixedPhi`). The
cone rule bypasses that owner entirely when the attributes allow — the L6 question ("is the
thing you are protecting the unitary or the emitter's bookkeeping?") has an answer here and
it is *the unitary*.

### F-2, in detail

`ir-pass/src/SwapRouteEmit.cpp` (~2903–2913), the `AngleSelectRegion` dispatch:

> "It cannot happen at HEAD because EVERY region kind that erases an arm constrains that
> arm to a shape a `select` cannot satisfy (`armBlockIsPureSpine`, **`valueArmIsPureChain`**,
> `inPlaceRotationArmTheta`, …) — measured on a hand-IR diamond … **A future region kind
> that erases a block whose contents it does not fix must extend the pre-flight to this Kind
> or re-prove that purity.**"

`probes/P1_untainted_select_cone.ll` puts `%sel = select i1 %cc, i32 11, i32 22` (untainted
condition) in a value arm: ORACLE `impure value arm`, SUBJECT **exit 0**, the select hoisted
into the pred. So the named ground is now false.

**The conclusion still holds**, for a different reason, and I verified it:
a `SelectRegion` / `AngleSelectRegion` is detected on a **tainted** condition, taint
propagation taints every user of a tainted value including a `select` that uses it as the
condition (`propagateWorklist`, `TaintPropagation.cpp:466` — generic over `V->users()`, with
only the measure-sink and theta/phi-arg-1 exceptions), so such a select is in
`Taint.Tainted` and **(K1)** refuses it. `probes/P2_tainted_select_cone.ll` (tainted
condition) declines on both binaries. The increment did not change a modification to a
different region kind — it changed one of the named constraints, which is the same trigger.
Right answer, stale stated ground: **L7's shape**, and the file explicitly asked to be
re-derived.

---

## Attack-by-attack record

### A — HOIST ORDER (if/else, two cones). **Could not break it.**
`probes/A_ifelse_two_cones.ll`: ORACLE `impure value arm`; SUBJECT exit 0. Emitted order is
`cone0 · chain0 · cone1 · chain1`; `opt -passes=verify` clean. `probes/A2_interleaved.ll`
puts a cone member *between* two chain links in block order (`%c1; %v1; %c2; %v2`): hoisted
as `%c1 %c2 %v1 %v2`, verify clean, stage 2b `2 verified, 0 violation(s), 0 unproven`, and
**byte-identical to its pre-hoisted twin** `probes/A2_twin.ll`.

I could not construct an operand-ordering violation, and there is a structural reason to
state rather than leave implicit: a cone member's in-arm operands are only ever other cone
members (the (K1) direct operand test refuses a chain-link operand, and every non-terminator
arm instruction is chain ∪ cone or the helper rejects), block order gives definition-before-use
among those, and for an out-of-arm operand `X`: every path to `ArmBB` runs through `Pred`, so
`X` dominating `ArmBB` implies `X` dominates `BI`. **The hoist is SSA-valid for any number
of arm predecessors.** The `isa<PHINode>` conjunct is doing real work here — an arm φ used
by a chain link's classical slot is the one arm-block value that would not be available, and
it is rejected.

### B — THE LOAD-HOIST MEMORY ARGUMENT. **Falsification attempts all failed.**
- *Can a chain link write?* No. `walkValueChain` (`ArmClassify.cpp:2289`) admits only
  `BinaryOperator` with non-empty `binaryStem`; it `break`s on anything else. Verified by
  source read.
- *Can a (K2)-passing cone member write?* `mayWriteToMemory() || mayHaveSideEffects()` covers
  store, `atomicrmw`, `cmpxchg`, `fence`, **volatile load** (`LoadInst::mayWriteToMemory` is
  `isVolatile()`), `MemIntrinsic`, `llvm.assume`, `llvm.lifetime.*`, and any call that may
  write / may throw / may not return. Measured: `probes/Q1_memcpy.ll` (`llvm.memcpy` in the
  arm) declines on both.
- *Can the other arm write?* No — (K2) is asked of each arm independently, so an if/else with
  a writing arm declines before either arm is hoisted.
- *Can a cone member be `readnone` but throwing?* No: `mayHaveSideEffects()` includes
  `mayThrow()`, and `probes/K3_pure_call.ll` (`nounwind willreturn memory(none)`, i.e. the
  strongest thing C can express) declines anyway at (K4).

So the increment's "by construction, not by analysis" claim holds **for the population the
increment describes**. F-1 is the exception and it is about a *call*, not a write.

### C — (K4)'s STRENGTH. **Could not find an admitted-but-unsafe member.**
- `udiv` by a run-time classical divisor: declines (the shipped reject fixture). A dominating
  classical `if (n != 0)` does **not** rescue it — the no-context form has no DT/AC, so it is
  strictly more conservative than a context-aware call would be. That is the safe direction.
- Run-time-indexed global array load (`probes/P6_runtime_index_load.ll`): declines — the GEP
  has no constant offset so `isDereferenceableAndAlignedPointer` refuses. ⚠ This is why
  `MEASUREMENT.md` §2's own headline exhibit `flat_qc_load` **still declines on the SUBJECT**
  (re-measured: both binaries `impure value arm`); the increment fixes the *scalar* cone, not
  that row. Consistent with `IMPL_INC1.md` §3, but a reader of `MEASUREMENT.md` §2 would take
  the opposite.
- `alloca` in the arm + a load from it (`probes/Q2_alloca_in_arm.ll`): declines.
- `llvm.lifetime.start` in the arm: `memory(argmem: readwrite)` ⇒ (K2) refuses, so the
  "lifetime.start inside the arm" shape cannot arise with the load admitted.
- A speculatable **intrinsic** (`llvm.abs.i32`, `probes/K5_intrinsic.ll`) and a speculatable
  **declared** call (`probes/K1_spec_call.ll`) are now cone members and are hoisted. For an
  ordinary callee that is semantically fine (`speculatable` is LLVM's own promise, and the
  6.5 owner hoists such calls too) — it only becomes F-1 when the callee is a CQ intrinsic.
  ⚠ Neither `IMPL_INC1.md` nor the fixture headers say the cone now admits **calls** at all;
  the surface is described as "the `load @k`, `mul`, `add`, `xor`".
- `freeze` of a classical value (`probes/P5_freeze_cone.ll`): now a cone member. Harmless.

### D — THE ROUND-2 FENCE. **I built the shape the record says it could not exhibit.**

`probes/D3_round2_cone_gap.ll`: a 6.5 classical-call-arm region (`@f #0 = { nounwind
willreturn memory(none) }`), then a filler block, then a value region whose **cone** is
`%k1 = mul i32 %y, 3` over the 6.5 region's merge φ.

```
$ ./run.sh probes/D3_round2_cone_gap.ll
--- ORACLE  exit=1  cq controlled lowering: impure value arm under quantum control
--- SUBJECT exit=1  cq controlled lowering: value arm classical operand became quantum under quantum control

$ CQ_CTRL_DBG=1 CQ_CTRL_BT=1 …/cq-opt … -S probes/D3_round2_cone_gap.ll -o /dev/null
CQ_CTRL_DBG: decline [value arm classical operand became quantum] at:   %k1 = mul i32 %out, 3
 2  cq-opt  cq::declineRound2TaintedArmCone(llvm::Module&, cq::TaintSet&) + 667
```
Backtrace-confirmed: `declineRound2TaintedArmCone` is the firing predicate, and the anchor is
the cone member reading the now-tainted `%out`. **The filler block is the whole trick**:
without it (`probes/D1_round2_cone.ll`) the pair declines earlier at `lowerControlRegions`'
`sequentialChainAlias` / `reorderable` overlap check (bd `35t0` — `ClassicalCallArm` is not a
reorderable Kind), which is almost certainly why the implementer's probes did not reach it.

I also checked the **no-cone neighbour** — the chain link reading the 6.5 merge φ directly
(`probes/D2_round2_nocone.ll`, `probes/D4_round2_nocone_gap.ll`). Both decline `control flow`
on **both** binaries, so the fence is not a fig leaf in front of an open hole of the same class.

**Consequence for the record (P3, folded into F-5's bucket):** `IMPL_INC1.md` §2 and
`TaintSet::ValueArmConeOps`' header both say *"⚠ Reachability is NOT claimed. The construction
above is argued, not exhibited; no probe in this increment produced it."* That sentence is now
false and should be corrected at **both** sites in the same change (L7-with-a-twist: a record
correction that is not applied to the source is not a correction). Per Rule 12 the shape now
owes a decline fixture; `probes/D3_round2_cone_gap.ll` is ready to become one.

### E — `ShadowCone` / `ValueArmConeOps` lifetime. **No dangling read found.**
- `detectControlRegions` is immediately followed by `lowerControlRegions` in **both** entry
  points (`CQLoweringPass.cpp` — nothing between them). `peelIndependentMergePhis` runs
  *before* detection, not between.
- `ShadowCone` has exactly the lifetime `Shadow` already had: a region's cone lives in its own
  arm block, and no other region's flatten can erase that block (two regions sharing an arm
  are refused by the overlap pre-flight; `B.Arm` has one predecessor while `A.MergeBB` has two,
  so they cannot alias). The sequential-chain case (`B.Pred == A.MergeBB`) is forced
  B-before-A by `sequentialChainAlias` — exercised by `probes/S1_two_value_regions.ll` (two
  value regions, a cone each): SUBJECT exit 0, verify clean, stage 2b `2 verified, 0
  violation(s), 0 unproven`, correct stream with `%out2` threading into the second region.
- `ValueArmConeOps` has **one writer** (the hoist) and **one reader**
  (`declineRound2TaintedArmCone`), and the reader runs at `CQLoweringPass.cpp:667` / `:1257` —
  after `repropagateControlMerges` (`:616` / `:1227`), before `lowerRotations` (`:839` /
  `:1331`), and long **before** `uncompute`. There is no post-`uncompute` read to dangle.
  Residual: F-8 (address recycling ⇒ false decline, safe direction, not reproduced).
- `ArmCone` is a fresh local declared inside the per-arm loop body, so an if/else's two cones
  cannot bleed into each other.

### F — THE (K3) UNREACHABILITY CLAIM. **Could not reach it; the claim is sound.**
My first attempt (`probes/F1_k3_merge_use.ll`, a cone member used in the merge block) is not a
valid module at all — **both** binaries reject it before the pass runs:
`Instruction does not dominate all uses! %kk = load … / %use = add i32 %m, %kk`. That is the
claim's own argument made mechanical: an arm block dominates nothing but itself, so an
external use is not expressible except as a merge φ on the arm edge, and that route is closed
earlier (a second merge φ ⇒ `soleMergePhi` null ⇒ `control flow`; a *sole* merge φ carrying the
cone member ⇒ `walkValueChain` returns EMPTY ⇒ `value-arm swap-route` at `ArmClassify.cpp:6193`).
I accept "(K3) is defensive and unreachable" as measured.

### G — FIXTURE HYGIENE. **Good; the three Rule-12 defects are all absent.**
- **Negatives are pure.** `NOROUTE` carries only `-NOT` directives. The three counts live in
  their own whole-file prefixes (`FCNT` / `CCNT` / `CONECNT`), each `COUNT-n` + `NOT` — no
  positive COUNT windows a negative.
- **Decline fixtures are non-vacuous**: all three use `RUN: not … 2>&1 | FileCheck` with the
  message on stderr, not an IR-text `CHECK-NOT` on an empty stdout.
- **Each decline fixture declines for the reason its header claims** — proven by
  single-conjunct mutation, not by re-reading the prefix (files in `mut/`):

  | mutant | change | SUBJECT |
  |---|---|---|
  | `mut/m_unspec_to_mul.ll` | (K4) fixture's `udiv` → `mul` | **exit 0** |
  | `mut/m_store_to_load.ll` | (K2) fixture's `store` → `load` | **exit 0** |
  | `mut/m_stray_untainted.ll` | (K1) fixture's `mul %q, 9` → `mul %v0, 9` | **exit 0** |

  All three are `impure value arm` unmutated. So each fixture is a discriminator for exactly
  its named conjunct.
- **Mutation matrix over the ACCEPT fixture** (I mutated the SUBJECT's *lowered output* and
  re-ran each prefix, since I may not rebuild). ⚠ My first "cone after chain" mutant was a
  **NULL MUTANT** — the cone already sits immediately before the chain link, so my edit
  changed nothing and I nearly filed a MISSED against a fixture that catches it (L10, my
  instrument, caught by `diff`ing the mutant against the original). Corrected results:

  | mutant | caught by |
  |---|---|
  | null control (unmodified) | PASS on all 5 prefixes ✓ |
  | `mut/A.ll` cone load duplicated | `CHECK`, `CONECNT` |
  | `mut/B.ll` one cone member dropped | `CHECK` |
  | `mut/C2.ll` cone moved after the chain link | `CHECK` |
  | `mut/E.ll` two cone members swapped | `CHECK` |
  | `mut/F.ll` a rail allocated for the cone value | `CHECK`, `NOROUTE` |
  | `mut/D.ll` extra `cqrt_x` injected after the free | `CHECK` |

  0 MISSED overall. The contiguous `CHECK-NEXT` block is what does the work; `CONECNT` earns
  its keep on the duplication mutant, which `CHECK` alone would also catch but which no
  ordering-insensitive prefix would.
- `python3 tools/negative_vacuity_check.py` over the five new fixtures:
  `5 fixture(s), 16 directive(s) evaluated, 0 VACUOUS, … [cq-opt 3497126f3528e8ea]`, rc=0.
- e2e slice: rebuilt the whole pipeline by hand on the SUBJECT — `opt` exit 0, stage 2b
  `1 verified, 0 violation(s), 0 unproven`, linked and run, **trace byte-identical to
  `slice_control_value_arm_cone.expected.log`**. The four cone instructions are present in the
  lowered module as ordinary classical IR (`load i32, ptr @k` / `mul nsw` / `add nsw` / `xor`),
  so the golden's `cq_template_add_i32_hl(h1, 2)` really is computed at run time.
- The slice's byte-identity claim checks out for the pipeline that matters: without `-g`
  (which is what `run_slice.sh` uses) the two stage-1 files are identical; with `-g` the
  instruction streams are identical and only the `#dbg_value` records and metadata numbering
  differ. Worth one word of qualification in the comment, no more.
- LLVM 19 emits `#dbg_value` **records**, not `llvm.dbg.value` instructions, so
  `for (Instruction &I : *ArmBB)` never sees them and cone admission does not depend on `-g`.
  I checked this explicitly because an instruction-form debug intrinsic would have been a
  free cone member.

### H — DOES ANY EXISTING STREAM MOVE? **No mover in 872 fixtures.**
The record carries no corpus result (F-5), so I ran my own A/B, with a **full-stderr sha**
comparison instead of a tag regex (closing F-6's blind spot):

```
$ # 622 fixtures matching value|swap|classical_call|select|switch + a deterministic
$ # 1-in-6 sample of the other 1495 = 872 files; both binaries on the same input
$ cut -f2 sweep.tsv | sort | uniq -c
    872 SAME
```
0 A→D, 0 D→A, 0 STDERR (decline-string) moves, 0 STREAM moves. Files: `sweep.list`,
`sweep.tsv`.

There is also a structural argument for "no shipped stream moves" that I checked against the
source and that is stronger than the corpus: for an arm instruction that **is** on the chain
the control flow is unchanged (`continue`); for one that is **not**, the old code returned
`false` immediately, so every module that accepted before had an empty cone, `ShadowCone`
stays empty, the hoist loop over `A.Cone` is empty, and `declineRound2TaintedArmCone`
early-outs on an empty `ValueArmConeOps`. The `CQ_CTRL_BT` lever is `getenv`-gated.

**`SwitchArmProve.cpp`'s re-derived mirror** (`valuePureChain`, `:106`) is **strictly
stricter** — it still rejects any non-chain arm instruction. So no switch arm can carry a
cone, `emitSwitchValueRegion`'s re-derivation at emit cannot meet one, and the divergence is a
Rule-14 debt (already filed in `IMPL_INC1.md` §3) rather than a correctness gap. Measured:
`probes/R1_switch_cone.ll` declines identically on both binaries. Nested depth-2 with an inner
cone (`probes/R2_nested_cone.ll`) and an in-loop cone (`probes/L1_inloop_cone.ll`) also decline
on both, as `IMPL_INC1.md` §3 says.

### Other things I measured that are not findings
- **Taint escapes are intact.** A cone member loading a parked tainted value — the route that
  would make a qubit *handle* the `_hl` classical literal (the afmv wrong-unitary class) —
  is closed at the store, not at the cone: `probes/M1_global_park.ll` and
  `probes/M2_alloca_park.ll` both give `cq taint escape: tainted value stored to memory` on
  both binaries. And a `!cq.railbank` cell load is seeded TAINTED in `collectAndSeed`
  (`TaintPropagation.cpp:107-140`), so (K1) refuses it. A speculatable call taking the routed
  register (`probes/K2_spec_call_tainted_arg.ll`) gives `tainted value consumed by an unknown
  callee` on both.
- **A multi-region twin that is BYTE-identical across both binaries.**
  `probes/T1_value_cone_then_phase.ll` — a value region with a cone followed by a phase
  kickback region (the `hcrg` sequential shape) — against `probes/T1_twin.ll`, the same
  program with the cone written in the pred. ORACLE: cone form `impure value arm`, twin
  **exit 0**. SUBJECT: both exit 0, **same md5 `6bde9f5a…` of the lowered function body**.
  So the increment reproduces, byte for byte, a stream the ORACLE already emitted for the
  pre-hoisted spelling, on a shape with a second region behind it. Stage 2b clean. This is
  the strongest single witness I have, and it is stronger than the shipped fixture pair
  because one half of it is measured on the *old* compiler.
- **C-level twin identity on a second shape.** `c/twolink.c` (a two-link chain with two cone
  members) vs `c/twolink_pre.c`: stage-1 IR genuinely differs (so the twin is not vacuous —
  I checked, because `-O1` sinks pred-computed classicals and can make such a pair identical),
  both accept on the SUBJECT, both decline on the ORACLE, and the **17-line traces are
  byte-identical**. Stage 2b clean on both.
- `tools/show_pipeline.sh`'s new decline banner captures `rc` on the line after the command
  (not inside `if ! cmd`) — correct, and it is not a gate.
- `IMPL_INC1.md` §1's "the change, in four places" table omits `ir-pass/src/ControlDetect.cpp`
  (the `CQ_CTRL_BT` lever). `MEASUREMENT.md` §5 calls that lever "the session's **temporary**"
  one; it is in the diff as shipped and is now permanent. Fold into F-3's doc bucket.

---

## WHAT I DID NOT DO

This section is load-bearing; read it as the boundary of the clearance.

1. **I ran no suite.** No `ctest` (full or filtered), no `lit`, no `ir-pass-lit`, no
   `cq-opt-equivalence-full`, no twin matrices, no e2e slice via `ctest`. Instructed not to;
   gates were in flight. **No `FileCheck` line was executed by lit in this round** — I invoked
   `FileCheck` directly ~35 times against the fixtures' prefixes, which is not the same thing
   (lit supplies `--implicit-check-not` and other RUN-line flags I did not reproduce; the
   PROTOCOL's S3 note records a harness that measured itself this way).
2. **I rebuilt nothing**, so every behavioural claim is about the two pinned binaries and
   nothing else. See **F-4**: the source on disk moved under me mid-review. I read the
   *pointer* form of `valueArmIsPureChain` from `git diff` at the start and the *reference*
   form from the file later. I compared the two and satisfied myself the delta is
   behaviour-neutral for the single call site (the `!Cone` branch was unreachable; the new
   `Reject()` clears a fresh per-arm local that is never read on a false return) — but I did
   **not** measure the newer source, and nobody should read my measurements as covering it.
3. **I swept 872 of 2117 fixtures**, not all of them: all 622 matching
   `value|swap|classical_call|select|switch`, plus a deterministic 1-in-6 sample (`NR%6==1`)
   of the remaining 1495. **623 fixtures of that remainder were never run.** I did not verify
   the brief's "2117 fixtures, null control 0, positive control 1" claim, and no corpus result
   file exists in the record to cite instead (F-5).
4. **No simulation, no statevector, no backend** (Rule 2). Every unitary claim here is
   analytic or rests on gate-stream/trace identity against a form the compiler already lowered.
5. **I did not attack cross-function or multi-TU shapes** (bd `1yeu`'s structural instrument
   gap). Every probe is one function per module. A cone whose member is used across a
   `llvm-link` boundary is untested by me and by every gate in the tree.
6. **I did not attack `-O2` / `-O3`** stage-1 pipelines, nor `-O0`.
7. **I did not attack the cone against Phase 6 specialization (`SpecializeDetect`), `AbortPark`
   (7.2), `IOSink` (7.6), the 7.5 guarded store, or QRAM/rail-bank lowering** beyond the two
   taint-escape probes and one `!cq.railbank` source read. In particular I did **not** try a
   cone member that is a Phase-6 spec candidate's argument.
8. **I ran exactly one in-loop probe** (`probes/L1_inloop_cone.ll`, a flat in-loop value arm).
   I did not try a rolled cone under a loop-carried handle (bd `zujr`), a banked loop, a nested
   loop, or a `break` region — all of which `IMPL_INC1.md` §3 says are out of scope, but "out
   of scope" is a claim about intent, not a measurement.
9. **I did not reproduce F-8** (address recycling causing a false decline). It is reasoned
   from the code, filed as P3 in the safe direction, and I did not build a module that frees a
   cone member.
10. **I did not check the labreport entry** `docs/labreport/sessions/015-…tex` (it appeared
    while I was working) or any bd state, and I made no bd writes.
11. **I did not audit `tests/e2e/CMakeLists.txt`'s three post-union checks** (duplicate
    `add_test` names, count reconciliation, sweep-still-last) beyond reading the diff hunk.
12. **I did not run a duplicate-body fixture scan** (L8's sha-256-over-non-comment-lines check)
    — no fixture was renamed by this increment, but a merge could still resurrect one.
13. **F-1 and F-2 are IR-level.** I established that F-1 is not reachable through
    `clang -O1` + CQ.h by measuring what clang emits for `__attribute__((const))`; I did
    **not** exhaustively enumerate every clang attribute, pragma or IR-producing path, so
    "unreachable from C" is a measured negative on the one route I checked, not a proof.
