# progress — impl_inc1b (bd test_C_libtooling-3qlq.2, Inc 1 PART B: P3 / P4 / P5)
Worktree `$SP/wt/inc1b`, branch `3qlq-inc1b`, base = part A's last commit fa96336.
Oracle binary: `$SP/wt/pre-3qlq/build/ir-pass/cq-opt` (pre-3qlq, 52d7764).
Subject binary: `$SP/wt/inc1b/build/ir-pass/cq-opt`.

## Step 0 — build + measure the customers FIRST (DONE 2026-09-05)
`cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release`
then `cmake --build build -j8` → `BUILD_OK` (log `$SP/progress/inc1b_build.log`, ~4 min,
BOTH `libCQPass.so` and `cq-opt`).

Probes in `$SP/progress/inc1b_probes/` (new surface, `void cq_phi(double)` from
`$SP/wt/inc1b/include/CQ.h`). Stage 1 = `/usr/local/opt/llvm@19/bin/clang -I<wt>/include
-include CQ.h -O1 -emit-llvm -S`. Dispositions measured on the SUBJECT binary at base
fa96336 (i.e. part A's HEAD = my red half).

| probe | source | `-O1` shape MEASURED | disposition at base (exit) |
|---|---|---|---|
| `p3_and` | `if (q==5 && r==3) cq_phi(.3)` | `%5 = select i1 %3, i1 %4, i1 false` ; `br i1 %5` ; arm = 1 void phase call ; merge NO φ | 1 — `cq controlled lowering: branch phase on a bare i1 condition under quantum control` |
| `p3_or` | `\|\|` | `%5 = select i1 %3, i1 true, i1 %4` | 1 — same string |
| `p3_foldnest` | `if (q==5) { if (r==3) cq_phi(.3); }` | **BYTE-IDENTICAL `@slice` body to `p3_and`** | 1 — same string |
| `p4_nest` | `if(q>5){cq_phi(.25); if(q<9) cq_phi(.75);}` | GENUINE 2-level nest; merge `%6` has **3 preds and NO φ** | 1 — `cq controlled lowering: control flow under quantum control` (at the OUTER `br`) |
| `p5_switch` | 3 one-gate cases | `-O1` **TABLES** it: `@switch.table` + `cq_phi(load)` | 1 — `cq QRAM access: const-global table read under tainted control: index not provably in-bounds …` |
| `p5_ifchain` | `if/else if/else if` on `==` | tabled IDENTICALLY | 1 — same QRAM string |
| `p5_switch_struct` | arms of 1 / 2 / 0 gates | SimplifyCFG **SINKS** the trailing call: cascade of blocks + `phi double` angles | 1 — `control flow` |
| `p5_ngate` | arms of 1 / 2 / 3 gates | sunk cascade, 2 `phi double` | 1 — `control flow` |
| `v_many` | arms of 4 / 3 / 2 gates | sunk cascade, 5 `phi double` | (not run) |
| `p5_vol` | volatile per-arm angles, dense cases | `@switch.table` of **ptr** + volatile load | (not run) |
| `p5_sparse` | volatile angles, cases 0/5/17 | switch SURVIVES but every arm is EMPTY and the merge holds one `phi ptr` + ONE shared `cq_phi` — a DATA-MUX, not a phase switch | 1 — `control flow` |

### FINDING F-0 (measured, 7 spellings) — P5 HAS NO plain-C `-O1` CUSTOMER, AND
### OQ-4's PROPOSED REMEDY ("arms that differ STRUCTURALLY / N-gate arms") DOES NOT WORK.
A homogeneous-phase switch arm's ONLY content is `call void @cq_phi(double)`, so every
arm's suffix is identical modulo one operand and SimplifyCFG's common-code sinking ALWAYS
applies: with dense case values `-O1` builds a `@switch.table` of angles (or of pointers),
with sparse ones it sinks the calls into a cascade with `phi double` / `phi ptr` angles. It
is a property of the CONSTRUCT (there is nothing else an arm may hold), not of the
spellings I picked. See `## OWNER QUESTION OQ-11`.

### Grammar fact that contradicts my brief (measured)
The brief says `SelectClassify::collectCondTree` "already accepts" `select i1 %a, i1 %b,
i1 false`. IT DOES NOT — the walk is `dyn_cast<BinaryOperator>` only (SelectClassify.cpp
~520), and `control_swap_reject_select_i1sel_combinator.ll` is a SHIPPED DECLINE fixture
for exactly that spelling. Since the LOGICAL-SELECT form is what `clang -O1` measurably
hands the `br` (all three P3 rows above), P3 requires WIDENING the grammar, not reusing it.

## Step 1 — Rule-14 lift: `CondTreeEmit.{h,cpp}` (commit f94d8f4)
The condition-tree flag NETWORK moved OUT of `SelectMergeEmit.cpp` steps 1 and 5 into a
new TU with THREE entry points — `emitCondNode` (one node, forward or exact adjoint, with
optional `cqrt_x` polarity brackets for P4), `emitCondNetwork` (post-order forward) and
`stripCondNetwork` (exact LIFO). `SelectMergeEmit` now calls it. Two policy knobs, both
added so the 4.4 stream does not move: `AllowQQLeaves` (true = the bd adia `qqSelectLeafWidth`
policy the select ships; false = the branch phase's, which has no Q+Q mint) and an optional
`StripsOut` vector (the branch phase records each leaf strip in `taint.DischargedFlagGates`,
the select records nothing, as before).
`emitCondNetwork` returns a THREE-WAY `CondNetDisp` rather than a bool, and that is a
correctness point, not style: `MintDiagnosed` means `lowerCompareToFlag` was ALREADY loud, so
the caller must return SILENTLY — a bool would have made me add a second
`control flow under quantum control` on top of the existing `no template …`, changing what
every affected decline fixture reads on stderr.
`CondTree::Nodes` is now `Instruction *` (a node may be a logical `SelectInst`), and node
decomposition is ONE function, `decomposeCondNode`, asked by the walk AND by the emitter.
`Specialization::mintCondNetwork` (the forward-only clone variant, own `cqq.g` name, own
NodeMints/NodeRails capture) is NOT folded in — a cross-reference comment says why, and it is
listed under What is left.

### `collectCondTree` grammar widening, GATED
New `AllowLogicalSelect` parameter (default FALSE). ON it admits `select i1 %a, i1 %b, i1
false` (= AND) and `select i1 %a, i1 true, i1 %b` (= OR); the two NOT-carrying complements
and a constant child are refused. It is ON only for the register-free branch phase — the 4.4
DATA select and the 6.x clone lift keep the shipped grammar, so
`control_swap_reject_select_i1sel_combinator.ll` still declines.

## Step 2 — P3 (commit 8525b38)
Classifier (`classifyPhaseKickback` step 5/6): the condition is now a `collectCondTree` tree.
Single leaf = part A's path verbatim. COMPOUND adds a per-leaf ladder — tainted leaf,
`comparePredLowerable`, `compareFlagMintable`, NOT Q+Q (the network mints at
`AllowQQLeaves=false`, so a Q+Q leaf would fail MID-network — the ziov.4 mutate-then-decline
class), no i1-operand leaf, leaf and node both in `Pred` — plus a size bound
(`kPhaseCondTreeMaxLeaves`/`MaxNodes` = 8/8, stated: each leaf is a live flag rail and each
node a live ancilla between mint and strip), a STRUCTURAL data-use fence (every tree
instruction's users must be inside the tree or be the branch; else
`condition used outside the branch`) and the leaf-union provenance + per-leaf positional
scan for the stale-condition guard.
Emitter (`emitPhaseKickbackRegion`): network → gates on the ROOT → LIFO strip → flatten →
cascade-erase the tree interior (`flattenRegion` owns only the root).

### ⚠ FINDING F-1 — a SIGSEGV I introduced and fixed inside this step, worth recording
The `select i1` that IS the branch's compound condition is ALSO a tainted-condition select,
so `ControlDetect`'s select scan handed it to `classifySelectRegion`, which ACCEPTED it as an
i1 DATA select. `emitSelectRegion` then dereferenced a select `emitPhaseKickbackRegion` had
already erased: `exit=139`, stack in `diagnoseUnderControl(nullptr, …)`, on the FLAGSHIP
plain-C customer `if (q==5 && r==3) cq_phi(0.3)`. Fixed with `ClaimedSelects` — the exact
analogue of the `Claimed` set an accepted nest uses for its inner `br` — threaded
`detectControlRegions` → `handleBranchRegion` → `classifyPhaseKickback`, which fills it at
ACCEPT. The node-in-`Pred` fence above is the second half of that fix: the select scan is
per-block and runs after that block's terminator, so a node in ANOTHER block could be visited
before this region claims it.

### MEASURED (subject `$SP/wt/inc1b/build/ir-pass/cq-opt`)
`p3_and` / `p3_or` / `p3_foldnest` all exit 0. Emitted stream for `&&` (and for the folded
nest — the two `@slice` bodies are **byte-identical**, `diff` empty):
```
icmp_eq_i32_hl(h,5) -> h_cmp ; icmp_eq_i32_hl(h2,3) -> h_cmp1
cqrt_alloc_i1(false) -> g ; cqrt_toffoli(h_cmp,h_cmp1,g)
cqrt_rz_i1(g, 0.3)
cqrt_toffoli(h_cmp,h_cmp1,g) ; cqrt_free(g)
icmp_eq_i32_hl_unc(h_cmp1,h2,3) ; cqrt_free(h_cmp1)
icmp_eq_i32_hl_unc(h_cmp,h,5)   ; cqrt_free(h_cmp)
```
`||` is the same with the OR node (`cnot;cnot;toffoli` … `toffoli;cnot;cnot`). NO `cqrt_cswap`,
NO `_controlled`, NO non-i1 `cqrt_rz`, NO surviving `@cq_phi`.
Stage 2b `free_pairing_check.py` STRICT: **PASS** on all three (6 rail mints, 6 frees, 6
verified, 0 violations, 0 unproven).

## Rule-14 witness for step 1 (MEASURED, 2026-09-05)
`$SP/progress/inc1b_sweep_v2.sh` runs EVERY `ir-pass/test/*.ll` through the BASE binary
(`$SP/wt/inc1b-base/build/ir-pass/cq-opt`, a worktree at fa96336, built for this) and the
SUBJECT, comparing stdout (`-o -`), stderr and exit code:
```
SWEPT=1602 DIFFS=2
```
and **both "diffs" are artifacts of a concurrent rebuild replacing the subject binary
mid-sweep** (`rc 0 -> 137` and `rc 1 -> 127`); re-run individually with a quiescent build
both are `IDENTICAL`. So the lift plus P3 changed **0 of 1602** fixture outputs — which is
exactly the claim the lift needed, since P3's own accept shape has no fixture yet. The
definitive post-P5 sweep is reported below.

## Step 3 — P4, the genuine depth-2 nest (commit HEAD~0)
ONE region, `Kind = PhaseKickbackNest`, pre-peeled in `handleBranchRegion` AFTER the flat
kickback (that order is load-bearing and the comment says why: the flat classifier returns
NotApplicable on a nest only because its `uncondSucc(arm) == merge` test runs first).
New `classifyPhaseKickbackNest` + `emitPhaseKickbackNestRegion`; `flattenRegionTree` gained a
NULL-merge-φ path (a register-free nest has no φ at all) and is otherwise untouched.
`ControlRegion` gained `InnerCondition` + `InnerArmNegated`, and the six WP5 leftovers
(`Conj`, `CondA`, `CondB`, `FlagA`, `FlagB`, `Flag`) are **DELETED** — they belonged to the
excised controlled-op generation, were written and read by nothing, and would have been a
SECOND representation of a compound condition beside the `CondTree` that is now real.

### MEASURED — `p4_nest.c` = `if (q>5){cq_phi(.25); if (q<9) cq_phi(.75);}` exit 0
```
icmp_sgt_i32_hl(h,5) -> h_cmp
cqrt_rz_i1(h_cmp, 0.25)                <- the OUTER arm's phase, on f1
icmp_slt_i32_hl(h,9) -> h_cmp1
cqrt_alloc_i1(false) -> g ; cqrt_toffoli(h_cmp,h_cmp1,g)
cqrt_rz_i1(g, 0.75)                    <- the INNER arm's phase, on f1 AND f2
cqrt_toffoli(h_cmp,h_cmp1,g) ; cqrt_free(g)
icmp_slt_i32_hl_unc(h_cmp1,h,9) ; cqrt_free(h_cmp1)
icmp_sgt_i32_hl_unc(h_cmp,h,5)  ; cqrt_free(h_cmp)
```
NO `cqrt_cswap`, NO work rail, NO `_controlled`, only `cqrt_rz_i1`. Compare the 4.3 route it
replaces: 2 `cqrt_alloc_i32` work rails, FOUR `cqrt_cswap`, an inner flag minted FROM rail1,
and a TENSORED `cqrt_rz_i32`. Stage 2b STRICT: **PASS** (6 free sites, 6 verified, 0
violations, 0 unproven).

### ⚠ FINDING F-2 — a double free I introduced and fixed inside this step
`flattenRegionTree` erases `Outer.Condition` and `Inner.Condition` as two separate dead
values. The emitter builds its two `ControlRegion`s as copies of the one plan region, so the
copy's inherited `Condition` was the OUTER root in both — erasing it TWICE. SIGSEGV inside
the flatten on the very first P4 run. Fixed by re-pointing `Inner.Condition` at
`R.InnerCondition`, with the reason recorded in place.

## Step 4 — P5, the register-free PHASE SWITCH (commit 2a2ec7a)
PRE-PEELED in `ControlDetect`'s switch dispatch — the FIFTH pre-peel, for the same
reason as the third and fourth: with `void @cq_phi(double)` arms the merge carries no φ,
so the G0-G11 ladder's G1 (`soleSwitchMergePhi`) refuses it and declines generically. New
`SwitchClassify::classifyPhaseKickbackSwitch` pushes a `SwitchRegion/Phase` with
`Merge == nullptr` (that null IS the marker of the register-free shape), and
`SwitchRouteEmit.cpp` is REWRITTEN: per content case, mint `f_i = (q == k_i)` with
`emitEqFlag`, `cqrt_rz_i1(f_i, θ)` per gate, `_unc` strip, free. The VALUE and DATA-MUX
switch classes (which DO have a merge φ) still go through the ladder and are untouched.

### MEASURED — hand IR (`$SP/progress/inc1b_probes/p5_hand.ll`, N=3, one 2-gate arm)
```
icmp_eq_i32_hl(h,0) -> h_cmp ; rz_i1(h_cmp,.1) ; icmp_eq_i32_hl_unc(h_cmp,h,0) ; free
icmp_eq_i32_hl(h,1) -> h_cmp1; rz_i1(h_cmp1,.2); rz_i1(h_cmp1,.25)
                              ; icmp_eq_i32_hl_unc(h_cmp1,h,1); free
icmp_eq_i32_hl(h,2) -> h_cmp2; rz_i1(h_cmp2,.3) ; icmp_eq_i32_hl_unc(h_cmp2,h,2); free
```
exit 0; stage 2b STRICT **PASS**. ORACLE on the same IR: exit 1 `control flow`.
The §5 CONST-FOLD RE-ANCHOR SCRUB is RETIRED with the route (a `void cq_phi` has no arg-0
to fold, and there is no merge φ to degenerate).

## Step 5 — the two non-i1 Rz minters RETIRED (commit 2a2ec7a)
* `ir-pass/src/NestedRouteEmit.{h,cpp}` **DELETED** (the 4.3 swap-routed nest), with its
  dispatch and the `Depth>0`/`ParentIdx` parent-child call removed from
  `lowerControlRegions`. `RegionTreeDetect::recoverRegionTree` no longer has an ACCEPT
  branch: every criterion it proves is a consequence of the RETIRED register form (a merge
  φ, a `cq_phi` diagonal-alias base, an inner flag minted from the parent's work rail), so
  under D1/D2 the shape cannot exist. Rule 17 is satisfied because the shape the increment
  set out to build — the GENUINE depth-2 phase nest — DOES lower (P4).
* `RotationLowering::emitRz` **DELETED** (definition + declaration). Part A left it standing
  with zero callers precisely because part B was going to rewrite the two other minters;
  both are now gone.
* `ControlledSymbols::controlledRotationFn`'s `stem` parameter lost its `RotStem::Rz`
  DEFAULT — a compile-time fence, not tidiness: nothing in the pass mints a controlled Rz
  any more, and a defaulted `Rz` would let a future caller mint one by OMISSION (the
  "absence of a decision" failure mode bd 3c6m.67 and bd big5 both document).

### THE BRIEF'S ACCEPTANCE GREP, MEASURED
`grep -rn 'rzRtFn(' ir-pass/src ir-pass/include` → **4 call sites, every one `"i1"`**
(`SwapRouteEmit::emitPhaseKickbackRegion`, `::emitPhaseKickbackNestRegion`,
`SwitchRouteEmit::emitSwitchPhaseRegion`, `AngleSelectEmit`) plus the definition and the
declaration. `controlledRotationFn(` has 2 call sites, both passing `RotStem::Ry`
explicitly. **No minter of a non-`i1` Rz remains in the pass.**

## Step 6 — Rule-12 fixtures (commits 1230737, 30eea56)
**35 files: 34 NEW (15 accept / 19 decline) + 1 REWRITTEN header.** Every accept's CHECK
lines are DERIVED from the pass output by `$SP/progress/inc1b_mkchecks.py` and never typed
(the Inc-4 round-1 review found 9 of 20 fixtures naming an SSA value the pass never
produced); every count lives in its OWN prefix and `NOROUTE` is whole-file and
PURE-NEGATIVE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 discipline).

| family | files | what it pins |
|---|---|---|
| `control_phase_kickback_{and2,or2,andbo,xor2,and3_tree,tree_negated,tree_shared_leaf}` | 7 accept | both logical-select spellings + the `and`/`xor` BinaryOperator ones, depth-2 nesting, the `cqrt_x` polarity bracket, a shared leaf minting ONCE |
| `control_phase_kickback_reject_tree_*` | 7 decline | classical leaf, Q+Q leaf, out-of-tree data use, the NOT-form complement, a stale leaf wire, a cross-block leaf, the 8/8 size bound |
| `control_phase_nest_kickback*` | 5 accept | the genuine nest, both polarities, an empty outer arm, a COMPOUND inner tree |
| `control_phase_nest_reject_*` | 6 decline | the MIXED nest (OQ-7), a merge φ, a tainted angle, in-loop, depth 3, the block-order assumption |
| `control_phase_switch_kickback*` | 3 accept | N=3, an N-gate arm, an empty case |
| `control_phase_switch_reject_*` | 7 decline | non-empty default, grouped fall-through, tainted angle, stale scrutinee, unowned scrutinee data use, a merge φ, **the real `clang -O1` table fold** |

`control_phase_kickback_reject_bare_i1.ll`'s header was CORRECTED, not deleted: it claimed
the compound `select i1` condition "is P3/P4 and a SEPARATE increment", which part B makes
false.

### ⚠ FINDING F-3 — a USE-AFTER-FREE found by the `compound_inner` NEST fixture
The nest's INNER condition tree lives in `Mid`, and `flattenRegionTree` erases `Mid`
WHOLESALE — so the post-flatten cascade that erases dead tree interiors was calling
`use_empty()` on instructions the block destructor had already freed. SIGSEGV inside
`ValueSymbolTable::reinsertValue`, on the FIRST run of that module. The single-compare
nests were silently fine only because their inner "tree" is just the root, which the
cascade skips — so no accept-only or count-only test could have found it; **only a nest
with a NON-TRIVIAL inner tree does.** The fix snapshots the `Pred`-RESIDENT survivors
BEFORE the flatten. (The flat P3 path is structurally immune: its tree is fenced to `Pred`,
which `flattenRegion` never erases.)

### ⚠ FINDING F-4 — an ORDERING ASSUMPTION that pre-dates this increment, now pinned
`ClaimedSelects` inherits `Claimed`'s block-order assumption exactly: both are filled when a
region's OUTER construct is dispatched and read when a block that construct owns is
reached, so both rely on the owner being visited first — the same thing the 4.3 nest
recorded as "`-O1` visits the outer Pred before the inner Mid". A hand-IR nest whose `Mid`
precedes its `Pred` therefore has its INNER `br` classified first, and it DECLINES LOUDLY
(`control flow`) — MEASURED, no output written, clean under
`DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib`. Pinned by
`control_phase_nest_reject_block_order.ll` with the fix (dispatch terminators in RPO)
recorded rather than done.

## OWNER QUESTIONS

### OQ-11 — P5 HAS NO PLAIN-C `-O1` CUSTOMER, AND OQ-4's PROPOSED REMEDY DOES NOT WORK
prep-b's OQ-4 recorded that `-O1` tables a phase switch whose arms "differ only by a
double", and proposed: *"Inc 1b implements P5 on the IR `switch` (hand-IR fixtures) + an
e2e slice whose arms differ STRUCTURALLY (N-gate arms)."* **The second half is measured
NOT to work.** A homogeneous-phase arm's ONLY possible content is
`call void @cq_phi(double)`, so every arm's suffix is identical modulo one operand and
SimplifyCFG's common-code sinking ALWAYS applies. Seven spellings, all measured
(`$SP/progress/inc1b_probes/`):

| spelling | `-O1` result |
|---|---|
| 3 one-gate cases, dense values | `@switch.table` of angles + ONE `cq_phi(load)` |
| `if/else if/else if` on `==` | the SAME table, byte-identical |
| arms of 1 / 2 / 0 gates | calls SUNK into a cascade, 1 `phi double` |
| arms of 1 / 2 / 3 gates | sunk cascade, 2 `phi double` |
| arms of 4 / 3 / 2 gates | sunk cascade, 5 `phi double` |
| per-arm `volatile double` angles, dense | `@switch.table` of **ptr** + a volatile load |
| per-arm `volatile double` angles, cases 0/5/17 | switch survives but EVERY arm is empty and the merge holds one `phi ptr` + one shared `cq_phi` — a DATA-MUX |

It is a property of the CONSTRUCT (there is nothing else an arm may hold), not of the
spellings picked. **So there is no P5 e2e slice in this increment, and the brief's request
for one cannot be satisfied as written.** What IS shipped: P5 lowers correctly on the IR
`switch` (3 accept fixtures, 7 decline fixtures, hand IR, stage 2b STRICT PASS), and the
two things `-O1` actually produces are PINNED as loud declines —
`control_phase_switch_reject_table_fold.ll` carries the verbatim `-O1` module.
**Owner decision needed:** (a) accept that P5 is hand-IR-only, as the if/else kickback arm
has been since part A; or (b) commission the TABLE-FOLD RECOGNIZER as its own increment
(the table is `private unnamed_addr constant` with `ConstantFP` entries, so the N angles
ARE statically known — the lowering would be per-entry eq-flags off the index, i.e. exactly
P5 with the case values read from the table). (b) is what turns P5 into a real customer;
prep-b already flagged it as "a FOLLOW-ON needing an owner ruling".

### OQ-12 — the 4.4 DATA select still declines the logical-select condition
`collectCondTree` gained `AllowLogicalSelect`, and it is deliberately **OFF** for the 4.4
data select and the 6.x clone lift, so `control_swap_reject_select_i1sel_combinator.ll`
(a SHIPPED decline fixture) is unchanged. That means `int x = (q==5 && r==3) ? a : b;`
still declines while `if (q==5 && r==3) cq_phi(θ);` now lowers — one grammar, two verdicts,
decided by a flag. The asymmetry is the safe direction and it kept this increment's blast
radius at zero on the select layer (measured: 0 of 1602 fixture outputs changed by the
lift), but it is exactly the "absence of a decision that hardens by repetition" shape bd
3c6m.67 and bd big5 warn about, so it is recorded rather than left implicit.
**Proposed:** widen the data select in a follow-on with its own probe family (the emitter
already handles it — only the classifier's grammar flag differs), not as a side effect here.

### OQ-13 — `Specialization::mintCondNetwork` is a THIRD copy of the network
Rule 14's lift covers `SelectMergeEmit` (forward + strip) and the two new branch-phase
callers. `Specialization.cpp`'s `mintCondNetwork` is a FORWARD-ONLY variant with its own
ancilla name (`cqq.g`), its own `NodeMints`/`NodeRails` capture and NO strip (the Bennett
wrap owns the single reverse). Folding it into `CondTreeEmit` would move the specialization
goldens, so it is left in place with a cross-reference comment saying why.
**Proposed:** a follow-on that gives `emitCondNetwork` a "keep the flags live + capture"
mode; not this increment.

### NOT AN OWNER QUESTION — recorded so nobody re-raises it
No implementation finding contradicts a PRD §2 decision or a §12 assumption. PRD §6.3's
"N>1 `cq_phi` per arm declines" was already superseded by the orchestrator (OQ-6) and part
B follows that for the switch arms too, on the same ground (nothing is summed; the angles
compose in the hardware).

## Step 7 — the e2e WITNESS (the brief's twin gate)
The migrated slices were copied from `$SP/wt/prep-b/tests/e2e/` (prep-b's branch is not
merged into mine) and run through the FULL pipeline with MY `include/CQ.h` — stage 1
`clang -O1`, stage 2 lowering, stage 2b `free_pairing_check.py` STRICT, stage 3 link
(templates BEFORE runtime), stage 4 trace. Artifacts in `$SP/progress/inc1b_e2e/`.

| slice | ORACLE (pre-3qlq, same IR) | SUBJECT |
|---|---|---|
| `slice_control_phase_andcond.c` (`&&`) | exit 1 `control flow` | exit 0, 2b PASS, **17 trace lines** |
| `slice_control_phase_nest.c` (folded nest) | exit 1 `control flow` | exit 0, 2b PASS, **17 trace lines** |
| `slice_control_nested_phase.c` (GENUINE nest, P4) | exit 1 `control flow` | exit 0, 2b PASS, **15 trace lines** |
| `slice_control_phase_nest_deep.c` (MIXED nest) | exit 1 `impure phase arm` | exit 1 `impure phase arm` — OQ-7's disposition, unchanged |
| `slice_control_switch_phase.c` | exit 1 QRAM table read | exit 1 QRAM table read — finding F-0 |

### ⚠ THE BRIEF'S BYTE-IDENTITY WITNESS HOLDS
`diff slice_control_phase_andcond.subj.trace slice_control_phase_nest.subj.trace` is
**EMPTY** — the `&&` spelling and the folded-nest spelling produce the same trace, byte for
byte. That is a statement about `clang -O1` (both fold to ONE branch on
`select i1 %a, i1 %b, false`) as much as about the lowering, and the fixture header says so.

```
cqrt_alloc_i32(0) -> h0 ; cqrt_ry_i32(h0, 0x1p-1)
cqrt_alloc_i32(1) -> h1 ; cqrt_ry_i32(h1, 0x1p-2)
cq_template_icmp_eq_i32_hl(h0, 5) -> h2
cq_template_icmp_eq_i32_hl(h1, 3) -> h3
cqrt_alloc_i1(0) -> h4
cqrt_toffoli(h2, h3, h4)
cqrt_rz_i1(h4, 0x1.3333333333333p-2)
cqrt_toffoli(h2, h3, h4)
cqrt_free(h4)
cq_template_icmp_eq_i32_hl_unc(h3, h1, 3) ; cqrt_free(h3)
cq_template_icmp_eq_i32_hl_unc(h2, h0, 5) ; cqrt_free(h2)
cqrt_measure_i32(h0) -> 0 ; cqrt_measure_i32(h1) -> 0
```
The GENUINE nest's trace is the P4 stream — `rz_i1` on `f1` for the outer phase, one
`cqrt_toffoli`, `rz_i1` on the conjunction for the inner, LIFO undo, three frees. In both:
`cqrt_cswap` **0**, `_controlled` **0**, non-i1 `cqrt_rz` **0**, surviving `@cq_phi` **0**.

**NO P5 e2e SLICE EXISTS** and cannot be written — see OQ-11.

## Step 8 — the gates, all MEASURED on `$SP/wt/inc1b/build`

### `ctest -R ir-pass-lit` (log `$SP/progress/inc1b_lit2.log`, 33.2 s)
**1270 passed · 1 expectedly failed · 366 FAILED · corpus 1637.**
Partition, computed as a SET DIFFERENCE and not by eye:
```
grep -lE '@cq_phi_[a-z0-9]+' ir-pass/test/*.ll   -> 491 files (the retired family)
red \ that set                                    -> 0
```
**ZERO red outside the migration set.** Of my 34 NEW fixtures, **0 are red**.
Part A measured 362; the **+4** are exactly the four fixtures that used to LOWER through
the retired family via the nest/switch ROUTE and now decline —
`control_swap_switch_phase{,_passthrough}.ll`, `control_swap_switch_scrutinee_measured.ll`
and `control_swap_reject_blockaddress_switch_arm.ll` (whose body is
`control_swap_switch_phase.ll`'s verbatim). All four are in the 491.

### Full fixture-corpus byte-identity sweep vs the BASE binary (fa96336)
`$SP/progress/inc1b_sweep_v2.sh` — every fixture through both binaries, comparing stdout
(`-o -`), stderr and exit code (log `inc1b_sweep_final.log`):
```
SWEPT=1602 DIFFS=4
```
and the 4 are exactly the four named above. **Everything else is byte-identical**, which is
the Rule-14 witness for the `CondTreeEmit` lift: the 4.4 select layer did not move at all.

### `ctest -R 'frontend-lit|runtime|cq-opt-equivalence'`
**9/9 Passed, 0 failed** (log `inc1b_other.log`) — incl. `cq-opt-equivalence` (sampled) and
all 7 `runtime` entries.

### `ctest -j6 -R '^e2e-'` — 252 passed, **65 failed of 317** (log `inc1b_e2e_all2.log`)
**NONE of the 65 is a lowering change.** Partition, measured
(`$SP/progress/inc1b_e2epart.sh`, results in `inc1b_e2e_owned.txt`):
```
identical-lowering = 0   pass-output-DIFFERS = 0   stage1-clang-fail = 60   no-single-.c = 5
```
* **60** fail at STAGE 1 — `clang` refuses the `.c` because it calls the RETIRED two-argument
  `cq_phi(x, angle)` (part A's surface change; prep-b's migration is not merged into my tree);
* **3** are multi-file slices whose HELPER uses the retired surface — verified:
  `tests/e2e/spec_select_caller.c:23` is `a = cq_phi(a, 3.14);`
  (`specialize-select`, `specialize-twoarm-select`, `control-cond-onward-ctl-phase`);
* **1** is `e2e-loop-twin-matrix`, whose GENERATOR emits old-surface programs (its first
  failure is the same clang error);
* **1** is `e2e-fixture-guard-liveness`, whose 7 SKIPs are ALL on migration-set `.ll`
  fixtures (each has 2 `@cq_phi_` references and each is in the 366).
For every failing slice with a single `.c`, the lowered IR + stderr + exit code are
IDENTICAL between the base binary and mine wherever stage 1 succeeds (0 differ).

## Exact diagnostic strings (Rule 12 — every fixture mirrors these character-for-character)
ONE new string in this increment:
* `cq controlled lowering: branch phase condition tree too deep under quantum control`

Every other decline REUSES an existing spelling, deliberately, so no fixture learns a new
string for an unchanged rule:
`cq controlled lowering: {control flow, nested control flow, control flow inside a loop
body, rotation angle, control condition has no template, condition used outside the branch,
condition predates a non-diagonal gate, condition data use neither escaped nor measured,
impure phase arm, branch phase on a bare i1 condition} under quantum control`, plus the
pre-existing QRAM string the `-O1` table fold hits.

---

# HAND-BACK

## 1. What shipped
Branch `3qlq-inc1b` in `$SP/wt/inc1b`, 8 commits on top of part A's `fa96336`
(`git log --oneline fa96336..HEAD`), **59 files changed, +4164 / −766**.

| commit | what |
|---|---|
| `76519c8` | step 0 — probes + measured pre-increment dispositions (no tree change) |
| `f94d8f4` | Rule-14 lift: `CondTreeEmit.{h,cpp}`; `collectCondTree` gains the GATED logical-select node |
| `8525b38` | **P3** — compound condition tree for the branch phase (+ `ClaimedSelects`) |
| `40800b4` | **P4** — the genuine depth-2 nest; `flattenRegionTree` null-φ path; WP5 fields deleted |
| `2a2ec7a` | **P5** — the phase switch by eq-flag kickback; `NestedRouteEmit` + `emitRz` DELETED |
| `1230737` | 34 Rule-12 fixtures + the nest-cascade UAF fix |
| `30eea56` | the block-order assumption pinned as a decline fixture |
| `71d4cce` | measurements |

**Pass source:** `+ ir-pass/{include,src}/CondTreeEmit.{h,cpp}` (new TU, registered in
`ir-pass/CMakeLists.txt`); `− ir-pass/{include,src}/NestedRouteEmit.{h,cpp}` (deleted);
edited `SelectClassify.{h,cpp}`, `SelectMergeEmit.cpp`, `ArmClassify.cpp`, `ArmAnalysis.h`,
`ControlDetect.cpp`, `ControlPlan.h`, `SwapRouteEmit.cpp`, `SwitchClassify.{h,cpp}`,
`SwitchRouteEmit.cpp` (rewritten), `RegionFlatten.cpp`, `RegionTreeDetect.{h,cpp}`,
`RotationLowering.{h,cpp}`, `ControlledSymbols.h`, `Specialization.cpp`.
**NO runtime symbol added** — `tools/opcode_table.yaml` and `runtime/` are untouched
(`git diff --stat fa96336 HEAD -- runtime tools/opcode_table.yaml` is empty).

**Fixtures:** 34 new (15 accept / 19 decline) + 1 rewritten header; corpus 1602 → 1637.

## 2. What I ran (and only what I ran)
* `ctest -R ir-pass-lit`: **1270 passed · 1 XFAIL · 366 FAILED**, red set ⊆ the 491-file
  `@cq_phi_<sfx>` migration set (set difference = 0); 0 of my 34 new fixtures red.
* Full-corpus byte-identity sweep vs the fa96336 binary: **SWEPT=1602 DIFFS=4**, all four in
  the migration set and all four "used to lower through the retired route, now declines".
* `ctest -R 'frontend-lit|runtime|cq-opt-equivalence'`: **9/9 Passed**.
* `ctest -j6 -R '^e2e-'`: 252/317; the 65 failures partition to **60 stage-1 clang failures
  + 3 helper-file + 1 generator + 1 record-gate**, all retired-surface casualties;
  **0 have a lowering-output change** vs the base binary.
* Full pipeline (stages 1-4 incl. stage 2b STRICT) on 5 migrated slices + 6 probes, on MY
  binary and the ORACLE. `free_pairing_check.py` STRICT **PASS** on every accepting one.
* `grep -rn 'rzRtFn(' ir-pass/src ir-pass/include` → 4 call sites, **all `"i1"`**.
  `controlledRotationFn(` → 2 call sites, both `RotStem::Ry` explicit.
I did NOT run the full `ctest` (Rule 19 / brief: the orchestrator runs it at the gate).

## 3. Findings that are NOT mine to decide
`## OWNER QUESTIONS` above: **OQ-11** (P5 has no plain-C customer and OQ-4's remedy is
measured not to work — accept hand-IR-only, or commission the table-fold recognizer),
**OQ-12** (the 4.4 data select still declines the logical-select condition — one grammar,
two verdicts, decided by a flag), **OQ-13** (`Specialization::mintCondNetwork` is a third
copy of the network).
Plus finding **F-0** (the 7-spelling `-O1` measurement behind OQ-11) and the three defects
I found and fixed inside my own work: **F-1** the `ClaimedSelects` SIGSEGV, **F-2** the
`flattenRegionTree` double-erase, **F-3** the nest-cascade use-after-free — each reachable,
each measured, each recorded in place.

## 4. What is left
1. **Rule 13.** This is a core-lowering change (`ArmClassify`, `ControlDetect`,
   `SwapRouteEmit`, `SwitchClassify`, `SwitchRouteEmit`, `SelectClassify`, `RegionFlatten`,
   `RotationLowering`) and it has had **NO adversarial round**. It found THREE crash/UAF
   defects in its own work before shipping (F-1/F-2/F-3), two of which only a
   NON-TRIVIAL-tree fixture could reach. Budget the rounds; the 8h7d.5/drbq record is
   4-for-4 on "the first round finds a confirmed silent miscompile".
2. **The migration.** prep-a's 491 fixtures and prep-b's slices are not merged into my
   branch; 366 lit reds and 65 e2e reds are that, by construction. **FOUR fixtures need
   more than a mechanical rewrite** — `control_swap_switch_phase{,_passthrough}.ll`,
   `control_swap_switch_scrutinee_measured.ll` (they pin the ROUTED phase switch, which no
   longer exists — they become P5 fixtures) and
   `control_swap_reject_blockaddress_switch_arm.ll` (its body is the first one's verbatim,
   so it must be re-based on a shape that still LOWERS or its guard is never reached).
3. **Doc rows still describing the deleted nest emitter** in `ControlPlan.h:55`,
   `TaintPropagation.h:482`, `SwapRouteEmit.h:80` and inside `RegionTreeDetect.cpp`'s
   criterion prose. They are comments, not code; I updated `RegionTreeDetect.h`, the
   `recoverRegionTree` accept site and `RotationLowering`, and left the rest for the
   orchestrator's doc pass rather than churning nine files.
4. **Follow-ons named in the code:** widen the 4.4 data select to the logical-select
   grammar (OQ-12); unify `Specialization::mintCondNetwork` (OQ-13); grouped
   fall-through and a non-empty default for P5; depth ≥ 3 nests; an in-loop nest; Q+Q
   leaves in a branch-phase tree; the ziov shared-flag path for a compound condition.
