# Track X — GATES (hash-keyed; PROTOCOL §"a gate result is a fact about a BINARY, not about a moment")

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`

## Binaries

```
ORACLE  (read-only, /Users/sorenwilkening/Desktop/CQ_lang/build)
  cq-opt       5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8
  libCQPass.so 5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4
SUBJECT (/Users/sorenwilkening/Desktop/CQ_x5/build, after the Track X comment+header edits)
  cq-opt       5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8
  libCQPass.so 5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4
```

⚠ **THE SUBJECT IS BIT-IDENTICAL TO THE ORACLE, ON BOTH ARTEFACTS.** That is the mechanical proof
that this track's change is comments and fixture headers only — it moves no corpus row, changes
no decline string and touches no analysis site, so every gate line already recorded against
`5c6f7490a81c7505…` anywhere in the tree remains valid for this branch (PROTOCOL §S2's logic at
track scope). The corpus sweep, `cq-opt-equivalence-full`, `^e2e-` and the twin matrix were
therefore NOT run, deliberately.

Also measured, before any probe was believed: the worktree's pass source is byte-identical to the
primary checkout's, so the "ORACLE" in every probe row below **is** HEAD's compiler.
```
$ for d in ir-pass include runtime; do diff -rq $d /Users/sorenwilkening/Desktop/CQ_lang/$d; done
  -> only .DS_Store / .lit_test_times.txt / Output   (no source file differs)
```

## Gate lines

```
configure+build (cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm
                 -DCMAKE_BUILD_TYPE=Release && cmake --build build -j8)
  | 5c6f7490a81c7505 | BUILD_RC=0, both CQPass and cq-opt built (never --target CQPass alone)
  | trackX | 2026-09-14c

cd build && lit -v ir-pass/test --filter 'backedge'
  | 5c6f7490a81c7505 | 4/4 Passed, 1.85s (of 1994 discovered) | trackX | 2026-09-14c

ctest --test-dir build -R ir-pass-lit --output-on-failure
  | 5c6f7490a81c7505 | 1/1 Passed 72.15 s — 100% tests passed, 0 failed out of 1 | trackX | 2026-09-14c
```

```
EDIT BATCH 2 (the bd id named in source trigger (3c); docs re-cited to post-edit line numbers)
cmake --build build -j8
  | 5c6f7490a81c7505 | BUILD2_RC=0 — cq-opt and libCQPass.so BOTH STILL BIT-IDENTICAL to the
                       ORACLE after the second comment batch | trackX | 2026-09-14c

cd build && lit ir-pass/test --filter 'backedge|acyclic_nondominated'
  | 5c6f7490a81c7505 | 5/5 Passed, 7.42s (of 1994 discovered) | trackX | 2026-09-14c
```

⚠ `ctest -R ir-pass-lit` was **NOT** re-run after edit batch 2 and is **CITED** from the line
above: the binary is byte-for-byte the same, batch 2 touched no fixture and no `RUN:` line, and
the five fixtures that batch 1 *did* touch were re-run. Reported as
`cited: ir-pass-lit 1/1 Passed 72.15 s @ 5c6f7490a81c7505 (trackX)`.

**Reported as Rule 19 requires:** `ran: ir-pass-lit 1/1 Passed 72.15 s @ 5c6f7490a81c7505 (trackX)`.
NOT run by this track and not claimed: the full `ctest -j6`, `^e2e-`, `cq-opt-equivalence-full`,
the twin matrices, any corpus sweep, any injection matrix.

## Per-probe pipeline rows (all on `5c6f7490a81c7505`; `trackX/probes/run.sh`)

### Calibration — the merge gate's own X5 probes, reproduced
```
x5a_inloop_prep_backedge_carry.c   DECLINE  state prep merged with a quantum register   (= filing)
x5b_inloop_prep_guard_collider.c   ACCEPT   2b 4 mint(s) / 4 left / 0 free              (= filing)
x5c_inloop_ry_backedge_carry.c     ACCEPT   2b 4 mint(s) / 4 left / 0 free              (= filing)
```

### Tripwires + the acyclic fixture
```
control_inplace_ry_reject_stateprep_backedge_phidesc_collider.ll     DECLINE F2
control_inplace_ry_reject_stateprep_backedge_nonphidesc_collider.ll  DECLINE F2
control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll      DECLINE F2
```

### wx8g capability calibration (so nothing below is vacuous)
```
w2d_railcond_inloop_prep_minimal.ll   ACCEPT  2b 2 mint(s) / 2 left / 0 free
w1d_cmpcond_inloop_prep_minimal.ll    ACCEPT  2b 2 mint(s) / 2 left / 1 free
```

### THE RE-DERIVATION — three-way isolation, ONE binary
```
BARE-RAIL (wx8g's newly-admitted spelling)
  w3_railcond_inloop_prep_backedge_phidesc_collider.ll   DECLINE F2
  w3b_railcond_inloop_prep_only_nonphi_mdesc.ll          F2 SILENT -> cq uncompute: dead chain
                                                                      would free a measured register
  w3c_railcond_inloop_prep_only_nonmdesc.ll              DECLINE F2
COMPARE-CONDITIONED (the tripwires' own spelling)
  w1_inloop_prep_backedge_phidesc_collider.ll            DECLINE F2
  w1b_inloop_prep_only_nonphi_mdesc.ll                   F2 SILENT -> control flow inside a loop body
  w1c_inloop_prep_only_nonmdesc.ll                       DECLINE F2
FAILED SCAFFOLDS (recorded; do NOT read these declines as the skip working)
  w1_railcond_… / w1b_railcond_…                         control flow inside a loop body (R7, anchor %b)
  w2_railcond_…                                          cq loop lowering: loop-carried tainted value
                                                           crosses iterations  (lowerLoops, pre-detection)
  w2b_… / w2c_…                                          control flow inside a loop body (R7, anchor %rt)
```

### hrts / l3i1 — the acyclic half, isolated on ONE binary
```
c2_inloop_acyclic_bypass_nondominated_phi.ll        DECLINE F2
c2c_inloop_bypass_phi_DOMINATED_by_merge.ll         F2 SILENT -> uncompute: dead chain …
c2d_inloop_acyclic_bypass_no_phi.ll                 F2 SILENT -> uncompute: dead chain …
c2_…_live.ll                                        DECLINE F2
c2c_…_live.ll                                       cq taint escape: tainted value muxed by a
                                                      classical-condition phi   (the masking hrts names)
```

### Unconstructible shapes (`/usr/local/opt/llvm@19/bin/opt -passes=verify`)
```
a1_nonphi_mdesc_at_arm_slot_INVALID.ll    "Instruction does not dominate all uses!"  input module is broken
a2_nonphi_mdesc_at_pred_slot_INVALID.ll   "Instruction does not dominate all uses!"  input module is broken
c4_arm_block_phi_taking_M_INVALID.ll      "Instruction does not dominate all uses!"  input module is broken
```

### Job 2 — the F × P composition
```
fp_r19.c   ACCEPT  11 lines  2b 3 mint(s) / 2 left / 1 free: 1 verified, 0 violation(s), 0 unproven
fp_m28.c   ACCEPT  29 lines  2b 8 mint(s) / 6 left / 2 free: 2 verified, 0 violation(s), 0 unproven
fp_x1_value_consumer_nonvacuous.c      ACCEPT  (NOT the composition shape — -O1 short-circuits the &&)
fp_x2_or_tree.c                        ACCEPT  2b 3/2/1 verified
fp_x3_two_preps_two_phi_leaves.c       DECLINE condition predates a non-diagonal gate
                                               (anchor %10 = select i1 %9, i1 %5, i1 false)
fp_x4_inloop_phi_leaf_FxPxW.c          DECLINE control flow
fp_x5_m28_positive_polarity.c          ACCEPT  (NOT the composition shape — ±1 folds to add(a, sext …))
fp_x5b_m28_positive_delta3.c           ACCEPT  29 lines  2b 8/6/2 verified   <- the NON-VACUOUS twin of m28
fp_x6_twofn_cross_function.c           ACCEPT  2b 12/8/4 verified; each fn's stream = its single-fn form
fp_x7_negated_prep_or_tree.c           ACCEPT  2b 3/2/1 verified
fp_x8_gate_between_prep_and_kickback.c ACCEPT  2b 3/2/1 verified; source order preserved
```

## ⚠ NOTE FOR A FUTURE CORPUS-SWEEP AGENT

The shared corpus recipe globs `$SES/track*/probes`, so this directory will be swept. **Three
files in it are DELIBERATELY INVALID IR** and are meant to be:
`a1_nonphi_mdesc_at_arm_slot_INVALID.ll`, `a2_nonphi_mdesc_at_pred_slot_INVALID.ll`,
`c4_arm_block_phi_taking_M_INVALID.ll`. They exist to record that
`opt -passes=verify` **rejects** them ("Instruction does not dominate all uses!") — that rejection
IS the measurement (`X5_REDERIVATION.md` §3c). They will produce a parse/verify error row on
**every** binary, identically, so they are never movers; do not "fix" them and do not delete them.

Two more are FAILED SCAFFOLDS kept on purpose, with their reasons in the gate lines above:
`w1_railcond_inloop_prep_backedge_phidesc.ll` and
`w1b_railcond_inloop_prep_nophi_only_nonphi_desc.ll` decline at R7 rather than at F2, and
`w2*_railcond_*` decline at `lowerLoops` / R7. **Reading any of those declines as "the dominance
skip working" is the mistake they are committed to prevent** — the working measurement is `w3*`.
