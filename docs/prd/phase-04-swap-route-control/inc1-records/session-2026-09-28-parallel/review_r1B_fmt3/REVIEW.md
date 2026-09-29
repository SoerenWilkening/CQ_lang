# Rule-13 review r1B — bd `test_C_libtooling-fmt3` (surface B: the circuits the header CHANGED)

- **Subject**: `c7890520` (on `605f84ee`), diff `9a230646..c7890520`, worktree
  `.claude/worktrees/agent-aea6988dda116aa5b` (used READ-ONLY; this directory is the only thing written there).
- **Binaries**: subject `build/ir-pass/cq-opt` sha-256 `3f6db37f5cf937b4d70f5736e28ceb4a…` = the frozen oracle
  `scratchpad/frozen/cq-opt.main_9a230646` (measured, `shasum -a 256` on both). Every verdict difference below
  is the HEADER: "OLD" = `git show 9a230646:include/CQ.h`, "NEW" = the subject's `include/CQ.h`, same binary.
  For the composition probe: bd `z0re` subject `cq-opt` `8441d60db8fd77b74bd7e660…` (worktree `agent-a284a60d747f2ed82`, HEAD `5651797e`).
- **Time**: ~40 min wall, box load 36–69 throughout (all runs `-j≤3`).
- **Private worktree**: `scratchpad/rev_r1B_fmt3` at `c7890520`, CONFIGURED + `--target cq_runtime` only (no pass build —
  the pass is bit-identical to the oracle); removed at the end.

**What I ran, literally.** (1) The 8 changed/new slices through clang→cq-opt→2b STRICT→link→run under NEW and OLD
header (`probes/pipe.sh`; `results/slices_old_new.txt`). (2) 45 hand-written C probes (`probes/src/*.c`, runtime
values via `atoi/atof(argv[1])`), each under both headers, rolled vs hand-unrolled twin where it applies
(`results/run1.txt` + the logs quoted below). (3) Stage-1 body equality of the 3 `_ternary` slices vs the old
if/else fold, by my own script (not `ternary_module_eq.py`). (4) The CMake harness fix in the private build:
configure, no-op build, header edit, revert, and a false-green/false-red demonstration of the residual.
(5) `tools/angle_select_twin_matrix.py --quick --phi-surface void` under both headers. (6) The loop twin matrix's
OWN generator and `verdict()` on 24 `rifelse`-crossed cells + the same 24 for `req` (`probes/src/rifelse_cross.py`).
(7) A header MUTANT (nomerge kept on `cq_theta_si32` only) against the frontend fixture and two width probes.
(8) The red-green of `tests/frontend/cq_theta_nomerge.c` on the OLD header.

**NOT run**: `lit`, full `ctest`, the full 382-cell loop twin matrix (I read the expected-file diff and ran 24 extra
cells), the full (non-quick) angle-select matrix, `inplace_twin_matrix.py`, the multi-TU z0re `_spec` slice, any
C++ TU / `_Generic` / hand-declared-prototype coverage (r1A's surface), a pass mutant (no pass code changed).

## Verdict: **CLEAR-WITH-ITEMS** — 0 P1, 3 P2, 4 P3

The three restreamed goldens are the same unitary on both polarities, the X pair is on the compare ancilla, the
ancilla returns to |0⟩ before its free (STRICT 2b clean), and the "exact vs 2^-54" claim holds. The in-loop accept
is the Rule-13-cleared in-place Ry if/else emitter, rolled == hand-unrolled, K-independent, and every spelling I
could write in which the condition reads the rotated register declines. G-13's owed probe was run (three shapes +
one matrix cell) and is clean. The ternary slices hand the pass the old fold's bodies byte-for-byte and the twin
gates still compare two independent emitters. The harness fix works and has no spurious-reconfigure cost.

What the round found is that **the change's measured movers are a CORPUS count, and the population is wider in
BOTH directions**: legitimate common-code merges on ONE register are now forbidden too (A→D, F-r1B-1), z0re's
owner-ruled if/else accepts decline once the two compose (F-r1B-2), and 15 of the 16 attribute tokens are
unpinned (F-r1B-3). None is a wrong circuit.

---

## Findings

### F-r1B-1 — P2, INTRODUCED — the header forbids LEGITIMATE merges too: an if/else whose arms share a rotation of the SAME register now DECLINES

`nomerge` cannot tell fmt3's hazard (two calls on DIFFERENT registers made identical by an IPSCCP pin) from an
ordinary common-code sink/hoist of a chained call on ONE register. The second was correct and is now refused:

| probe | source (one register `r`, condition on `q`) | OLD header | NEW header |
|---|---|---|---|
| `g11F.c` | `if (q==m) { r=Ry(r,.9); r=Ry(r,.1); } else { r=Ry(r,.1); }` | **ACCEPT** 11 lines, STRICT 2b clean | DECLINE `impure phase arm` |
| `g11L.c` | the same inside a classically-bounded loop, `q` re-rotated per trip | **ACCEPT** 33 lines | DECLINE `condition predates a non-diagonal gate` |
| `g11G.c` | `if (q==m) { cq_phi(.7); r=Ry(r,.1); } else { r=Ry(r,.1); }` (phase arm + common tail) | **ACCEPT** 11 lines | DECLINE `impure phase arm` |

The OLD accepts are the right circuit, measured: `-O1` sank the common `cq_theta(phi(Ry(r,.9), r), .1)` into the
merge (`probes/out/g11F.OLD.s1.ll`), which is the hand-written diamond `g11T.c`
(`if (q==m) r=Ry(r,.9); r=Ry(r,.1);`), and **`g11F.OLD.trace` is byte-identical to `g11T.NEW.trace`**. The sunk φ
is `[Ry(r), r]` — two names of ONE rail — which is exactly what fmt3's members are NOT. Over-declining a realizable
circuit is a defect by the owner's 2026-09-11 ruling; the owner accepted the if/else RESTREAM as the cost of option
B (TRACK §9, CQ.h "COST, ACCEPTED BY THE OWNER"), and this A→D class is recorded nowhere (TRACK §3 "e2e: 0 A→D" is
true of the e2e corpus, which has no such shape).

Repro (`S=scratchpad/r1B_fmt3`): `$S/runp.sh g11F 4; $S/runp.sh g11L 4; $S/runp.sh g11G 4; $S/runp.sh g11T 4`
(`runp.sh` = same `cq-opt`, NEW then OLD header). Bead filed (bd `test_C_libtooling-4l5q`). The remedy is pass-side (an if/else whose
arms are CHAINS of in-place Ry on one register, or a common-prefix/suffix peel) or an owner ruling that this, too,
is accepted cost — not a header edit.

### F-r1B-2 — P2, INTRODUCED BY COMPOSITION with bd `z0re` — z0re's owner-ruled if/else accepts decline under the fmt3 header

bd z0re (lands BEFORE fmt3, per its commit `9a68064f`) admits "an UNTAINTED Ry-stem angle-select base on the direct
path" (owner ruling 2026-09-28, option a), and its C slices spell it as the IF/ELSE:
`if (q > 3) r = cq_theta(t, 0.75); else r = cq_theta(t, 0.25);` (`t = m + 1`, classical). Measured with the **z0re
binary**:

| slice | z0re cq-opt + OLD header | z0re cq-opt + fmt3 header |
|---|---|---|
| `slice_z0re_angle_select_runtime_base.c` | ACCEPT 10 lines == z0re's golden | **DECLINE** `if/else state prep allocates two rails` |
| `slice_z0re_angle_select_runtime_base_exact.c` | ACCEPT 10 lines == z0re's golden | **DECLINE** same string |
| same `_exact` respelled TERNARY (`probes/src/z0re_exact_ternary.c`) | — | ACCEPT, **byte-identical to z0re's `_exact` golden** (the frozen oracle declines it `rotation angle`) |

So whichever of the two lands second turns z0re's e2e entries RED at the merge gate (`_spec` is multi-TU and was
not run; it has the same if/else and is expected to move the same way). The decline is an over-decline (the circuit
is one rail: `alloc(t); Ry(B); cRy(f, A−B)` — what z0re already emits). And z0re's slice headers state that
"`-O1` folds it to ONE `cq_theta(t, select(q > 3, .75, .25))`" — false under fmt3 (L7, to be corrected at the
source in the same merge). TRACK §9.7 says "the orchestrator re-runs the header A/B after z0re lands"; this is that
measurement, done now: **2 of 2 single-TU z0re angle-select slices A→D**. Fix at merge: respell z0re's C slices as
the ternary (goldens unchanged, measured for `_exact`) and pin the if/else spelling as a decline with an L8 trigger
naming bd gjn2 — or an owner ruling. Repro:
`OPT=$S/cq-opt.z0re $S/pipe.sh <z0re>/tests/e2e/slice_z0re_angle_select_runtime_base_exact.c X <subject>/include`.

### F-r1B-3 — P2, INTRODUCED (unpinned conjunct) — 15 of the 16 `nomerge` tokens are pinned by nothing

`tests/frontend/cq_theta_nomerge.c` exercises `cq_theta_si32` only, and every stage-1 mover in the implementer's
A/B is an `int` slice. MUTANT: a header keeping `CQ_THETA_NOMERGE_` on `cq_theta_si32` ONLY (`sed` over the
subject header; `grep -c '^CQ_THETA_NOMERGE_'` 16 → 1): the frontend fixture stays **GREEN** (FileCheck rc 0), and
the `double`/`_Bool` width probes `gw_f64.c`/`gw_b1.c` silently go back to the MERGED 11-line angle-select stream.
Every committed layer would pass. The attribute IS effective at every width I tried (`gw_{b1,i8,i16,i64,u32,f32,f64}.c`
all restream 11 → 13 lines, STRICT 2b clean, correct `cqrt_ry_<W>_controlled` width) — it is the PIN that is
missing. One `CHECK-LABEL` function per `_Generic` row in the frontend fixture (an if/else of two identical-shape
`cq_theta` on that width, `CHECK: br i1`) closes it. Overlaps r1A's surface (does `nomerge` close the class);
filed here because it is a Rule-12 item on the change itself.

### F-r1B-4 — P3, INTRODUCED — `angle_select_twin_matrix.py` goes VACUOUS, not divergent, and bd gjn2 says the opposite

bd gjn2's note (and TRACK §9.7) predict the instrument's Ry cells "will … DIVERGE". Measured
(`--quick --phi-surface void --jobs 3`): OLD header **6 BOTH-ACCEPT-IDENTICAL + 3 BOTH-DECLINE**; NEW header **all 9
Ry cells `DEGENERATE-FOLD`** ("Reported, not compared — there is nothing under test in that cell"), tally
`flagged 0`, **rc 0**. It reports a pass while comparing nothing — L10's failure mode exactly. Nothing registered in
ctest runs it (grep over every CMakeLists/lit.cfg/shell harness: 0 hits), so no gate goes red or green on it.
Fix: generate the Ry subject as the ternary (as gjn2 suggests), and make `DEGENERATE-FOLD` a FLAGGED verdict when
the cell's angle axis is not `equal`. Note appended to bd gjn2. Files: `results/asm_{new,old}.txt`.

### F-r1B-5 — P3, INTRODUCED — the loop twin matrix still files `rifelse` under "E — the two decline controls"

The expected-file edit is exactly one data row (`m_none_rifelse_none_none_none` DECLINE-BOTH-DIFFERENT →
ACCEPT-IDENTICAL) plus comment blocks — confirmed from the diff. But `RY_DECLINE_REGION = ("rcond", "rifelse")`
and the `# E — the two decline controls` group are unchanged, so the new C-reachable accept keeps ONE matrix cell
while `req` gets the A-star / RGATE / RECORD crossings. I ran those crossings with the matrix's own `sources()` and
`verdict()` (`probes/src/rifelse_cross.py`, 24 cells): **`rifelse` = `req` cell-for-cell** (14 ACCEPT-IDENTICAL,
8 DECLINE-BOTH, 2 DECLINE-BOTH-DIFFERENT, 0 divergences); the OLD header gives 5/16/3 (DECLINE-BOTH /
-DIFFERENT / UNROLLED-ONLY), so the driver sees the header. Moving `rifelse` to `RY_OTHER_REGION` would add ~20
witnessing cells at no red; the name "decline control" is now false for it (L7). Deliberate expected-file edit.

### F-r1B-6 — P3, INTRODUCED — the record's cost statement names only the restream; the population moves both ways

CQ.h / `docs/frontend.md` §3.1 / TRACK §9 describe the cost as "the IF/ELSE spelling … lowers as two controlled Ry
— the same unitary" and the movers as "5 = 3 STREAM + 2 D→A". Those are corpus counts. Measured on hand probes,
header-only, same binary:
- **D→A, all correct** (twin byte-identity or analysis): a flat Ry if/else followed by a NON-DIAGONAL gate on the
  condition register (`g17F` ACCEPT vs its ternary twin `g17T` DECLINE `condition predates a non-diagonal gate` on
  BOTH headers — i.e. `AngleSelectEmit` over-declines this, the in-place path does not); `g1U/g2U/g13U` (flat, 3
  regions + trailing gates); run-time classical angles (`g7F`, `g7R` rolled == `g7U` unrolled); non-finite angles
  (`g8F` inf, `g8N` NaN — consistent with the oracle, which already accepts `Ry(inf)` uncontrolled `g8u` and in a
  diamond `g8D`; no additivity is involved on the compare path); two sequential if/else regions sharing ONE compare
  (`g16F`, two flags minted and stripped); the rolled forms `g1R`, `g2R`, `g7R`, `g13R`.
- **A→D**: F-r1B-1 and F-r1B-2.
Consequence for bd gjn2 (note appended): its plan "reuse AngleSelectEmit / its fences" would RE-DECLINE `g17F`,
`g1U`, `g7F` and the whole in-loop form (S7) unless it keeps the in-place path's reach — a by-difference re-route
is an A→D change and owes its own round.

### F-r1B-7 — P3, INTRODUCED (record) — TRACK §9.2 `_ne` writes the old controlled angle as `−fl(0.6)`

The committed old golden is `-0x1.3333333333334p-1` = −(fl(0.9) − fl(0.3)), one ulp from −fl(0.6)
(`-0x1.3333333333333p-1`) — the very L7-F1/F3 slip `slice_control_angle_select_ry.c`'s header warns about. The
conclusion survives: the old `_ne` realized `0.9 − 0x1.3333333333334p-1 = fl(0.3) − 2^-54` on the q==5 branch; the
new stream emits `fl(0.3)` and `fl(0.9)` verbatim. Fix the one symbol.

---

## The five questions, answered with evidence

**Q1 — restreamed goldens.** Re-run on the subject binary + NEW header: all three `== golden`, STRICT 2b
`2/2/1 verified, 0 violation, 0 unproven`; under the OLD header each reproduces its pre-fmt3 golden. Stage-1 of
`_ne` (`probes/out` / `results/slices_old_new.txt`): `icmp eq %q, 5; br %c, %T(Ry .3), %F(Ry .9)` — `-O1` swapped
the successors (Rule 9). Emission (`SwapRouteEmit.cpp` `emitInPlaceRotationRegion`, compare path): arms in
successor order, a ¬flag arm is `x(f); T; x(f)` on the MINTED flag, the second theta chained onto the first (M-β).
- `ry`: f=[q==5]; `cRy(f,.9); X f; cRy(f,.3); X f` → f=1: Ry(.9) (second gate sees f=0); f=0: Ry(.3). Source: q==5→.9. ✓
- `_ne`: `cRy(f,.3); X f; cRy(f,.9); X f` → q==5: Ry(.3), q≠5: Ry(.9). Source `if (q != 5) .9 else .3`. ✓
- `_derived_base`: the same on the `mul` rail `h2`; FREEZE holds (one free = the flag; `h2` left allocated; two M-A warnings, as before). ✓
- X only on `h2`/`h3`, the `cq_template_icmp_*` result (ancilla), never on `h0`/`h1`. Between mint and
  `icmp_…_unc` only the disjoint rotated rail moves, so the strip recomputes f and returns it to |0⟩; the X pair is
  self-inverse. 2b verifies both free sites.
- "Exact vs 2^-54": old `ry` f=1 realizes `0.3 + 0x1.3333333333334p-1 = fl(0.9) + 2^-54` (0.9000000000000000777
  vs 0.9000000000000000222); new emits `fl(0.9)` and `fl(0.3)` verbatim. ✓ (see F-r1B-7 for the `_ne` bullet).
- Width sweep (7 register types): same restream, correct `cqrt_ry_<W>_controlled` symbol, 2b clean.

**Q2 — the in-loop accept.** Emitter: `emitInPlaceRotationRegion` on both arms (compare path), rolled by the drbq
Inc-3 loop form. Its slice: rolled trace == unrolled trace == golden (39 lines), 2b STRICT clean on both; OLD
header declines both (`condition predates a non-diagonal gate`). K-independence re-measured on my own `g2R`: 90
lowered lines at K=3 and K=1000, the only diff is the bound constant.
- **G-13 (owed): trailing non-diagonal gate on every register the condition reads.** `g1` (condition `((q^(i+k))&6)==4`,
  `q` NOT rotated in the body, `Ry(q,.7)` and `Ry(r,.2)` after the loop): rolled == unrolled (47 lines), every
  per-trip `xor/and/icmp` rail `_unc`'d and freed before the post-loop `Ry(q)`. `g2` (`q` re-rotated per trip +
  post-loop gates): rolled == unrolled (41). `g13` (LICM-hoisted `p = q*3` read by the condition, post-loop
  `Ry(q)`): ACCEPT both, 2b clean both; traces differ ONLY in the position of the per-region `and/xor` `_unc`
  pairs (all read-only functions of the unmodified `h2`, discharged before `mul_unc(h2)` and before `Ry(h0)`) —
  the SAME divergence the single-arm diamond `g13DR/g13DU` shows on the ORACLE with the OLD header, so it is
  pre-existing, and equivalent. Matrix cell `m_none_rifelse_none_none_rypost`: ACCEPT-IDENTICAL.
- **Condition reads the rotated register**: `g3R/g3F` (`(r&6)==m`), `g4R` (`(q^r)&6`), `g5R` (pre-loop `p=r*3`),
  `g14R/U` (`t = r^m` carried), `g15R/U` (`q ^= r` in body) — **all DECLINE on both headers**. Bool rail
  condition in a loop (`g6R`) declines (`control flow`, both headers). No self-controlled accept found.
- **¬flag convention**: compare path = X bracket on the minted ancilla (the goldens); a rail if/else never reaches
  additivity — `RailCond && Arms.size() > 1` declines at classification (TRACK's `n23`; my `g6R`).
- **Non-finite angles**: F-r1B-6 — verbatim, consistent with the oracle's existing treatment; the additivity
  hazard CLAUDE.md names cannot arise on this path.
- **Twin-matrix edit**: exactly one data row changed (git diff), plus comments; see F-r1B-5 for the grouping.
- Not an accept: iteration-local rotated `r` with a measure in the body (`g12R`) still DECLINES rolled while its
  unrolled twin `g12U` now ACCEPTS — the known `il*`×`bcar` residue (CLAUDE.md §2), safe direction; the header
  adds a customer.

**Q3 — ternary slices.** My own stage-1 comparison (all `define` bodies, attribute refs stripped): the three
`_ternary.c` under the NEW header == the three if/else slices under the OLD header, **IDENTICAL ×3**, and each
`_ternary` is header-independent (identical under both). Each `_ternary` golden `cmp`-equals the pre-fmt3 golden of
its sibling (`git show 9a230646:…`). The two twin gates compare `_ternary` (classifyAngleSelect → `AngleSelectEmit`
by difference) against `_twin` (an uncontrolled `Ry(B)` + an Inc-1 in-place DIAMOND, `emitInPlaceRotationRegion`)
— two different emitters over two different stage-1 shapes, so still independent. `_derived_base_ternary`'s
`noinline` is a spelling difference the old slice did not have; module bodies are identical regardless.

**Q4 — the harness fix.** Private build (Unix Makefiles): configure → key `5d33ed68…`; no-op `cmake --build
--target cq_runtime` twice → **0 reconfigures**; append a comment to `include/CQ.h` → the next `--target
cq_runtime` build **re-runs CMake** and the key becomes `bc9a3c16…` (all 513 `CQ_S1_BASE=` entries in
`CTestTestfile.cmake`); the build after that → 0 reconfigures (no spurious churn); revert → key back to `5d33ed68…`
(deterministic). End-to-end, running `run_slice.sh` exactly as ctest would (ENV read from `CTestTestfile.cmake`,
subject binaries, `probes/slice_env.sh`): subject header → `slice_control_angle_select_ry` PASS; swap in the OLD
header **without building** → **PASS (false GREEN — the residual)**; `cmake --build` → key `635411c6…` → **FAIL**
(correct: the old header produces the old stream); ternary PASS under both; restore subject header without building
→ **FAIL (false RED)**; build → PASS. So the residual is exactly: *`ctest` after a header edit with no intervening
`cmake --build` of ANY target serves the last configure's key, and a warm cache entry for that key makes the slice
LIE in either direction.* The merge gate (`cmake --build build -j8 && ctest`) is not exposed. The key hashes the
absolute `-I<source>/include` flag, so keys differ between worktrees (expected; one cache per build dir). No other
configure-time snapshot of `include/` exists (every `execute_process`/`configure_file` in tracked CMake read:
`backend_contract.py` snapshots `runtime/*.h`, not `include/`). e2e sources `#include` only `"CQ.h"`, so the key is complete.

**Q5 — other instruments.** F-r1B-4 (angle-select matrix vacuous, not red; not in ctest). Loop twin matrix: 1 cell
moved, blessed by hand, my 24 extra cells clean (F-r1B-5). `inplace_twin_matrix.py` has two if/else subjects
(lines 713/717) and was not run by me or the implementer.

## Standing-lesson questions

- **L1**: no pass stage changed (binary bit-identical). The header only routes programs into existing emitters,
  whose round-2 records (`WireRuled` CmpCondRead, `markRailCondRead`) are pre-existing. N/A.
- **L2/L3**: the implementer listed the sets WIDENED. The sets NARROWED were not asked: (i) the legitimate
  same-register common-code merges (F-r1B-1), (ii) z0re's direct-path set reached via if/else (F-r1B-2), (iii) the
  instruments whose subject IS the if/else spelling (F-r1B-4, F-r1B-5). Asked here by probe.
- **L4**: no walker touched.
- **L5**: `nomerge` answers a semantic question ("do these two calls denote the same register?") with a blanket
  syntactic one ("never merge"); that is the owner-ruled design, and F-r1B-1 is its measured price.
- **L7**: F-r1B-4 (gjn2's "DIVERGE"), F-r1B-5 ("decline control"), F-r1B-6 (cost statement), F-r1B-7 (`−fl(0.6)`),
  and z0re's "`-O1` folds it to ONE call" (F-r1B-2). The source comments the change edited
  (`ArmClassify.cpp`, `SelectClassify.cpp`, `AngleSelectEmit.h`, `ControlPlan.h`) read correctly against my probes.
- **Rule 14**: no predicate added.
- **Rule 12**: the four new `.ll` declines are pure negatives (one `CHECK: error:` line, `not` on the RUN line).
  The frontend fixture IS red on the OLD header (FileCheck rc 1, five functions fail) and green on the new one —
  but see F-r1B-3 for what it does not pin. (My first red-green check printed `rc=0` for both headers because a
  `$(basename …)` inside the `echo` reset `$?`; re-measured with the status taken directly. Recorded because it is
  L10's failure mode, in my own harness.)
- **Mutants**: no code conjuncts exist; the one conjunct is the attribute, mutated per width in F-r1B-3.

## Tested and did not break

Q1 polarity (both successors), ancilla-only X, |0⟩ free, 2b STRICT, width sweep ×7; the in-loop accept's twin
identity, K-independence, G-13 ×3 + matrix `rypost`; five self/mixed/derived-condition spellings (all decline);
bool-rail loop; 24 `rifelse` matrix crossings; runtime angles flat + rolled (twin-identical); non-finite angles;
shared-compare sequential regions (`g16F`, correct); fused two-register if/else (`g16B`, declines both headers);
`switch` of Ry arms (`g9S`) and nested if/else (`g10N`) decline on both headers (string moves only); ternary body
equality ×3; harness reconfigure/no-churn/residual in both directions.

## Composition

Exercised: bd z0re × fmt3 — F-r1B-2 (2 z0re slices A→D; the ternary restores z0re's golden byte-for-byte).

## Beads

- Filed: F-r1B-1 as bd `test_C_libtooling-4l5q` (P2 bug, discovered-from fmt3).
- Appended notes: bd `test_C_libtooling-gjn2` (F-r1B-4, F-r1B-6's reach caveat), bd `test_C_libtooling-z0re`
  (F-r1B-2), bd `test_C_libtooling-fmt3` (summary + F-r1B-3).
