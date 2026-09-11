# FIX_A1_R2 — Track A.1, the round-2 Rule-13 fix (`review_a1_r2.md`, verdict **CLEAR-WITH-ITEMS**)

Fix record for the five items of the round-2 adversarial review of branch `compare-select-parity`
(worktree `/Users/sorenwilkening/Desktop/CQ_trackA`, on top of the round-1 checkpoint `b439944`,
itself on top of `main` 0c7380c). **Committed nowhere — the working tree is dirty on purpose; this
round adds no commit.** ORACLE for every A/B figure: `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
(+ `libCQPass.so`) at `main` 0c7380c, read-only. A **BASE** binary was additionally built from
`b439944` (via `git stash` + rebuild, then restored) and kept at
`scratchpad/trackA_fix2/base/` so every figure below can be read against BOTH the oracle and the
pre-round-2 tree. Nothing was written under the primary checkout or the other worktrees; both
targets (`CQPass` **and** `cq-opt`) were rebuilt after every source edit.

Read `review_a1_r2.md` first. Per finding → change (file:line) → fixtures → measurements, then the
mint-site table and the open questions.

---

## F-A1R2-1 — the `Covered` exemption is now keyed on whether a ruling EXISTS

### What was wrong

Rung (iii) of `reverifyCmpCondReads` exempts every gate reachable TAINT-BLIND, on the written ground
that *"the classifier applied its own disposition to it … RESPECT THAT ANSWER"*. For four of the
control consumers **no classifier applies any disposition**, because none of them ever reaches a
wire walk — MEASURED by grep, not argued:

* `lowerControlledIOSinks` (7.6) runs **before** `detectControlRegions` in both entry points;
* `classifyGuardedStoreArm` (7.5) and `classifyAbortPark` (7.2) are PRE-PEELS in
  `handleBranchRegion` that push their region and `return` before the generic `recoverRegion` path;
* `classifyClassicalCallArm` (6.5) runs before `classifyArms` and returns on Accept;
* none of `IOSinkLowering.cpp`, `GuardedStoreArmEmit.cpp`, `AbortParkEmit.cpp` or
  `classifyClassicalCallArm` contains a `findNonDiagonalWireGate` / `condWireDisposition` call.

So for those mints the round-1 ruling is the EMPTY SET while `Covered` is not, and two CONFIRMED
silent miscompiles stayed open — `io3.c` (a `cqrt_tape_write_i32_controlled` whose ctrl is minted
from `Ry(0.9)Ry(0.25)|x⟩` while the source compares `Ry(0.25)|x⟩`) and `gs1.c` (the same at
`cqrt_qram_store_i32_controlled`), both PRE-EXISTING on `main`, both `opt` exit 0, verify-clean and
STRICT-stage-2b clean.

### The change

A per-entry bit, supplied by the MINT SITE and never inferred at the backstop:

| file:line | what |
|---|---|
| `ir-pass/include/TaintPropagation.h:396` | `TaintSet::CmpCondRead::WireRuled` (+ the 20-line rationale above it, and the rung-(iii) sentence at `:342` re-worded) |
| `ir-pass/include/ArmAnalysis.h:243` | `markCmpCondRead(…, bool WireRuled)` |
| `ir-pass/src/ArmClassify.cpp:2571,2583` | the write half |
| `ir-pass/src/ArmClassify.cpp:2547` | **the fix**: `if (E.WireRuled)` gates the `collectNonDiagonalWireGates` enumeration; an `Unruled` entry passes an EMPTY `Covered`, i.e. the full re-ask |
| `ir-pass/include/CompareLowering.h:86` | `enum class CondReadKind { NotAControlRead, Unruled, WireRuled }` — ONE parameter, three answers, **default `Unruled`** so a forgetful new emitter over-DECLINES |
| `ir-pass/include/CompareLowering.h:179`, `src/CompareLowering.cpp:84,304,325,416,526` | `recordCondRead` (bool) → `readKind`; the record now carries `WireRuled` |
| `ir-pass/include/CondTreeEmit.h:181`, `src/CondTreeEmit.cpp:123,205` | `emitCondNetwork(…, bool LeafWireRuled = false)` — the network serves four consumers and cannot see which one called it, so the answer comes from the call site |

`WireWalk` is **untouched** this round (the round-1 `Covered` plumbing is unchanged).

### The mint-site table — every FORWARD `lowerCompareToFlag` site, and why

`inverse=true` strips are not reads and are not recorded. A balanced-paren audit over
`ir-pass/src/*.cpp` (excluding `CompareLowering.cpp`) finds **19 call sites: 11 forward, and every
one carries an explicit `readKind`; 8 inverse, and none does** — so the table below is the complete
enumeration, checked mechanically rather than by reading.

| site | consumer | bit | why |
|---|---|---|---|
| `SwapRouteEmit.cpp:731` (`emitInPlaceRotationRegion`) | drbq in-place Ry arm | **WireRuled** | `classifyArms` → `condWireDisposition` over `Prov` |
| `SwapRouteEmit.cpp:1141` (`emitRegion`) | value arm / generic region | **WireRuled** | same |
| `SwapRouteEmit.cpp:1661` (`emitPhaseKickbackRegion`, non-tree) | flat phase kickback | **WireRuled** | `classifyPhaseKickback` → `condWireDisposition` / `railCondWireDisposition` |
| `SwapRouteEmit.cpp:1634` → `CondTreeEmit.cpp:205` | flat kickback, TREE condition | **WireRuled** | same classifier, per-leaf |
| `SwapRouteEmit.cpp:1985`, `:2005` → `CondTreeEmit.cpp:205` | 4.3 depth-2 nest, outer + inner | **WireRuled** | `classifyPhaseKickbackNest` walks EACH level's `condProvenance` union (`ArmClassify.cpp:5102`) |
| `SelectMergeEmit.cpp:215` → `CondTreeEmit.cpp:205` | 4.4 data select (and `emitValueRegion`'s synthesized one) | **WireRuled** | `classifySelectRegion` GATE 2c (`SelectClassify.cpp:963`); the value-arm path came through `classifyArms` |
| `AngleSelectEmit.cpp:189` (`emitPhaseAngleSelect`) | Rz-stem angle select | **WireRuled** | dispatched from `SelectClassify` GATE 3, i.e. after gate 2c |
| `AngleSelectEmit.cpp:514` (`emitAngleSelectRegion`) | Ry-stem angle select | **WireRuled** | same |
| `IOSinkLowering.cpp:706` | 7.6 controlled I/O sink | **Unruled** | stage runs BEFORE `detectControlRegions`; no wire walk in the file |
| `GuardedStoreArmEmit.cpp:266` | 7.5 guarded Shadow store | **Unruled** | pre-peel; no wire walk in the file |
| `ClassicalCallArmEmit.cpp:202` | 6.5 classical-call arm | **Unruled** | classifier returns before `classifyArms`; no wire clause |
| `AbortParkEmit.cpp:387` | 7.2 abort park | **Unruled** | pre-peel; no wire walk in the file |
| `Specialization.cpp:219` (`mintCondNetwork`) | — | **Unruled**, inert | records into the CLONE's `TaintSet`, which this stage never reads; `specialize` runs later (O-5). Spelled rather than defaulted so the enumeration is complete in the source |
| `CompareLowering.cpp:413-416` (`lowerCompareToFlagRail`) | — | **Unruled** | ZERO callers at HEAD; the strongest re-ask if it is ever revived |
| `CompareLowering.cpp:522-526` (`rewriteCompare`) | straight-line DATA path | **NotAControlRead** | no record at all — unchanged from round 1 |

### Measurements

| probe | ORACLE | b439944 | here |
|---|---|---|---|
| `io3.c` (7.6 sink, blind-visible staler on the condition wire) | ACCEPT | ACCEPT | **DECLINE `condition predates a non-diagonal gate`** |
| `gs1.c` (7.5 guarded store, same shape) | ACCEPT | ACCEPT | **DECLINE**, same string |
| `multi/io3m.c` (`io3` as two TUs) | ACCEPT | ACCEPT | **DECLINE**, same string |
| `io4.c` (the same wire at the flat kickback) | DECLINE | DECLINE | DECLINE — unmoved |
| `io0`,`gs0` (clean controls), `io6`,`gs3` (staler on ANOTHER register) | ACCEPT | ACCEPT | ACCEPT |
| `multi/io5.c` (round-2-only staler at the sink — round 1's discriminator) | ACCEPT | DECLINE | DECLINE |

**The OTHER two `Unruled` consumers show no measured movement**, and I looked rather than assumed:
`scratchpad/trackA_fix2/src/cc1.c` puts the `io3` wire shape under a 6.5 classical-call arm and
declines `condition predates a non-diagonal gate` on ALL THREE binaries (the pure callee folds, so
`-O1` never hands the pass a classical-call arm), and `ap1.c` puts it under the 7.2 abort park and
declines `control flow` on all three (the reviewer's `ab1` result). So the narrowing's measured
population is exactly the two consumers the finding names; the other two are pre-empted by earlier
fences at every spelling I could build, and their `Unruled` marking is insurance with a written
reason rather than a measured capability.

Reviewer's round-2 probe corpus, `run.sh`, subject-vs-`b439944`: **exactly three movers — `io3`,
`gs1`, `io3m`** (`diff` of the two runs, everything else byte-identical). Round-1 probe corpus
(`review_a1_r1_probes/run.sh`): **0 movers**. Implementer probe corpus (20 programs incl. the four
two-TU pairs and `sw1`/`sw2`): **0 movers**.

### ⚠ THE COST, AND IT CONTRADICTS THE BRIEF'S PREMISE — read this before anything else

The brief says the narrowing *"must NOT cost the 12 in-loop accepts (all ArmClassify consumers)"*,
quoting the review's own reason that an `Unruled` re-ask *"cannot cost the twelve in-loop accepts,
all of which are `ArmClassify` consumers"`. **That premise is false by exactly one file, and the
counterexample is at one of the two consumers the finding is about.** Measured, all eleven others
ACCEPT unchanged; the twelfth is `lowering_live_record_tape_ctrl_observed_accept.ll`, a **7.6
I/O-SINK** consumer, and it moves ACCEPT → DECLINE.

* **What it was.** The sole pin of the CTRL-slot arm of `reachesObservingSink` (M-A, bd
  `test_C_libtooling-6uqc`): the ctrl slot of `cqrt_tape_write_<W>_controlled` is an OBSERVING sink,
  so a live derived record read into it is the program's own data.
* **Why it now declines.** Its condition's `condProvenance` cone is `{%q, %c}`; the in-place
  `cq_theta(%q,.25)` is a gate on `%q`'s wire that PRECEDES the mint, and with the exemption gone
  the position-aware prong cannot prove it post-emission.
* **This particular circuit was FAITHFUL** — `%c` is an out-of-place `mul` rail written before the
  gate, so the flag really did encode `c > 3`. The decline is an over-decline OF THIS PROGRAM.
* **It is nevertheless PARITY, and that is why it was taken.** The identical program with the sink
  replaced by a flat phase kickback declines **on the ORACLE** with the same string (measured,
  `scratchpad/trackA_fix2/probe/tape_kick_twin.ll`): six of the seven consumers already refuse this
  wire shape, and the 7.6 sink accepted it only because nothing asked. Choosing the other direction
  would mean giving the fence-less consumers a NARROWER question than every classifier asks — an
  accept-direction widening of a Rule-13-core stage, unreviewed, on my own argument. Prime
  Directive: when in doubt, decline.
* **The pin is LOST and the arm is UNPINNABLE by construction** — said plainly rather than left to
  be discovered. M-A's subject needs the record's READ to come AFTER a gate on its wire; the CTRL
  slot IS the region's condition; the wire fence accepts such a gate only if it comes AFTER the
  read. The two cannot both hold, so no straight-line program exhibits the arm and passes the fence.
  The SRC-slot arm (`lowering_live_record_sibling_read_taped_accept.ll`) and the toffoli-control HOP
  (`lowering_live_record_condtree_toffoli_observed_accept.ll`, GREEN here) keep their own pins.
* **Disposition:** the file is `git mv`'d to `lowering_reject_live_record_tape_ctrl_cond_staler.ll`
  and rewritten as a DECLINE whose header carries this whole paragraph, the twin measurement and
  the open question. It is not deleted, and the rename does not hide the loss.

### Fixtures (7 new + 1 re-homed)

| file | kind | ORACLE | b439944 | here |
|---|---|---|---|---|
| `lowering_reject_io_controlled_cmp_blind_staler.ll` | DECLINE (`io3`) | **rc 0 → RED** | **rc 0 → RED** | rc 1 |
| `lowering_reject_guarded_store_cmp_blind_staler.ll` | DECLINE (`gs1`) | **rc 0 → RED** | **rc 0 → RED** | rc 1 |
| `lowering_reject_phase_kickback_cmp_blind_staler.ll` | DECLINE (`io4`) — the PARITY REFERENCE | rc 1 | rc 1 | rc 1 |
| `lowering_io_controlled_cmp_other_register_staler.ll` | ACCEPT control (`io6`) | rc 0 | rc 0 | rc 0 |
| `lowering_guarded_store_cmp_other_register_staler.ll` | ACCEPT control (`gs3`) | rc 0 | rc 0 | rc 0 |
| `lowering_reject_live_record_tape_ctrl_cond_staler.ll` | re-homed (was the M-A accept) | **rc 0 → RED** | **rc 0 → RED** | rc 1 |

The two accept controls carry whole-file `FCNT`/`XCNT`/`RYCNT` exact counts and a `SILENT` stderr
prefix (a trailing `CHECK-NOT` after positives is windowed and asserts nothing). The three decline
fixtures mirror the diagnostic character-for-character; their IR-text negatives would be vacuous (a
`DS_Error` decline writes 0 bytes to stdout), so the "no silent fallback" property is pinned by the
`not` inversion, and each header says so.

---

## F-A1R2-2 — Q-3 is ANSWERED: keep the `InPlaceRailOps` crossing; it has a live decline face

No code change — `railWireNamesBackward`'s crossing is kept exactly as round 1 shipped it. What
changes is the record and the coverage: round-1 Q-3 asked whether to delete it as untested
insurance, and the answer is **no**, because `f4f.c` is single-TU plain `clang -O1` C that declines
**only** because of it (ORACLE ACCEPT → here DECLINE `condition measured before the control route`;
the compare's direct operand is the POST-`xor` name, the `cq_measure` names the PRE-`xor` phi, and
without the crossing `railWireNamesBackward(post)` is the singleton `{post}` with no measure user).

Why round 1's `ip1`/`ip3` missed it, recorded because it is a `-O1` fact and not a failure of
imagination: they used `add`, and `-O1` rewrites `(q+1) > 5` SIDEWAYS onto the pre-`add` value, so
the measured register lands directly in the compare and the crossing is never needed; `xor` does not
distribute over the compare.

Fixtures: `control_phase_kickback_reject_cmp_inplace_xor_measured_parent.ll` (DECLINE, **ORACLE
rc 0 → RED**; rc 1 on b439944, i.e. it pins a round-1 capability nothing pinned) and
`control_phase_kickback_cmp_inplace_xor_other_register.ll` (ACCEPT control — the identical loop with
a DIFFERENT register measured; rc 0 on all three). `FIX_A1_R1.md`'s Q-3 is rewritten in place with
the answer, leaving the original question visible.

---

## F-A1R2-3 — the rail-path accept class is a CLASS, stated with its ground

No code change. The corrected sentence, now in `FIX_A1_R1.md` §F-A1-2, `IMPL_A1.md` §5 and
`BRIEF_A1.md`'s ERRATA-2: *A.1 is decline-monotone on the COMPARE path; on the RAIL path rung (ii)'s
per-activation barrier admits the **iteration-local class** — a register whose SOURCE-theta origin
re-executes on every path from the measurement back to the read — whose measured plain-C members are
`b1`, `b2`, `r3`, `b3`, `b4`.* "Exactly two, by name" read as an exhaustive claim about programs and
was not one.

Three pinned, each for a distinct shape (no duplicates):

| fixture | probe | what is distinct |
|---|---|---|
| `control_phase_kickback_rail_inloop_iterlocal_invariant_seed.ll` | `b3` | the seed is loop-INVARIANT and NON-constant, so LICM is the expected outcome; `-O1` does NOT hoist the `cq_theta` (a call is not speculatable) and the mint stays in the body — measured, pinned by `CHECK-LABEL` |
| `control_phase_kickback_rail_inloop_iterlocal_carried_seed.ll` | `r3` | the seed is a loop-CARRIED classical value off the previous trip's `cq_measure`: a carried SEED is not a carried REGISTER |
| `control_phase_kickback_rail_inloop_iterlocal_guarded_block.ll` | `b4` | the origin, branch and measure sit in a GUARDED sub-block, so "every path re-executes the origin" holds for a control-flow reason (the `o7c` argument) |

All three are ORACLE rc 1 → **DECLINE → ACCEPT movers**, rc 0 on b439944 and here; each carries
per-activation `ACNT`/`MCNT`/`RYCNT`/`FCNT` whole-file counts and a `NOROUTE` negative.

---

## F-A1R2-4 — the containment comment is rewritten

`ir-pass/src/ArmClassify.cpp` at the rung-(iii) call site (≈`:2484-2545`). The old claim
(`blind ⊆ round-1 ⊆ final`, "exempts no more than the classifier actually saw") is replaced by the
two ways it fails plus the derivation the code did not have:

* **(a)** it presumes a classifier walk; for the four fence-less consumers `round-1 = ∅` while
  `blind ≠ ∅` — measured as F-A1R2-1, and the `WireRuled` bit is the repair;
* **(b)** `Covered` is a SUPERSET of what the round-1 walk examined, because the return-first mode
  never PUSHES a staling gate while the enumerating mode does; the extra members are transitively
  post-emission, with the reviewer's three-step derivation (DT transitivity; leg 1 path extension;
  leg 2 can only break across a back edge, and a back-edge value arrives as a PHI that
  `CrossValueRouting` pushes in every mode) written out at the line;
* **why Q-2's "0 movers" is right by CONSTRUCTION**, not luck: `Seeds` is the `condProvenance` cone,
  so what the F-1b-1 crossing reaches backward is already its own seed in the blind walk;
* the precise meaning: *"`Covered` is a gate visible TAINT-BLIND at a mint whose round-1 wire
  disposition was actually TAKEN by `ArmClassify` (`condWireDisposition` / `railCondWireDisposition`)
  or by `SelectClassify`'s gate 2c"*, and an `Unruled` entry exempts nothing.

The stage header (`≈:2330`) and `TaintPropagation.h:342` are re-worded to match, so the three places
that describe rung (iii) cannot drift.

---

## F-A1R2-5 — record hygiene

`FIX_A1_R1.md:4` and `IMPL_A1.md:12` said "Not committed, not pushed"; both now say the tree is
checkpointed as `b439944` (a `wip(control):` commit to be squashed at landing) and NOT pushed, and
each says the old sentence was true when written and stale by the time the review read it.

### Injection matrix over the six new ACCEPT fixtures

`scratchpad/trackA_fix2/inject2.py` (the round-1 harness, re-pointed): one gate injected immediately
before each fixture's first control read — an extra `cqrt_measure`, a sibling `cqrt_ry` on the
condition wire, an extra `cqrt_free`, an extra `cqrt_x` — naming the module's first `cqrt_alloc`
handle; "caught" means SOME prefix goes red and the clean control must stay green.

**First run: 5 MISSED** — `lowering_io_controlled_cmp_other_register_staler.ll` was blind to an extra
measure (no `MCNT`), and `lowering_guarded_store_cmp_other_register_staler.ll` /
`control_phase_kickback_cmp_inplace_xor_other_register.ll` to an extra measure AND a sibling `cqrt_ry`
(no `MCNT`, no `RYCNT`). After adding those whole-file exact counts:
**6 accepts × 4 mutations, 0 MISSED, 0 DIRTY.**

---

## Gates (Rule 19), in the brief's order

| gate | command | result |
|---|---|---|
| per fixture | `cd build && lit -v ir-pass/test --filter '<name>'` | every new fixture green; every new DECLINE verified RED on the ORACLE **and** on b439944 by direct `cq-opt` runs |
| lit | `ctest --test-dir build -R ir-pass-lit --output-on-failure` | **Passed, 85.82 s, 0 failed** |
| lit detail | `cd build && lit -s ir-pass/test` | **1813 discovered · 1812 passed · 1 expectedly failed · 0 unexpected**, 105.01 s |
| corpus diff (ORACLE) | `python3 scratchpad/trackA_fix2/corpus_diff2.py oracle` | **`FIXTURES=1776 MISSING=1 RCDIFF=0 DIAGDIFF=0 OUTDIFF=0`** |
| corpus diff (b439944) | `python3 scratchpad/trackA_fix2/corpus_diff2.py base` | **`FIXTURES=1776 MISSING=1 RCDIFF=0 DIAGDIFF=0 OUTDIFF=0`** |
| the 1 MISSING | — | `lowering_live_record_tape_ctrl_observed_accept.ll`, the `git mv`'d file; measured separately at its new name: ORACLE rc 0, b439944 rc 0, here rc 1 |
| reviewer probes r2 | `session-9pum/review_a1_r2_probes/run.sh` (both binaries + BASE) | every row re-derived; **3 movers vs b439944: `io3`, `gs1`, `io3m`** |
| reviewer probes r1 | `session-9pum/review_a1_r1_probes/run.sh` (BASE vs here) | **0 movers** (`diff` empty) |
| implementer probes | `scratchpad/trackA_fix2/probes9pum.sh` over `session-9pum/probes` | **0 movers** |
| the M-1 twelve | direct `cq-opt` runs | **11 ACCEPT unchanged, 1 moved** (the 7.6 sink one — see the COST section) |
| e2e | `ctest --test-dir build -j6 -R '^e2e-' --output-on-failure` | **382/382 passed, 0 failed, 1293.88 s** (`e2e-loop-twin-matrix` alone 1293.79 s — the long pole; run under heavy concurrent-track load, loads sampled 8-145) |
| goldens | `git status --porcelain tests/` | **EMPTY** — no golden, no `tests/e2e/CMakeLists.txt`, nothing under `tests/` touched. `include/`, `runtime/`, `tools/` likewise empty |
| full suite | `ctest --test-dir build -j6 --output-on-failure` | **392/392 passed, 0 failed, 944.61 s** — Rule-19 gate moments 1 and 5 (a Rule-13-core change, and an accept/decline predicate moved). Run on the FINAL binary: the two comment-only edits made after the `^e2e-` gate were rebuilt (both targets) BEFORE this run, and nothing was relinked while any measurement was in flight |
| equivalence | `cmake --build build --target cq-opt-equivalence-full` | **`cq_opt_equivalence: compared 1813 fixtures, 0 mismatch(es)`** |

Counts, measured: `ls ir-pass/test/*.ll | wc -l` → **1813** (1803 + 10 new; the re-homed file is a
rename, not an addition).

---

## Open questions for round 3 / the owner

**Q-1 (round-2) — should rung (iii) be seeded from the CONE or from the compare's DIRECT OPERAND
WIRES, at EVERY consumer?** This is the question the one fixture mover raises, and it is older and
wider than Track A.1. The cone is `condWireDisposition`'s own seed set, so an `Unruled` re-ask over
the cone is exact parity with what a classifier would have asked — which is why it was shipped. But
the mint reads ONLY the compare's operand rails, so a gate on a NON-operand ancestor's wire cannot
stale it, and the F-A1-3 narrowing already established that distinction for rung (ii). Taking it for
rung (iii) would keep `lowering_live_record_tape_ctrl_observed_accept.ll` lowering AND still decline
`io3`/`gs1` — DERIVED from the two modules' seed sets (`io3`'s gate is on the compare's DIRECT
operand `%r`; the tape program's is on `%q`, an ancestor of the operand `%c`), **not implemented and
not measured** — at the price of making the four fence-less
consumers strictly more permissive than the ruled ones. **Not taken here**: it is an accept-direction
change to a Rule-13-core stage that no reviewer has seen, and the in-place aliasing case would need
the operand seeds expanded through `railWireNamesBackward` to stay sound.

**Q-2 — the M-A CTRL-slot arm (bd `test_C_libtooling-6uqc`) now has no pin, and is unpinnable while
the wire fence is cone-seeded** (the argument is in F-A1R2-1's COST section and in the re-homed
fixture's header). If Q-1 is answered the other way, the old fixture can be restored verbatim.

**Q-3 — `condWireDisposition` over-declines a faithful circuit** (the same program at the kickback,
on the ORACLE). Worth its own bd file if Q-1 is not taken; it is the reason the 7.6 accept looked
like a capability rather than a gap.

**Q-4 (carried from round 1, unchanged) — the residual of rung (iii) for a WIRE-RULED entry.** A gate
already reachable taint-blind at round 1, at a mint whose classifier ruled on it, whose WIRE the
round-2 merge then changed, is still exempted by identity. Closing it needs the classifier's own
disposition recorded per compare (a second record, a second round). The `WireRuled` bit is the
cheapest possible down payment on that record and is deliberately NOT it.

**Q-5 — `emitValueRegion`'s synthesized `SelectRegion` is `WireRuled` through `SelectMergeEmit`'s
call site**, on the ground that its region came through `classifyArms`. That is true today and is an
argument, not a mechanism: a future caller of `emitSelectRegion` that did not go through either
classifier would silently inherit `LeafWireRuled=true`. The `RailLadderProven` tripwire (bd `r9e5`
round 1, item 2) is the precedent for making that structural rather than argued.

**bd `test_C_libtooling-61k6`** is the orchestrator's file for the pre-existing ×2 miscompile; this
round closes it in the compiler, and the two decline fixtures are its reproducers.
