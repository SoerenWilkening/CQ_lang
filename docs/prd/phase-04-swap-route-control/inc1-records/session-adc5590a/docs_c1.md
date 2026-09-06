# docs_c1 — the COUNT/STATUS docs pass after the C-1 fix round (docs only)

Agent: `docs_c1`. Worktree `$SP/wt/fix-c1`, branch `3qlq-inc1-fix-c1`, base tip 3ec40c9.
Scope: `.md` only. No code, no fixtures, no tools, no build, no ctest/lit run
(a full ctest and a read-only lens are running against this worktree).

## Log

- 2026-09-06 step 0: read BRIEF_common, BRIEF_docs_c1, `$SP/progress/fix_c1.md` (whole file),
  notes §3.1/§3.2/§3.3, PRD §0 Status + E2 + E7 + E9, ROADMAP Phase-4 status block and the
  matrix paragraph, the session-0a61aa31 README. Worktree clean at 3ec40c9.

- step 1 (MEASURE, all in `$SP/wt/fix-c1`, `ctest -N` only — nothing built, nothing run):

  | command | result |
  |---|---|
  | `ls ir-pass/test/*.ll \| wc -l` | **1660** |
  | `ctest --test-dir build -N \| grep -c '^  Test'` | **342** |
  | `ctest --test-dir build -N \| sed -n 's/^  Test *#[0-9]*: //p' \| grep -c '^e2e-'` | **332** |
  | `ctest --test-dir build -N \| sed -n 's/^  Test *#[0-9]*: //p' \| grep -c '^e2e-slice-'` | **304** |
  | `grep -c '^m_' tools/loop_twin_matrix.expected.txt` | **255** |
  | `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` | **29** |
  | `ls tests/e2e/*.expected.log \| wc -l` | **306** |
  | `grep -c 'twin-identical' tests/e2e/CMakeLists.txt` | **19** |
  | `git diff --name-status 52d7764 HEAD -- ir-pass/test \| awk '{print $1}' \| sort \| uniq -c` | **95 A · 17 D · 473 M** |
  | `git diff --name-status 542d588 HEAD -- ir-pass/test` | **4 A**, no M, no D |

  BASELINE, same commands against the PRE-FIX SUBJECT `/Users/sorenwilkening/Desktop/CQ_lang`
  (542d588, never rebuilt): ctest **339**, `^e2e-` **329**, `^e2e-slice-` **302**,
  corpus **1656**, matrix rows **245**.
  DELTA, name-diffed rather than subtracted
  (`diff <(ctest -N …main… | sed …| sort) <(ctest -N …fix-c1… | sed …| sort)`): exactly **+3**,
  `e2e-phase-perbit-loop-mixed-twin-identical`,
  `e2e-slice-control-phase-perbit-loop-mixed`,
  `e2e-slice-control-phase-perbit-loop-mixed-unrolled`. No entry removed, none renamed.

  EVERY number agrees with `fix_c1.md`. One number in `CLAUDE.md` is now STALE and is
  NOT one the brief listed: the Inc-1 migration census `git diff --name-status 52d7764 HEAD
  -- ir-pass/test` reads **95 A** at this HEAD, not the **+91 ADDED** the doc quotes
  (the doc's figure was measured at the Inc-1 merge; the C-1 round's 4 new fixtures are
  the difference). Recorded in the `ir-pass-lit` line rather than silently overwritten.

- step 2 (CLAUDE.md, 4 edits):
  1. Build & Test ctest paragraph: new dated line at the TOP — "342 ctest entries
     (2026-09-06, the C-1 FIX ROUND …: +3, every one in the e2e layer …)" — with the
     339 paragraph kept VERBATIM under it as "was 339 (2026-09-05, …)", matching the
     existing "was 327 / was 324 / was 305" chain.
  2. `ir-pass-lit` line: 1656 → 1660 with the dated parenthetical naming all four new
     fixtures, plus the ⚠ note that the Inc-1 migration census (`git diff … 52d7764
     HEAD`) now reads 95 A / 17 D / 473 M while the doc's "+91 ADDED" is the Inc-1
     figure — left as measured, with the difference named, not silently restated.
     Added a sentence recording the B3 pin's new dedicated fixture pair, and that this
     doc pass ran nothing but `ctest -N` and makes no colour claim.
  3. Twin-matrix paragraph: dated re-measurement sentence — 255 + 29 = 284, sub-grid F
     (second-CARRIED-register axis, the only axis that can see C-1), 245 earlier rows
     byte-unchanged, the 9-of-10 pre-fix hard-failure figure stated AS SAMPLED (4 by
     hand), and the `addpost` DROP (an `-O1` sink, not a compiler defect).
  4. Line ~1004 — **DEVIATION FROM THE BRIEF, deliberate, see the OWNER-VISIBLE NOTE
     below.** The brief asked for "two → three … (the third, C-1, by the clearance
     itself)". That sentence's subject is the ONCE-ONLY-STAGE family (F-L3-1 +
     F-R1-1), and notes §3.1 records that the clearance ran **12 probes for a third
     once-only-stage instance and found NONE in the accept direction**, while §3.2
     grades C-1 as the third instance of the OTHER family (the in-loop entangled-rail
     leak). Writing "three" there would have put a claim into CLAUDE.md that the same
     tree's notes contradict. The number stays at TWO; the clearance's 12-probe result
     and the explicit "do not fold C-1 into this count" are added instead.

- step 3 (ROADMAP.md, 3 edits):
  * Phase-4 3qlq status block (~line 360): the ROADMAP recorded NO clearance BLOCK at
    all — it said only "Increment 1 SHIPPED (branch `3qlq-inc1`, merge `be4e2ea`)".
    Added the missing BLOCK record AND the dated fix line: "SHIPPED HERE MEANS
    IMPLEMENTED + REVIEWED ON A BRANCH, NOT LANDED … 2026-09-06: C-1 is FIXED on
    `3qlq-inc1-fix-c1` … one independent lens and a re-clearance are pending; landing
    follows the re-clearance verdict — do not read this block as landed."
  * The matrix paragraph (~line 810): the same dated re-measurement, 255 + 29 = 284,
    sub-grid F.
  * The "Two adversarial rounds found three CONFIRMED silent miscompiles" sentence:
    a ⚠ clause saying that three is the ROUND-1 count, round 2 added a fourth (PRD E9)
    and the clearance a fifth (C-1) — five over three adversarial passes on ONE
    increment, zero found by the fixture suite.

- step 4 (PRD `retire-swap-route-PRD.md`, 4 edits): the Status header block and §0
  "Shipping status" both gain the dated C-1-FIXED / lens+re-clearance-pending line
  ("Nothing here says Inc 0/1 have landed"); E7 gains ONE appended parenthetical with
  the fix round's counts (1656→1660, 339→342, 329→332, 302→304, 274→284, 304→306
  goldens) and the note that E7's own `52d7764 HEAD` census now reads 95 A / 17 D /
  473 M; E9 gains the "three is the round-1 count, it is FIVE" correction with the
  two-families note.

- step 5 (`inc1-records/session-0a61aa31/README.md`): added the pointer to
  `inc1-records/session-adc5590a/` (fix_c1.md, review_c1.md, clearance2.md, briefs/),
  "copied at landing", with the reading order (this dir = the BLOCK, that dir = its
  disposition) and "until the re-clearance lands, neither branch is on main".

- step 6 (VERIFY + COMMIT): `git status --short` shows exactly 4 modified files, all
  `.md` (`git diff --name-only | grep -v '\.md$'` empty). Markdown structure checked:
  CLAUDE.md code fences still 8 (even), every inserted line inside the Build & Test
  bash block starts with `#`, every inserted line in the matrix blockquote starts with
  `>`. Counts re-measured AFTER the edits and unchanged (1660 / 342 / 255 / 29).
  ONE commit: **ba01d8d** `docs(control): 3qlq — the C-1 fix round's COUNT/STATUS pass
  (342 ctest / 1660 lit / 284 matrix cells), all re-measured in the worktree`.
  Worktree clean. Nothing built, no lit, no ctest EXECUTION — `ctest -N` listing only.

---

## HAND-BACK

### 1 — what shipped
ONE docs commit **ba01d8d** on `3qlq-inc1-fix-c1` (parent 3ec40c9), 4 files, +121/−9,
**all `.md`**: `CLAUDE.md`, `ROADMAP.md`,
`docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md`,
`docs/prd/phase-04-swap-route-control/inc1-records/session-0a61aa31/README.md`.
No code, fixture, tool, golden or build artefact touched.

### 2 — what I ran (measurements only; nothing built, nothing executed under ctest)
See the step-1 table. Baseline commands re-run against the untouched main checkout
(542d588) for every delta; the ctest delta is a NAME DIFF, not a subtraction.

### 3 — findings that are NOT mine to decide

**## OWNER QUESTION — none.** Nothing I measured contradicts a PRD §2 decision or a §12
assumption. Two brief instructions were deviated from on ACCURACY grounds and are
recorded in the commit message rather than left silent:
* CLAUDE.md ~1004's "two → three (the third, C-1)" would have credited the
  ONCE-ONLY-STAGE family with a finding notes §3.1 explicitly says it does not have
  (12 probes, none found in the accept direction); C-1 is §3.2's OTHER family. Count
  left at TWO, with the clearance's 12-probe result and a "do not fold C-1 in" note.
* PRD E9 already records round 2's FOURTH, so C-1 is the FIFTH there, not the third.
  Written as five; ROADMAP's "three CONFIRMED" sentence corrected to match.

**Stale number surfaced, not fixed by overwriting:** `git diff --name-status 52d7764
HEAD -- ir-pass/test` now reads **95 A / 17 D / 473 M**; CLAUDE.md and PRD E7 quote
"+91 ADDED" as the INC-1 migration figure. That figure is correct as of the Inc-1
merge and stale by exactly the C-1 round's 4 fixtures. Both sites now say so; neither
number was silently restated. If the orchestrator wants ONE census at landing, that is
the line to re-measure.

### 4 — what is left
* Nothing in the docs-count scope. The commit is on the branch, NOT pushed.
* Not mine and still owed: the orchestrator's full `ctest -j6`, the independent lens on
  the C-1 fix, the re-clearance, and creating `inc1-records/session-adc5590a/` — the
  README I edited now promises that directory, so it must exist at landing.
* `tools/loop_twin_matrix.expected.register.txt` and the register-surface quarantine are
  untouched and still frozen history; sub-grid F is unreachable in that mode by design.
