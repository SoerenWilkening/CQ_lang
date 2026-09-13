# IMPL — Track M: the REGION-MERGE-φ rail leaf for the 4.4 DATA SELECT (bd `boi6` D-B, probe `p20`, spelling (a))

Session 2026-09-13. Worktree `/Users/sorenwilkening/Desktop/CQ_mphi`, branch `mphi-rail-leaf` (from `main`
`8659a77`). `BRIEF_M.md` / `SCOPE_M.md` beside this file; gates in `GATES.md`; probe artifacts in
`probes/impl/`. **Nothing committed, nothing pushed.** Report discipline (Rule 19 / `PROTOCOL.md` §3.3):
every claim is `ran:` (this agent executed it) or `cited:` (a `GATES.md` line whose hash matches the binary
on disk). Two binaries carry this work and the distinction is kept everywhere below:
**`2fd12991d3e91d10`** (the widening) → **`ae216b3727f5b1ec`** (after the orchestrator's 2026-09-13 ruling).

> ## THE HEADLINE
>
> **The owner's file compiles: 29 trace lines, 29 of 29 byte-identical to the T1 prediction** read off the
> frozen ORACLE *before any code was written*, STRICT stage 2b `8 rail mint(s) of which 6 left allocated, 2
> cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`. It is a registered e2e slice
> (`tests/e2e/slice_control_cascade_two_bools.c`) with two gates behind it that say the widening added an
> **ACCEPT, not a STREAM** — and both of those gates have been attacked with mutants before being trusted.
>
> H-6 was raised as a STOP, ruled **ADMIT**, and the measurement behind the ruling is in §7.

---

## 0. Measured BEFORE coding — the probes on the UNMODIFIED build

`ran:` the `SCOPE_M.md` §0.1 probe set plus the five session probes through the `PROTOCOL.md` pipeline.

**My unmodified build was BYTE-IDENTICAL to the ORACLE** — `cq-opt`
`fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661`, `libCQPass.so`
`40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93`, the two `PROTOCOL.md` hashes exactly.
That alone licenses citing the scoping row; the re-run was still worth 30 s, because the hash covers the pass
binary and not the stage-1 `clang`, the runtime archives or `free_pairing_check.py` — three of the five
pipeline stages. **All 27 rows plus the 5 session probes reproduce `probes/README.md` exactly**
(`probes/impl/verdicts_oracle_fbbe0820.txt`).

One row there is not a probe: `owner.main.O1` is an IR *excerpt*, not a standalone module (a stage-1 parse
error on both binaries).

---

## 1. The grammar and the classifier

### 1.1 `ir-pass/include/SelectClassify.h`

| what | where |
|---|---|
| `CondTree::RailPhiLeaves` — a NEW `SmallVector<PHINode *, 2>` | `:116` |
| the `RailLeaves` obligation note (`:79`), RE-ARMED for the new field | `:97-115` |
| `isCondRailPhiShape` — the syntactic half, exported | `:150` |
| `collectCondTree`'s new `bool AllowRailPhi = false` | `:218` |

**H-3 honoured as scoped: `isCondRailLeaf` is NOT widened and `RailLeaves` is NOT retyped.** Its element type
(`CallInst *`) is the enforcement — retyping to `Instruction *` would hand a φ, with no code change and no
review, to the depth-2 nest, the Rz-stem angle select, the kickback, `Specialization` and `SwapRouteEmit`.

### 1.2 `ir-pass/src/SelectClassify.cpp`

| # | what | where |
|---|---|---|
| 1 | `isCondRailPhiShape` — `PHINode`, `i1`, exactly 2 incomings | `:616` |
| 2 | the grammar's φ-leaf arm, **ROOT ONLY** (`V == Root`) | `:642-651` |
| 3 | `collectCondTree`'s return: `\|\| !Tree.RailPhiLeaves.empty()` | `:819` |
| 4 | `preppedRailPhiRegion` — **rung 0, the whole proof** | `:483-560` (anon namespace) |
| 5 | gate 2's call: `AllowRailPhi=true`, the ONE caller | `:868` |
| 6 | the merge-φ ladder: rung 0 / (i) / (ii) over `condProvenance(P)` | `:975-986` |
| 7 | gate 2c: `condProvenance(P)` into **`RailProv`** (rung (iii)) | `:1094-1107` |
| 8 | `R.RailLadderProven \|= !Tree.RailPhiLeaves.empty()` | `:1270` |

**Rung 0, final form** — nothing re-derived, the one owner CALLED (Rule 14; the drbq Inc-3 (b′) defect was a
second spelling of a predicate the tree already owned):

```cpp
for (const ControlRegion &R : plan.Regions) {
  if (R.Kind != ControlRegion::BranchRegion || R.Merge != P) continue;
  const bool TrueArm  = R.ClassArm      == ArmClass::InPlaceRotation && !R.Shadow.empty();
  const bool FalseArm = R.ClassArmFalse == ArmClass::InPlaceRotation && !R.ShadowFalse.empty();
  if (TrueArm || FalseArm) return &R;
}
return nullptr;
```

One deliberate departure from `SCOPE_M.md` §2.1, narrowing: **the class is PAIRED with its own content list
by FIELD identity** (`ClassArm`↔`Shadow`, `ClassArmFalse`↔`ShadowFalse`) rather than
`(ClassArm==IPR || ClassArmFalse==IPR) && !Shadow.empty()`. `ControlPlan.h`'s own convention is that the
pairing is by field and NOT by edge truth (`ArmNegated` carries the Rule-9 polarity), so the scoped form
would have admitted a region whose verdict sits on one arm and whose content list sits on the other.

### 1.3 What is NOT a conjunct: `RailLadderProven` (ruling item 2) — see §2.4

### 1.4 ROOT-ONLY φ admission, and a `SCOPE_M.md` correction

`SCOPE_M.md` §4 requires `m31` (`if (b1 && q > 3) a -= 3;` → `and i1 %phi, %cmp`) to keep declining, with the
fence given as "rung 0 asked per φ leaf; over-decline is safe". **That fence does not hold**: `m31`'s diamond
IS claimable as a state prep, so rung 0 would PASS and the compound tree would reach `CondTreeEmit`'s
NON-root rail path, where the φ (RAUW'd to a `cq_theta_i1` call by M-β) would be a read-only control of a
node `cqrt_toffoli`. That may well be sound — it is the shipped r9e5 non-root-rail treatment — but it has no
probe family, no fixture and no adversarial round.

So the grammar admits a φ leaf **only as the tree's ROOT**. `m31` dies in `collectCondTree` and keeps its
exact string. Orchestrator ruling: ROOT-ONLY stays (over-decline is safe). Pinned by
`control_swap_reject_select_mergephi_tree_leaf.ll` with a retirement trigger telling the widening increment
to FLIP that file rather than delete it.

### 1.5 `ArmClassify.cpp` — **0 lines, H-8 answered ONCE: change nothing**

`:3160`'s `RailCond` ternary and `:3325`'s `kBareRailCondReason` are untouched, so a φ at a `br` keeps
`control flow` (`m27`), a φ at the kickback keeps `branch phase on a bare i1 condition` (`m08`), a φ in a
loop keeps the loop layer's string (`m30`) — all three measured unchanged (§6). `kBareRailCondReason` is the
1b discriminator; re-pointing it at a φ would move three shipped fixtures' strings without moving a
disposition. The decision is written into the `CondTree` header so nobody re-litigates it.

---

## 2. The emitter, the two other sites, and the conjunct that came out

### 2.1 H-1: `SelectMergeEmit` was reading a raw `Value *` the prep's flatten had already freed

`ControlRegion::Condition` is a plain `llvm::Value *` (`ControlPlan.h:115`), filled at DETECTION with
`Sel->getCondition()`. The prep region emits FIRST (a `SelectRegion` sets no block fields, so it acquires no
Kahn edge; plan index is push order is block order, because `detectControlRegions` handles each block's
TERMINATOR before that block's `select`s). `emitInPlaceRotationRegion` ends in
`MergePhi->replaceAllUsesWith(Gates.back().first); scrubTaint(...); MergePhi->eraseFromParent();
flattenRegion(R, taint);` — **the φ this region recorded is destroyed before the select emitter runs.**

**Fix** (`SelectMergeEmit.cpp:150` and `:271`): one local,
`Value *Cond = Sel ? Sel->getCondition() : nullptr;`, used at both the `collectCondTree` re-derivation and
the `emitCondNetwork` call. `R.Condition` is never dereferenced there again. NOT a `WeakTrackingVH` on the
field — that would silently follow M-β's RAUW and hide the ordering premise instead of checking it.

**The backstop is the grammar's default, not a new check.** That call site does not pass `AllowRailPhi`, so a
re-read that is still a φ makes `collectCondTree` return false and the pre-existing LOUD `control flow`
decline fires before anything is emitted (detect-before-mutate, Rule 1).

**How I convinced myself the raw pointer is gone — MEASURED BY COUNTERFACTUAL.** Release has no ASan, so I
built one: that single line reverted to `Value *Cond = R.Condition;`, nothing else changed, binary
`4a8d52d4defc583d`. The owner's file and both polarity twins went ACCEPT → `control flow`, exit 1,
deterministically over three repeat runs — `collectCondTree` walked the ERASED φ's memory and the walk
failed. **Two things follow and only one is comfortable.** (a) The DIRECTION is benign: it silently LOSES a
proven accept rather than emitting a wrong stream, which is exactly why no golden and no `opt -verify` could
have caught it. (b) It is still a read of freed memory — the observable is whatever the freed bytes decode to
under this allocator on this run, so "the old code was safe" is **not** a reading this measurement supports.
The fix turns an undefined read into a defined one. The counterfactual was reverted and the restored build
hashed back bit-for-bit.

### 2.2 `CondTreeEmit.cpp` — **0 lines, as scoped, and VERIFIED not assumed**

`BRIEF_M.md` §2.5 asked me to verify that `markRailCondRead` (`:248`) and `RootIsRail` (`:226`) never see the
φ. They do not, and **the emitted stream is the witness**: the owner's file emits `cqrt_alloc_i1(0) -> h7;
cqrt_cnot(h1, h7)` — the `CopyRailRoot` ancilla. That path is gated on `isCondRailLeaf(Root)`, false for a
`PHINode`, so those two lines can only appear if the re-read root IS the hoisted `cq_theta_i1` call. The
record at `:248` is therefore made with the theta, exactly as for any r9e5 rail select.

### 2.3 The other two sites

* **H-7, `RegionFlatten.cpp:108` / `:205` / `:210`** — `isCondRailPhiShape` added beside `isCondRailLeaf` at
  all three "never erase a user's rail" guards. **NO SUBJECT TODAY, stated as a measured fact**: the only
  φ-conditioned construct Track M admits is a 4.4 DATA select, which sets no `Pred`/`MergeBB` and never
  reaches this stage; the φ's erasure belongs to the PREP region's own emitter. Added so the first widening
  giving a φ-conditioned region a flatten of its own cannot re-open the L9 block-lifetime hole in silence.
* **`Specialization.cpp:304`** — a φ-carrying tree is SKIPPED. Belt to a brace (that call site does not pass
  `AllowRailPhi`), written anyway because the `CondTree` header's obligation is that every consumer DECIDE
  explicitly, and a decision implicit in a defaulted argument is the "absence of a decision that hardened by
  repetition" that bit this project at the missing `xor i1` node (bd 3c6m.67).

### 2.4 Ruling item 2 — `RailLadderProven` came OUT of rung 0, and the measurement is why

`ran:` the orchestrator's named customer, `probes/impl/i2_cmpladder.c`:

```c
int b0 = cq_theta(0, 0.5); bool b1 = 0;
if (b0 == 1) b1 = cq_theta(b1, 0.5);
if (b1) a -= 3;
```

Single-φ merge, so `MergePhiPeel` never runs and F2 (bd `rb9x`) is never reached. Measured on `fbbe0820`
(ORACLE) and on `2fd12991`: **BOTH `control flow`, with exactly ONE diagnostic, at the select** — i.e. the
region WAS claimed and the select's rung 0 was reached. **It was refused by the `RailLadderProven` conjunct
alone.**

The flag answers *"did the RAIL ladder run for this region?"*, which is not the question the select needs
answered. The select needs *"will this φ become ONE physical register?"*, and that is exactly what the
`InPlaceRotation` class verdict means — its emitter hoists the arm's theta and RAUWs the φ to it (M-β). A
compare-guarded region reached the SAME committed verdict through `condWireDisposition`'s ladder. Requiring
the RAIL spelling of the proof was a claim about **how** the region was proved, not about **what** was
proved, and an over-decline of a valid circuit is a defect rather than a margin (owner ruling 2026-09-11).

**After the change** (`ae216b3727f5b1ec`): `i2_cmpladder` **ACCEPTS, 21 lines**, STRICT 2b clean, with the
compare flag minted, the prep fired as `cqrt_ry_i1_controlled` on a fresh rail, the flag stripped by its
`_unc` and freed at a proven `|0⟩`, and only then the select's rail-root merge reading the prepped register
as a control. Accept fixture `control_swap_accept_select_mergephi_cmp_cond_region.ll` (which was a DECLINE
fixture for one afternoon — its header carries that history, because the mistake is the lesson).

**The class conjunct still fires.** `probes/impl/i2_otherclass.ll` is a region genuinely CLAIMED under a
compare whose arm is a VALUE chain: it declines `control flow` on BOTH binaries. Fixture
`control_swap_reject_select_mergephi_other_class.ll`.

**One further customer arrived with it, and it is the best one in the set.** `m16` — the owner's cascade with
`volatile int av = 5; int a = av;`, so **nothing constant-folds** — moved DECLINE → **ACCEPT, 31 lines**. It
is the whole chain in one module: the `b0` rail, `if (b0 == 1) a -= 3` as a merge producing a QUANTUM `a`,
`if (a >= 3)` as a genuine compare ON that quantum `a` whose flag controls the `b1` prep, and finally line
99's select on the prep's merge φ. Three `cqrt_free`, all proven-`|0⟩`; both user registers read only as
controls. Fixture `control_swap_accept_select_mergephi_runtime_amux.ll`.

---

## 3. The three rungs, and H-2 / H-4

### 3.1 Rung (ii) over `condProvenance(P)` — H-2, the load-bearing line

Asked per member of `condProvenance(P) = {φ, T}`, not over `R.Shadow.front()`. The hazard is measured: `-O1`
gives the user's `cq_measure(b1)` the **φ** as its argument, while `railWireNamesBackward` `break`s at the
first non-call — so a closure seeded from the hoisted theta alone is the singleton `{T}` and the measurement
is **invisible**. The lowering would mint the select's `cqrt_cnot` control read off a register the user had
already collapsed. `condProvenance(P)` is also exactly the seed set rung (iii) walks: one closure, two rungs
(the 8h7d.5 F-1/F-3 lesson, L2). `railMeasuredBeforeReadPoint` takes a `const Value *` and is already total
over an arbitrary tainted name, so asking it per closure member is the ONE spelling, not a second one.

**RED-GREEN, `ran:`** — `m05` is the program: ORACLE `control flow` → subject `condition measured before the
control route`. Pinned by `control_swap_reject_select_mergephi_measure_before.ll` (`clang -O1 -g` output
verbatim, so the fused two-phi diamond and the measure's placement are `-O1`'s), verified RED on the ORACLE
by running the ORACLE binary against the committed fixture and its own `CHECK` line.

### 3.2 Rung (iii) — gate 2c, and the line whose ABSENCE would have been the over-accept

`SCOPE_M.md` site 6 says gate 2c is "ALREADY RIGHT for a φ". True of `condProvenance` as a HELPER, **false of
the gate as CALLED**: the seed loops iterate `Tree.Leaves` and `Tree.RailLeaves`, so a φ leaf contributes to
neither and gate 2c would never have looked at the prepped register's wire at all. One loop added (`:1106`),
seeding `RailProv` — the set that gets the DT prong a rail owes.

### 3.3 H-4 — the round-2 window

`markRailCondRead` is LIVE and required. Under spelling (a) the record is written with the already-RAUW'd
theta, not the φ (§2.2's stream is the witness), so `reverifyRailCondReads`' `dyn_cast_or_null<CallInst>` at
`ArmClassify.cpp:2504` succeeds and rungs (ii)/(iii) ARE re-asked — which makes `TaintPropagation.h`'s
`WeakTrackingVH` retirement trigger *moot rather than relied upon* for the flat case, a stronger position
than the scope predicted. `!cq.branchphase`, `taint.CmpCondReads` and `adjudicateTaintDelta` have **no
subject**: nothing diagonal is emitted on the user's register, no compare flag is minted by the rail path
(the rail IS the flag), and the widening manufactures no new tainted value. Round 2 itself is a no-op for
these programs (`TaintPropagation.cpp:1653` returns unless `UntaintedMergeRails` is non-empty, which only the
6.5 classical-call arm and the 4.5 switch data-mux populate).

---

## 4. Red-green log and the fixture set

### 4a. Step 1 — the ORACLE accepts pinned FIRST, before any pass edit

`ran:` written and GREEN on the unmodified build (= the ORACLE binary) before a line of pass source changed,
and re-verified GREEN on both later binaries:

| fixture | probe | what it is |
|---|---|---|
| `control_swap_accept_select_rail_after_prep.ll` | `m19` | the un-negated prep; M-β target = the single hoisted theta |
| `control_swap_accept_select_rail_after_prep_negated.ll` | `m18` | the OWNER's shape; M-β target = the chained cancelling clone |

Naming maps to SEMANTICS, not to the brief's listing order (`m18` IS the negated prep). These are the
discriminator that the widening adds an ACCEPT and not a STREAM: they are the same module one pipeline stage
later, which the frozen ORACLE already accepts with the target stream.

### 4b. The eight ACCEPT fixtures

Every one RED on the ORACLE (`control flow` at the select) except the two T1 pins, which are green on both.
Each carries the whole emitted stream, `ORD`-equivalent adjacency (`CHECK-NEXT` wherever the stream is
contiguous), and the pure-negative + count prefixes the brief specified:
`NOX-NOT: cqrt_x(i32 %h…)` on **both** user registers, `NOFREE-NOT` on both plus `%out`/`%h_op`,
`NOROUTE-NOT` on `cqrt_cswap`/`cqrt_rz`/`cqrt_toffoli`/`cq_phi`/`{{= phi }}`, and
`XCNT`/`FCNT`/`CNOTCNT`/`CPCNT`/`RYCNT`/`ACNT` counts **derived from the pass output**.

| fixture | shape | lines |
|---|---|---|
| `..._mergephi_rail_negated.ll` | **the owner's file** as `clang -O1 -g` hands it over | 29 |
| `..._mergephi_rail_prep_true_edge.ll` | the other polarity (prep on the TRUE edge, one `cqrt_ry_`) | 28 |
| `..._mergephi_rail_sdagger.ll` | the H-6 ADMIT: a second rotation of the register AFTER the select | 30 |
| `..._mergephi_cmp_cond_region.ll` | ruling item 2: the prep guarded by a COMPARE | 21 |
| `..._mergephi_runtime_amux.ll` | run-time `a` — the fully general cascade, nothing folds | 31 |
| `..._mergephi_two_selects.ll` | two independent selects reading one prep φ | 41 |
| `..._rail_after_prep{,_negated}.ll` | the T1 pins (green on BOTH binaries) | 28 / 29 |

⚠ **One trap worth recording because it cost a red and is invisible on inspection:** a literal `CHECK:` written
inside a fixture's prose comment **IS a FileCheck directive**. It happened once here (a header sentence
explaining why that file uses ordered rather than adjacent pins) and reddened the fixture. A scan of every new
fixture for directive-looking text before the first RUN line now reports 0 hits.

### 4c. The eight DECLINE fixtures

Rule 12(b) honoured throughout: the `not` on the RUN line plus the character-for-character string is the pin;
no vacuous IR-text `CHECK-NOT`s.

| fixture | ORACLE | SUBJECT | fence that owns it |
|---|---|---|---|
| `..._mergephi_two_rails.ll` (`m29`) | `control flow` | same | rung 0: no region's `Merge` is that φ |
| `..._mergephi_unclaimed.ll` (`m20`/boi6 `p5`) | `control flow` | same | rung 0: classically guarded ⇒ no region |
| `..._mergephi_tree_leaf.ll` (`m31`) | `control flow` | same | the grammar: ROOT-ONLY (§1.4) |
| `..._mergephi_three_incoming.ll` | `control flow` | same | the grammar: exactly 2 incomings |
| `..._mergephi_other_class.ll` | `control flow` | same | rung 0's CLASS conjunct, isolated (§2.4) |
| `..._mergephi_value_region.ll` | `bare i1 register condition` | same | ⚠ an EARLIER fence — see below |
| `..._mergephi_measure_before.ll` (`m05`) | `control flow` | **`condition measured before the control route`** | rung (ii) — the one red-green flip |

**`value_region` needs its label read carefully and its header says so.** MEASURED, the string is
`bare i1 register condition`, NOT `control flow`: an earlier fence owns that module (`classifyArms` refuses a
VALUE arm under a bare rail condition, bd `fg9k`), so the region never enters the plan and rung 0's class
conjunct is never reached. It is pinned as a DISCRIMINATOR (neither disposition nor string moved), **not** as
a proof that the class conjunct fires — `other_class.ll` is that proof. Retirement trigger written in.

`m30` (in-loop) has no fixture: it is owned by the loop layer BEFORE detection, unchanged on both binaries,
and a hand-IR fixture would pin a different layer's string.

### 4d. Injection (mutation) matrix — **56 applied, 0 MISSED, 0 N/A**

`ran:` 8 accept fixtures × 7 mutations (`probes/impl/inject.py`, artifact
`probes/impl/injection_matrix_ae216b37.txt`). The mutations: an injected `cqrt_x` **on a user register**; an
extra `cqrt_free` on the prep rail; an extra uncontrolled `cqrt_ry` on the rail; an injected `cqrt_cswap`; a
rail handle promoted into a classical immediate slot; the CNOT copy pair **unbalanced**; the two
`copy_<W>_controlled` **swapped** (identical symbol multiset, inverted answer — invisible to a count-only
check).

**The first pass read 43 applied / 1 MISSED / 13 N/A, and BOTH numbers were defects in MY harness and MY
prefixes, exactly as the brief budgeted.** The MISSED was a missing `RYCNT` prefix on the generated accepts
(the adjacency of `CHECK-NEXT` had been carrying it, so the one fixture that legitimately uses ordered pins
had no count to catch an injected rotation). The 13 N/A were the MUTATORS failing to match lowered IR that
carries `, !dbg !N`, plus a rail-in-immediate mutator that only knew one shape. Both fixed; second pass is
**56 / 0 / 0**. Re-reading the prefixes would have reported neither.

---

## 5. e2e — four slices, two gates, and the gates were attacked

`ran:` each with `ctest -R '^e2e-slice-<name>$'`; all STRICT stage 2b (`0 violation(s), 0 unproven`).

| ctest entry | source | lines |
|---|---|---|
| `e2e-slice-control-cascade-two-bools` | **the owner's file**, live code lines verbatim | **29** |
| `e2e-slice-control-cascade-two-bools-base` | the same minus line 99 (= `va`) | 19 |
| `e2e-slice-control-cascade-two-bools-uncond` | the prep made unconditional (= `m17`) | 28 |
| `e2e-slice-control-cascade-two-bools-int` | the `int b1` workaround the owner refused (= `m11`) | 28 |

**The 29-line golden equals the T1 prediction 29/29**, diffed line by line against `va.trace` 1–16 +
`m18.trace` 17–26 renumbered + three measures.

```
 1 cqrt_alloc_i1(0) -> h0                    b0's rail
 2 cqrt_ry_i1(h0, 0x1p-1)
 3 cqrt_alloc_i1(0) -> h1                    b1's rail, prepped to the seed 0
 4 cqrt_ry_i1(h1, 0x1p-1)                    the arm's Ry, fired UNCONDITIONALLY
 5 cqrt_ry_i1_controlled(h0, h1, -0x1p-1)    cancelled when b0=1 ⇒ exactly `if (b0==0)`
 6 cqrt_alloc_i1(0) -> h2                    ── the peeled a-mux, `if (b0==1) a -= 3` ──
 7 cqrt_cnot(h0, h2)                         the rail-root CNOT copy
 8 cqrt_alloc_i32(0) -> h3                   the fresh |0> out rail
 9 cqrt_alloc_i32(2) -> h4
10 cqrt_copy_i32_controlled(h2, h4, h3)      out = 2 iff b0 = 1
11 cqrt_x(h2)                                the ¬flag bracket — ON THE ANCILLA
12 cqrt_alloc_i32(5) -> h5
13 cqrt_copy_i32_controlled(h2, h5, h3)      out = 5 iff b0 = 0
14 cqrt_x(h2)
15 cqrt_cnot(h0, h2)                         h2 back to x⊕x = 0 on EVERY branch
16 cqrt_free(h2)                             ⇒ a proven-|0> free (Rule 6)
17 cq_template_add_i32_hl(h3, -3) -> h6      ── line 99 ── the arm chain, HOISTED
18 cqrt_alloc_i1(0) -> h7
19 cqrt_cnot(h1, h7)                         THE NEW THING: the PREPPED register as a control
20 cqrt_alloc_i32(0) -> h8
21 cqrt_copy_i32_controlled(h7, h6, h8)      out = a-3 iff b1 = 1
22 cqrt_x(h7)
23 cqrt_copy_i32_controlled(h7, h3, h8)      out = a   iff b1 = 0
24 cqrt_x(h7)
25 cqrt_cnot(h1, h7)
26 cqrt_free(h7)
27 cqrt_measure_i1(h0) -> 0
28 cqrt_measure_i1(h1) -> 0
29 cqrt_measure_i32(h8) -> 0
```

**Three invariants, read off the trace rather than asserted.** `h0` and `h1` are the user's registers and each
appears ONLY at arg 0 of a `cqrt_cnot` or as the CONTROL of `cqrt_ry_i1_controlled`. All four `cqrt_x` are on
the ancillas `h2`/`h7`, whose `x ⊕ x = 0` return makes their two `cqrt_free` proven-`|0⟩` ones. The hoisted
chain rail `h6` is left allocated and not `_unc`'d — the Rule-6 "value arm's chain-final rail" case.

### The two gates, and their mutant validation

* **`e2e-cascade-two-bools-base-prefix-identical`** — the flagship's golden must START with the base's 16
  lines byte for byte. A plain `compare_files` cannot express it (the base's tail is its own measurements),
  so `tests/e2e/compare_prefix.cmake` compares the prefix and fails loudly on a short input.
* **`e2e-cascade-two-bools-twin-identical`** — THE twin gate. `..._uncond` is the SAME select lowered from a
  condition that is already a `cq_theta_i1` CALL, **a shape the frozen ORACLE accepts with no Track M change
  at all**. `tests/e2e/compare_twin_half.cmake` compares flagship[17..26] against uncond[16..25] after a
  whole-token rename of the two rails (the flagship's extra cancelling prep gate shifts the numbering).
  **MEASURED IDENTICAL.**

⚠ **A checker nobody has tried to fool is a checker nobody should trust (L10), so I tried.** Five mutations,
five correct verdicts, and the two gates are **complementary**: perturbing a shared-prefix line reddens only
the prefix gate; swapping the two `copy_i32_controlled` in the select half reddens only the twin gate; a
truncated golden, an `h1`→`h10` rename-aliasing attempt, and a dropped line all redden loudly.
⚠ **And my first validation harness was itself broken** — `grep -c "tests failed"` matches ctest's *success*
line too, so every mutation looked caught. Re-run on exit codes. That is the same defect class the gates
exist to catch, one level up.

---

## 6. Corpus sweep, ORACLE vs SUBJECT

`ran:` once at hand-off on `ae216b3727f5b1ec` vs `fbbe0820ef4b176a`, over `ir-pass/test/*.ll` plus every
session probe directory named in `PROTOCOL.md`. A row is `rel | ORACLE | SUBJECT`, a verdict is
`A:<md5 of the lowered IR>` or `D:<diagnostic>`. Artifact: `probes/impl/corpus_ae216b3727f5b1ec.txt`; the
earlier sweep on `2fd12991d3e91d10` is kept beside it.

**2696 rows. 2672 unchanged. 0 ACCEPT→DECLINE. 0 both-accept lowered-IR changes.**

| movement | count | detail |
|---|---|---|
| unchanged | 2672 | every `A:` row bit-identical on both binaries |
| **DECLINE → ACCEPT** | **21** | of which **6 are the new accept FIXTURES themselves** (files that did not exist on the ORACLE side of the comparison, so they are not movers); **15 distinct programs** actually moved, every one from `D:cq controlled lowering: control flow` at a `select` |
| decline-STRING move | 3 | `m05.c` + its fixture → `condition measured before the control route` (rung (ii)); **`session-boi6/probes/p20.c` → `condition predates a non-diagonal gate`** (rung (iii)) |
| **ACCEPT → DECLINE** | **0** | |
| **both accept, lowered IR differs** | **0** | the strongest available statement of "an ACCEPT, not a STREAM" |

The fifteen real movers:

```
session-2026-09-13-orchestrator/probes/owner_file_2026-09-13.c   THE OWNER'S FILE      29 lines
session-2026-09-13-orchestrator/probes/vb.c, vc.c                = m01 byte-identically 29
session-2026-09-11-orchestrator/review_integration_probes/U1_owner_regfree_phi.c        29
trackM/probes/m01.c   the owner's line 99                                               29
trackM/probes/m02.c   if (!b1)                                                          29
trackM/probes/m04.c   a = 7                                                             29
trackM/probes/m06.c   b1 read as DATA too                                               35
trackM/probes/m10.c   prep on the true edge                                             28
trackM/probes/m13.c   cq_invert                          accept-then-LINKFAIL, §7.5
trackM/probes/m15.c   the S† second rotation             §7.1 — ruled ADMIT             30
trackM/probes/m16.c   run-time `a`, nothing folds        ruling item 2's own customer   31
trackM/probes/impl/i2_cmpladder.c      the compare-guarded prep (ruling item 2)         21
trackM/probes/impl/a_two_selects.c     two selects on one prep φ                        41
trackM/probes/impl/p3d8q_sibling.c     the 3d8q sibling shape             §7.2          31
```

**`U1_owner_regfree_phi.c` is worth naming separately**: it is the owner's OTHER spelling of line 99 —
`if (b1 == 0) a -= 3;`, the form commented out at the owner file's line 107 — and it accepts at 29 lines with
the two `cqrt_copy_i32_controlled` **order-swapped** relative to the owner's file, which is exactly the right
discrimination for the inverted polarity (`out = b1 ? a : a−3`).

**`p20` is the best row in the table and it is not an accept.** It is the probe bd `boi6` D-B is named after,
and it moves from `control flow` (the leaf grammar refusing to look) to `condition predates a non-diagonal
gate` (the WIRE fence, having looked and found the wire genuinely dirty — its arm theta is CHAINED on the
seed, an in-place Ry on the condition's own register). That is the "DECLINE → a LATER fence" category, and it
is the direct measurement of `SCOPE_boi6.md` §0.3's correction: the wire fence IS `p20`'s second blocker and
is NOT the owner's file's, and now one binary demonstrates both halves. Pinned by
`control_swap_reject_select_mergephi_chained_arm.ll` (RED on the ORACLE for the wrong reason, GREEN here for
the right one), which was added AFTER the sweep — its two verdicts were measured directly on both binaries.

⚠ **Read the "0 both-accept IR changes" row with its caveat.** It is a strong negative and it is not a proof
of the fifteen new accepts — by construction those rows have no ORACLE stream to compare against. What it
proves is that the widening is INERT for the 2672 modules that already lowered. The new accepts are evidenced
by §5 (the owner file, 29/29 against a prediction written before the code; the twin and prefix gates) and by
§4a (the T1 pins, green on BOTH binaries).

---

## 7. Open questions, found-in-passing, and the H-6 record

### 7.1 H-6 — raised as a STOP, ruled ADMIT, and the measurement that decided it

`m15` (the owner's file plus `b1 = cq_theta(b1, 0.25);` after the select) **ACCEPTS**, 30 lines, STRICT 2b
clean. Its trace is the owner's 29-line stream with **exactly one gate inserted**, at line 27 — between the
select's `cqrt_free(h7)` and the measures:

```
26 cqrt_free(h7)
27 cqrt_ry_i1(h1, 0x1p-2)      <- the second rotation, IN PLACE on the SAME rail h1
28 cqrt_measure_i1(h0) -> 0
29 cqrt_measure_i1(h1) -> 0    <- reads h1 AFTER the rotation, which is the source order
30 cqrt_measure_i32(h8) -> 0
```

**The walker's answer.** Gate 2c now seeds `RailProv` from `condProvenance(%6)` (§3.2). The position-free
prong finds the second theta and answers DIRTY; the **DT prong** — the prong a RAIL's seeds get — re-asks at
`EmitPoint = Sel`, finds the gate provably after every execution of the select, and answers CLEAN. That is
the shipped P1 argument verbatim: the copies read the register's basis label AT the select, and the ancilla,
both brackets and the copies are created, used and discharged BEFORE the rotation.

**`SCOPE_M.md`'s premise was wrong about the IR.** `m15` is not "two siblings on one rail":
`%9 = cq_theta_i1(i1 %6, double 0.25)` takes the SELECT'S OWN CONDITION as arg-0, so after M-β it is CHAINED
onto the hoisted gate. It is the S† shape. Measured on the **frozen ORACLE**: `m15u` (the identical program in
the rail-leaf spelling) **ACCEPTS at 29 lines, 2b clean**, and `s04` (the minimal shipped S† form) **ACCEPTS
at 16 lines**. Track M did not invent this accept; it made a second SPELLING reach a fence that was already
there and already answering. **Ruled ADMIT**; pinned by
`control_swap_accept_select_mergephi_rail_sdagger.ll`, whose header carries the state-vector argument and the
explicit statement of what it does *not* license.

### 7.2 bd `3d8q` — Track M ADDS CUSTOMERS, and no fence was built (ruling)

The genuine 3d8q class is TWO SIBLING READERS of the pre-rotation name: `bool c = cq_theta(b1, .25);` with
`b1` **still measured afterwards**, so two SSA names denote one register and nothing asks (the pass-wide
stale-record guard sweeps PURE ops only, so a `cq_theta`/`cq_measure` reader of a stale name is asked by
nothing). Probe `probes/impl/p3d8q_sibling.c`, with its rail-leaf control `p3d8q_sibling_rail.c`:

| probe | ORACLE `fbbe0820` | SUBJECT `ae216b37` |
|---|---|---|
| `p3d8q_sibling_rail` (rail-leaf spelling) | **ACCEPT, 30 lines, 2b clean** | ACCEPT, 30 lines |
| `p3d8q_sibling` (the merge-φ spelling) | DECLINE `control flow` | **ACCEPT, 31 lines** |

So the hole is **pre-existing** — the ORACLE already accepts it through the rail spelling — and Track M adds
a second spelling that reaches it. That is the bd `1m5p` lesson verbatim: *"pre-existing" is true of the
defect and FALSE of its population.* **No fence was built** (ruling); this belongs to bd `3d8q`.

### 7.3 Over-declines and corrections for the orchestrator to file

* **`m15i` — the compare-spelling asymmetry, an over-decline.** The same program as `m15` written with
  `int b1` **DECLINES ON THE ORACLE** with `condition predates a non-diagonal gate`, because a COMPARE's
  seeds get the position-free walk with NO DT prong while a RAIL's get the DT prong. One program, two
  spellings, two verdicts, on the frozen binary. This is `xqgx`/A.2 territory (the "S† after a compare select
  via the DT prong" widening); Track M adds customers to the rail side of it. Source
  `probes/impl/m15i.c`.
* **ROOT-ONLY (`m31`), with the corrected fence statement.** Kept declining by a deliberate scope decision,
  **not** by `SCOPE_M.md` §4's stated fence — rung 0 PASSES for `m31` (its diamond is a claimable state
  prep), so the fence is the grammar's `V == Root`, not the ladder. Over-decline is safe; retirement trigger
  in the fixture.
* **`SCOPE_M.md` corrections owed to the record** (Rule 11 — say it where the next reader looks): §4's `m31`
  fence is wrong (rung 0 passes); site 6's "gate 2c is ALREADY RIGHT for a φ" is true of the helper and false
  of the gate as called; H-6's "two siblings on one rail" misreads the `-O1` IR; and §2.1's
  `RailLadderProven` conjunct was an over-decline (§2.4).

### 7.4 The `NOROUTE-NOT: phi` fixture-hygiene bug — FIXED (7 files), and 6 more carry it latent

`ir-pass-lit` reported **7 FAILED** on my worktree. All seven carried a bare `; NOROUTE-NOT: phi`, which
matches the substring "phi" inside the **module path** `.../CQ_mphi/...` that `cq-opt` prints in its
`ModuleID` / `source_filename` preamble. A negative that can match the harness's own preamble is not a
negative about the program: the fixture passed or failed on **where the checkout happened to live**, and
reddened for anyone working in a worktree named `*phi*`.

**Fixed, minimally, in all seven** — re-anchored to `{{= phi }}` (the LLVM instruction spelling), with the
history written into each file so it is not "tidied" back. Each verified by `lit --filter` **from the
`CQ_mphi` path where it previously failed**, and the anchor re-validated against a module that DOES carry a
surviving `phi` (it reddens). Files: `control_swap_accept_post_region_theta{,_shapes,_shared_rail}.ll`,
`control_swap_accept_seq_{diamond_chain,ifelse_then_diamond}.ll`, `control_swap_accept_two_iterations.ll`,
`lowering_live_record_region_owner_probe.ll`.

⚠ **SIX MORE FIXTURES CARRY THE SAME PATTERN AND ARE CURRENTLY GREEN**, which is worth a bd of its own because
green is exactly why nobody will look: `control_mixed_value_io.ll`,
`control_phase_kickback_rail_tail_phi.ll`, `control_predmux_accept_w6_direct_condphi.ll`,
`control_predmux_accept_nested_shortcircuit_claim_order.ll`,
`control_predmux_accept_i1phi_branch_cond.ll`, `control_predmux_accept_w6_stranded_merge_condphi.ll`. Each
has its bare `-NOT: phi` in a prefix that ALSO carries positive lines, so a positive match WINDOWS the
negative past the preamble — the Rule-12(a) windowing lesson doing accidental duty as a fix. Their scope
depends on a positive's position, which is not a property anyone chose. Left untouched (they do not fail, and
they are not this track's fixtures to edit).

### 7.5 H-9 — `cq_invert`, answered by measurement

`m13` moves DECLINE → accept-at-`opt`-then-LINKFAIL (`___cq_invert_begin` / `___cq_invert_end` undefined).
**This is the pre-existing Phase-8 state, not something Track M created**: `probes/impl/h9_ctl.c` (the same
brackets in the rail-leaf spelling) does **exactly the same on the frozen ORACLE** — exit 0, STRICT 2b clean,
then LINKFAIL on the same two symbols. The pass never lowers or reverses the brackets; they survive as
undefined externs. Note it under bd `ixao`; no inversion was built.

### 7.6 What this agent did NOT run, by protocol

`ctest -R '^e2e-'` as a whole, the full `ctest -j6`, `cq-opt-equivalence`, any twin matrix, the duplicate-body
scan. ⚠ **`cq-opt-equivalence-full` is OWED at merge**: a decline string moved (`m05`) and analysis sites
changed, which is `PROTOCOL.md`'s own trigger for it.

---

## §GATES — a copy of `GATES.md`

# Track M — gate ledger (`../PROTOCOL.md` §3.1)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`.
**A gate result is a fact about a BINARY, not about a moment.** Read this file before running any
gate; if the hash is unchanged and the gate is recorded, CITE the line instead of re-running it.

A cited line whose hash does not match the binary on disk is a FINDING.

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| per-probe pipeline (stages 1,2,2b,3,4) over `probes/` — 27 probes | `fbbe0820ef4b176a` (ORACLE, `e96f89c`) | 9 ACCEPT (`m03` 23, `m07` 23, `m09` 23, `m11` 28, `m12` 31, `m17` 28, `m18` 29, `m19` 28, `m26` 25 trace lines; every one STRICT stage 2b `0 violation(s), 0 unproven`) / 18 DECLINE with the anchors in `probes/README.md` | M-scope | 2026-09-13 12:4x |

**Not run by this agent, by protocol (the "scoping" column):** any build, `lit`, any `ctest` entry,
`cq-opt-equivalence`, the corpus sweep, the injection matrix, any twin matrix. The ORACLE hash was
verified by `probes/run.sh` before each sweep and matched `PROTOCOL.md`.
| per-probe pipeline (1,2,2b,3,4) over `probes/` + the session `probes/` — 32 modules | `fbbe0820ef4b176a` (impl worktree, UNMODIFIED — byte-identical to the ORACLE) | reproduces `probes/README.md` EXACTLY: 9 ACCEPT (m03 23, m07 23, m09 23, m11 28, m12 31, m17 28, m18 29, m19 28, m26 25; all STRICT 2b `0 violation(s), 0 unproven`) / 18 DECLINE with the recorded strings; va ACCEPT 19; vb/vc = m01; vd/ve as recorded | M-impl | 2026-09-13 14:1x |
| `lit --filter control_swap_accept_select_rail_after_prep` (the T1 pins, written BEFORE any pass edit) | `fbbe0820ef4b176a` | 2/2 PASS | M-impl | 2026-09-13 14:2x |
| per-probe pipeline over `probes/` + session `probes/` | `2fd12991d3e91d10` (SUBJECT: grammar + ladder + gate-2c seed + H-1 + H-7) | 11 DECLINE→ACCEPT (m01/m02/m04/m06/m10/m13/m15 + owner file + vb/vc + U1), 1 decline-string move (m05 → `condition measured before the control route`), 0 ACCEPT→DECLINE; **owner file ACCEPT 29 lines = the T1 prediction 29/29**, STRICT 2b `8 mints / 6 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven`; va unchanged ACCEPT 19 | M-impl | 2026-09-13 14:5x |
| H-1 counterfactual (`Cond = R.Condition` restored, ONE line, nothing else) | `4a8d52d4defc583d` (throwaway, reverted) | m01/m02/m04 ACCEPT→`control flow` exit 1, deterministic over 3 repeat runs ⇒ the emitter was walking the ERASED φ | M-impl | 2026-09-13 14:4x |
| H-6 discriminator on the FROZEN ORACLE (`m15u` = m15 in the rail-leaf spelling, `m15i` = compare spelling, `s04` = the shipped S†) | `fbbe0820ef4b176a` (ORACLE) | `m15u` **ACCEPT 29, 2b clean**; `s04` **ACCEPT 16, 2b clean**; `m15i` DECLINE `condition predates a non-diagonal gate` | M-impl | 2026-09-13 15:0x |
| H-9 control on the FROZEN ORACLE (`h9_ctl` = m17 + `cq_invert` brackets) | `fbbe0820ef4b176a` (ORACLE) | ACCEPT exit 0, STRICT 2b clean, then LINKFAIL `___cq_invert_begin`/`___cq_invert_end` ⇒ m13's new disposition is the PRE-EXISTING Phase-8 state | M-impl | 2026-09-13 15:0x |
| `lit --filter mergephi` (the 7 decline fixtures) | `2fd12991d3e91d10` | 7/7 PASS; `..._measure_before.ll` separately verified RED on the ORACLE `fbbe0820` for the OLD string | M-impl | 2026-09-13 15:1x |
| `ctest -R ir-pass-lit` (ONCE, at hand-off) | `2fd12991d3e91d10` | 1894 PASS / 1 XFAIL / **7 FAILED — ALL a worktree-PATH artefact, 0 regressions**: each carries a bare `NOROUTE-NOT: phi` that matches "phi" inside the module path `.../CQ_mphi/...`. Re-run from a path with no "phi": **7/7 PASS and 7/7 lowered IR byte-identical to the ORACLE**. Effective: 1901 PASS / 1 XFAIL / 0 regressions. Filed in IMPL_M.md §7.5 | M-impl | 2026-09-13 15:2x |
| corpus sweep ORACLE-vs-SUBJECT (ONCE, at hand-off) — `ir-pass/test/*.ll` + every `PROTOCOL.md` session probe dir | `2fd12991d3e91d10` vs `fbbe0820ef4b176a` | **2681 rows: 2668 unchanged, 11 DECLINE→ACCEPT (every one `control flow` at a select), 2 decline-string moves (m05 + its fixture → `condition measured before the control route`), 0 ACCEPT→DECLINE, 0 both-accept lowered-IR changes.** Artifact `probes/impl/corpus_2fd12991d3e91d10.txt` | M-impl | 2026-09-13 15:3x |

**NOT run by this agent, by protocol (the "implementation" column):** `ctest -R '^e2e-'`, the full `ctest`,
`cq-opt-equivalence`, any twin matrix, the duplicate-body fixture scan.
**NOT run because the H-6 STOP deferred the work that would be their subject:** the injection (mutation)
matrix and the three e2e slices — the ACCEPT fixtures and slices they run over were deliberately not written
(`IMPL_M.md` §7).

### After the orchestrator's H-6 = ADMIT ruling (2026-09-13 pm) — binary `ae216b3727f5b1ec`

The rung-0 predicate dropped its `RailLadderProven` conjunct (ruling item 2), so the binary moved
`2fd12991d3e91d10` → `ae216b3727f5b1ec`. Every row below is on the NEW binary; rows above it are facts about
the OLD one and stay as the record of how it got here.

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| item-2 measurement: the compare-guarded prep customer (`i2_cmpladder.c`, single-φ merge, no peel ⇒ F2/rb9x not reached) | `fbbe0820` ORACLE / `2fd12991` subject | BOTH `control flow`; the region is CLAIMED (exactly ONE diagnostic, at the select) and was refused by the `RailLadderProven` conjunct ALONE | M-impl | 2026-09-13 16:0x |
| item-2 after the change | `ae216b3727f5b1ec` | `i2_cmpladder` **ACCEPT 21 lines**, STRICT 2b `6 mints / 5 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven`; `i2_otherclass` (a claimed VALUE-class region) still DECLINES `control flow` on BOTH binaries | M-impl | 2026-09-13 16:1x |
| bd `3d8q` sibling probe (two SIBLING readers of the pre-rotation name) | `fbbe0820` ORACLE | `p3d8q_sibling_rail` (rail-leaf spelling) **ACCEPT 30 lines, 2b clean** ⇒ the hole is PRE-EXISTING; `p3d8q_sibling` (φ spelling) DECLINE `control flow` | M-impl | 2026-09-13 16:0x |
| bd `3d8q` sibling probe | `ae216b3727f5b1ec` | `p3d8q_sibling` **ACCEPT 31 lines** ⇒ Track M ADDS CUSTOMERS to bd `3d8q`; no fence built (ruling) | M-impl | 2026-09-13 16:1x |
| whole probe set re-run | `ae216b3727f5b1ec` | identical to `2fd12991` on every probe EXCEPT `m16` (run-time `a`), which moves DECLINE → **ACCEPT 31 lines**, 2b `3 free: 3 verified, 0 violation(s), 0 unproven` — the item-2 widening's own customer | M-impl | 2026-09-13 16:1x |
| `NOROUTE-NOT: phi` hygiene fix, 7 fixtures | `ae216b3727f5b1ec` | all 7 re-anchored to `{{= phi }}`; `lit --filter` GREEN **from the `CQ_mphi` worktree path**, where they previously failed; anchor re-validated against a module that DOES carry a surviving `phi` (it reddens) | M-impl | 2026-09-13 16:2x |
| `lit --filter` per new fixture (16 new: 8 accept, 8 decline) | `ae216b3727f5b1ec` | 16/16 PASS. Header scan for directive-looking prose before the first RUN line: 0 hits (one was found and fixed — a literal `CHECK:` inside a comment IS a directive) | M-impl | 2026-09-13 16:3x |
| **injection (mutation) matrix**, 8 accept fixtures × 7 mutations | `ae216b3727f5b1ec` | **56 applied, 0 MISSED, 0 N/A.** First pass was 43 applied / 1 MISSED / 13 N/A — the MISSED was a missing `RYCNT` prefix, the 13 N/A were the MUTATORS not tolerating `, !dbg !N`; both fixed and re-run. Artifact `probes/impl/injection_matrix_ae216b37.txt` | M-impl | 2026-09-13 16:4x |
| the 4 e2e slices, each `ctest -R '^e2e-slice-<name>$'` | `ae216b3727f5b1ec` | 4/4 PASS — `cascade-two-bools` **29**, `_base` **19**, `_uncond` **28**, `_int` **28** lines, every one STRICT stage 2b `0 violation(s), 0 unproven`. The 29 lines equal the T1 prediction 29/29 | M-impl | 2026-09-13 16:5x |
| the 2 new CMake gates + their MUTANT VALIDATION | `ae216b3727f5b1ec` | `base-prefix-identical` and `twin-identical` PASS; **5 mutations, 5 correct verdicts, and the two gates are COMPLEMENTARY** (prefix-half perturbation reddens only the prefix gate; select-half copy swap reddens only the twin gate; a truncated golden, an `h1`→`h10` alias attempt and a dropped line all redden loudly) | M-impl | 2026-09-13 16:5x |
| `ctest -R ir-pass-lit` (ONCE, at hand-off; pass source changed) | `ae216b3727f5b1ec` | **PASSED, 50.77 s. 1908 discovered / 1907 PASS / 1 XFAIL / 0 FAILED** — the 7 path-artefact failures are gone (fixed, not masked) | M-impl | 2026-09-13 17:0x |
| corpus sweep ORACLE-vs-SUBJECT (ONCE, at hand-off; hash changed) | `ae216b3727f5b1ec` vs `fbbe0820ef4b176a` | see IMPL_M.md §6 — artifact `probes/impl/corpus_ae216b3727f5b1ec.txt` | M-impl | 2026-09-13 17:1x |

**Counts after Track M** (measured, not quoted): `ls ir-pass/test/*.ll` **1908** (was 1893) ·
`ls tests/e2e/*.expected.log` **359** (was 355) · `ctest -N` **409** (was 403).

**STILL not run by this agent, by protocol:** `ctest -R '^e2e-'` as a whole, the full `ctest -j6`,
`cq-opt-equivalence` (⚠ **OWED at merge**: a decline string moved and analysis sites changed — see
`PROTOCOL.md`'s "iff a decline string / analysis site changed"), any twin matrix, the duplicate-body scan.

| new decline fixture `..._mergephi_chained_arm.ll` (= boi6 probe `p20`, the probe this increment is NAMED after) | `ae216b3727f5b1ec` / `fbbe0820` ORACLE | RED on the ORACLE (`control flow` — the leaf grammar pre-empts), GREEN here (`condition predates a non-diagonal gate` — rung (iii)/gate 2c). Added AFTER the corpus sweep, so its two verdicts were measured directly on both binaries rather than swept | M-impl | 2026-09-13 17:2x |
| rebuild after a COMMENT-ONLY edit to `SelectClassify.cpp` | `ae216b3727f5b1ec` | hash UNCHANGED — confirms the build is deterministic and that the corpus sweep's binary is the one on disk | M-impl | 2026-09-13 17:2x |

