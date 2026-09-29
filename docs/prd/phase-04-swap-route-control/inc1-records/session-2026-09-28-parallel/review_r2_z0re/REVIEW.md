# Rule-13 review r2 — bd `test_C_libtooling-z0re`, round 2 (the implementer's fixes for r1A / r1B)

- **Subject:** worktree `agent-a284a60d747f2ed82`, round-2 commit `9a68064f` on round 1 `369c61b9`;
  diff reviewed `369c61b9..9a68064f` (source: `ArmClassify.cpp`, `AngleSelectEmit.cpp`,
  `ArmAnalysis.h`, `ControlPlan.h`; fixtures, slices, `tests/e2e/CMakeLists.txt`).
  `build/ir-pass/cq-opt` sha-256 `8441d60db8fd77b74bd7e660…`, `libCQPass.so`
  `14d57aaa6106c74246bd1bd1…` — re-hashed at the start, matching the brief.
- **Oracle:** `scratchpad/frozen/cq-opt.main_9a230646` (`3f6db37f5cf937b4d70f5736…`, re-hashed).
- **Round-1 binary** (not rebuilt — it exists): `scratchpad/z0re_bins/cq-opt.subj_v2`
  (`51b5f78d84de5c6befe82496…`, the binary r1A/r1B examined). Implementer's mutants used as-is:
  `R1_step0_rederive` `b8b4c361…`, `R2_step0_never` `9a0e8728…`, `R3_step0_always` `b269d08e…`,
  `M5_no_record_angle` `f3ed7c4e…`, `M6_no_reask` `8a211413…`.
- **Time:** about 60 minutes, load average ~100.
- **What I ran, literally:**
  - `git diff 369c61b9..9a68064f` of the four source files, read in full; the new/changed comments
    read against the code they describe.
  - `probes/run.sh` (stage 1 with `clang -O1`, 2-TU via `llvm-link` where a `.lib.c` exists; stage 2
    on each named binary; for each ACCEPT: STRICT 2b, link, run with argv) over 22 probe sources
    (§Probe index), on ORA / V2 / SUB and, where stated, on M5 M6 R1 R2 R3.
  - The implementer's `z0re_probes/minilit.py` (runs the RUN lines exactly) over the 11 fixtures the
    round-2 diff touches plus `control_angle_select_reject_runtime_base_round2_quantum.ll` and
    `control_angle_select_ry_runtime_base.ll`, on ORA / V2 / SUB.
  - `tests/e2e/run_slice.sh` with the ORACLE and with the SUBJECT on the four slices behind the two
    new identity gates.
  - `z0re_probes/foldcmp.sh` on r1A `a1/a3/a5` vs `a1legit/a3legit/a5legit`.
  - A φ-incoming-order swap of the three `…_postfold*.ll` fixtures through SUB.
  - bd `fmt3` option B SIMULATED: `probes/inc_nomerge/CQ.h` is the worktree's `CQ.h` with
    `__attribute__((nomerge))` on all 16 `cq_theta_*` declarations (checked: the attribute reaches the
    call sites, and it stops the if/else merge — `t2nm` below).
- **What I did NOT run:** no lit suite, no ctest, no corpus A/B, no mutation matrix (the implementer's
  counts are read, not re-run: lit 2430/2429+1 XFAIL, ctest 96/96 subset, A/B 0 movers r1→r2 over
  3640). **No private build and no new mutant** — the implementer's R1/R2/R3 and round-1 M5/M6 were
  sufficient to attribute every verdict I needed. No `+Asserts` build.

## Verdict: **CLEAR-WITH-ITEMS**

Round 2's code changes are behaviour-preserving where they claim to be and introduce nothing: 0 verdict
or stream movers between the round-1 and round-2 binaries on everything I ran (13 fixtures, 5 L1-route
probes, 6 r1B accept probes compared at the lowered-IR level). The L1 re-ask fires on the ANGLE-SELECT
path, not only the prep path, on every late-taint route I could reach, through BOTH sub-paths of the
new step 0. **0 P1.** One **P2**, on a sentence round 2 added: the claim that bd `fmt3` option B makes
the S3 untainted-base angle select UNREACHABLE FROM C is false — a ternary on the angle reaches it from
plain C, with or without `nomerge` (F-r2-1). The brief to this round repeats that premise. Three P3s.

## Findings

### F-r2-1 — P2 (L7), INTRODUCED by round 2 (text only; no wrong circuit): "under fmt3 option B the S3 untainted-base admission becomes UNREACHABLE FROM C" is FALSE

**Where it is stated.** `ArmClassify.cpp` S3 comment (*"⚠ UNDER bd `fmt3` OPTION B THIS WHOLE
UNTAINTED-BASE ADMISSION BECOMES UNREACHABLE FROM C (owner-accepted, 2026-09-28). The angle select
exists at all only because SimplifyCFG MERGES …"*); TRACK §R2.8 bullet 1; the retirement trigger in
`tests/e2e/CMakeLists.txt`; `control_angle_select_reject_literal_base_offwire_fold.ll` (*"what S3 owes
a hand-IR / non-C front end"*); and this round's brief (*"will make … the S3 angle select unreachable
from C"*).

**The premise is wrong.** The angle select does not exist "only because SimplifyCFG merges two
thetas". A user who writes the angle as a ternary produces the identical IR with no merge at all:

```c
int q = cq_theta(m, 0.5); int t = m + 1;
int r = cq_theta(t, (q > 3) ? 0.75 : 0.25);          // probes/src/t1.c
```

`clang -O1` gives `%5 = select i1 %4, double 7.5e-01, double 2.5e-01; cq_theta_si32(i32 %3, double %5)`
— one theta, a select on the angle, an untainted runtime base. Measured:

| probe | CQ.h | ORACLE | SUBJECT |
|---|---|---|---|
| `t1` ternary, runtime base | stock | `rotation angle` | **ACCEPT**, 10 lines, STRICT 2b `1 verified, 0 violation, 0 unproven`, trace **byte-identical to `slice_z0re_angle_select_runtime_base_exact.expected.log`** |
| `t1nm` same | **nomerge** | `rotation angle` | **ACCEPT**, identical trace |
| `t2nm` the committed if/else slice | **nomerge** | `if/else state prep allocates two rails` | same (the if/else half of the claim IS right) |
| `t3` / `t3nm` ternary, LITERAL base 6 | stock / nomerge | `rotation angle` | `rotation angle` (drbq.13's decline, reachable from plain C) |
| `t5` / `t5nm` `cq_theta((q == s) ? q : s, (q2 > 3) ? .75 : .25)` | stock / nomerge | `rotation angle` | ACCEPT, 13 lines, 2b clean: `alloc(7); ry(.25); flag; cry(.5)` |

**Why P2 and not P1.** No circuit is wrong: `t1`'s stream is the exact golden, and `t5`'s zt0b
relational fold acts on an ARG-0 SELECT, not on a theta merge — the select's value is `s` on every
branch (copying `q` when `q == s` yields `s`), so the folded module denotes the same unitary and
there is no fmt3-class hazard to fence. What is wrong is an owner-facing premise ("owner-accepted")
and three planning consequences that rest on it:

1. The S3 runtime-base admission **stays a plain-C accept surface after fmt3**; its clearance must not
   be discounted as "hand IR / future front end only".
2. At the fmt3 landing, `slice_z0re_angle_select_runtime_base{,_spec,_exact}.c` and the two gates on
   them should be **RESPELLED as ternaries** (which keep the committed goldens byte-for-byte — measured
   for `_exact`) rather than re-derived as declines; likewise r1B's C probes `as_*`, `p2as_*`, `zi*`,
   `zm*`, `a01*`, `L1as_exit`, `L7as_ff` keep their C-level coverage the same way.
3. The literal-base decline fixture's header ("what S3 owes a hand-IR / non-C front end") undersells
   it: `t3` is plain C.

**Fix:** reword the S3 comment, TRACK §R2.8, the CMake trigger and the literal-base header to "the
IF/ELSE spelling becomes unreachable; the TERNARY spelling (`cq_theta(t, c ? A : B)`) is unaffected".
Appended to bd `fmt3` and bd `z0re`.

Repro: `cd review_r2_z0re/probes/src && BINS="ORA SUB" ../run.sh t1; BINS="ORA SUB" INC=$PWD/../inc_nomerge ../run.sh t1nm; … t2nm; … t3nm; ../run.sh t5 5 7`.

### F-r2-2 — P3 (L7): F2 retirement trigger (4) states fmt3's closure in the present tense

*"The closure is bd `fmt3` OPTION B (`nomerge` on `cq_theta_*`, owner 2026-09-28), which removes the
MERGE at the C level. If `nomerge` is ever dropped from `CQ.h` …"* — at `9a68064f`, `CQ.h` carries no
`nomerge` (`grep -c nomerge include/CQ.h` → 0). The WINDOW caveat sits a paragraph earlier in the same
block, but trigger (4) read alone says the route is closed. Suggest "WILL be closed by … once it lands;
OPEN until then (the WINDOW above)". The fmt3 prediction itself holds under my simulation: r1A's
`a1/a3/a5/a6` all decline `nested control flow` on both binaries with the `nomerge` header (`nm_a*`).

### F-r2-3 — P3 (L7, overstated reason): step 0's comment calls the old re-derivation's admission a hazard

The new comment says the old spelling would have admitted a base that S3 proved TAINTED and that
became untainted by emission *"as a fresh-rail prep that no classifier accepted"*. That transition,
occurring one stage LATER (after emission, via `specialize()`'s scrub), is an accepted and pinned
stream today — `spec_angle_select_runtime_base_side_door.ll`: S3 proves the tainted base (S8/S9),
`T0` then lowers as a SOURCE, twin-identical. S3's tainted-base proof is strictly stronger than the
runtime-base admission, so the old verdict was not a hazard; the new step 0 simply makes the two
timings of one transition disagree (decline before emission, accept after). Both are unreachable or
benign, and the ONE-question refactor is right on Rule-14 grounds — only the stated reason is
overstated. Also: *"`RuntimeSeedAdmitted` is only ever set by S3's Ry stem"* is true of the
`AngleSelectRegion` kind only; F1 sets it for `StatePrep` regions (`ArmClassify.cpp:6390`).

### F-r2-4 — P3, PRE-EXISTING relative to round 2 (round-1 V2 == round-2 SUB; oracle declines too): the angle-select member of bd `nivh`

`s1C.c`: a 6.5 `%out` base (`y = 5; if (q > 3) y = f(n);`) under an angle select whose condition
(`q2 > 7`) does NOT read it. V2 and SUB decline `state prep seed became quantum`; ORACLE declines
`rotation angle`. With the record or the re-ask removed (M5 / M6) it ACCEPTS with a trace
**byte-identical** (sha `1ece5c59`) to the hand-inlined twin `s1T.c`, which ACCEPTS on all three
binaries — a realisable chained controlled Ry, so an over-decline, the same class r1A filed as
bd `nivh` for the prep. Appended to bd `nivh`. (`s1R.c`, the condition READING the base, is the real
hazard: M5/M6 accept it with `1 left dirty` template rail — the re-ask is correct there.)

## Focus items, answered

### 1. Step 0 now trusts `R.RuntimeSeedAdmitted` — every transition, and what step 0 does

Old: `UntaintedBase_emit && !(IsTheta && isRuntimeStatePrepSeed(Base, taint_emit))` → decline.
New: `UntaintedBase_emit && !R.RuntimeSeedAdmitted` → decline. They differ in exactly two cases:

- **(a) flag false, base untainted at emission, Inst/Arg int/fp** (old admits, new declines). Flag
  false on the Ry stem means S3 saw a TAINTED base, so this needs a live value to LOSE taint between
  classification and emission. I listed every `scrubTaint`/`Tainted.erase` in the ten control emitters
  (`SwapRouteEmit`, `SelectMergeEmit`, `Switch{Route,Value,DataMux}Emit`, `RegionFlatten`,
  `ClassicalCallArmEmit`, `GuardedStoreArmEmit`, `AbortParkEmit`, `AngleSelectEmit`): every one is
  scrub-then-`eraseFromParent` of the same instruction, so no live value loses taint in the window.
  Unreachable — consistent with R1/R2 surviving.
- **(b) flag true, base untainted at emission but no longer Inst/Arg int/fp** (old declines, new
  admits — this would be the drbq.13 LITERAL base getting in). Needs an emitter to RAUW an untainted
  Instruction/Argument to a `Constant` before this region emits. The nine merge-RAUW sites
  (`RegionFlatten.cpp:179`, `ClassicalCallArmEmit.cpp:275`, `SwitchValueEmit.cpp:376`,
  `SelectMergeEmit.cpp:400`, `SwapRouteEmit.cpp:585/1197/1387/1626`, `SwitchDataMuxEmit.cpp:230`) all
  replace a TAINTED merge value (a φ or select the region owns) with a tainted value; the kickback's
  re-anchor goes Constant → register, the opposite way. **Argued, not constructed.**

**The reverse transition IS reachable and is the one to watch:** flag true (untainted at
classification), base TAINTED at emission (an earlier 6.5 region RAUW'd it to `%out`). Step 0 passes
it as a register base, the Inc-2b stream is emitted over a base S8/S9 never vetted, the record is taken
ON THE FLAG, and the post-fixpoint re-ask declines. Measured on the S3 path:

| probe (angle select, base derived from a 6.5 value) | ORA | V2 | SUB | M5 no-record | M6 no-reask | R3 (decline every untainted base at step 0) |
|---|---|---|---|---|---|---|
| `s1C` direct `%out`, condition disjoint | rotation angle | seed became quantum | seed became quantum | ACCEPT | ACCEPT | **seed became quantum** → base tainted at emission |
| `s1R` direct `%out`, condition reads it | rotation angle | seed became quantum | seed became quantum | ACCEPT (1 dirty template rail) | ACCEPT | **seed became quantum** → tainted at emission |
| `s2C` volatile local | rotation angle | seed became quantum | seed became quantum | ACCEPT | ACCEPT | — |
| `s3C` opaque classical call `g(y)` | rotation angle | seed became quantum | seed became quantum | ACCEPT | ACCEPT | **control flow** → untainted at emission, tainted in round 2 |
| `s4C` store-forwarded buffer | rotation angle | seed became quantum | seed became quantum | ACCEPT | ACCEPT | — |
| `s5C` 4.4 select base | ACCEPT 21 | ACCEPT 21 | ACCEPT 21 | same | same | (tainted at round 1: Inc 2b) |

So both sub-paths of the new step 0 are exercised, the re-ask is the fence on each (M5/M6 accept), and
R1/R2 (round-1 step 0 / never decline) give the identical string on `s1C`/`s1R`/`s3C`. A peel clone
cannot be an admitted base: `MergePhiPeel` runs before detection and its select carries a tainted
compare clone, so S3 sees it tainted (flag false). A two-hop round-2-only region (`s6C`) could not be
built from C: `-O1` threads the second compare into the first arm and it declines
`value-arm swap-route` on all binaries. Re-ask slots unchanged: `CQLoweringPass.cpp:1010` (`run()`)
and `:1654` (`runOnFunction()`).

### 2. `isRuntimeStatePrepSeed` without `isa<Constant>`

Equivalent by LLVM's class hierarchy (a `Constant` is neither an `Instruction` nor an `Argument`).
Callers unchanged: F1 (`ArmClassify.cpp:5640`), the flag (`:6389`), S3 (`:9210`); the two emitters no
longer call it (`grep`: comments only). No verdict or stream moved: 13 fixtures PASS on V2 and SUB
alike; 5 r1B accepts (`as_i8`, `as_f80`, `p2as_f64`, `L2b`, `w_f64`) give **byte-identical lowered
IR** and traces on V2 and SUB. The new header's "UNPINNABLE-AND-MEANINGFUL" classification of
`!Tainted` and the type test is accurate.

### 3. The post-fold fixtures really are the legitimate program

`foldcmp.sh` re-run: `a1/a3/a5` vs their `*legit.c` differ only in the order of the merge φ's two
incomings. The offwire fixture's body is r1A's `a3.s1.ll` with `atoi` results as arguments. Swapping
the φ incoming order in all three fixtures gives byte-identical SUB output (only the ModuleID line
differs), so "the pass keys on incoming BLOCKS, not order" holds. All three FAIL on ORA, PASS on V2/SUB.

### 4. The two independent-witness gates

`run_slice.sh` with the ORACLE: `slice_z0re_runtime_seed_prep_literal` and
`slice_z0re_angle_select_runtime_base_exact_inplace` **match their committed goldens byte for byte**;
the z0re halves decline on the oracle (`state prep seed does not match the merge incoming`,
`rotation angle`). SUB matches all four. Independence: the literal witness reaches F1's LITERAL seed
clause (stage-1: `phi [ %7, %6 ], [ 6, %2 ]`), so only the admission differs and the shared
`emitInPlaceRotationRegion` output is the oracle's; the in-place witness is a genuine in-place
controlled-Ry diamond (stage-1: `cq_theta(%3, .5)` in the arm on `%3 = cq_theta(6, .25)`), a different
emitter from `emitAngleSelectRegion`. Not the new path twice.

### 5. Comments / L7 — every sentence round 2 added or changed

- F2 header, relational half "UNPINNABLE": **correct.** LLVM 19 `isImpliedCondition` for
  `RPred = EQ` with a non-constant `R1` can only answer through `isImpliedCondMatchingOperands`, i.e.
  when the branch compare's operands ARE `{V, s}`; a non-`icmp` LHS (bare rail, `fcmp`) returns
  nullopt; and `classifyArms` refuses a non-`CmpInst` condition structurally (`ArmClassify.cpp:4857`),
  not just by r1A's `e20`. The tainted operand is in `CondWire`, so with the exclusion the half is an
  equivalent mutant on every reachable input.
- F2 header, the corrected `select`-fold paragraph and the WINDOW: correct. Trigger (4): F-r2-2.
- S3 comment, "safe ONLY because" correction: correct. "UNREACHABLE FROM C": **F-r2-1**.
- `AngleSelectEmit` step-0 comment: F-r2-3. "the only taint-shrinking stage, `specialize()`'s scrub":
  true in the sense that matters (every other `Tainted.erase` in the tree is erase-paired).
- `isRuntimeStatePrepSeed` header, `ArmAnalysis.h` ("the EMITTERS do NOT call it"), `ControlPlan.h`:
  correct.

### 6. Stream moves round 1 → round 2

None found: 5 r1B accepts (lowered IR byte-identical), `s5C` and `s1T` (traces identical across ORA,
V2, SUB), 13 fixtures (same PASS set on V2 and SUB). Consistent with the implementer's 0 movers of 3640.

## Standing lessons

- **L1.** Round 2 adds no computation between the control rounds: the flag is set at classification in
  the round that emits it. The record + re-ask pair is unchanged and fires on the S3 path through both
  sub-paths of the new step 0 (table above), in both entry points (slots unchanged).
- **L2/L3.** After round 2 the flag is the only thing either emitter reads for a runtime seed: the
  prep emitter never had an admission re-derivation (`SwapRouteEmit.cpp:957-966` records on the flag
  only), and the angle-select emitter now matches it. The asymmetry that remains — step 0 still reads
  EMISSION taint for "is the base tainted?" — is deliberate and sound (a tainted base goes to the Inc-2b
  path and, if flagged, to the re-ask).
- **L4 / L5.** No walker and no shape list changed.
- **L7.** F-r2-1, F-r2-2, F-r2-3.
- **Rule 14.** Improved: one spelling of the runtime-seed question, asked at classification.
- **Rule 12.** The new IR accepts (`…runtime_base_{i8,f64}.ll`, `…postfold{,_offwire,_noread}.ll`) sit
  on predicates whose decline partners exist and still have subjects
  (`…_reject_runtime_base_round2_quantum.ll`, `…_reject_literal_base_offwire_fold.ll`, the prep
  round-2 / mismatch / quantum-incoming declines — all PASS on SUB, and the L1 ones FAIL on ORA). NEG
  prefixes are pure `CHECK-NOT`. Step 0's `!R.RuntimeSeedAdmitted` conjunct is unpinned (R2 survives)
  — recorded honestly by the implementer; case (a) above is unreachable, so Rule 12 has no subject.

## Mutants

No private build. The implementer's R0 null control exists (moves 0); I did not re-run it. I used
R1/R2/R3 and round-1 M5/M6 as ATTRIBUTION instruments: R3 tells which sub-path of step 0 a probe takes,
and M5/M6 show the record and the re-ask are the fence on the S3 path (all five route probes flip to
ACCEPT without either). No conjunct was added in round 2 besides the flag read, so no new
delete-one-conjunct mutant was owed.

## Composition

- **z0re × bd fmt3 option B** (lands after z0re): simulated with `probes/inc_nomerge/CQ.h`. The if/else
  C slices decline (`t2nm`), r1A's fold probes decline `nested control flow` (`nm_a1/a3/a5/a6`), the
  runtime-seed prep slice keeps its golden byte-for-byte (`t4nm`) — all as round 2 predicts — and the
  TERNARY angle select is unaffected (`t1nm`, `t5nm`), which round 2 does not predict (F-r2-1).
- **z0re × rhk5** (lands before z0re): not re-measured here; r1B's `k3C` is the program the
  orchestrator owes on the composed binary (TRACK §R2.5).

## Attacked and NOT broken

- Every transition of the step-0 refactor (§1), with the reverse transition constructed and caught on
  five routes; the two divergent cases argued unreachable from the emitter inventory.
- The `isa<Constant>` removal (§2): equivalence by class hierarchy, 0 movers measured.
- The post-fold fixtures' "legitimate program" ground, including φ-order insensitivity (§3).
- The independence of both new witnesses, reproduced with the oracle (§4).
- Every round-2 comment for truth (§5); the relational half's "unpinnable" claim against LLVM 19's
  `isImpliedCondition`.
- The zt0b relational fold via an arg-0 select into a ternary angle select (`t5`): sound — no in-place
  rotation exists in the source.

## Probe index (`probes/src`, runner `probes/run.sh <name> [argv…]`, `BINS=` / `INC=` env, outputs in `probes/out`)

`s1C s1R s2C s3C s4C s5C s6C` + twins `s1T s6T` (angle-select L1 routes) · `t1 t2 t3 t5` and their `*nm`
copies (ternary vs if/else, stock vs `nomerge` `CQ.h`) · `t4nm` (prep slice under `nomerge`) ·
`nm_a1 nm_a3 nm_a5 nm_a6` (r1A fold probes under `nomerge`) · `b_as_i8 b_as_f80 b_p2as_f64 b_L2b
b_c4bool b_w_f64` (r1B probes, round-1 vs round-2) · `pf_postfold{,_offwire,_noread}{,_swap}.ll`
(φ-order swap) · `inc_nomerge/CQ.h`.
