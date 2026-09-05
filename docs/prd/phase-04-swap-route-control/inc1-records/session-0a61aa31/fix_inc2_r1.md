# fix_inc2_r1 — Rule-13 ROUND-1 FIX agent for Inc 2 (value arms by controlled-copy merge)

Agent: `fix_inc2_r1`. Worktree `$SP/wt/inc2`, branch `3qlq-inc2` (base tip 8c526d9).
SUBJECT-BEFORE binaries copied aside BEFORE any edit:
  `$SP/progress/inc2_before_cq-opt`, `$SP/progress/inc2_before_libCQPass.so` (from build/, stamped 14:59).
ORACLE: `$SP/wt/pre-3qlq/build/ir-pass/{cq-opt,libCQPass.so}` @ 52d7764.

## 2026-09-05 — step 0: setup
- Read BRIEF_common, BRIEF_fix_inc2_r1, BRIEF_impl_inc2, impl_inc2.md, review_inc2_V1.md,
  review_inc2_V2.md, OWNER_QUESTIONS.md OQ-22/OQ-23. Done.
- Copied SUBJECT-BEFORE binaries (`cp -f`), verified sizes.
- Findings to dispose: F-V1-1..F-V1-7, F-V1-9 (bd), F-V2-1..F-V2-6, plus the
  `SwitchValueEmit.cpp:133` loud-bail item.
- Next: read the sources I will touch and the probe artifacts V1/V2 left behind.

## 2026-09-05 — step 1: SOURCE edits (comments + one new fence), build launched
All in `$SP/wt/inc2`, value path only (no phase/rotation path touched).
1. **F-V2-1** `ir-pass/src/SwitchValueEmit.cpp` lines 1–30 REWRITTEN (they were
   byte-identical to `main` and described the RETIRED cswap route in the present tense,
   citing `emitRoute` from a header this commit deleted). New header states the retired
   stream explicitly AS retired, then the shipped preload + XOR-delta recipe, the mutual-
   exclusion argument, and what is left allocated (F-V2-3). Also the `CaseStream` doc
   comment (was "routed VALUE stream … erased after rewire", contradicting its own field
   comment two lines below) and `ir-pass/include/SwitchRouteEmit.h`'s
   `emitSwitchValueRegion` doc (was "route + verbatim chain replay + one copy-out + LIFO
   reverse-play"). Touched NO phase-side comment (Inc 1b owns SwitchRouteEmit.cpp).
2. **F-V2-11** `SwitchValueEmit.cpp` `if (!Arm.Block || Arm.Values.empty()) continue;`
   SPLIT: null Block still `continue`s (a straight-to-merge case's merge incoming IS `p`,
   so the preload already holds the answer), `Values.empty()` now `return bailLoud(R)`
   like every neighbour. Unreachable at HEAD; comment says so, no fixture.
3. **F-V1-2** `SwapRouteEmit.cpp` `emitValueRegion`: new PRE-MUTATION fence
   `if (!comparePredLowerable(Cond) || !compareFlagMintable(Cond, taint))` beside
   F-QQCOND, mirroring `AngleSelectEmit` step 0b in lockstep (+ `#include "ArmAnalysis.h"`).
   Comment records that no fixture can pin it and WHY (needs an i128 condition; F-V1-9).
4. **F-V1-4 / F-V2-3** `SwapRouteEmit.cpp` step 5: "exactly as the route left them"
   REPLACED — `p` is as the route left it, the chain FINAL is NOT (`_unc`'d by nothing,
   freed by nothing, dirty and entangled where the route returned every rail to |0>),
   with the soundness argument and the 3qlq.5 consequence.
5. **F-V1-6** the speculation fence's "on a |0> work rail, i.e. `0 sdiv n`" rationale
   REPLACED with the cswap-superposition reading; added the "INT_MIN/-1 arm is exercised
   by nothing" note (clang -O1 folds `p / -1` to `sub`).
6. **F-V1-3** the Abi pre-flight's fp arm marked as an UNREACHED backstop, with the two
   fences ahead of it NAMED and MEASURED (see step 2 below).
7. **F-V1-8** one header line: the hoist only ever moves a link LATER within Pred.
8. **F-V1-1** the widening RECORDED in the emitter header (HandleWidth[out] inherited from
   `emitSelectRegion`, p119.6), naming the fixtures that will pin it.
9. **F-V1-5** `ir-pass/src/ArithLowering.cpp` G6/G7: the value-arm merge added as
   CONSUMER 2 of the pair, with the two wrong-unitary shapes spelled out and the pinning
   fixture named.

## 2026-09-05 — step 2: MEASURED, the fp backstop is doubly unreachable
- `n1_fp_diamond.ll` (hand IR, `br` diamond + `phi double`) on the BEFORE binary:
  rc=0, lowers with `cqrt_copy_f64_controlled` — the fp phi is claimed by
  `flattenPredMuxRegions` (pipeline slot `CQLoweringPass.cpp:196`, BEFORE
  `detectControlRegions` at :322). `PredMuxFlatten.cpp`'s own W5 witness (bd vyqi) says
  it claims "the flat sole-2-incoming SCALAR-FP-phi diamond … which ArmClassify's fp fence
  categorically declines" — so this is BY DESIGN, and impl_inc2's totality-table row
  ("ArmClassify declines an FP-typed merge as an ANGLE") names a real fence that is not
  the one that fires. Correction goes in the notes.
- A multi-phi fp+int diamond (`fp_try1.ll`) is ALSO claimed (rc=0).
- `fp_try2.ll` (an `fp128` arm, which PredMux's E4 width gate refuses): declines
  `cq controlled lowering: value-arm swap-route under quantum control` — earlier than the
  fp merge fence — and IDENTICALLY on both binaries. So no constructible diamond reaches
  `emitValueRegion`'s `copyControlledFn` fp arm: comment, not fixture, as the brief allows.

## 2026-09-05 — step 3: RESUMED after the round-1 instance was killed by a rate limit
Inspected `$SP/wt/inc2`: 4 MODIFIED sources (step 1 above, all present and complete),
5 UNTRACKED lit fixtures (the F-V1-1 pins, written 16:52-16:54) and 4 UNTRACKED e2e files
(`slice_control_value_merge_qq_compare.{c,expected.log}`,
`slice_control_value_polarity{,_twin}.c` — the two polarity goldens and every CMakeLists
registration are still MISSING). Nothing discarded.
- SUBJECT-BEFORE binaries confirmed present at 16:42 (`$SP/progress/inc2_before_*`), the
  build tree at 16:49/16:50 (i.e. built WITH the step-1 source edits), so the copy-aside
  step is done and correct.
- `lit --filter 'control_swap_value_accept_(i8_merge_cast|i64_merge_cast|qq_compare)'`
  on MY binary: **5 of 5 PASS**. Same 5 on the **ORACLE** binary
  (`CQ_OPT=$SP/wt/pre-3qlq/build/ir-pass/cq-opt …`): **5 of 5 FAIL**. RED-GREEN for F-V1-1.
- `diff` of `$SP/progress/fix_inc2_r1_work/e2e/qq.trace.log` vs the committed-to-be
  `slice_control_value_merge_qq_compare.expected.log`: identical (29 lines).
- `cmp` of the two polarity traces (`polarity.trace.log` / `polarity_twin.trace.log`,
  produced by the previous instance through the full pipeline on MY binary): **IDENTICAL,
  23 lines** — F-V1-7's witness holds.
- Remaining: commit the source edits; F-V1-5 fixture; the 3 e2e goldens + CMakeLists (2
  slices + 1 `cmp` gate); F-V2-2 slice header; F-V2-5 contiguity; F-V2-6 fixture pins +
  the switch-half accept discriminator; F-V1-9 bd issue + reproducer records; the notes
  file §1 + PRD errata.

## 2026-09-05 — step 4: commits for the step-1 sources, F-V1-1 and F-V1-7
- `0efe1f0` the 4 source files (F-V1-2 fence + the F-V1-3/4/6/8, F-V2-1/3/11 record repairs).
- `b624826` F-V1-1: the 5 accept fixtures + `slice_control_value_merge_qq_compare`
  (+ golden, 29 lines, reproduced by me through the full pipeline; STRICT 2b rc=0).
- `143e92a` F-V1-7: `slice_control_value_polarity{,_twin}` + their goldens (23 lines each,
  `cmp` IDENTICAL, both STRICT 2b rc=0) + the 4th `cmp` gate
  `e2e-value-polarity-twin-identical`, all registered in tests/e2e/CMakeLists.txt.
- `ctest -R 'e2e-slice-control-value-polarity|…-merge-qq-compare|e2e-value-.*-twin-identical'`:
  **7/7 PASSED** (the 3 new slices + all FOUR twin gates), 3.85 s.
- Next: F-V1-5 fixture (`control_swap_value_ifelse_head_out_of_place.ll`, already NAMED by
  the ArithLowering comment I committed), then F-V2-5 contiguity and F-V2-6.

## 2026-09-05 — step 5: F-V1-5, F-V2-2, F-V2-5, F-V2-6 (commits acc1a30, <next>)
- **F-V1-5** `ir-pass/test/control_swap_value_ifelse_head_out_of_place.ll` (NEW, hand IR,
  TWO functions on ONE-LINK chains: `@ifelse_add_heads` and `@diamond_add_head`). MEASURED
  on my binary: both heads `cq_template_add_i32_hl` (out of place), zero `cqrt_addc_i32`.
  INJECTION-VALIDATED with the M-C conversion spliced in by hand (head -> `cqrt_addc_i32`
  + the copy source RAUW'd to the parent): CAUGHT by CHECK and NOROUTE in BOTH functions;
  a stray `cqrt_ry` between the pinned lines is CAUGHT by CHECK. `ArithLowering.cpp`'s
  consumer-2 paragraph now names the file and says why one-link.
- **F-V2-2** `tests/e2e/slice_control_value_derived.c:3-5,12` rewritten: the twin and the
  gate it named do not exist; the header now carries the CMakeLists rationale and V2's
  MEASURED both-binaries decline. `ctest -R e2e-slice-control-value-derived`: PASSED.
- **F-V2-5 + F-V2-6** all 7 re-derived accepts converted to a contiguous
  `CHECK`->`CHECK-NEXT` chain from the first alloc to the measure, with the flag STRIP
  pinned immediately before its free; `control_swap_value_accept_div_const.ll` gained FCNT
  (COUNT-2) and CCNT (COUNT-2) prefixes; `control_swap_value_accept_nonclobber.ll` gained
  CCNT. NEW `control_swap_switch_value_accept_div_const.ll` — the switch-half ACCEPT
  discriminator (rc=0 on BOTH binaries, so it is on the same side of the fence on both).
  ⚠ LLVM-19/FileCheck TRAP hit while writing these: a comment paragraph containing the
  literal token `CHECK` followed by a colon is parsed as a DIRECTIVE. Two of my prose
  lines became failing checks. Never write that token with a colon in fixture prose.
- **RED-GREEN, MEASURED** (`$SP/progress/fix_inc2_r1_work/inject.py`, 7 mutations x 8
  accepts, clean control first): on the PRE-FIX files (`git show acc1a30:…`) **13
  mutations were NOT CAUGHT** — `M11_stray_ry` in 7 of 7, and `M9_drop_flag_strip`,
  `M5_drop_chain_unc`, `M7_drop_rail_free`, `M10_dup_ccopy`, `M12_free_before_strip` all
  uncaught in `accept_div_const` (plus `M10` in `accept_nonclobber`). On the fixed files:
  **0 NOT CAUGHT**, every applicable mutation caught by >= 1 prefix, most by two.
- `lit --filter 'control_swap_value|control_swap_switch_value|lowering_uncompute_interior_leak'`:
  **45 of 45 PASS**.

## 2026-09-05 — step 6: F-V1-2 turned out REACHABLE; F-V1-9 filed; PRD errata; a NEW finding
### ⚠ THE ROUND-1 CLAIM "F-V1-2 HAS NO REPRODUCER" IS FALSE FOR THE VALUE ARM
MEASURED on `$SP/progress/review_inc2_V1/probe/f1_i128cond.ll` (a VALUE diamond under
`icmp sgt i128`), three binaries:
| binary | rc | first diagnostic | `cq controlled lowering:` count |
|---|---|---|---|
| ORACLE 52d7764 | 1 | `no template for opcode 'icmp i1' in tainted context` | **0** |
| SUBJECT-BEFORE 8c526d9 | 1 | the same | **0** |
| my binary | 1 | `cq controlled lowering: control flow under quantum control` | 1 |
`CQ_CTRL_DBG=1` names `%c = icmp sgt i128 %qw, 5`. So detection DOES hand an
i128-condition VALUE diamond to `emitValueRegion`, my F-V1-2 fence fires, and the
**VALUE half of F-V1-9's Rule-1 gap is CLOSED as a side effect**. The PHASE half
(`f2_i128cond_phase.ll`) is unchanged on every binary and stays open.
- NEW decline fixture `control_swap_value_reject_i128_cond.ll`; red-green MEASURED
  (PASS on mine, FAIL under `CQ_OPT=$SP/progress/inc2_before_cq-opt`).
- The source comment that said "NO FIXTURE PINS THIS" is REPLACED by the measured truth.
- **bd `test_C_libtooling-3qlq.8` CREATED** ("control layer neither claims nor declines a
  tainted i128 compare branch condition (pre-3qlq)", bug, P3, parent 3qlq) — the id my
  source comment already referenced. Reproducers + a README committed under
  `docs/prd/phase-04-swap-route-control/inc2-records/`.
- Commit `b727da8`.

### F-V1-4/F-V2-3 PRD errata + F-V2-4 census re-measure
- PRD §3 and §7.1 gained inline ERRATA blocks (the chain FINAL / switch deltas are left
  allocated AND DIRTY, not `_unc`'d; 3qlq.5 UNSOUND BY DEFAULT; and §7.1's "6 _unc" is
  5 plus two further `lowerOps` deltas). Commit `1677a77`.
- cswap census re-measured MYSELF: `grep -rn "emitRoute(" ir-pass/src ir-pass/include`
  = **7 call sites in 3 files** (NestedRouteEmit :162/:176/:178/:194, SwitchRouteEmit
  :159/:172, AbortParkEmit :381) + `EmitInverse.cpp:261` re-emitting an existing cswap.
  ONE minter (`ControlledSymbols::cswapFn`, reached only from `emitRoute`). V2's
  correction confirmed; the material claim (zero VALUE-path sites) holds.

### ⚠ NEW FINDING F-FIX-1 (mine — the F-V2-1 class in files NEITHER lens read)
`grep -ci "cswap|work rail|route-back|reverse-play|swap-route"` over the value slices:
`tests/e2e/slice_control_value_diamond.c` = **8** mentions, last touched by the 4.2
commit `7139b7a`; `tests/e2e/slice_control_switch_value.c` = **9**, last touched by the
4.5 commit. Both describe the RETIRED route in the PRESENT TENSE ("compute the chain on
a |0> work rail … CSWAPs p into the rail … route-back-dagger"), and **both goldens had
been regenerated by the increment while their prose was not** — the two flagship
customers of the two rewritten emitters each contradicting their own `.expected.log`.
Both headers rewritten; goldens UNCHANGED (`ctest -R e2e-slice-control-value-diamond$|
e2e-value-diamond-twin-identical|e2e-slice-control-switch-value` all PASS), because only
prose moved. A fifth site corrected: `EmitInverse.cpp`'s cswap-seam guard still said "the
swap-route value-arm emitter brackets its R† route cswaps itself" — now names the three
emitters that DO still route and which one survives Inc 1.

### The notes file
`docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC2_NOTES.md` written: §1 is the
round-1 record (a per-finding disposition table + §1.1-§1.10 one section per finding +
§1.11 "what worries me" for round 2), §2 is what round 1 measured that should not have to
be re-measured. Next: rebuild + full lit + the targeted e2e set, then hand back.

## 2026-09-05 — step 7: measurements on the final binary
- `cmake --build build -j8`: **BUILD_RC=0** (`fix_inc2_r1_build4.log`; BOTH CQPass and
  cq-opt, never `--target CQPass` alone).
- `ctest -R ir-pass-lit`: **PASSED, 49.96 s** (`fix_inc2_r1_lit2.log`).
- `lit ir-pass/test` (full): **1594 discovered · 1593 passed · 1 expectedly failed**
  (the standing `lowering_invert_add_i32.ll` XFAIL), 81.6 s (`fix_inc2_r1_lit3.log`).
  Corpus **1586 -> 1594** (+8: 5 F-V1-1 accepts, the F-V1-5 tripwire, the i128 decline,
  the switch-half accept discriminator).
- **DISPOSITION SWEEP, all 1594 fixtures x 2 binaries** (MY binary vs SUBJECT-BEFORE
  `$SP/progress/inc2_before_cq-opt` @ 8c526d9; rc + first error line diffed;
  `fix_inc2_r1_work/disp.sh`, run under `bash` via `xargs -P6 -n25` — V2's zsh
  word-splitting trap avoided): **EXACTLY ONE DIFFERENCE**, and it is my own new
  fixture `control_swap_value_reject_i128_cond.ll` (rc=1 on BOTH, the diagnostic moving
  from the template error into the control dialect). **ZERO pre-existing fixtures changed
  disposition** — the F-V1-2 fence declines nothing that used to lower.
- `free_pairing_check.py` **STRICT** (no `--allow-unproven`) on the lowered IR of all 14
  value/switch ACCEPT fixtures incl. every one I added: **rc=0 on 14 of 14**.
- 3 new e2e slices through the full pipeline by hand: STRICT 2b rc=0, traces 23/23/29.
- Launched the full `ctest -j6 -R '^e2e-'` in the background (the layer that could
  witness an accept->decline flip in a real program).

---

# HAND-BACK — fix_inc2_r1 (Inc 2, Rule-13 ROUND-1 FIX)

## 1. What shipped
Branch `3qlq-inc2` in `$SP/wt/inc2`, **8 new commits on top of `8c526d9`**, 36 files,
+2019 / -220. NO runtime symbol added (`tools/opcode_table.yaml` and `runtime/`
untouched); the one behavioural change is a DECLINE (see F-V1-2).

| commit | finding(s) |
|---|---|
| `0efe1f0` | F-V1-2 fence + F-V1-3/4/6/8 + F-V2-1/3/11 record repairs |
| `b624826` | F-V1-1 — 5 accept fixtures + `slice_control_value_merge_qq_compare` |
| `143e92a` | F-V1-7 — the 4th twin pair + `e2e-value-polarity-twin-identical` |
| `acc1a30` | F-V1-5 — `control_swap_value_ifelse_head_out_of_place.ll` + the G6/G7 consumer list |
| `46b07ab` | F-V2-5 + F-V2-6 + F-V2-2 — contiguity, the strip pin, counts, the switch discriminator |
| `b727da8` | F-V1-2 REACHABLE + F-V1-9 — `control_swap_value_reject_i128_cond.ll` + inc2-records/ |
| `1677a77` | F-V1-4/F-V2-3 PRD errata + **F-FIX-1** (the two flagship slice headers) |
| `87a90d7` | `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1 + the EmitInverse cswap-seam prose |

### Per-finding status
| # | status | fixtures / files |
|---|---|---|
| F-V1-1 | **KEPT + PINNED** (OQ-22) | `control_swap_value_accept_{i8_merge_cast,i64_merge_cast,qq_compare_on_merge,qq_compare_i8,qq_compare_i16}.ll` + `slice_control_value_merge_qq_compare` (+golden). Red-green: **5/5 FAIL on the 52d7764 oracle, 5/5 PASS here.** Two false hand-back sentences corrected in notes §1.1 and in `SwapRouteEmit.cpp`. |
| F-V1-2 | **FIXED — and REACHABLE, contrary to the review** | `control_swap_value_reject_i128_cond.ll` (red-green vs SUBJECT-BEFORE `8c526d9`). |
| F-V1-3 | **FIXED (source comment, measured)** | no fixture: measured that NO constructible diamond reaches the fp backstop (PredMux claims the `phi double` diamond on both binaries; an `fp128` arm declines earlier, identically on both). |
| F-V1-4 = F-V2-3 | **FIXED (PRD errata + source + 3 headers)** | PRD §3/§7.1 errata blocks; notes §1.4 with V2's allocated/dirty table; **3qlq.5 recorded UNSOUND BY DEFAULT**. |
| F-V1-5 | **FIXED + PINNED** | `control_swap_value_ifelse_head_out_of_place.ll` (2 functions, one-link chains) + `ArithLowering.cpp` CONSUMER 2. Injection-validated. |
| F-V1-6 | **FIXED (rationale restated)** | plus the `INT_MIN/-1` arm recorded as exercised by nothing. |
| F-V1-7 | **FIXED** | `slice_control_value_polarity{,_twin}` + goldens + the 4th `cmp` gate. |
| F-V1-9 | **FILED as bd `test_C_libtooling-3qlq.8`**, VALUE half closed | `docs/prd/phase-04-swap-route-control/inc2-records/{README.md,f1_i128cond.ll,f2_i128cond_phase.ll,e1_i128cond.c}`. PHASE half still open. |
| F-V2-1 | **FIXED** | `SwitchValueEmit.cpp` header + `CaseStream` doc + `SwitchRouteEmit.h`. |
| F-V2-2 | **FIXED** | `slice_control_value_derived.c` header. |
| F-V2-4 | **FIXED (re-measured myself)** | 7 `emitRoute` sites in 3 files + `EmitInverse.cpp:261`; material claim holds. Notes §1.8. |
| F-V2-5 | **FIXED, measured red-green** | all 7 accepts contiguous. |
| F-V2-6 | **FIXED, measured red-green** | strip pinned in all 7; FCNT+CCNT on `accept_div_const`, CCNT on `accept_nonclobber`; NEW `control_swap_switch_value_accept_div_const.ll`. |
| F-V2-11 | **FIXED** | `Values.empty()` now `bailLoud`; null block still `continue`s, with the reason. |
| **F-FIX-1 (NEW, mine)** | **FIXED** | `slice_control_value_diamond.c` and `slice_control_switch_value.c` headers (8 and 9 stale route mentions; last touched by the 4.2/4.5 commits while their goldens had been regenerated), plus `EmitInverse.cpp`'s cswap-seam prose. |

## 2. What I ran (only what I ran)
- `cmake --build build -j8` — **BUILD_RC=0**, both `CQPass` and `cq-opt`.
- `lit ir-pass/test` (full, my binary): **1594 discovered · 1593 passed · 1 expectedly
  failed** (the standing `lowering_invert_add_i32.ll` XFAIL), 81.6 s. Corpus 1586 → 1594.
- `ctest -R ir-pass-lit`: **PASSED**, 49.96 s.
- `ctest -j6 -R '^e2e-'`: **100% tests passed, 0 failed out of 330**, 1064 s (the count
  is 326 → 330: +3 slices, +1 `cmp` gate). Log `fix_inc2_r1_e2e1.log`.
- **Whole-corpus DISPOSITION SWEEP, 1594 fixtures × 2 binaries** (mine vs SUBJECT-BEFORE
  `8c526d9`): **exactly ONE difference**, my own `control_swap_value_reject_i128_cond.ll`
  (rc=1 on both; the diagnostic moves into the control dialect). **Zero pre-existing
  fixtures changed disposition.**
- **INJECTION MATRIX** (7 mutations × 14 accepts, clean control first): pre-fix **13 NOT
  CAUGHT**; after, **0 NOT CAUGHT**.
- `free_pairing_check.py` **STRICT**: rc=0 on the lowered IR of all 14 value/switch
  accept fixtures and on all 3 new e2e slices.
- Red-green on the ORACLE for the 5 F-V1-1 fixtures (5/5 FAIL) and on SUBJECT-BEFORE for
  the i128 fixture (FAIL).
- I did NOT run `frontend-lit`, the `runtime` entries, or `ctest` in one invocation.

## 3. The twin gates — all FOUR pass
`e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical`, plus the 3 new slices and
the 7 pre-existing value/switch slices: green inside the 330/330 run. The polarity pair is
23 lines, `cmp` silent.

## 4. Findings that are NOT mine to decide (`## OWNER QUESTION`)
Nothing NEW from me. Standing, unchanged: OQ-22 (F-V1-1, disposed KEEP+PIN by the
orchestrator and executed), OQ-23 (V2's basis-state evaluator — referenced in notes §2 as
a measurement, deliberately NOT added as a ctest gate), and the increment's own three
(Q+Q *condition* capability; the run-time classical SHIFT AMOUNT; the `value-arm
swap-route` string naming a retired mechanism).

## 5. What is left
- **bd `3qlq.8`**: the PHASE half of the i128 Rule-1 gap is still open (only the VALUE
  half is closed). Suggested disposition in the issue: one condition-width gate at
  detection covering all four region kinds, rather than per-emitter.
- **A round 2 should aim at notes §1.11**, especially item 1: the increment's own
  REVIEWER FLAG — `emitSelectRegion` is now reachable with a coherent Rz-lineage operand
  that `SelectClassify` would refuse — is STILL UNLENSED; both round-1 lenses checked the
  other gates and left this one. Items 2–4: the merge's correctness now leans on
  `ArithLowering`'s self-described weak tripwire; the dirty finals are sound only while
  `p` is retained (bd `select-merge-no-chainwalk-exemption` now protects a second path and
  does not say so); V3 has no byte-identity twin of any kind.
- **REBASE onto Inc 1 is still to do** (the orchestrator's). Overlap: `SwapRouteEmit.cpp`
  (I touched only `emitValueRegion` + its header), `ArithLowering.cpp` (one comment),
  `EmitInverse.cpp` (one comment), `SwitchValueEmit.cpp` / `SwitchRouteEmit.h` (value-side
  only — Inc 1b rewrites `SwitchRouteEmit.cpp`, which I did not touch).
- New bd memory: `filecheck-directive-token-in-fixture-prose`.
