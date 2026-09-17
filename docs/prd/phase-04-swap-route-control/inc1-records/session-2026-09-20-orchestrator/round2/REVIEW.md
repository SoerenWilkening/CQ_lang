# Rule-13 round 2 — bd `zujr`, THE LOOP-CARRIED HANDLE VARIABLE — VERDICT `CLEAR-WITH-ITEMS`

Independent reviewer, 2026-09-20. **No P1. No P2. Five P3s**, plus two of round 1's
four named residuals RESOLVED (one closed by construction, one confirmed real but
un-weaponizable).

**SUBJECT** = the primary read-only build. Verified before the first probe and not
rebuilt under any measurement:

```
$ shasum -a 256 /Users/sorenwilkening/Desktop/Projects/CQ_lang/build/ir-pass/cq-opt
e7bbfd69a9e25d3832373b8418d24239a4ddebf79d75e9e3a9252c254e0192f2  build/ir-pass/cq-opt
84061321f9d6f9747b80a29e55210674d79411ad11c104f582cc76aac4622156  build/ir-pass/libCQPass.so
```
Matches the brief's `e7bbfd69a9e25d383237…`. `git log -1` = `00c36e93`, tree clean.
**No build, no relink, no `pkill`, no ctest, no `bd` write.** One `lit --filter`
spot-check (of the three allowed).

Probes: `round2/probes/` (45 files). Pipeline per the brief; `probes/` C files are
compiled `-O1` without `-g` unless noted, `.ll` files are fed to `cq-opt` verbatim.
Every `.ll` probe was checked non-empty before any ACCEPT was scored (the 0-byte
passthrough trap).

---

## 1. Findings

| # | sev | finding | probe |
|---|---|---|---|
| R2-1 | P3 | **The promotion mutates for a `use_empty()` φ**: a dead carried-handle header φ gets a `cqrt_alloc_<W>(seed)` qubit in the preheader, left allocated forever, for a value nothing reads. Residual escape A is REAL — `declineClassicalMuxes`' `use_empty()` skip does not cover the φ — but the promotion SUCCEEDS on it, so the backstop is not what is missing. | `e1_deadphi_exempts_escape.ll` vs `e1c_control_nodeadphi.ll` |
| R2-2 | P3 | **(P1)'s stated ground is wrong even though its conclusion holds today.** `taint.ControlOwnedRails` is NOT "the record every Phase-4 merge emitter writes"; **Phase 7.4 puts three non-merge rails in it, at `lowerLoops` time, i.e. BEFORE the promotion**, and `emitBreakForward` RAUWs the break's escape φ onto one of them. Both of (P1)'s conjuncts are satisfiable for an outer-loop header φ over an inner break loop. Closed today by a DIFFERENT fence (nested-loop). L7 / round-1-F-1 shape. | `g1_nested_break_outreg_as_latch.c`, `g2_break_then_merge.c` |
| R2-3 | P3 (over-decline) | **The MULTI-EXIT carried handle declines**, on an exit φ muxing two `i32` HANDLES under the loop's own classical test — the identical argument that admits the header φ. Distinct from bd `h1ip`: no zero-trip guard, so `h1ip`'s filed fix does not reach it. | `f1_multiexit_handle.ll`, `f2_multiexit_reads_seed.ll` |
| R2-4 | P3 (unrecorded accept) | **The UN-GUARDED zero-trip carried-handle loop ACCEPTS and is CORRECT, and nothing in the increment's record measured it.** It is the one shipped shape where the promoted register is the **answer** rather than a which-path record, and it has no fixture. It also accepts an **unbounded runtime trip count** with no `hasFiniteClassicalTripBound` on this path. | `m1_runtime_bound_headexit.ll`, `m1z_zero_trip_main.ll`, `m1t_two_trip_main.ll` |
| R2-5 | P3 (trigger sharpening) | **Target 4 (`AsLowered`) VERIFIED BY CONSTRUCTION, and round 1's retirement trigger is the wrong one.** The two peels can disagree only on a `BinaryOperator`; I enumerated all ten `ControlOwnedRails.insert` sites and every one inserts a `CallInst`. The trigger is *"the day any `BinaryOperator` enters `taint.ControlOwnedRails`"*, which is greppable — not *"the day (Z6) admits an in-place latch step"*, which is not the only door. | source enumeration (below) |

### R2-1 — the promotion mutates for a dead φ

`promoteLoopCarriedHandleSeeds` (`LoopLowering.cpp:6065`) has no `use_empty()` test.
`declineClassicalMuxes` (`TaintPropagation.cpp:1605`) has one and takes it:

```cpp
if (Phi->use_empty())
  continue;
```

`e1_deadphi_exempts_escape.ll` is a loop whose merge rail has NO carry, plus a header
φ `%dead = phi i32 [ 5, %entry ], [ %anext, %head ]` with **no users**. It satisfies
every conjunct of `loopCarriedHandlePhi` ((Z8) is vacuous — no users to walk). The
control `e1c` is the same module with that one line deleted.

```
$ diff <(sed -n '/define i32 @f/,/^}/p' e1c_control_nodeadphi.s2.ll) \
       <(sed -n '/define i32 @f/,/^}/p' e1_deadphi_exempts_escape.s2.ll)
2a3
>   %cq.carried = call i32 @cqrt_alloc_i32(i32 5)
6a8
>   %dead = phi i32 [ %cq.carried, %entry ], [ %out, %head ]
```

Both exit 0; stage 2b goes `4 rail mint(s) of which 3 left allocated` → `5 … of which
4 left allocated`. **A qubit is allocated, and a trace line emitted, for a value the
program does not read.**

Why it is P3 and not higher: an `alloc` is not a measurement and not a non-diagonal
gate, so no unitary is wrong; Rule 6 already accepts a left-allocated rail. What it
does cost is real but bounded — the extra `cqrt_alloc` **renumbers every downstream
handle**, so any golden containing the shape would move.

**LIMIT, stated as the brief requires**: `clang -O1` deletes a dead φ, so **this is an
IR-level result and I did not demonstrate a C-level one** — the bd `hrts` caveat in
CLAUDE.md §5, exactly. `e1c` also ACCEPTS, so the (c3) exemption the dead φ hands out
changed no verdict here; **I could not turn residual escape A into a wrong circuit.**

Suggested shape of a fix, for whoever takes it: a `P.use_empty()` skip in the
promotion, red-green against `e1`/`e1c`. It is a mutation-avoidance clause, not a
fence, so it does not need a decline.

### R2-2 — (P1)'s ground, and the 7.4 members of `ControlOwnedRails`

The comment at (P1) (`LoopLowering.cpp:6020-6035`) reads:

> **(P1)** THE LATCH INCOMING IS A CONTROL-MERGE `%out` RAIL, asked by reading
> `taint.ControlOwnedRails` — the record every Phase-4 merge emitter writes at its own
> `Tainted.insert(rail)` site.

Every insertion site in the tree:

```
ClassicalCallArmEmit.cpp:217  taint.ControlOwnedRails.insert(Out);          <- 6.5 arm  (two X-bracketed controlled copies)
IOSinkLowering.cpp:787        taint.ControlOwnedRails.insert(MuxOut);       <- 7.6 tape (two X-bracketed controlled copies)
SelectMergeEmit.cpp:332       taint.ControlOwnedRails.insert(Out);          <- 4.4
SwitchDataMuxEmit.cpp:145     taint.ControlOwnedRails.insert(Out);          <- 4.5
SwitchValueEmit.cpp:294       taint.ControlOwnedRails.insert(Out);          <- 4.5
LoopLowering.cpp:2119         taint.ControlOwnedRails.insert(H);            <- 7.4 break R / idx / OUT   ** NOT A MERGE **
BreakReversePlay.cpp:780      taint.ControlOwnedRails.insert(LB.RailHandle);<- 7.4, but runs AFTER the promotion
BreakReversePlay.cpp:782      taint.ControlOwnedRails.insert(C);            <- 7.4, but runs AFTER the promotion
BennettWrap.cpp:109,115       cloneTaint.ControlOwnedRails.insert(...)      <- DISJOINT clone taint set
```

`LoopLowering.cpp:2119` is inside `emitBreakForward`, which runs from `lowerLoops`
(`CQLoweringPass.cpp:500`) — **before the promotion at `:766`**. Five lines later that
same emitter does `Rgn.EscapePhi->replaceAllUsesWith(OutReg)`. `OutReg` is minted in
`PreB`, the break loop's external predecessor: **outside the break loop, but inside
any enclosing loop**. So for an outer-loop header φ whose latch incoming is the inner
loop's escape value, (P1)'s two conjuncts

```cpp
if (!LatI || !taint.ControlOwnedRails.count(Pf->LatchVal) ||
    !L->contains(LatI->getParent()))
  continue;
```

are **both satisfied by a rail that is not a controlled-copy merge `%out`** — the break
construct's output register, written by an index-gated capture + exit consolidation,
which the per-trip unitary argument at `loopCarriedHandlePhi` does not describe.

**MEASURED CLOSED TODAY, by a fence that is not this one:**

```
$ ... -passes=cq-lowering -S g1_nested_break_outreg_as_latch.s1.ll
error: <unknown>:0:0: in function run i32 (i32): cq controlled lowering: loop under quantum control
$ ... -passes=cq-lowering -S g2_break_then_merge.s1.ll
error: <unknown>:0:0: in function run i32 (i32): cq controlled lowering: loop under quantum control
```

**RETIREMENT TRIGGER**: the day nested loops admit a break loop inside an outer loop
(bd `vsr6` is the nearest live work), **re-derive (P1) from scratch**. The safe reading
of the set is *"rails some emitter owns"*, never *"controlled-copy merge out-rails"*;
if (P1) wants the latter it should say so structurally, the way `railLocalQualifies`'
`MergeOutRail` lambda already does (`ControlOwnedRails` membership **AND** a
`cqrt_alloc_`-prefixed callee — which would NOT separate `OutReg` either, so a real
narrowing needs a per-emitter record, not a name test).

This is round-1 F-1's shape a second time: true conclusion, wrong ground, and the
ground is what the next widening will read.

### R2-3 — the multi-exit carried handle over-declines

`f1_multiexit_handle.ll`: header exits early on `%i == %x`, latch exits normally on
`%i+1 == 3`; the exit φ is `%e = phi i32 [ %a, %head ], [ %anext, %latch ]` — the
header φ on one edge, the merge `%out` on the other. (Z8) **passes** (both incomings
are tainted handles). The wall is one stage later:

```
=== f1_multiexit_handle : opt exit=1
error: <unknown>:0:0: in function f i32 (i32): cq taint escape: tainted value muxed by a classical-condition phi
=== f2_multiexit_reads_seed : opt exit=1
error: <unknown>:0:0: in function f i32 (): cq taint escape: tainted value muxed by a classical-condition phi
```

Both incomings are `i32` handles and WHICH is live is decided by the loop's own
CLASSICAL exit tests — the whole argument bd `zujr` makes for the header φ, applied to
the exit φ. Per the owner's 2026-09-11 ruling an over-decline is a defect to remove.
**Not** bd `h1ip`: there is no zero-trip guard here and the preheader alloc is never
bypassed, so "hoist the alloc above the guard" does not fix it. Suggest a new bead, or
a second clause on `h1ip`.

At the C level `-O1` folds two `break`s over one IV into a `umin` (measured:
`c5_multi_exit.c` lowers to a single-exit loop), so **the C spelling of this shape is
not reachable through `clang -O1` and the `.ll` is the only witness** — state it that
way if it is filed.

### R2-4 — the un-guarded zero-trip loop, and an unbounded runtime trip count

`m1_runtime_bound_headexit.ll` is a **non-rotated, header-exiting** carried-handle loop
whose bound is the argument `%n`. No guard block, so `getLoopPreheader()` is `entry`
and the promotion's alloc is on **every** path; the exit needs no φ, so (Z8) is
vacuous. It accepts, and it is correct at both ends:

```
=== m1z_zero_trip_main (n = 0) : opt exit=0, 2 trace lines
cqrt_alloc_i32(5) -> h0
cqrt_measure_i32(h0) -> 0
=== m1t_two_trip_main (n = 2) : opt exit=0, 26 trace lines   [two full activations]
```

Stage 2b STRICT on both: `1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven`.

Two things worth recording, neither a defect:

* **(Z8)'s comment is accurate but narrow.** It says *"it cannot make the ZERO-TRIP
  path name one, because … a ROTATED loop's zero-trip GUARD edge bypasses it"*. True of
  the rotated shape. The **un-rotated** zero-trip loop names a register and returns
  |seed⟩, which is the right answer — so (Z8) is an EXIT-φ-shape conjunct, not a
  zero-trip fence, and the increment's record does not say so. This is the only shape
  in which the promoted `cq.carried` is the **answer** the program measures rather
  than a which-path record, and it has **no fixture**.
* **Nothing on this path asks for a finite trip bound.** `%n` is unbounded, and the
  loop leaks two rails per trip (`%h`, `%out`; only `%bf` is freed). Under the
  qubits-not-scarce regime that is the accepted Rule-6 leak, and runtime classical
  bounds are already shipped (`tests/e2e/slice_loop_break_qq.c` runs with a runtime
  `n`), so I grade it **recorded, not defective**. It is here because an unbounded
  emitted gate count is the kind of fact that should be in the record deliberately
  rather than by omission.

### R2-5 — target 4 resolved by construction, with a sharper trigger

Round 1: *"Unobservable today — (Z6) refuses a binop latch and `peelInPlaceStep` returns
null for a select, a phi and a `cqrt_alloc`, so the chain is always exactly
`{φ, LatchVal}` — and it becomes live the day (Z6) admits an in-place latch step."*

Verified, and the reasoning is completable: `peelInPlaceStep` (`LoopLowering.cpp:310`)
returns a different answer under `AsLowered=false` and `true` **only** in its
`BinaryOperator` branch. `latchIsControlMergeRail` admits exactly three classes —
`taint.ControlOwnedRails` membership, `SelectInst`, `PHINode` — and the enumeration in
R2-2 shows **every** member of `ControlOwnedRails` is a `CallInst` (and `BennettWrap`'s
go to the disjoint `cloneTaint`). So no admitted latch incoming can be a
`BinaryOperator`, the walk in `collectCarriedHandleChains` cannot take a second step,
and `RootsOut` cannot disagree with `onRail`. **Confirmed, by construction rather than
by reading.**

The trigger round 1 recorded names one of the two doors. The other is
`ControlOwnedRails` acquiring a non-call member. Record it as: **the day any
`BinaryOperator` enters `taint.ControlOwnedRails`, or (Z6) grows a fourth class,
`collectCarriedHandleChains`' `AsLowered=false` and `railLocalQualifies`' `onRail`
`AsLowered=true` can disagree about a chain member.** That form is greppable at the ten
insertion sites.

---

## 2. Residual escape B — `liftOneRegisterMergePhi` on a header φ: CLOSED BY CONSTRUCTION

Round 1 named this as where a widening must look first and called the function's
self-description UNVERIFIED. It is **false in general and irrelevant to this
increment**, and both halves are worth having in the record.

**(a) The function does not refuse "loop-reachable merges" and nothing in it says it
does.** The phrase is `declineClassicalMuxes`' comment listing, not a clause. What
refuses a loop merge is (7a)/(7b), and **both are vacuous when `Chains[i].Gates` is
empty**: the per-edge loop is `for (CallInst *G : Chains[i].Gates)`. A header φ whose
incomings all resolve to a common base with **no gate on any edge** — e.g.
`%p = phi i32 [ %r, %pre ], [ %r, %latch ]` — therefore DOES lift. That lift is a pure
renaming onto a base both edges already name, so it is **benign**; a gate on either
edge is refused by (7a) (preheader edge: the gate reaches the latch) or (7b) (latch
edge: the back edge re-reaches the gate).

**(b) It can NEVER take a carried-handle φ, for three independent reasons.** Any one
suffices; they are listed because a widening only has to break one:

1. **Clause (2)** requires EVERY incoming tainted. An **unpromoted** carried-handle φ's
   non-latch incoming is the classical seed — (Z4) requires it untainted. A
   **promoted** one's is `%cq.carried`, which the promotion **deliberately** does not
   taint (`"⚠ THE PROMOTED HANDLE IS NOT ADDED TO taint.Tainted, DELIBERATELY"`). Both
   readings fail (2).
2. **Clause (3)** requires one common wire base. The seed must dominate the preheader
   terminator ((Z4) plus SSA); the latch incoming must be defined **inside** `L`
   ((Z5)). A value defined outside `L` and a value defined inside it cannot be the same
   `Value*`.
3. **Mutual exclusion on the φ shape.** `latchIsControlMergeRail`'s PHINode clause
   requires **some predecessor** of the φ's block to carry a **tainted** conditional
   branch; the lift requires **every incoming block's** terminator to be
   `terminatorIsClassical`. For a φ the incoming blocks **are** the predecessors, so no
   single φ can satisfy both.

So the backstop `declineClassicalMuxes` provides to the two GRANT slots is **not**
weakened from this direction. The remaining hole is R2-1's `use_empty()` — real, and
un-weaponized here.

---

## 3. WHAT I ATTACKED AND DID NOT FIND

Listed because "no finding" without the list is worthless. Every row was run on the
subject binary above.

**(A) Target 1 — `break` beside a carried handle (round 1 did two hand probes).**

| probe | shape | result |
|---|---|---|
| `c1_break_after_arm.c` | classical runtime `break` AFTER the region arm | **ACCEPT**, 38 lines, **trace byte-identical to the 3-trip baseline** `c0k` |
| `c1n_break_never_taken.c` | the same with the break never taken (4 activations) | **ACCEPT**, 50 lines, identical to the 4-trip unrolled twin `c1nu` modulo the documented trip-1 `-O1` const-fold (+1 preheader alloc, +2 for the folded first compare) |
| `c1o_break_first_trip.c` | break on trip 1 (1 activation) | **ACCEPT**, 14 lines, exactly one activation, measures the trip-1 `%out` |
| `c2_break_before_arm.c` | break BEFORE the region arm | DECLINE `loop-carried tainted value crosses iterations` |
| `c3_break_tainted.c` | a 7.4 TAINTED value-arm break beside the carried handle | DECLINE `loop under quantum control` |
| `c4_break_carried_on_break_edge.c` | exit value read on the break edge and the normal edge | ACCEPT, trace identical to `c1` |
| `c5_multi_exit.c` | two `break`s | ACCEPT — but `-O1` folds both into `llvm.umin`, so it is **not** a multi-exit test; see `f1`/`f2`, which are |
| `b1`–`b4` (`bool b0[N]` spellings) | break + the rail bank | DECLINE at `RailBankPromote` (`array has cells no iteration writes` / `cell index is not an injective per-iteration index`) |
| `g1`, `g2` | nested break loop, `OutReg` as the outer latch incoming (the R2-2 construction) | DECLINE `loop under quantum control` |

**The pairing question the brief asked** — *"do the promotion's preheader `cqrt_alloc`
and the per-trip `%out` rails pair correctly on EVERY exit path?"* — is **YES** on
every accepting probe. Stage 2b is STRICT-clean on all of them (`1 verified, 0
violation(s), 0 unproven`), the activation count matches the exit taken on all three
of `x = 0 / 2 / 99`, and the value measured is the last activation's `%out` (or the
promoted preheader handle when there is no activation, R2-4).

**(B) Rule 8 / Rule 6 on the carried handle — a spelling past the 4.4 select wall.**
Five constructions, all safe-direction. `loop_carried_handle_reject_postloop_rotation.ll`
dies at the select because of bd `r903`'s `i8` `_Bool` wire; I removed that wire
(`bool b = cq_theta((bool)0, …)`, no bank, a clean `i1` condition) and it **still
declines**:

| probe | trailing non-diagonal gate on | rolled | flat twin |
|---|---|---|---|
| `r1_postloop_rot.c` | the carried register, post-loop | DECLINE `control flow under quantum control`, `CQ_CTRL_DBG` names the select: `decline [control flow] at:   %9 = select i1 %7, i32 %8, i32 %5` | `r1u` compiles with the ruled WARNING `non-diagonal gate over a live derived record` (bd `lyyf`) |
| `r2_inloop_rot_after_merge.c` | the merge rail, in-body, one trip earlier | DECLINE `cq opcode lowering: operand predates a non-diagonal gate` | — |
| `r3_postloop_rot_other.c` | the last trip's condition rail | DECLINE `control flow under quantum control` | — |
| `k1_cond_reads_carried_postry.c` | the register the CONDITION reads (the session-2026-09-18 G-13 protocol item) | DECLINE `control flow under quantum control` | `k1u` compiles with the same ruled warning |

So the rolled form is **strictly more conservative than the flat form in every
spelling I could build**, which is the increment's own claim, now measured on four
more shapes. **The session's carried Rule-19 protocol obligation** (*"an
accept-direction widening of a CONDITION fence owes one rolled-vs-unrolled probe with
a trailing non-diagonal gate on every register the condition reads"*) is **discharged
by `k1`/`k1u`**, in the safe direction.

**(C) L1 — a round-2-falsified premise at the two GRANT slots.** (Z6)'s shape half and
(Z7) `taintedExit` are asked at ROUND-1 taint where `ControlOwnedRails` is empty. The
dangerous direction is *shape TRUE at round 1, record FALSE at final taint, no
decline*. Built the sharpest spelling I could: a loop **bound** that is a 4.4 value
merge over two classical CONSTANTS, hence data-untainted at round 1 and tainted after
`repropagateControlMerges` re-seeds from `%out` — i.e. a **quantum-dependent trip
count**, Rule 18's permanent decline, reached through a stage that only ever asked at
round 1.

```
=== h1_round2_tainted_exit.c      : DECLINE  cq controlled lowering: loop under quantum control
=== h3_round2_bound_railloop.c    : DECLINE  cq controlled lowering: loop under quantum control
=== h3c_control_classical_bound.c : ACCEPT   (the classical-bound control, 9 trace lines)
```

**It holds, and the reason is worth writing down**: `repropagateControlMerges` runs a
SECOND full `detectControlRegions`, which re-adjudicates the loop's now-tainted exit
branch and declines it. So the round-2 backstop for (Z7) is control **detection**, not
the loop layer — the loop layer's own Q1 genuinely is round-1-only. Verified in both
the with-carried-handle (`h1`) and without (`h3`) spellings. `e1_round2.c` from
round 1's set is the seed-taint version of the same question.

**(D) L2 — what other set was computed over the (L3) closure.** The exempted `store`
still falls through to `railLocalQualifies`' final operand loop, so a bank-parked
handle defined outside `L` and not `onRail` is still refused there — the sibling is
applied. The cross-iteration read through memory (a bank cell written on trip `i` and
read on trip `i+1`, which would cross with **no header φ** for clause (i) to see) is
refused upstream: `l1_bank_cross_iter_read.c` → `cq taint escape: tainted value stored
to memory`. `l2_bank_read_all_after.c` (every cell measured after the loop) accepts and
is well-formed: 41 lines, 3 per-trip `ry_i1` rails each measured once, `1 verified, 0
violation(s), 0 unproven`.

**(E) Structural variants around the carried handle** (each with its twin where it
accepts): in-place dtzb `add` on the carried register (`d1`, DECLINE `kMsgCrossIter`);
two carried handles cross-read by one condition (`d2`, DECLINE `classical-condition
phi`); exit value read through a post-loop temp (`d3`, ACCEPT, 39 lines, clean); the
condition reading the carried register (`d4`, ACCEPT, 47 lines — **last activation
gate-for-gate identical to the unrolled twin `k2`**, the 5-line delta being exactly the
documented trip-1/trip-2 `-O1` folds: `+1` preheader alloc, `+2` trip-1 compare folded
to TRUE, `+2` trip-2 spelled by additivity); runtime zero-trip guard (`d5`, DECLINE —
bd `h1ip`); nested (`d6`, DECLINE); **two regions per trip** (`d7`, ACCEPT, 74 lines,
vs `d7u` 74 lines, differing only in the trip-1 const-fold).

**(F) Verifying inherited claims (Rule 11).** Round 1 reports six findings "FIXED IN
SOURCE"; I spot-checked **four**, not the two the brief asked for:
F-1 (the (L3) ground now cites `isInteriorTerminalHandle` (I3)+(I1) with the
template-rail retirement trigger — present, `LoopLowering.cpp:4083-4098`);
F-3 (the prescan walks `F`'s blocks with the neighbour's *"Do not 'simplify' it back"*
quoted — present, `:6074-6092`);
F-4 (the DEFER/GRANT split and the two named residuals — present, `:1213-1236`);
F-6 (`grep -c "MUTANT Z"` = **5, 5, 5, 5** on the four reject fixtures);
plus F-2's fixture `loop_carried_handle_accept_bank_l3_isolated.ll` exists with the
"no carried-handle φ anywhere" header, and the (Z1) preheader correction is in place.
`lit --filter 'loop_carried_handle'` → **7 of 7 PASS**, 0.85 s.

**(G) Things I checked and found sound, briefly.** `taintedExit` iterates **all**
exiting blocks (not just the latch) — a header-exiting tainted test is caught. (Z8)'s
reader loop correctly ignores non-φ out-of-loop users (harmless, they read handles) and
its `!taint.Tainted.count(In)` test is equivalent to "is a handle" at that point in the
pipeline. `ClassicalCallArmEmit`'s `Out` and `IOSinkLowering`'s `MuxOut` **are** the
two-X-bracketed-controlled-copy shape (P1)'s argument assumes — read at the source, not
assumed — so those two non-4.4 members of `ControlOwnedRails` are sound for (P1).
`BennettWrap` writes the disjoint `cloneTaint`, never `taint`.

**(H) Where both halves of a twin agreed, I asked separately whether the shared stream
is right (L10).** For `d4`/`k2`, `d7`/`d7u` and `c1n`/`c1nu` I read the last activation
against the analytic argument in `loopCarriedHandlePhi`'s header: the flag is minted by
a reversible template, the controlled Ry fires with the flag as **control** (diagonal in
the control basis, so it does not disturb the which-path record), the `_unc` strip's
premise holds because nothing writes the register between mint and strip, the merge
writes a **fresh** `|0⟩` rail from two X-bracketed controlled copies leaving the
previous register untouched, and the `bf` ancilla returns to `x ⊕ x = 0` before its
free. In the accepting traces **every** `cqrt_x` is on an ancilla and **every**
`cqrt_free` is of that ancilla; no user register is ever bracketed or freed. That holds
on all seven accepting twin pairs.

---

## 4. WHAT I DID NOT DO

* **No build, no relink, no full `ctest`, no `ir-pass-lit`** — per the brief. One
  `lit --filter` run (of three allowed). So **I ran no regression layer**: every ACCEPT
  and DECLINE above is a single-module measurement on the subject binary, and none of
  it is evidence about the shipped suite.
* **No corpus A/B sweep** over `ir-pass/test/*.ll` and **no twin-matrix run** — both
  would relink or contend with other work. Round 1 did the 2099-fixture A/B; I did not
  repeat or extend it.
* **No oracle binary.** Everything is measured on the subject alone, so I can say what
  the shipped compiler does and **not** what moved. Where I claim a shape is
  "pre-existing" I say which fence closes it, not which binary it moved on.
* **I did not attack**: the 512-block budget path; `MergePhiPeel` interacting with a
  carried handle; the `switch` (4.5) emitters as the latch incoming; the 7.6 tape
  `MuxOut` as a latch incoming (read the source, did not build it); a multi-latch or
  irreducible body (structurally excluded by (Z1), unverified by construction); `i64`
  and `i1` carried φs beyond (Z3)'s decline; and the second entry point
  (`CQLoweringPass.cpp:1267`) — I only exercised `run()`.
* **I did not weaponize residual escape A.** R2-1 shows the escape is real and that the
  promotion mutates through it; I could not build a module where the grant it hands out
  changes a verdict or a unitary. A third round should try the combination I ran out of
  time on: a dead carried-handle φ whose GRANT is the only thing satisfying
  `invariantRegisterRootsImpl`'s `AnyCarried` early-out, in a loop whose in-body rails
  the spine would then discharge per trip.
* **I filed nothing in `bd`** and wrote nowhere outside `round2/`.
