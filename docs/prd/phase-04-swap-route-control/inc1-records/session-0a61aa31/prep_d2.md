# prep_d2 — Inc-1 prep (d2): the loop twin matrix under the new surface

Agent: prep_d2. Worktree: $SP/wt/prep-d, branch `3qlq-inc1-matrix` (rebased onto c4bd888).
SUBJECT = $SP/wt/prep-d/build (this branch). ORACLE = $SP/wt/pre-3qlq/build (52d7764).

## 2026-09-05 — step 0: read the plan of record
- Read BRIEF_common.md, BRIEF_prep_d2_matrix.md, BRIEF_prep_d_matrix.md,
  progress/prep_d.md (full), progress/review_r1_L5.md §F-L5-2 + §F-L5-7,
  progress/fix_r1.md (full, incl. the Inc-1b merge section).
- Worktree state MEASURED: `git log --oneline -12` shows 6 prep-d commits on top of
  c4bd888 (`ffa95cc` tip); `git status --short` empty; no `build/` dir yet.
- `include/CQ.h:62` in this worktree IS the shipped void surface, column-aligned:
  `void                cq_phi     (double angle);`  ⇒ F-L5-7(b) reproduces here.
- Launched background configure+build (both CQPass and cq-opt) -> prep_d2_build.log.

## 2026-09-05 — step 1 (resumed after rate-limit kill): build was ALREADY COMPLETE
- `$SP/progress/prep_d2_build.log` ends `BUILD_RC=0`; both targets linked.
- FRESHNESS MEASURED: `build/ir-pass/{cq-opt,libCQPass.so}` mtime 16:56 vs newest
  `ir-pass/src/*.cpp|include/*.h` mtime 16:52 -> build is NEWER than every source. No rebuild.
- `git status --short` empty; tip `ffa95cc` (6 prep-d commits on c4bd888).
- Read: BRIEF_common, BRIEF_prep_d2_matrix, BRIEF_prep_d_matrix, progress/prep_d.md,
  review_r1_L5 §F-L5-2 + §F-L5-7, progress/fix_r1.md (full incl. the Inc-1b merge).
- Next: read the three instrument headers + the guard at loop_twin_matrix.py:~1313 + the
  ctest registration at tests/e2e/CMakeLists.txt:~4263.

## 2026-09-05 — step 2: the state of the two `loop-twin` ctest entries, MEASURED
- `python3 tools/loop_twin_matrix_quarantine_test.py` at `ffa95cc` -> **RC=1, TRACEBACK**:
  `TypeError: install.<locals>.<lambda>() takes 1 positional argument but 2 were given`
  (`loop_twin_matrix.py:793` calls `control_sources(cname, cfg.phi_surface)`; the selftest's
  stub at `loop_twin_matrix_quarantine_test.py:104` is `lambda name: ("", "")`).
  ⇒ prep-d's `--phi-surface` signature change broke `e2e-loop-twin-quarantine-selftest` and
  it was not re-run. FINDING (mine to fix, job 5). The selftest is NOT in my touch list, but
  `ctest -R loop-twin` must be green, so I take it.
- `e2e-loop-twin-matrix` (CMakeLists.txt:4263) passes NO `--phi-surface` -> F-L5-7(a), 175
  HARNESS-ERROR against the shipped header. Both entries are therefore red/meaningless at
  `ffa95cc`.
- Nothing outside `tools/loop_twin_matrix*.py` hard-codes the two table paths (grep over
  *.py/*.txt/*.md/CMakeLists.txt); only CLAUDE.md and ROADMAP.md MENTION them, and those are
  the docs agent's.

## 2026-09-05 — step 3: F-L5-7 fixed + the void mode made the SHIPPED gate (commit dadfca3)
- `phi_surface_of_header(text)` — pure, C-comments stripped, whitespace-insensitive.
  MEASURED against three real headers:
    include/CQ.h (shipped)                -> void
    $SP/wt/pre-3qlq/include/CQ.h          -> register
    $SP/progress/prep_d_include/CQ.h      -> void
- The guard now runs on EVERY invocation, BOTH directions (F-L5-7(a) as well as (b)).
- `SURFACE_TABLES`: void owns the LIVE names; the register tables were `git mv`d to
  `tools/loop_twin_matrix.{expected,quarantine}.register.txt`, content byte-unchanged.
- The void mode's early-return block is DELETED — void falls through the ordinary gate.
- `SURFACE_CONTROL_VERDICTS` pins both boundary controls per surface (void pins TBD until
  measured; placeholder written from prep_d's oracle run and to be re-measured on the SUBJECT).
- `tests/e2e/CMakeLists.txt:4278` gains `--phi-surface void` + the reason.
- SELFTEST: was RED (TypeError, 0 cases ran). Fixed, then extended 12 -> 27 cases:
  every case under BOTH surfaces + 2 guard-mismatch cases + 1 case asking
  `phi_surface_of_header` about the REAL include/CQ.h. **27 case(s), 0 failure(s)**, no
  clang/opt/plugin.
- Launched the SUBJECT void 274-cell measurement (instrumented copy under
  $SP/progress/prep_d2_run1, dumping every TRACE-DIVERGENCE signature) -> run1.log.

## 2026-09-05 — step 4: the SUBJECT void run, MEASURED (run1)
Instrumented copy, SUBJECT build $SP/wt/prep-d/build, shipped `include/`, 274 cells, --jobs 6.
TALLY (bare verdicts, quarantine deliberately EMPTY so nothing was labelled):
  ACCEPT-IDENTICAL 126 · UNROLLED-ONLY 59 · DECLINE-BOTH 39 ·
  DECLINE-BOTH-DIFFERENT 21 · TRACE-DIVERGENCE 29
⇒ IDENTICAL to review_r1_L5's subject tally at fa96336. **The round-1 fixes moved NONE of
  the 14** (F-L5-2's list reproduces cell-for-cell).
Partition against the 15 register-surface quarantined cells:
  all 15 still diverge under void; the other 14 are exactly F-L5-2's list. 0 cells dropped.

CLASSIFICATION, from FULL TRACES (not from the verdict):
 * 8 cells with the `add` a-register SUFFIX — `m_{add,none,rz,xor}_{der,range}_add` —
   are class B (bd a3z7) CHARACTER FOR CHARACTER:
     rolled  `cqrt_addc_i32(h0, 3)` then `cqrt_measure_i32(h0)`
     flat    `cq_template_add_i32_hl(h0, 3) -> hN` then `cqrt_measure_i32(hN)`, h0 left
             allocated and entangled. Same mechanism, same direction (FLAT deficient).
 * 4 cells `m_xor_{der,gt}_{none,rz}` are the SAME M-C decision one axis over (the `xor`
   PREFIX): rolled `cqrt_xorc_i32(h0,9)` in place, flat `cq_template_xor_i32_hl(h0,9)->h1`
   out of place — but the flat rail IS `_unc`'d and freed, so NEITHER side leaks. Same
   owner, DIFFERENT direction. Recorded as class B with its own direction string.
 * 2 cells `m_xor_range_{none,rz}` carry a SECOND, independent phenomenon on top:
   `clang -O1` folds the flat spelling's mask 9 -> 8 (the range test `x-6 <u 14` is
   closed under a bit-0 flip because 6 and 20 are even), so the two sides are not the same
   program. FITS NEITHER FILED CLASS -> **FINDING**, see the OWNER QUESTION section.
 * `m_*_rz_*` cells carry the SAME DIGEST as their `_none` twins — the D2 witness the
   docstring predicted (an uncontrolled void `cq_phi` is deleted, so the `rz` axis value
   collapses onto `none`). 14 cells, 7 distinct digests.

BOUNDARY CONTROLS under void on the SUBJECT, MEASURED:
  q_noregion  ACCEPT-IDENTICAL   (its two sources are byte-identical on both surfaces —
                                  verified, `control_sources` diff)
  q_armoncond TRACE-DIVERGENCE   (the ORACLE gave DECLINE-BOTH-DIFFERENT)
  ⇒ and the divergence IS bd 1m5p class A verbatim: rolled leaves the top rail
    `h3 = sqrt((double)a + 3.0)` allocated, flat discharges all three LIFO.
    The control cannot bound the quarantine under void, because a branch phase writes no
    register, so the control's own body now SATISFIES class A's precondition. It is kept,
    pinned BY SIGNATURE (dbf4c162d1de5139) as the smallest class-A reproducer in the tree,
    and the file says it no longer bounds anything.

## 2026-09-05 — step 5: the void tables, WRITTEN AND VERIFIED
- `tools/loop_twin_matrix.quarantine.txt` (NEW, void surface): **29 cells** —
  6 class A (bd 1m5p) · 21 class B (bd a3z7; 17 B-suffix FLAT-deficient + 4 B-prefix
  NEITHER-deficient) · 2 class C (`m_xor_range_{none,rz}`, NO FILED ISSUE — the FINDING).
  Every digest re-measured on the VOID surface; the register-surface digests are NOT
  carried over (a register-surface trace digest says nothing about a void one).
- `SURFACE_CONTROL_VERDICTS` pins may now be a `(verdict, digest)` PAIR, and
  `q_armoncond`'s is `("TRACE-DIVERGENCE", "dbf4c162d1de5139")` — a control pinned to a
  divergence is pinned to THAT divergence.
- `QUARANTINE_HEADER` + `EXPECTED_HEADER` (both script-owned) rewritten: class B split
  into its two directions, class C written out with its measured `-O1` mask fold, the
  class-A note that `q_armoncond` is now an INSTANCE of class A, and a "which surface does
  this file measure" banner.
- `--regenerate` under void, SUBJECT, 274 cells, 20:12:35 -> 20:21 (~8m30s at --jobs 6 on
  a loaded box): **"regenerated .../loop_twin_matrix.expected.txt (245 cells; 29
  quarantined and omitted)"**, exit 0. It REFUSES to write over any hard failure, so a
  clean write is itself the proof that all 29 quarantined cells diverge with their pinned
  signature and BOTH boundary controls match their pins (incl. the new signature pin).
- Header re-spliced from the updated `EXPECTED_HEADER` constant (the regenerate parent had
  imported the pre-edit module), rows byte-unchanged: 245.
- Final plain gate run launched -> prep_d2_gate.log.

## 2026-09-05 — step 6: BOTH loop-twin ctest entries GREEN, and the pre->post diff
- `ctest --test-dir build -R 'loop-twin' --output-on-failure` after a cmake reconfigure:
    e2e-loop-twin-quarantine-selftest   Passed   1.33 s
    e2e-grover-loop-twin-identical      Passed   0.05 s
    e2e-loop-twin-matrix                Passed 693.37 s   <-- was HARNESS-ERROR x175
    e2e-inplace-ry-loop-twin-identical  Passed   0.04 s
  **100% tests passed, 0 failed out of 4**, total 694.87 s. (693 s is ~2x the 8h7d.5
  quiet-box figure quoted in CMakeLists; this box is carrying other agent sessions.)
- Plain gate run tally, SUBJECT, void, 274 cells:
    ACCEPT-IDENTICAL 126 · UNROLLED-ONLY 59 · DECLINE-BOTH 39 ·
    DECLINE-BOTH-DIFFERENT 21 · TRACE-DIVERGENCE 29 (all quarantined)
    controls: q_noregion ACCEPT-IDENTICAL · q_armoncond TRACE-DIVERGENCE (pinned by sig)
  "all cells match ...; all 29 quarantined cells diverge with their pinned signature;
   both boundary controls as pinned for the `void` surface"
- LOOP pre1 -> post1 TRANSITIONS (99 cells unchanged, 175 moved):
    DECLINE-BOTH-DIFFERENT -> ACCEPT-IDENTICAL        74   <-- Inc 1's capability
    DECLINE-BOTH           -> UNROLLED-ONLY           31
    DECLINE-BOTH-DIFFERENT -> UNROLLED-ONLY           24
    DECLINE-BOTH-DIFFERENT -> TRACE-DIVERGENCE        14   <-- F-L5-2, now quarantined
    DECLINE-BOTH           -> DECLINE-BOTH-DIFFERENT  13
    a3z7-quarantined       -> TRACE-DIVERGENCE         8   (label only; --out prints bare)
    1m5p-quarantined       -> TRACE-DIVERGENCE         5   (label only)
    PHI-UNLOWERED-BOTH     -> TRACE-DIVERGENCE         2   <-- D2 deletion works
    PHI-UNLOWERED-BOTH     -> ACCEPT-IDENTICAL         2   <-- D2 deletion works
    DECLINE-BOTH-DIFFERENT -> DECLINE-BOTH             2
  PHI-UNLOWERED is GONE (4 -> 0): every uncontrolled void `cq_phi` is now deleted (D2).

## 2026-09-05 — step 7: F-L5-7(b) REPRODUCED IN THE OTHER TWO INSTRUMENTS (commit ea329a7)
- The literal-substring guard was DUPLICATED in `inplace_twin_matrix.py:1643` and
  `angle_select_twin_matrix.py:751`. MEASURED: it refused the shipped header and killed
  this increment's own first inplace POST launch. Both now call
  `phi_surface_of_header` via the existing `from loop_twin_matrix import ...` (Rule 14).
- RED-GREEN, both instruments, MEASURED exit codes:
    --phi-surface void --include-dir $SP/wt/pre-3qlq/include -> **rc 2**, names `register`
    --phi-surface void --include-dir <subject>/include       -> **rc 0**, 472 / 158 cells
- `inc1-records/loop_post1.txt` committed (274 rows + a provenance header that answers the
  PRE table's four predictions one by one). Two load-bearing answers:
    * PHI-UNLOWERED 4 -> 0 (D2 deletes every uncontrolled void cq_phi).
    * the 100 PHI-FREE cells did NOT move, 100 of 100, measured against the REGISTER
      committed verdicts — Increment 1 moved no cell whose program never says `cq_phi`.
- inplace void POST run relaunched (472 cells) -> prep_d2_inplace.log.

## 2026-09-05 — step 8: the inplace + angle-select POST records (commit 399def0)
INPLACE, ALL-PAIRS, 472 cells, void, SUBJECT, --jobs 6, exit 0:
  PREFIX-IDENTICAL 215 · RZ-ONLY(over-decline) 119 · PREFIX-MISMATCH 114 · DECLINE-BOTH 24
  PRE (oracle):  RY-ONLY 232 · DECLINE-BOTH-DIFF 87 · PHI-UNLOWERED 78 · DECLINE-BOTH 75
  transitions (all 472 cells, same set):
    RY-ONLY -> PREFIX-IDENTICAL 139 · RY-ONLY -> PREFIX-MISMATCH 93 ·
    DECLINE-BOTH-DIFF -> RZ-ONLY 69 · PHI-UNLOWERED -> PREFIX-IDENTICAL 62 ·
    DECLINE-BOTH -> RZ-ONLY 50 · DECLINE-BOTH -> DECLINE-BOTH 24 ·
    PHI-UNLOWERED -> PREFIX-MISMATCH 16 · DECLINE-BOTH-DIFF -> PREFIX-IDENTICAL 13 ·
    DECLINE-BOTH-DIFF -> PREFIX-MISMATCH 5 · DECLINE-BOTH -> PREFIX-IDENTICAL 1
  PHI-UNLOWERED 78 -> 0 (D2). The 114 mismatches are prep_d's OQ-3 at scale, by cfg:
    diamond 75 · ifelse 27 · clsbefore/clsbetween/negated 4 each. NOT a gate (no ctest).
ANGLE SELECT, 158 cells, void, SUBJECT, WITH --oracle, exit 0:
  RED-GREEN-MISS 66 · PHI-UNLOWERED 28 · RZ-VOID-NO-TWIN-ACCEPT 18 ·
  EXPECTED-DECLINE-RUNTIME-ARMS 13 · DEGENERATE-FOLD 12 · BOTH-DECLINE 11 · SUSPICIOUS 10
  Only THREE transitions: BOTH-ACCEPT-IDENTICAL -> RED-GREEN-MISS 66 (all stem=theta,
  shapes the ORACLE already accepted — D5 leaves the Ry stem alone);
  RZ-VOID-NO-TWIN-DECLINE -> ACCEPT 18 (THE INCREMENT: every stem=phi cell now lowers,
  `2 rz_i1, 2 cqrt_x`); PHI-UNLOWERED -> PHI-UNLOWERED 28.
  ⚠ MEASURED: all 28 PHI-UNLOWERED rows read `select@new 0 residual` — the residual is
    on the ORACLE leg. On the SUBJECT it is 0 of 28. The verdict fires on ANY leg, so in
    a run that HAS an oracle it cannot go away; reading it as "Inc 1 left 28 calls
    unlowered" is exactly backwards. Recorded in the record's header.
- stateprep PRE (oracle, 297 cells) launched -> prep_d2_sp_pre.log

## 2026-09-05 — step 9: the --stateprep void PAIR (commit 7f4776f) + final scope
STATEPREP, 297 cells, void, --jobs 6, exit 0 on both halves:
  PRE (ORACLE 52d7764):  IDENTICAL 84 · SUBJ-DECLINES-TWIN-ACCEPTS 73 · DECLINE-BOTH 53 ·
                         PHI-UNLOWERED 45 · DECLINE-BOTH-DIFF 32 · SUBJ-ACCEPTS-TWIN-DECL 10
  POST (SUBJECT):        IDENTICAL 130 · SUBJ-DECLINES-TWIN-ACCEPTS 85 · DECLINE-BOTH 40 ·
                         DECLINE-BOTH-DIFF 31 · SUBJ-ACCEPTS-TWIN-DECL 11 · PHI-UNLOWERED 0
  238 of 297 cells did not move. PHI-UNLOWERED 45 -> 0 with 34 landing on IDENTICAL and
  NONE on a decline. Measured over all 297 rows: ZERO transitions out of an accepting
  verdict.
  ⚠ BOTH HALVES WERE TAKEN AFTER Inc 1 EXISTED (the PRE half is the ORACLE BINARY run
    late). Stated in the PRE record's own header; it is not a record nobody could have
    influenced, and it must not be read as one.
  ⚠ A HEADER CLAIM I WROTE WAS MEASURED FALSE BEFORE COMMIT and is corrected in place:
    I said the Inc-4 F2 seed fence was the largest message among the
    SUBJECT-DECLINES-TWIN-ACCEPTS rows. MEASURED it is the THIRD — `control flow` 44->48,
    `rotation angle` 18->22, seed 8->12, `value-arm swap-route` 3->3.
FINAL SCOPE, `git diff --name-only ffa95cc..HEAD` (14 files):
  tools/{loop,inplace,angle_select}_twin_matrix.py · tools/loop_twin_matrix_quarantine_test.py ·
  tools/loop_twin_matrix.{expected,quarantine}.txt (VOID, live) ·
  tools/loop_twin_matrix.{expected,quarantine}.register.txt (the renamed history) ·
  tests/e2e/CMakeLists.txt (the one entry) ·
  inc1-records/{loop,inplace,angle_select}_post1.txt + inplace_stateprep_{pre,post}1.txt
  Nothing under ir-pass/, tests/e2e/*.c, include/. Working tree clean.
FINAL GATE STATE, MEASURED: `tools/loop_twin_matrix.py`, both tables, the ctest entry and
the selftest are BYTE-UNCHANGED since the `ctest -R loop-twin` 4/4 run
(`git log 414fbf9..HEAD -- <those paths>` is EMPTY). The three commits after it touch only
the other two instruments and the records.

## HAND-BACK — prep_d2

### 1. What shipped (branch `3qlq-inc1-matrix`, 5 commits, ffa95cc..7f4776f)
```
dadfca3  the void surface becomes the SHIPPED loop-matrix gate (guard, tables, selftest)
414fbf9  the VOID expected table + quarantine, 29 pinned divergences in three classes
ea329a7  F-L5-7(b) in the other two instruments + inc1-records/loop_post1.txt
399def0  inc1-records/{inplace,angle_select}_post1.txt
7f4776f  inc1-records/inplace_stateprep_{pre,post}1.txt
```
14 files, all inside the brief's scope. Nothing under `ir-pass/`, `tests/e2e/*.c`, `include/`.
NOTE the one addition to the literal touch list: `tools/loop_twin_matrix_quarantine_test.py`.
It was RED at ffa95cc (TypeError, 0 cases ran) and job 5 requires `ctest -R loop-twin` green.

* **F-L5-7(b) FIXED, three call sites, one spelling.** `phi_surface_of_header()` — pure,
  C-comments stripped, whitespace-insensitive — replaces the literal substring test in ALL
  THREE instruments (it was duplicated; it broke this increment's own first inplace run).
  MEASURED: shipped `include/CQ.h` -> `void`; pre-3qlq `include/CQ.h` -> `register`.
  Asked in BOTH directions on EVERY invocation, so F-L5-7(a)'s 175 HARNESS-ERROR + 172
  "verdict changed" is now one line naming the surface it was handed.
* **F-L5-7(a) FIXED.** `e2e-loop-twin-matrix` gains `--phi-surface void`. Because that makes
  void the SHIPPED surface, it stops being a mode: it reads and writes its own expected
  table and quarantine through the same code path. `SURFACE_TABLES` gives the LIVE names to
  the SHIPPED surface; the register tables are renamed `.register.txt`, content byte-unchanged.
* **F-L5-2 DISPOSED.** All 14 re-measured on the fixed binary — **none moved**; the tally is
  review_r1_L5's cell for cell. All 14 quarantined with class, owner+DIRECTION, bd issue and
  a VOID-surface SHA-256. 8 are a3z7 class B verbatim; 4 are the same M-C decision on the
  `xor` PREFIX with a different direction; **2 fit NEITHER filed class — the FINDING below.**
* **Boundary control `q_armoncond` DIVERGES under void and is a class-A INSTANCE.** Pinned by
  `(verdict, digest)`; the file says it no longer bounds the quarantine.
* **POST records** for all three instruments + the `--stateprep` PAIR.

### 2. Per-instrument cell counts per verdict, and the pre->post deltas
LOOP — 274 cells, void, SUBJECT, exit 0, 693.37 s through the ctest entry:
  ACCEPT-IDENTICAL 126 · UNROLLED-ONLY 59 · DECLINE-BOTH 39 · DECLINE-BOTH-DIFFERENT 21 ·
  TRACE-DIVERGENCE 29 (ALL quarantined)   [PRE: DBD 122 · DB 81 · AI 50 · quarantined 13 ·
  PHI-UNLOWERED 4 · UNROLLED-ONLY 4]
  transitions: DBD->AI 74 · DB->UO 31 · DBD->UO 24 · DBD->TD 14 · DB->DBD 13 ·
  quarantined->TD 13 (label only) · PHI-UNL->TD 2 · PHI-UNL->AI 2 · DBD->DB 2; 99 unchanged.
  ⇒ PHI-UNLOWERED 4 -> 0, and the 100 PHI-FREE cells did not move, 100 of 100, measured
    against the REGISTER committed verdicts.
INPLACE ALL-PAIRS — 472 cells, exit 0:
  PREFIX-IDENTICAL 215 · RZ-ONLY(over-decline) 119 · PREFIX-MISMATCH 114 · DECLINE-BOTH 24
  [PRE: RY-ONLY 232 · DBD 87 · PHI-UNLOWERED 78 · DB 75; PREFIX-* were both 0]
  ⇒ PHI-UNLOWERED 78 -> 0. The 114 mismatches are prep_d's OQ-3 at scale (diamond 75,
    ifelse 27, clsbefore/clsbetween/negated 4 each), NOT a gate — no ctest entry.
INPLACE --stateprep — 297 cells, PAIR, exit 0 both halves:
  PRE  IDENTICAL 84 · SDTA 73 · DB 53 · PHI-UNLOWERED 45 · DBD 32 · SATD 10
  POST IDENTICAL 130 · SDTA 85 · DB 40 · DBD 31 · SATD 11 · PHI-UNLOWERED 0
  ⇒ 238 unchanged; PHI-UNLOWERED 45 -> 0 (34 to IDENTICAL, 0 to a decline); ZERO
    transitions out of an accepting verdict.
ANGLE SELECT — 158 cells, WITH --oracle, exit 0:
  RED-GREEN-MISS 66 · PHI-UNLOWERED 28 · RZ-VOID-NO-TWIN-ACCEPT 18 ·
  EXPECTED-DECLINE-RUNTIME-ARMS 13 · DEGENERATE-FOLD 12 · BOTH-DECLINE 11 · SUSPICIOUS 10
  Only 3 transitions: BOTH-ACCEPT-IDENTICAL->RED-GREEN-MISS 66 (all stem=theta, oracle
  already accepted — D5); RZ-VOID-NO-TWIN-DECLINE->ACCEPT 18 (THE INCREMENT);
  PHI-UNLOWERED->PHI-UNLOWERED 28 — **the ORACLE's leg**, `select@new 0 residual` on all 28.

### 3. QUARANTINE ADDITIONS (`tools/loop_twin_matrix.quarantine.txt`, 29 cells)
Carried over with VOID-measured digests: 15 (6 class A / 9 class B).
ADDED, 14: class B / bd a3z7 / FLAT deficient (8) —
  m_{add,none,rz,xor}_der_add, m_{add,none,rz,xor}_range_add
class B / bd a3z7 / NEITHER deficient (4) — m_xor_{der,gt}_{none,rz}
class C / bd test_C_libtooling-3qlq / NO ISSUE OF ITS OWN (2) — m_xor_range_{none,rz}

### 4. FINDINGS THAT ARE NOT MINE TO DECIDE
See `## OWNER QUESTION` below (OQ-D2-1 the class-C cells, OQ-D2-2 the boundary control,
OQ-D2-3 the register mode's future). prep_d's OQ-1/2/3 all still stand and OQ-3 is now
measured at 114 cells.

### 5. What I ran
* `ctest --test-dir build -R 'loop-twin' --output-on-failure` -> **4/4 passed**, 694.87 s
  (selftest 1.33 · grover-twin 0.05 · matrix 693.37 · inplace-ry-twin 0.04), after a cmake
  reconfigure. `git log 414fbf9..HEAD -- <the gate's four input paths>` is EMPTY, so the
  gate ran on exactly the committed bytes.
* `python3 tools/loop_twin_matrix_quarantine_test.py` -> **27 case(s), 0 failure(s)**, rc 0
  (12 cases x 2 surfaces + 2 guard-mismatch + 1 shipped-header). Was rc 1 / TypeError.
* The loop matrix under void on the SUBJECT three times (instrumented, --regenerate, plain).
* inplace all-pairs, inplace --stateprep x2 (oracle + subject), angle_select with --oracle.
* Red-green on the guard in all three instruments, MEASURED exit codes: rc 2 against the
  wrong-surface header, rc 0 against the right one.
* I did NOT run `ir-pass-lit`, the e2e slices, or the full `ctest`: I touched no compiler
  source and no fixture (Rule 19; the orchestrator owns the gate).

### 6. What is left
* The class-C disposition (OQ-D2-1) and, if the owner widens a3z7's scope, a
  `--refresh-quarantine` to re-file the 4 B-prefix cells.
* CLAUDE.md and ROADMAP.md still describe the register-surface quarantine as "15 cells" and
  name `tools/loop_twin_matrix.quarantine.txt` as that file. Both are now the VOID file with
  29 cells in three classes. That is the docs agent's, not mine — flagged here so it is not
  missed.
* Whether `inplace_twin_matrix.py` and `angle_select_twin_matrix.py` should ever become
  gates is still the open owner cost decision (bd drbq.9).

## OWNER QUESTION

### OQ-D2-1 — 2 quarantined cells fit NEITHER filed class, and the instrument's own
### docstring prescribes a fix nobody is authorized to make
`m_xor_range_none` and `m_xor_range_rz` are recorded as CLASS C with the epic's own bd id
because there is no issue for them. They carry class B's M-C disagreement AND, on top of it,
a `clang -O1` fold that makes the two SPELLINGS different programs.
MEASURED (subject, void, full traces in `$SP/progress/prep_d2_run1/cell_xor_range_none.txt`):
  rolled   `cqrt_xorc_i32(h0, 9)`
  unrolled `cq_template_xor_i32_hl(h0, 8) -> h1`     <-- MASK 8, NOT 9
The region `if (a > 5 && a < 20)` canonicalizes to `(x - 6) <u 14`, and [6,20) is closed
under a bit-0 flip because both bounds are even; on the FLAT spelling the second
repetition's `a ^ 9` cancels the first, so the xor result reaches nothing but the range test
and InstCombine drops the low bit. In the rolled loop the xor is in place on the
loop-carried `a` and the low bit is live, so it cannot.
`tools/loop_twin_matrix.py`'s docstring says the honest response to a legitimate `-O1`
asymmetry is to MAKE THE IMMEDIATE OPAQUE (as `off` already is), not to quarantine it. Doing
that changes the generated source of every `xor`-prefix cell and would move committed rows,
so it is an owner decision. Until it is taken the two are pinned, which is strictly safer
than blessing them and does not retire the gate.
The same phenomenon is documented for these cells on the REGISTER surface, where it produced
a DISPOSITION mismatch (ROLLED-ONLY) instead — see `loop_twin_matrix.expected.register.txt`.

### OQ-D2-2 — the second boundary control is now an INSTANCE of the class it bounds
MEASURED on the subject under void: `q_armoncond` is a TRACE-DIVERGENCE whose signature is
bd 1m5p class A verbatim (rolled leaves the top rail `h3 = sqrt((double)a + 3.0)` allocated;
flat discharges all three LIFO). It bounded "the divergence needs an arm OFF the condition
register" by putting the arm back ON — and a branch phase writes no register, so under the
void surface the control's own body satisfies class A's precondition. There is no substitute:
the only void gate that writes a register is `cq_theta`, and an in-place Ry arm on the
condition's own wire is itself a loud decline (drbq Inc 1).
I kept it, pinned by SIGNATURE, as the smallest class-A reproducer in the tree, and wrote in
both the script and the quarantine header that the void quarantine's class story is bounded
by `q_noregion` plus the per-cell signatures and NOT by this control. If the owner wants the
bound back, it needs a NEW control designed for the void surface — which is a change to a
Rule-13 instrument's assertions, not a prep decision.

### OQ-D2-3 — the `register` surface is unreachable and its tables are frozen history
`a = cq_phi(a, T)` does not compile against the shipped `include/CQ.h`, and fix_r1 made the
retired `@cq_phi_<sfx>` family a RESERVED NAME (a loud decline), so `--phi-surface register`
can only run against a stand-in header from outside the tree. I kept the mode and its tables
(renamed `.register.txt`, content byte-unchanged) rather than deleting them, because they are
the only readable record of 274 measured verdicts on the surface this epic retires and
because deleting them would make `git log --follow` the only way to reach that record. The
brief allowed deleting them from `tools/` instead. Which of the two the owner wants is a
one-line change either way.
