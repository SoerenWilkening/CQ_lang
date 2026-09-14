# Track D — ADVERSARIAL REVIEW round 1 (Rule 13), bd `3d8q` — the STALE-READER fence

**Reviewer:** independent; did not write the code. **Round:** 1 of a ≥2-round budget.
**Verdict: NOT CLEAR.** One over-ACCEPT in the unforgivable class (F-D1-1), in the new fence's own
exemption mechanism, on the simplest in-loop spelling of the defect this increment exists to close.
Four further items below. The `g2_measure_parent` deviation is adjudicated **in the implementer's
favour** (§Deviation).

## 0. First act — binary identity (brief's STOP condition)

```
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_3d8q/build/ir-pass/{cq-opt,libCQPass.so}
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}
```
| | measured | brief |
|---|---|---|
| SUBJECT `cq-opt` | `7fe2bcbfb6c9712613952e6db33ab36dc3525275af99109cf0edfe4ea112fb23` | match |
| SUBJECT `libCQPass.so` | `4f73e1c8cb5f59244a6e0cfad17682c75c5b60926223ba5fc9e252d6b0b9e4c0` | match (prefix) |
| ORACLE `cq-opt` | `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc` | match |
| ORACLE `libCQPass.so` | `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d` | match |

All four match. Proceeded. Every ORACLE-vs-SUBJECT row below is a statement about the edits alone.

Probes: `$SES/trackD/review_r1_probes/` (`m.sh`, `src/`, `s1/`, `ORACLE/`, `SUBJECT/`, `fx/`, `e2e/`).
`m.sh` generates stage 1 ONCE per probe and feeds the SAME `.ll` to both binaries, and **refuses to
measure a zero-byte `.ll`** (the passthrough trap the brief names). No probe was skipped for that reason.

---

## F-D1-1 — OVER-ACCEPT / SILENT MISCOMPILE. A loop body with EXACTLY ONE `cq_theta` on a loop-INVARIANT quantum name still compiles, emitting a stream byte-identical to a different, well-formed program

**Severity: over-ACCEPT / silent miscompile — the unforgivable class.** This is bd `3d8q`'s own
signature, in its simplest in-loop spelling, surviving the fence built to close it.

### Probe

`review_r1_probes/src/r5_inloop_invariant_seed.c`

```c
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int b=cq_theta(q,0.1); s+=cq_measure(b); } return s; }
```

`q` is **loop-invariant**. At trip 2 the name `q` denotes `Ry(.3)|0>` while the register holds
`Ry(.4)|0>`; at trip 3, `Ry(.5)|0>`. Three different states of one register, named by one consumed
name — a no-cloning request (Rule 8), and `CLAUDE.md`'s own CORRECTNESS RISK §2 rail-staleness rule
verbatim: *"a rail member may be read only where no rail-relabelling gate (Ry …) executes between the
record's definition and the read **without that definition re-executing**."* The trip-1 gate executes
between `%1`'s definition and the trip-2 read, and `%1` never re-executes.

### Commands and both verdicts

```
cd $SES/trackD/review_r1_probes && ./m.sh src/r5_inloop_invariant_seed.c src/r5t_selfassign_twin.c
```
```
r5_inloop_invariant_seed | O=A[trace=8] | S=A[trace=8] |      <-- UNCHANGED. The fence never fires.
r5t_selfassign_twin      | O=A[trace=8] | S=A[trace=8] |      <-- a DIFFERENT, well-formed program
diff SUBJECT/r5_inloop_invariant_seed.trace SUBJECT/r5t_selfassign_twin.trace
*** TRACES BYTE-IDENTICAL ***
```

`r5t` is `for(...){ q=cq_theta(q,0.1); s+=cq_measure(q); }` — the self-assigned chain. **Two different
programs, one circuit**, `opt` exit 0, verify-clean. That sentence is this project's own definition of
the defect (bd `3d8q` description; `review_1b_r2.md` §F-1b2-1).

Emitted stream (SUBJECT, `SUBJECT/r5_inloop_invariant_seed.trace`):
```
cqrt_alloc_i32(0) -> h0
cqrt_ry_i32(h0, 0x1.3333333333333p-2)        ; the .3 seed
cqrt_ry_i32(h0, 0x1.999999999999ap-4)        ; .1  — trip 1
cqrt_measure_i32(h0) -> 0
cqrt_ry_i32(h0, 0x1.999999999999ap-4)        ; .1  — trip 2, on a register the source says is |psi_q>
cqrt_measure_i32(h0) -> 0
cqrt_ry_i32(h0, 0x1.999999999999ap-4)        ; .1  — trip 3
cqrt_measure_i32(h0) -> 0
```
One rail, chained — the compilation of `r5t`, not of `r5`.

### Population — measured, 4 accept / 2 decline, which isolates the mechanism

| probe | shape | ORACLE | SUBJECT |
|---|---|---|---|
| `r5_inloop_invariant_seed.c` | one in-loop theta on an invariant seed | A 8 | **A 8 — MISS** |
| `r5a_while_runtime_trip.c` | same, RUNTIME trip count | A 8 | **A 8 — MISS** |
| `r5b_invariant_template_seed.c` | same, seed is a TEMPLATE rail (`q&1`) | A 9 | **A 9 — MISS** |
| `r5d_invariant_seed_measure_only.c` | same, the measure is AFTER the loop | A 6 | **A 6 — MISS** |
| `r5c_invariant_two_siblings.c` | **two** in-loop thetas on the invariant | A 15 | D (new string) ✔ |
| `r5e_nested_invariant.c` | two loops, one theta each, same invariant | A 10 | D (new string) ✔ |

The fence catches the shape the moment a **second** gate exists and misses it when the reader is its
own only staler. `r5c` is `l1_inloop_sibling_invariant.c` minus the compare and the `cq_phi` — i.e. the
implementer's own moving in-loop member differs from the miss by one extra sibling.

### Root cause — the `Self`/`Covered` self-exemption is unconditional and is tested BEFORE the harmlessness proof

`OpcodeLowering.cpp::recordStaleQuantumReaders` builds `Self = {I}` for every `cq_theta_` reader and
passes it as `Covered`. In `WireWalk.cpp::walkNonDiagonalWireGates`:

```cpp
if (Exempt.count(CI)) continue;
if (Covered && Covered->count(CI)) { Work.push_back(CI); continue; }   // <-- before gateIsHarmless
... gateIsHarmless(EmitPoint, CI, Seed, Seeds, *DT, RequireEmitDominance) ...
```

Traced on `r5`'s stage-1 IR (`s1/r5_inloop_invariant_seed.ll`: `%1 = cq_theta(0,.3)` in entry,
`%6 = cq_theta(%1,.1)` in the body, `%7 = cq_measure(%6)`):

* reader `%6`, record operand `%1`. Backward closure: `%1`'s arg-0 is the constant `0` -> break;
  `Exempt = {%1}`. Forward from `%1`: its **only** user is `%6`, which is in `Covered` -> skipped as
  evidence, pushed to Work. Forward from `%6`: only `%7`, not a gate. **No candidate -> ACCEPT.**
* reader `%7`, record operand `%6`: ancestry `{%6,%1}` all `Exempt` -> no candidate -> ACCEPT (correct;
  `%7` reads the current trip's own result).

So the **only** staling gate in this program is the reader's own **previous dynamic instance**, and
`Covered` exempts it by **SSA identity**, unconditionally. `Covered`'s contract was written for Track
A.1 ("a gate the CALLER has already ruled on"), where the caller really had ruled on it. For the new
reader policy the claim "already ruled on" is false in exactly one direction: the reader has not been
ruled on **against itself at a previous iteration**.

This is **L2 in the standing lessons**: a set was widened (the swept-instruction set) and a second set
computed over the same closure (the exemption set) was not re-derived for the new members.

### Minimal fix

Ask the self-gate the **same** question every other gate is asked — no new relation (Rule 14).
In `recordStaleQuantumReaders`, replace the unconditional `Self.insert(CI)` with:

```cpp
// Grant the self-exemption only where the reader provably cannot re-execute against the
// same record. The reader IS a gate on its own wire; in a loop whose seed is not
// re-established per trip, its PREVIOUS instance stales this instance's read.
if (SelfCI && gateIsHarmless(&I, SelfCI, Rec, ArrayRef<Value *>(Rec), *DT,
                             /*RequireEmitDominance=*/false))
  Self.insert(SelfCI);
```

Hand-traced against `gateIsHarmless` as shipped (`WireWalk.cpp`), for every family the increment pins:

| shape | leg | result |
|---|---|---|
| `r5` (invariant seed, in loop) | leg 1 fails (`isPotentiallyReachable(%6,%6)` true via the back edge); `SeedDef = %1`, not a phi, `Barriers={%1}`; `reachesWithoutBarrier(%6,%6,{%1})` **true** | **not harmless -> DECLINE** ✔ |
| `r5t` / `lowering_stale_reader_postloop_measure_accept.ll` (phi-carried) | leg 1 fails; `SeedDef` is the header phi, `phiTracksWire` true -> barrier on every back-edge path -> `reachesWithoutBarrier` **false** | harmless -> **ACCEPT** ✔ |
| straight-line chain (`r8`, `f1w2`) | `isPotentiallyReachable(I,I)` false -> leg 1 | harmless -> **ACCEPT** ✔ |
| exclusive arms (`lowering_stale_reader_exclusive_arms_accept.ll`, the 14 drbq fixtures) | not in a loop -> leg 1 | harmless -> **ACCEPT** ✔ |
| in-loop controlled-Ry arm (the 12 `control_inplace_ry_inloop_*`) | seed is the header phi -> barrier | harmless -> **ACCEPT** ✔ |

**Caveat the implementer must honour:** `Covered`'s other half is "walk THROUGH it". When the
exemption is withheld the self-gate must be **returned as the staler**, not merely walked through — do
it by not inserting into `Self` (as above), never by weakening the `Covered` contract inside the walker,
which Track A.1 owns. `gateIsHarmless` has external linkage but may need a `WireWalk.h` declaration.

**I could not build or run the suite (brief), so this fix is traced, not measured.** It must be
re-measured across `ir-pass-lit` and specifically against those 26 in-loop / exclusive-arm fixtures.

### Ancillary facts worth carrying

* **No fixture pins either disposition of this shape.** `lowering_stale_reader_postloop_measure_accept.ll`
  uses the **phi-carried** form (`%rm = cq_theta(%r,.9)`, `%r` the header phi), which the fix keeps as an
  ACCEPT. The invariant-seed form appears in no fixture, in either direction.
* The accept fixture's own header already contains the reasoning that condemns `r5`: *"the header phi
  that IS the barrier has been replaced by the **loop-INVARIANT preheader mint** and this module
  declines."* Exactly so — when the walk reaches `gateIsHarmless` at all. In `r5` it never does.
* `LoopLowering::staleRailRecordRead` does not cover it either: it is invoked from the rail-collapse
  paths (`LoopLowering.cpp:2304, 2693`) and `r5` has no quantum rail phi to collapse. The pass-wide
  backstop is the correct owner; this is not a missing specialised fence.

---

## F-D1-2 — OVER-ACCEPT (latent) + Rule 1 "no third path". The `WeakTrackingVH` drain conflates ERASURE with RAUW, and has three outcomes where the code and all three comment blocks enumerate two

**Severity: over-ACCEPT (latent) / documentation.** Not demonstrated on a reaching program; the
mechanism is read off the LLVM 19 header and the shipped drain.

LLVM 19 `llvm/IR/ValueHandle.h:197-203`:

> `WeakTrackingVH` — *"Value handle that is nullable, but tries to track the Value. This is a value
> handle that tries hard to point to a Value, **even across RAUW operations**, but will null itself out
> if the value is destroyed."*

`declineRecordedStaleQuantumReaders`:
```cpp
for (WeakTrackingVH &VH : taint.StaleQuantumReaders) {
    auto *I = dyn_cast_or_null<Instruction>(VH);
    if (!I || taint.StaleDeclined.count(I)) continue;
    diagnoseStaleQuantumReader(I);
```
Three outcomes, not two:
1. **valid original** -> diagnose. Intended.
2. **null** (destroyed) -> skip. Intended, and the comment's claim ("an owner claimed and PROVED the
   shape") is an unproven universal, but a defensible one.
3. **RAUW'd** -> the handle now points at a **different value**, and nothing in the drain can tell.
   * replacement is an `Instruction`: `diagnoseStaleQuantumReader` fires on the **wrong instruction** —
     a loud decline with a `!dbg` from an unrelated site. IMPL_D §7b's anchor table cannot see this:
     every probe in it declines on an instruction no emitter touched.
   * replacement is a non-`Instruction` (`Constant`, `Argument`, `poison`): `dyn_cast_or_null` returns
     null and the recorded decline is **dropped silently** — an over-ACCEPT with no diagnostic anywhere,
     which is precisely the Rule-1 "no third path" failure that has been hit once before and was found by
     review, not by the suite.

Between the two slots the pass RAUWs freely (`emitInPlaceRotationRegion`'s M-alpha/M-beta,
`MergePhiPeel`, `liftOneRegisterMergePhi`, `SelectMergeEmit`). Whether any of them RAUWs a *recorded
reader's own result* is the open question.

**What I probed, and what it showed (all A/A or correct D, no drop demonstrated):**
```
./m.sh src/r20_vh_inplace_arm_erases_reader.c src/r20b_vh_control_no_erase.c \
       src/r21_vh_flat_arm_stale.c src/r22_stateprep_stale_seed.c src/r23_angle_select_stale_base.c
r20_vh_inplace_arm_erases_reader | O=D[stale rail record read past a controlled Ry] | S=D[same]
r20b_vh_control_no_erase         | O=A[7] | S=A[7]
r21_vh_flat_arm_stale            | O=A[6] | S=D[rotation/measure operand predates a non-diagonal gate]
r22_stateprep_stale_seed         | O=D[state prep merged with a quantum register] | S=D[same]
r23_angle_select_stale_base      | O=A[6] | S=D[rotation/measure operand predates a non-diagonal gate]
```
The in-place-arm and state-prep shapes are claimed by **earlier owners with their own stale fences**
(exactly as the design intends); the compare-arm and folded-angle-select shapes decline correctly on the
new string. So the intended path holds in the five shapes I could construct.

**Minimal fix** (cheap, strictly safe, and makes outcome 3 impossible to miss): record the identity
beside the handle and separate the three cases —
```cpp
// erased  => an owner claimed and proved the shape: skip.
// RAUW'd  => NOT the same claim. Nobody proved anything; decline loudly.
for (auto &[VH, Orig] : taint.StaleQuantumReaders) {
  if (!VH) continue;                                   // destroyed
  auto *I = dyn_cast<Instruction>(static_cast<Value *>(VH));
  if (!I || I != Orig) { diagnoseStaleQuantumReaderRAUW(Orig); continue; }   // loud, never silent
  ...
}
```
At minimum, the three comment blocks (`TaintPropagation.h`, `OpcodeLowering.cpp`,
`CQLoweringPass.cpp` x2) must stop saying "a nulled entry is the only other case".

---

## F-D1-3 — RECORD HYGIENE. `TaintSet::StaleQuantumReaders`' header comment documents a residual the shipped code CLOSES, and forbids the fix the shipped code IMPLEMENTS

**Severity: documentation/record hygiene.** No behaviour change, but Rule 0/11: future agents depend on
these blocks, and this one is now false in both halves.

`ir-pass/include/TaintPropagation.h`, in the block added by this increment:

> *"⚠ RESIDUAL, filed rather than hidden: the analysis runs at ROUND-1 taint, so a reader whose operand
> becomes tainted only at the round-2 fixpoint (a 6.5 / 4.5 merge `%out` rail) **is not adjudicated**.
> That is a MISS of the 3d8q class … **Re-asking it after the fixpoint is NOT a fix** …"*

The shipped code re-asks it, delta-scoped, from `adjudicateTaintDelta`
(`TaintPropagation.cpp:1649`), and IMPL_D §4 records that this was **finding F-5**, the change that
took the last two accepts (`S03_stale_mux_sibling.c`,
`control_swap_select_cmp_round2_window_accept.ll`) to DECLINE. I re-measured a round-2 customer myself:

```
./m.sh src/r32_delta_s03_chain.c
r32_delta_s03_chain | O=A[trace=36] | S=D[cq opcode lowering: rotation/measure operand predates a non-diagonal gate]
```

A reader of this paragraph will believe a hole is open that is closed, and that the mechanism in front
of them is forbidden. **Fix:** replace the paragraph with the delta-scoped design, keeping only the true
half — *a **FULL** re-sweep after the fixpoint is not the fix, because `lowerLoops` has already run.*

---

## F-D1-4 — FIXTURE HYGIENE. `diagnosePreLoopCommitStale` now has ZERO positive pins, and the compensating enumeration has a named gap

**Severity: fixture hygiene (Rule 12(c)).** Disclosed by the implementer (IMPL_D §8, follow-on #3) with
the argument **explicitly labelled a plausibility argument, not a measurement** — the disclosure is
exemplary and I am not re-litigating it. Two things I can add.

**Measured.** The string `pre-loop in-place op no longer provable at lowering` is carried by exactly
**8** fixtures, **all 8 as `-NOT` directives**, **0 positive `CHECK`**:
```
grep -rn 'pre-loop in-place op no longer provable' ir-pass/test/*.ll     # 8 hits, all "NOROUTE-NOT:"
grep -c 'CHECK.*pre-loop in-place op no longer provable' <each>          # 0, 0, 0, 0, 0, 0, 0, 0
```
So the predicate is unpinned in the positive direction, exactly as recorded.

**The gap in the enumeration.** The compensating argument is that every program reaching the tripwire
must contain *"a `cq_theta`/`cq_measure` reader (this fence), a pure op (`declineStaleRecordOps`) or an
escape (`declineTaintEscapes`) — all three earlier."* That enumerates the ways an **extra use of the
RAUW'd wire** can arise. But `classifyInPlaceReassignment`'s G2 can also fail under FINAL taint for a
different reason the tripwire's own neighbouring comment names: *"the classical immediate that stopped
being classical"* — a **taint-GROWTH** event, not a stale read, and none of the three earlier owners is
the natural claimant of it. I did **not** falsify the argument (the shape needs the eqpx construction and
I had no build), so this stays an item; but the enumeration should not be read as exhaustive when it is
known not to cover G2's other failure mode.

The fixture's own RETIREMENT TRIGGER is correctly written and should stand.

---

## F-D1-5 — ITEM (strengthening, not a defect). The `Delta` scope's DIRECT sub-case is sound — I closed it by exhaustive trace; the residual is the ROUTING sub-case, and it leans on a DIFFERENT fence

The brief's item 1 asks for the probe the implementer could not build. I could not build it either — but
I can now say **why**, which is more than "unfalsified".

The delta filter is on the **record operand**: `if (Delta && !Delta->count(Rec)) continue;`. A
`cq_theta` result is tainted from round 1 unconditionally (it is the sole taint SOURCE), so any reader
whose operand is a theta result is **never** in the delta. The round-2 hop that matters is the
**backward** one — `Taint->Tainted.count(Arg0)` in the ancestry closure — since the forward walk needs
no taint at all. Enumerating what round 2 can therefore add to a reader's closure:

1. **a direct reader of the newly-tainted parent `P`** — it is in the delta, so it IS analysed; and for
   any pair of readers of `P`, whichever runs **second** fails leg 1 (`isPotentiallyReachable` holds)
   and then leg 2 (`P`'s def precedes both, so no barrier lies between them) and **declines**. Both
   orders checked by hand and corroborated: `r31_delta_direct.c`, `r32_delta_s03_chain.c` (the latter
   A -> D on the new string). **Closed.**
2. **a gate behind another gate** — that is a CHAIN, and the round-1 **forward** walk from the reader's
   own operand already reaches it with no taint-gated hop (this is `g1`/`f1w`, which move). **Closed.**
3. **a gate behind a ROUTING node** (`phi`/`select`) that is itself tainted at ROUND 1 via a different
   incoming — then that gate's record operand is the routing node, not `P`, so it is **not** in the
   delta, and the reader is not either. **This is the one residual.**

Sub-case 3 requires a live `phi`/`select` over tainted data with heterogeneous incomings — which
`declineClassicalMuxes` refuses, or the one-register merge-phi lift claims (in which case every incoming
is the same register and the closure is the same wire anyway). So the delta scope is probably sound —
**but its soundness is now partly carried by `declineClassicalMuxes`, and nothing records or pins that
coupling.** That is L3-shaped (a second predicate now names part of this fence's obligation) and should
be written into the source comment rather than left as an inference.

My two probes for sub-case 3 both died at an earlier owner, as the implementer's did:
```
./m.sh src/r30_delta_routing.c src/r31_delta_direct.c
r30_delta_routing | O=D[cq controlled lowering: control flow under quantum control] | S=D[same]
r31_delta_direct  | O=D[cq controlled lowering: control flow under quantum control] | S=D[same]
```
(my 6.5-arm spelling is not a claimable region, so these two are **inconclusive**, not clean.)

---

## Deviation (brief item 4) — VERDICT: the implementer is RIGHT. `g2_measure_parent` must DECLINE; BRIEF_D.md §3 carries the wrong record

Adjudicated on the unitary, as instructed.

```c
int q = cq_theta(0,0.3);   /* rail R := Ry(.3)|0>                          */
int a = cq_theta(q,0.5);   /* in-place Ry(.5) on R; R := Ry(.5)Ry(.3)|0>   */
return cq_measure(q) + a;  /* the source names Ry(.3)|0>                   */
```

**Does measuring the PARENT name after a child rotation name a state the register no longer has?
Yes.** `q` denotes `Ry(.3)|0>`; at the measurement the register holds `Ry(.8)|0>`. These are different
states with different computational-basis distributions under any Ry convention, because `.3 != .8`.
The emitted circuit measures the post-`.5` state while the source asks for the pre-`.5` one, silently.
That is the miscompile, not a naming nicety. The legal spelling of "measure the register" is to measure
the **live** name — which is `f1w2_chain_measure_twice.c`, and it stays ACCEPT (measured below).

**Measured parity, which settles it independently of any record:**
```
./m.sh src/r9_g2_measure_parent.c src/r9b_g2_pureop_twin.c src/r8_tip_measure_twice.c
r9_g2_measure_parent | O=A[trace=5] | S=D[cq opcode lowering: rotation/measure operand predates a non-diagonal gate]
r9b_g2_pureop_twin   | O=D[cq opcode lowering: operand predates a non-diagonal gate] | S=D[same]
r8_tip_measure_twice | O=A[trace=6] | S=A[trace=6]
```
`r9b` is `g2` with `cq_measure(q)` replaced by `q+1` — **the identical wire question** — and it has
declined **on the ORACLE**, i.e. since Phase 5. A compiler in which `q+1` on a consumed `q` is refused
and `cq_measure(q)` on the same consumed `q` is accepted is not exact; it is the exact asymmetry
bd `3d8q`'s root-cause paragraph names.

**Which record is wrong.** Not bd `3d8q`'s sentence — **BRIEF_D.md §3's attribution of it.** The
primary source is `review_1b_r2.md` (session-3qlq4), and it says both things unambiguously:

* its **boundary table** (§F-1b2-1, "The exact boundary, measured") lists
  `` | `f1`, `g1`, `g2_measure_parent.c` | a **`cq_measure` sink** | **ACCEPT** | `` in a table whose
  first two rows are the *correct* declines — i.e. `g2` is enumerated **among the defective accepts**,
  beside `f1` and `g1`, which everyone agrees must move;
* its hand-trace of the intended fix reads: *"`cq_measure(%b)` in the well-formed chain, seed `%b`:
  ancestry `{%b,%a,%q}` all `Exempt` -> **ACCEPT**"* — ancestry `{%b,%a,%q}` means `%b` is the chain's
  **TIP**. That is `f1w2_chain_measure_twice.c`, and it accepts (measured, 6 lines, unchanged).

bd `3d8q`'s compressed *"the well-formed chain and `cq_measure(b)` on it stay ACCEPT (ancestry exempt)"*
is a faithful summary of that TIP bullet. **BRIEF_D.md §3 re-attached the sentence to
`g2_measure_parent`, which is a PARENT measure, not a tip measure, and to which the ancestry exemption
does not apply** (the staler `a` is a descendant on the forward wire, not an ancestor). The transcription
slip is the brief's; the implementer's reading and their deviation are correct.

**Recommendation: keep the DECLINE; do not take the one-line revert.** Amend BRIEF_D.md §3 and add a
line to bd `3d8q` so the ambiguity cannot be re-inherited: *"`cq_measure` of the chain TIP stays ACCEPT
(`f1w2`); `cq_measure` of a CONSUMED PARENT declines (`g2_measure_parent`) — the pure-op twin has
declined since Phase 5."*

---

## Non-findings — the brief's items I verified rather than restated (Rule 11)

| # | claim | how I checked | result |
|---|---|---|---|
| 7 | the two fixtures adjudicated "by one operand" emit BYTE-IDENTICAL streams | old text @ORACLE vs new text @SUBJECT, sha-256 over the lowered IR with `ModuleID`/`source_filename` stripped (`fx/`) | **VERIFIED.** `control_inplace_ry_stateprep_fcmp_oeq_twin` `8b4a37ac8b913913` == `8b4a37ac8b913913`; `..._deadgate_leak_control` `c1a878cf4be2920f` == `c1a878cf4be2920f`. Source delta is one operand each (`%t`->`%rt`, `%3`->`%20`). And the **OLD text genuinely declines on the SUBJECT** with the new string, so both edits were forced, not cosmetic. |
| 6 | `p07_chained_after` / `ProvenPostRegion` survives (bd `3d8q` names it) | `./m.sh src/r13_p07_chained_after.c` | **A 5 / A 5**, unchanged. |
| 6 | the fence is exact in the over-DECLINE direction | 8 hand-built well-formed programs: read-before-gate (`r1`), measure-then-extend (`r2`), two independent rails (`r3`), in-loop measure-then-rotate on a carried phi (`r4`), pre-loop read + in-loop chain (`r6`), template parent (`r7`), tip measured twice (`r8`), post-loop measure (`r11`) | **8/8 A/A, identical trace counts. No over-decline found.** |
| — | "ZERO `e2e/` movers", the load-bearing number | targeted sample of **40** `tests/e2e/*.c` (every slice matching `chain|inplace|loop|grover|cascade|stale|rotate|measure|theta`), both binaries, verdict + sha-256 of lowered IR (accepts) + md5 of stderr (declines) | **0 movers, 0 stream/stderr differences.** Corroborated on a sample. Not the `^e2e-` gate. |
| — | the 9 new fixtures pin what they claim, on the binary under review | each run directly through `build/ir-pass/cq-opt` + `FileCheck` (not lit) | 6 negatives `opt` exit 1 + FileCheck PASS; 3 accepts exit 0 + FileCheck PASS. |
| 7b | the `!dbg` anchor survives the deferral | 4 declines I built myself, `-O1 -g` | `r5c…c:4:31`, `r21…c:4:15`, `r9…c:3:70` real `file:line:col`; **no `<unknown>:0:0`**. ⚠ minor: `r23_angle_select_stale_base.c:4:0` reports **column 0** — a real line, a lost column, on the folded-angle-select path. Worth one line in the record, not a finding. |

---

## What I did NOT examine

* **No build of any kind** and **no full suite** (brief). Every fix I propose is **traced, not measured**.
* **No corpus sweep** and **no twin matrix** (brief; one of each is in flight elsewhere). I therefore did
  **not** verify the 3093-row / 43-mover table, the 1935-pass lit figure, the `--regenerate`-not-run
  claim, or the twin-matrix prediction. The 40-slice e2e sample and the 9-fixture direct run are samples,
  and I report them as samples.
* **No injection/mutation matrix.** The "36 mutations, 0 MISSED" and the "8 MISSED, pre-existing on the
  ORACLE" figures are unverified by me.
* **`runOnFunction` twin-pipeline parity** checked only by **reading** the diff (both calls appear in both
  entry points at the mirrored slots); not executed.
* I read `OpcodeLowering.cpp`, `WireWalk.{h,cpp}`, `TaintPropagation.{h,cpp}` and `CQLoweringPass.cpp`
  diffs in full, and 3 of the 14 touched fixtures in full; the other 11 only as diffstat + the two
  converted ones.
* **F-D1-2 is not demonstrated on a reaching program** — only on the LLVM 19 header semantics plus the
  drain as written. **F-D1-4's plausibility argument is not falsified**, only narrowed.
* No lit invocation produced usable output; I ran the fixtures through `cq-opt`+`FileCheck` directly
  instead, so my **one permitted lit re-run is unspent**.

---

## Verdict and round budget

**NOT CLEAR.**

| # | severity | one line |
|---|---|---|
| **F-D1-1** | **over-ACCEPT / silent miscompile** | a loop body with exactly ONE `cq_theta` on a loop-invariant quantum name still compiles, byte-identical to a different well-formed program; `Self`/`Covered` exempts the reader's own previous dynamic instance unconditionally |
| **F-D1-2** | over-ACCEPT (latent) / Rule 1 | the `WeakTrackingVH` drain reads ERASED and RAUW'd as the same thing; a RAUW to a non-`Instruction` drops a recorded decline with no diagnostic anywhere |
| **F-D1-3** | record hygiene | `TaintSet::StaleQuantumReaders`' comment documents a residual the code closes and forbids the mechanism the code ships |
| **F-D1-4** | fixture hygiene | `diagnosePreLoopCommitStale`: 8 `-NOT`s, 0 positive pins; the compensating enumeration does not cover G2's taint-growth failure mode |
| **F-D1-5** | item (strengthening) | the Delta scope's direct sub-case is closed by exhaustive trace; the residual routing sub-case leans on `declineClassicalMuxes`, unrecorded |

F-D1-1 alone is disqualifying: it is the unforgivable class, it lives in the fence's own exemption, and
the shape is the plainest thing a user writes when they mean "rotate this register a bit each trip" —
a Grover-style repeated-oracle loop written with a fresh name compiles to the wrong circuit today, and
still does after this increment.

**The increment is nonetheless close, and the direction is right.** 14 reproducers move, the must-not-move
set held under my own independent sampling, the two forced fixture edits are byte-identical as claimed,
no over-decline turned up in 8 hand-built well-formed programs or 40 e2e slices, and the one flagged
deviation is correct on the unitary. The two halves / two slots design is well argued and the honest
self-reporting in IMPL_D §9 is what made this round efficient.

**Round 2 is WARRANTED, on four things:**
1. **the F-D1-1 fix, and its re-measurement** — specifically the 12 `control_inplace_ry_inloop_*` /
   `control_swap_inloop_*` and the 14 exclusive-arm fixtures, plus a NEW decline fixture for the
   invariant-seed shape and a NEW accept fixture for the phi-carried twin (neither disposition is
   pinned today), plus the e2e and twin-matrix layers, since this moves an in-loop disposition;
2. **F-D1-2's drain** — either construct a reaching RAUW or implement the identity check, which is
   cheap enough that "could not construct" should not be the disposition;
3. **the routing sub-case of the Delta scope** (F-D1-5), by someone who can build — the coupling to
   `declineClassicalMuxes` wants a written argument or a pin;
4. **a re-run of the r5 family after any fix** — `r5`, `r5a`, `r5b`, `r5d` must move, and `r5c`, `r5e`,
   `r5t`, `r1`–`r4`, `r6`–`r8`, `r11` must not. The probes and `m.sh` are in
   `$SES/trackD/review_r1_probes/` for exactly that.

Given the measured hit rate `CLAUDE.md` Rule 13 records — and that F-D1-1 was found in round 1 in the
area the implementer themselves pointed at (§9 item 3, "leg 2 with a non-phi loop-invariant seed …
reachable for the first time") — **budget round 3 as well, and expect the fix itself to need one.**
