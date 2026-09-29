# Rule-13 review r1A — bd `test_C_libtooling-z0re`, Surface A (F1 runtime seed · relational F2 · L1 re-ask)

- **Subject:** worktree `agent-a284a60d747f2ed82`, commit `369c61b9`, diff `9a230646..369c61b9`.
  `build/ir-pass/cq-opt` sha-256 `51b5f78d84de5c6befe82496…` and `libCQPass.so` `fe42a1e8ad49bb261e64c86c…`,
  both re-hashed at the start of the round and matching the brief.
- **Oracle:** `scratchpad/frozen/cq-opt.main_9a230646` (`3f6db37f5cf937b4d70f5736…`, re-hashed).
- **Time:** about 95 minutes, under a load average of 230–340 from other agents.
- **What I ran:**
  - `git diff` of the 8 source files, read in full.
  - `clang -O1 -mllvm -print-pipeline-passes`, re-measured: no `gvn`, `newgvn`, `jump-threading`
    or `correlated-propagation`. It does contain 1× `ipsccp`, 1× `sccp`, 2× `early-cse`, 8× `instcombine`,
    `indvars`, `licm`, `reassociate`, `simple-loop-unswitch<trivial>` and 8 `simplifycfg` variants.
  - 45 probe modules, run through `probes/run.sh`. It runs stage 1 on the probe (2-TU via
    `llvm-link` when a `.lib.c` exists), then stage 2 on the ORACLE and on the SUBJECT. Every ACCEPT
    then gets STRICT 2b, a link, and a run with runtime argv values. Twins are compared by trace `cmp`.
  - One red-green spot-check, on `control_inplace_ry_reject_stateprep_runtime_seed_round2_quantum_from_c.ll`
    with the fixture's own RUN line and FileCheck. The subject PASSES. The oracle FAILS, declining with
    the F1 string.
- **What I did NOT run:**
  - No lit, no ctest, no corpus A/B, no allocator sweeps (the brief says not to repeat the
    implementer's sweeps).
  - **No mutant build.** At a load of about 330, one private build of `cq-opt` was not affordable. §4
    gives a conjunct-by-conjunct equivalence argument instead, and I say which conjuncts no fixture
    can pin.
  - No `+Asserts` build.

## Verdict: **CLEAR-WITH-ITEMS**

The change does what it says, and the L1 re-ask holds against every route I tried: 6.5 `%out`,
a derivative through memory, a volatile local, an opaque call, a 4.4 select, and a loop-carried
header φ. **0 P1 INTRODUCED.** There is **one P1 PRE-EXISTING** on the same fence family (F2), and
it bears directly on the drbq.13 reasoning in this change: bd `fmt3`, F-r1A-2. Two P2s are about
stated reasons that are false, and one of them comes with a reachable population the widening adds.
There are five P3s.

## Findings

### F-r1A-1 — P2, INTRODUCED population (the defect class is pre-existing, bd `zt0b`)

**The claim.** Two stated reasons say `-O1`'s one relational fold never reaches the admitted F1 site:

- TRACK §3: *"It produces no REGION, so neither admitted site is reached."*
- The F2 header (`ArmClassify.cpp:1994`): *"InstCombine's relational simplification acts on a
  SELECT, which a diamond whose arm holds a `cq_theta` CALL never becomes."*

**It does reach F1, once the fold is NESTED inside a quantum region.** The mechanism:

1. SimplifyCFG sinks an **inner** if/else of two thetas, which gives one φ.
2. `FoldTwoEntryPHINode` turns that φ into `select (q == s), q, s`.
3. InstSimplify folds the select to `s`.
4. The **outer** region's arm is now `cq_theta(s, θ)`, and its Pred incoming is `s`.

That is a runtime-seed prep, and F1 admits it. F2's relational half is asked about the **outer**
branch (`q2 > 3`) and cannot see the pin, because the pinning branch has been erased.

| probe | source (`s = atoi(argv[2])`) | ORACLE | SUBJECT |
|---|---|---|---|
| `a1.c` | `r=s; if (q2>3) { if (q==s) r=cq_theta(q,.9); else r=cq_theta(s,.9); }` + `measure(q)` | F1 decline | **ACCEPT**, exit 0, STRICT 2b `1 verified, 0 violation`, 12 lines; `q` (h0) is never rotated |
| `a3.c` | same with `t = q/4`, inner `t == s` | F1 decline | **ACCEPT**, 13 lines |
| `a5.c` | `a1` without reading `q` afterwards | F1 decline | **ACCEPT**, 11 lines |
| `a1u.ll` | `a1`'s IR **before** the sink, hand-written | `nested control flow` | `nested control flow` |

In the source, `q` is rotated IN PLACE on `q2>3 ∧ q==s`, and `a1` then reads the stale `q`.
The lowered circuit prepares a fresh `|s⟩` instead.

**Grade and ownership.**

- **Not P1.** In every spelling I could build, the rotated register is the operand of the erased
  compare: `select(X==Y, X, Y) → Y` needs X in the compare, and `simplifyWithOpReplaced` needs A to
  contain X. That makes it α-like, the flat version `p1.c` already accepts on the oracle (bd `zt0b`),
  and the unfolded source is not realisable in CQ's register model anyway.
- **It is an owner question.** Does the 2026-09-11 α trade extend to a pin on an **erased inner
  branch under a different region condition**? The literal analogue `a4.c` accepts on the ORACLE, so
  the question is pre-existing for literals too.
- **What is P2.** The two sentences above are the load-bearing "no subject" claim. They are false as
  class statements, and the source comment carries one of them (L7).
- **Filed.** Appended to bd `zt0b`, whose description said "not reachable through either site z0re
  widens".

Repro: `cd review_r1A_z0re/probes/src && ../run.sh a1 5 7` (and likewise `a3`, `a5`, `a1u`, `a4`).

### F-r1A-2 — P1, PRE-EXISTING (lowered IR byte-identical on the oracle and the subject) → bd `test_C_libtooling-fmt3`

This is drbq.13's own counter-example (TRACK §4 `a1`), nested inside a diamond prep region: `a6.c`,

```c
int t = q / 4; int q2 = cq_theta(7,.4); int r = 5;
if (q2 > 3) { if (t == 5) r = cq_theta(t,.9); else r = cq_theta(5,.9); }
return cq_measure(r) + cq_measure(t) + cq_measure(q2);
```

At `-O1`, IPSCCP pins `t` to 5 on the inner edge, both thetas become `cq_theta(5,.9)`, and the inner
compare is deleted. What reaches the pass is `r = 5; if (q2>3) r = cq_theta(5,.9)`, with `t = sdiv q,4`
still live and measured.

**Both binaries ACCEPT at exit 0 with STRICT 2b clean**: `alloc(5)→h3; cry(h2,h3,.9); … sdiv(h0,4)→h4;
measure(h4)`. The source rotated `t` in place and the circuit never does.

**The flat twin `a6f.c` DECLINES on both binaries at F2** (`state prep seed is proven equal to the
condition register`). So this is the F-R1-1 / sideways class, which the project keeps declined
(drbq.14: "21 non-wire colliders STAY"), getting past F2 because F2 anchors LVI on the **region's
own** two edges.

Why it matters to this change: TRACK §4 and the new S3 comment justify keeping drbq.13 declined with
*"the DIAMOND prep of a literal is safe only because F2 asks … on one of the branch's edges"*. `a6`
shows the diamond is exposed in the same way under nesting. drbq.13 should stay declined, but that
premise needs correcting (L7), and the owner's options (b)/(c) for drbq.13 should be weighed against
a fence that also covers the diamond.

Repro: `../run.sh a6 5 7; ../run.sh a6f 5 7`.

### F-r1A-3 — P2 (L7): "MEASURED live rather than dead" is about the exclusion, not the relational half

The F2 header says the relational half is "MEASURED live rather than dead" because mutant M2 (drop
the exclusion) kills a fixture. That measures `excludedAtTest`. The **relational half itself** (the
`isImpliedCondition` loop and the fp loop) is fully masked by `CondWire` for every condition that
reaches a prep today:

- compound conditions decline first (`e20.c`, `control flow` on both binaries);
- a single compare can only imply equality about its own operands, and those are in `CondWire`.

So deleting the whole half is an **equivalent mutant on every reachable input**, and no fixture can
pin it. That is acceptable by design, but the comment should say "unpinnable until retirement
trigger (2) fires", not "measured live".

F-r1A-1 and F-r1A-2 show that the real exposure is a pin on an edge that **is not the region's**,
which the relational half does not look at at all. Retirement trigger (1), "an equality-propagating
pass enters `-O1`", misses the SimplifyCFG-sink route that already exists.

### P3s

1. **`control_inplace_ry_reject_stateprep_runtime_seed.ll` is now an ACCEPT whose name says reject.**
   Its RUN lines have no `not`. Same family as bd `gahu`; L8 says not to `git mv` it before a merge,
   but the header should carry the retirement note.
2. **The `isRuntimeStatePrepSeed` sub-conjuncts are EQUIVALENT at every caller, so no fixture can pin
   them.**
   - `isa<Constant>` is subsumed by `!isa<Instruction> && !isa<Argument>`.
   - `Tainted.count` is implied by `StatePrep` (F1 and the flag assignment) and by `UntaintedBase`
     (S3 and emitter step 0).
   - The int/fp type test is implied by the prototype validation plus F1's clause 3.
   - The header calls the `Constant` exclusion "the whole scope line". It is documentation, not a
     fence.
3. **L1 re-ask over-decline, pre-existing verdict with a new string.** In `l6C.c`, the 6.5 `%out`
   seed has a condition (`q2 > 7`) that does not read it, so the circuit is a realisable in-place
   controlled Ry. The subject declines with `state prep seed became quantum`. The oracle declined it
   at F1. The inlined twin `l6T.c` ACCEPTS on both binaries, with byte-identical traces. The owner's
   "over-decline is a defect" ruling makes this a follow-on: re-route to the chained path rather than
   decline.
4. **An in-loop Ry-stem angle select on a runtime base declines ROLLED and accepts UNROLLED.**
   - `g1C.c` (rolled): SUBJECT `control flow inside a loop body`, ORACLE `rotation angle`.
   - `g1T.c` (unrolled): SUBJECT ACCEPT, 24 lines, STRICT 2b clean, a correct by-difference stream.
   - This is safe, but it is an over-decline and a rolled/unrolled divergence the matrix does not
     cover.
5. **The zt0b bead text ("not reachable through either site z0re widens") is now false.** Corrected
   by appended note.

## Standing-lesson answers

- **L1.**
  - **Record placement.** The record is keyed on the classifier's verdict: `RuntimeSeedAdmitted` is
    set at `ArmClassify.cpp:6326` and at `:9536`, and read at `SwapRouteEmit.cpp:965` and
    `AngleSelectEmit.cpp:529`.
  - **Every emitter that commits a prep takes the record.** Both dispatch sites
    (`SwapRouteEmit.cpp:1245` rail condition and `:1302` compare) reach the one
    `emitInPlaceRotationRegion`, and `emitAngleSelectRegion` has one caller (`:2968`).
  - **No path skips the record after hoisting.** In both emitters the record is taken before the
    irreversible hoist, and every earlier `return` diagnoses.
  - **No region reconstruction drops the flag.** The `ControlRegion` reconstructions at
    `ControlDetect.cpp:847` and `SwapRouteEmit.cpp:638` are switch and select kinds, never a prep.
  - **The re-ask runs in both entry points** (`run()` :1010, `runOnFunction()` :1654), after
    `specialize()`.
  - **Nothing after the re-ask writes `taint.Tainted` before `lowerRotations`.** I read the four
    stages in between; `resolvePhantomCloneArgReads` takes a `const TaintSet&`.
  - **`lowerCloneControl` needs no re-ask.** `SpecializeReject` rejects any clone body holding a
    theta.
  - **arg-0 rewrites cannot hide a seed.** Of the `setArgOperand(0, …)` sites, the ones at
    `AngleSelectEmit.cpp:566` and `SwapRouteEmit.cpp:987/1018` rewrite the *controlled* gate (the
    record names the source), `:1561` is on the phase path, and `RotationLowering.cpp:452` only
    touches a whole-value `undef`.
  - **Routes measured to decline with the new string:**
    - `m2C.c`: volatile local;
    - `m3C.c`: opaque classical call on the 6.5 value;
    - `m1C.c`: store-forwarded buffer;
    - `l6C.c`: condition disjoint from the seed;
    - the implementer's `l3C.c`/`l4C.c`.
  - **Routes that decline earlier:** `m1b.c` (non-forwardable buffer) is caught by the round-2 escape
    guard. `b1.c`/`b2.c` (4.4 select) and `g6C.c` (loop-carried) are already tainted at round 1.
  - **No crash.** None of these crashed in the stages between round 2 and the slot.
- **L2/L3.**
  - The R4/R6 skip for a prep and the S7-rail/S8/S9 skip for a runtime angle-select base are sound.
    The rotated rail is freshly minted.
  - The G-13 probe holds. `g3C.c`/`g3T.c` (in-loop runtime prep, with a trailing non-diagonal Ry on
    the condition register) are twin-identical, 22 lines, STRICT 2b clean. The ORACLE declined both
    at 2c. `h1C.c` (flat, seed is the condition's classical operand, then a trailing Ry on `q`) strips
    the flag before the Ry.
  - Feed-forward `g5C.c`/`g5T.c` (the seed is the previous trip's measured prep) is twin-identical.
- **L4.** The relational loop is an any-of over the COMPLETE candidate list, with the exclusion
  applied per entry before the return. An excluded early entry cannot mask a later one. There is no
  return-first defect.
- **L5.** The relational question is semantic (`isImpliedCondition`). Its **anchor** is still
  syntactic, "the region's branch", and that is exactly what F-r1A-1 and F-r1A-2 defeat.
- **L7.** Five wrong or incomplete stated reasons:
  - F-r1A-1's two sentences;
  - the S3 comment's "diamond is safe" premise (F-r1A-2);
  - "measured live" (F-r1A-3);
  - bd `zt0b`'s "not reachable".
- **Rule 14.** Satisfied. `isRuntimeStatePrepSeed`, `fcmpEqualityHoldsOnEdge` and `excludedAtTest`
  each have one spelling, and the extractions are verbatim (checked by diff against the pre-change
  switch and conjunct list).
- **Rule 12.** Every new accept has a decline partner: mismatch, quantum incoming, round-2 ×3, and a
  literal-base fold. The negatives are pure; counts sit in their own `ACNT`/`FCNT`/`RYCNT` prefixes.
  Naming issue: P3-1.
- **LVI precondition (attack 4).** The runtime path returns before any LVI query.
  `isImpliedCondition` is purely syntactic and has no dominance precondition. `Cand` keeps its
  `DT->dominates` filter.

## Attacked and NOT broken

- **The `-O1` substitution argument, for the arm and the Pred slot of a single region.** Measured
  pipeline: none of the passes it contains substitutes one non-`Constant` SSA value for another,
  except through the select fold of F-r1A-1. The implementer's `e02`/`e09`/`e16` agree.
  - `e20.c` (a compound condition carrying `q == s`) declines `control flow` on both binaries.
  - `c1.c` (a switch with prep arms) declines `control flow` on both.
  - `c2.c` (the seed loaded from an array of quantum values) declines `tainted value stored to
    memory` on both.
- **Runtime-base analogue of drbq.13 (attack 6).** `a2.c` (the fold feeding an angle select) keeps a
  3-predecessor merge and declines `nested control flow` on both. `d1.c` (a prep whose theta angle is
  itself a quantum select) declines `control flow` on both.
- **Composition (z0re × cepm+3zr4).**
  - `comp2.c` + `comp2.lib.c`: `t = h(q, m)` with `h` ignoring `q`. The seed is a spec-call result
    and is classical today via the vsfp dead-argument drop. ORACLE F1 decline; SUBJECT ACCEPT
    `alloc(8); cry(f,h,.2)`, STRICT 2b clean. **This is the program cepm+3zr4 moves onto the direct
    path at propagation, and the program to re-run on the composed binary.**
  - `comp1.c`: `h` depends on `q`. It lowers identically on both binaries as a CHAINED in-place Ry on
    the clone's out rail, 22 lines, 2b clean.
  - **Composition hazard to watch.** If cepm ever marks a result classical that does depend on the
    quantum argument, F1 now admits it and `cqrt_alloc_<W>(result)` is taken of what may be a
    **handle number**. The only backstop is the post-`specialize()` re-ask, and only if
    `specialize()` re-marks the result tainted.

## Mutants

None were built (see the header). Here is my answer to attack 5, "separate the weakest conjunct":

- **Weakest conjunct: the `Tainted.count` test inside `isRuntimeStatePrepSeed`.** It is provably
  **equivalent** at all four callers (P3-2), so no input can separate it.
- **`!PreallocatedBankSeed` in the flag assignment is also equivalent.** The bank seed `cqrt_alloc`
  is kept out of `Tainted` (`TaintPropagation.cpp:159`) until `lowerRotations` adopts it, which
  happens after the re-ask.
- **The implementer's M1–M8 cover every conjunct that is not equivalent.** The relational half is
  unpinnable (F-r1A-3).

## Probe index (`probes/src`, runner `probes/run.sh <name> [argv…]`, outputs in `probes/out`)

`a1 a3 a5` (F-r1A-1) · `a1u.ll` (unfolded) · `a4` (literal on-wire, oracle ACCEPT) · `a6 a6f` (F-r1A-2) ·
`a2 d1 e20 c1 c2` (declines) · `b1 b2` (4.4 seed, identical on both) · `l6C l6T` (P3-3) · `m1C m1b m1u m2C m3C`
(L1 routes) · `g1C g1T` (P3-4) · `g2C g3C g3T g5C g5T g6C h1C` (loops, G-13, feed-forward) · `comp1 comp2`
(composition).
