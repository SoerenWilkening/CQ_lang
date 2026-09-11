# Brief — bd `test_C_libtooling-b6ap`: the MULTI-PHI MERGE PEEL (Track B)

Written 2026-09-11 by the orchestrator (session `01NHxGVinGBKbb499HFCuwhT`). The owner's stated end-goal
for this session: **compile every program that has a valid circuit; over-declines are the defect to
remove**, and `example/grover/grover_oracle_uncompute.c` as it stands today (read it in the primary
checkout; git-excluded) MUST compile once this increment, the F2 narrowing (Track C) and bd `l4x4` (Track D)
have landed. This increment is the FIRST and OUTERMOST wall of that file and is bool-independent.

You are the IMPLEMENTATION agent. Model: opus. Worktree `/Users/sorenwilkening/Desktop/CQ_b6ap`, branch
`merge-phi-peel` (from `main` 0c7380c), its OWN `build/`. **Never write under
`/Users/sorenwilkening/Desktop/CQ_lang/`** — its `build/ir-pass/cq-opt` + `libCQPass.so` are the frozen
ORACLE (`main` 0c7380c) for every A/B measurement. Do NOT commit, do NOT push. Report only what you ran.

## 0. Read first

`SCOPE_b6ap.md` beside this file — ALL of it; it is the design of record and it is measured (44 probes in
`probes/`, README with verdicts). Then `CLAUDE.md` (Prime Directive; Rules 1, 9, 12, 13, 14, 17, 19; the
"block lifetime / sequential regions / hcrg" bullet; the two standing lessons "a stage that runs ONCE has a
round-2-FALSE premise" and "when a set is NARROWED, ask what other predicate names the same gate"; Build &
Test), `bd show test_C_libtooling-b6ap`, PRD `retire-swap-route-PRD.md` §14 (the rail select), and bd
memories `hcrg`, `predmux`, `predicate-runs-once-round2-taint-window-r9e5`.

## 1. Decisions taken by the orchestrator (do not re-litigate; record disagreement in IMPL §7)

1. **The CLONE option** (SCOPE §6): the peeled `select` gets its OWN `CmpInst` clone (or, for a rail
   condition, the rail itself); the region's compare is never shared. Cost 0 lines in `ControlDetect` /
   `ArmClassify` / `SelectClassify`. The measured accept `h09c` (22 lines, 2b clean) is the target stream.
2. **Slot** (SCOPE §2, §8): a new accept-only normalisation `peelIndependentMergePhis` (own file
   `ir-pass/src/MergePhiPeel.cpp` + header), called after the PredMux fixpoint and immediately before
   `detectControlRegions`, **and again on the round-2 path in `repropagateControlMerges`, in BOTH entry
   points**. Measured customer for the round-2 call: `p80` (declines today) vs `p81` (one-phi control,
   accepts).
3. **Predicate P1–P8 as a DECLINE PARTITION** (SCOPE §3), verbatim: diamond/if-else shape; 2-incoming phi;
   every incoming AVAILABLE AT THE PRED (constant / argument / dominates the `br`); peel every passing phi;
   if ≥2 phis fail, leave the region untouched (it then declines loudly as today — `control flow`); muxable
   type (the 4.4/kjd1 set); distinct incomings; condition a `CmpInst` clonable into the merge OR a rail
   leaf; non-dead. **Never hoist** anything out of an arm (`h30b` pins it).
4. **Polarity** (SCOPE §4, Rule 9): `select C, Φ[Pred], Φ[Arm]` when the merge is the TRUE successor,
   swapped otherwise — derive from the `br`, never assume.
5. **Placement**: the select at the phi's own position in the merge block (SCOPE §7); the region's flatten
   must not erase it — SCOPE H-1 (`doomedBlocks`, hcrg) is the first hazard to close, with a fixture.
6. **Witness** (SCOPE §11): hand-IR lit PAIRS — the fused two-phi module vs the same module with the
   phi already spelled as a select — byte-identical lowered output (`diff` the two `%t.ll`s in the fixture
   via a `RUN:` line, or a `compare_files`-style check), because `-O1` re-phi-ifies every plain-C twin
   (SCOPE §0.1: there is NO C twin; the peel restores a spelling `-O1` destroys).

## 2. Rule 12 — red-green, in this order (names follow SCOPE §13; keep the tree's conventions)

Write the DECLINE partition first and watch each go RED/GREEN as SCOPE §13 says: a phi whose arm incoming
is DEFINED IN THE ARM (not peelable; the region keeps declining `control flow`); ≥2 non-peelable phis; an
fp phi over an ANGLE (must stay out — a fp DATA mux goes to the kjd1 fp select, an angle never; say how you
tell them apart and pin both); 3-phi merge (accept, `h`-shape from the probes); the round-2 customer `p80`
(RED on the oracle, GREEN here — this is the "runs twice" pin); the hcrg sequential pair with a peeled
select in region 1's merge hosting region 2's branch; the owner's shapes: state-prep arm (int seeds),
phase arm, bool-rail + phase (16 lines), 6.5 call arm, Q+Q mux, fp mux. For every accept, the injection
matrix (an extra `cqrt_x` on a user register, an extra `cqrt_free`, a `cqrt_copy_*_controlled` on the wrong
flag, a missing `_unc`) must be caught by a whole-file count prefix — report MISSED/DIRTY, target 0/0.

## 3. e2e (STRICT stage 2b, registered in `tests/e2e/CMakeLists.txt` after the `select_bool` group)

- `slice_control_fused_regions_int.c`: the owner's file with `int b0`, `int b1` (the shape that compiles
  with THIS increment alone; SCOPE §16 `h09c`, 22 lines) — read its golden line by line against the
  analytic stream (mint → the region's prep → the peeled select's own mint → copies → strips → frees).
- `slice_control_fused_regions_phase_bool.c`: bool rail condition + phase arm + the `a` mux (16 lines).
- The owner's file VERBATIM is NOT registrable yet (it hits `bare i1 register condition` at the prep arm —
  bd `l4x4` — and then F2); put it under `probes/` with its measured verdict on both binaries, and say in
  IMPL §6 exactly which string it stops on after this increment.

## 4. Corpus diff and record

Re-create the pre-vs-post harness (`session-r9e5/IMPL_B1.md` §5) in
`/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/b6ap/`:
every `ir-pass/test/*.ll` on oracle vs subject (rc + stdout + stderr); this increment is ACCEPT-MONOTONE, so
the only movers allowed are DECLINE→ACCEPT with the `control flow` string, each listed and each explained
(what the region is, what got peeled, the trace). Then the probe corpora (`session-b6ap/probes/`,
`session-r9e5/probes/`, `review_b1_r{1,2,3}_probes/`, `session-3qlq4/probes/`, `session-{r903,l4x4,boi6}/probes/`):
list every mover.

Write `session-b6ap/IMPL_b6ap.md`: §0 measured before coding, §1 the stage (file:line, both call sites),
§2 the predicate as shipped vs SCOPE §3 (every deviation named), §3 red-green log with the RED runs on the
oracle, §4 e2e, §5 corpus + probe diff, §6 the owner's file after this increment (verbatim string), §7 open
questions for the reviewer. New probes under `probes/` with the README extended.

## 5. Gates (Rule 19), in the worktree, in order

1. `cd build && lit ir-pass/test --filter '<name>'` while iterating.
2. `ctest --test-dir build -R ir-pass-lit --output-on-failure`.
3. `ctest --test-dir build -j6 -R '^e2e-' --output-on-failure`; `git status --porcelain tests/`.
4. Full `ctest --test-dir build -j6 --output-on-failure` ONCE at the end (Rule-13 core: a new normalisation
   before region detection; Rule 19 moments 1 and 5). Exact pass line + wall time.
5. `cmake --build build --target cq-opt-equivalence-full` if any diagnostic string was added or moved.

## 6. Non-negotiables

- Build BOTH targets (`cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm
  -DCMAKE_BUILD_TYPE=Release && cmake --build build -j8`), never `--target CQPass` alone.
- Accept-monotone: no fixture or golden may move DECLINE-ward, and no existing accept's output may change
  (0 OUTDIFF except the listed DECLINE→ACCEPT movers).
- Loud strings only; an unpeelable shape keeps declining `control flow` through the existing catch-all.
- No new runtime symbol, no YAML, no `include/` change.
- If the peeled select's placement or the clone interacts with a fence you did not expect (SCOPE H-3's
  fp/F2 over-decline is known and is OQ-2 — do not "fix" F2 here), write it in IMPL §7 and stop there.
- Do not commit, do not push, do not touch the primary checkout's `build/`.

Final message to the orchestrator (≤40 lines): the stage + both call sites; the predicate as shipped;
DECLINE→ACCEPT movers (fixtures + probes) with one line each; the owner's file's next string; gate results
verbatim; §7 open questions.
