# fix_eqpx_c — DOCS-ONLY round 3, closing lens round 2's four DOC items (F-E2-1..4)

Worktree `$SP/wt/eqpx`, branch `eqpx-fix`, base beb34e0. HARD SCOPE: no non-comment .cpp/.h change,
no fixture body change, no golden. Final gate: `cmp build/ir-pass/cq-opt $SP/bin/eqpx-1333278/cq-opt`.

## 2026-09-06 step 0 — read + subject currency  [DONE]
Read BRIEF_common.md, BRIEF_fix_eqpx_c.md, review_eqpx_r2.md from `## VERDICT` (line 125) to end,
fix_eqpx_b.md hand-back (lines 145-238).
MEASURED in `$SP/wt/eqpx`:
- `git log --oneline -3` -> beb34e0 / 27b7800 / 1333278
- `git status --porcelain` -> EMPTY
- `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` -> EMPTY (build current)
NEXT: step 1 (F-E2-1, tu_exth.c + README two-TU rule).

## 2026-09-06 step 1 — F-E2-1 (tu_exth.c + the README two-TU rule)  [DONE]
MEASURED in `.../session-7bbdb89e/eqpx_reproducers_r1/`:
- `grep -oh 'ext_[a-z_0-9]*' *.c | sort | uniq -c` -> **30 `ext_f`, 5 `ext_h`** — EXACTLY two symbols.
- per-file: `ext_h` in **d03_classical_phi_imm.c, d05_classical_call_imm.c** ONLY; `ext_f` in the
  other **15** (x01-x04, x08-x12, x14, x15, y05-y08).
- sibling dir `session-82e6b530/eqpx_reproducers/`: `ext_f` only (63 hits, 0 `ext_h`) — its README's
  rule is correct as it stands; nothing to change there.
SHIPPED: `tu_exth.c` copied byte-identically from `$SP/progress/review_eqpx_r1_work/p/tu_exth.c`
(`cmp` IDENTICAL; `od -c` = `int ext_h(int a){ return a+3; }\n`), and the README's two-TU rule
replaced by a per-symbol TABLE naming `ext_f` -> `../../session-82e6b530/eqpx_reproducers/tu_extf.c`
and `ext_h` -> `tu_exth.c` (here), with a dated note on why it was missing.
VERIFIED by running the README's own recipe (W=$SP/progress/fix_eqpx_c_work):
| program | tag | result |
|---|---|---|
| d03_classical_phi_imm | fix | `ACCEPT d03_classical_phi_imm fix 2b=0 lines=6 imm=0 run=0` |
| d05_classical_call_imm | fix | `ACCEPT d05_classical_call_imm fix 2b=0 lines=6 imm=0 run=0` |
| d03_classical_phi_imm | main | `ACCEPT … main 2b=0 lines=6 imm=0 run=0` |
| d05_classical_call_imm | main | `ACCEPT … main 2b=0 lines=6 imm=0 run=0` |
`cmp` main-vs-fix trace: **BYTE-IDENTICAL** both. Matches the README's recorded rows exactly.
NEXT: step 2 (F-E2-2, the six stale citations + the citation sweep).

## 2026-09-06 step 2 — F-E2-2 (the stale citations + the sweep)  [DONE]
INSTRUMENT: `$SP/progress/fix_eqpx_c_work/citation_sweep.py` — every
`(LoopLowering|ArithLowering|OpcodeLowering)(\.cpp)?:<n>` citation **plus the bare `` `:<n>` ``
CONTINUATIONS these docs write** (attributed to the last file named on the same line — this is
how `| OpcodeLowering:341 / :428 |` and `(LoopLowering:2187, :2617)` are spelled, and a
file-qualified-only regex misses 4 of the 10 introduced misses), over the notes, the PRD,
`CLAUDE.md`, `ROADMAP.md`, the three edited sources and the 16 new fixtures. It prints the
SUBJECT text at line n, the `main` text at line n, and where `main`'s line n moved to (difflib
line mapping); the verdicts are HAND-adjudicated in `$W/citation_verdicts.txt` (62 rows).
MEASURED, **62 citations scanned** (0 in `CLAUDE.md`, `ROADMAP.md` or the PRD — all 62 are in the
notes, the 3 sources and the 16 fixtures):
| | BEFORE (tree at beb34e0) | AFTER (this commit) |
|---|---|---|
| citations scanned | 62 | 52 |
| OK | 43 | 43 |
| **MISS-INTRODUCED** | **10** | **0** |
| MISS-PREEXISTING | 9 | 9 (untouched, per brief) |
Logs `$SP/progress/c_citation_sweep_{BEFORE,AFTER}.txt` (BEFORE taken with the edits `git stash`ed).
THE 10 INTRODUCED MISSES, all fixed by NAME (6 citing lines):
1. notes:1589 `LoopLowering.cpp:2922` -> `commitOutOfLoopInPlaceOps`' **(A) DIRECTION** comment (real :2962)
2-3. notes:2071 `OpcodeLowering:341` / `:428` -> `lowerOps` Phase 1's M-C guard conjunct /
   its Phase-2 dispatch (real :469 / :556) — **NOT in the lens's six**: the lens swept
   `LoopLowering` only, and both were CORRECT on `main`
4-5. notes:2073 `LoopLowering.cpp:212-213` -> "its one `OutOfPlace` return" (real :252-253)
6-7. notes:2073 `LoopLowering:2187`, `:2617` -> the round-1 guard in `tryCaseA` / the round-2
   guard in `collapseRailPhisIn` (VERIFIED enclosing fn by `awk`; real :2227 / :2657)
8. notes:2074 `LoopLowering:928` -> `collectRailGates`' `OnThisRail` call (real :968)
9-10. notes:2508 and `OpcodeLowering.cpp:426` `LoopLowering.cpp:206` -> `railValueConsumerDisposition`
   ... by NAME (real :246)
THE 9 PRE-EXISTING, LEFT UNTOUCHED (wrong on `main` too; none in a paragraph this branch edited):
`OpcodeLowering:263` x4 and `:350` x2 (notes:1320/1413/1572 + `LoopLowering.cpp:3058`; on `main`
the two real readers were `:341`/`:428`), and notes:2075's `LoopLowering.cpp:3214` / `:3412-3413`
for the two `AsLowered=true` sites (real on the subject: `:3280` / `:3483`) — the lens's own
excluded example.
LINE-COUNT DISCIPLINE: every edit is line-count-preserving (`OpcodeLowering.cpp` 581 = 581, notes
2836 = 2836) so no citation ANYWHERE shifts, incl. the historical `NOTES.md:1976` cross-reference
in `session-82e6b530/rebase_c1d.md`.
NEXT: step 3 (F-E2-3, §3.16 strictimm breakdown).

## 2026-09-06 step 3 — F-E2-3 (§3.16 strictimm breakdown)  [DONE]
INDEPENDENTLY RE-COUNTED from the lens's own artefact `$SP/progress/review_eqpx_r2_work/strict_fix_fixtures.txt`
(82 non-empty rows) with an `awk` classifier:
`42 sub i32 0, %k · 19 load volatile · 16 add · 3 cqrt_measure_i32 · 2 Argument` = **82**, and
`grep -c 'ptr @g,'` = **1**, `grep -c 'load volatile'` = **19** -> the `@g` load IS one of the 19.
The lens's F-E2-3 reproduces exactly. §3.16 now reads `16 add` and folds the `@g` load into the
19 `load volatile`, with the correction and its attribution named in place. Total stays 82,
ZERO rail producers unchanged. Line count preserved (2836 = 2836).

## 2026-09-06 step 4 — F-E2-4 (CLAUDE.md antecedent)  [DONE]
On `main` (`git show main:CLAUDE.md`, line 1090) "That last one" followed *"…but the same class one
writer over."*, i.e. the eqpx member. The branch inserted the ⭐ FIXED clause between them, so the
nearest antecedent became the round-1 lens's `0 rail producers` parenthetical. Re-anchored to
**"THE eqpx MEMBER — not the ⭐ clause just above it, which is its fix — also RETIRES …"**.
One line, line count preserved.
NEXT: step 5 (notes §3.16 round-2 subsection + copy the four progress files and five briefs).

## 2026-09-06 step 5 — the record (notes §3.16 round-2 subsection + the copies)  [DONE]
APPENDED to §3.16: `##### THE ROUND-2 ADVERSARIAL LENS on the doc pass … verdict CLEAR-WITH-ITEMS`
— the code-did-not-move `cmp`, the 80-injection superset matrix (0 MISSED vs 47/80 pre-edit, and
28/48 on the lens's 3-kind subset), F-E1-2/F-E1-1 closure, adjudication (A)'s M2+M3 (0 OUTDIFF over
1707) and M-E (24 moved), the 879 accept modules / 0 rail producers, and the full ctest
**367/367, 350.23 s, EXIT=0, TIP=beb34e0** READ from `$SP/progress/orch_full_ctest_eqpx.log` (NOT
re-run by me). Then the four DOC items F-E2-1..4 with what closing each MEASURED, the 9 PRE-EXISTING
citation misses named so nobody re-finds them, and a standing rule paragraph ("cite the NAME, never
the line") with the line-count-preserving discipline this commit used.
COPIED into `docs/prd/phase-04-swap-route-control/inc1-records/session-7bbdb89e/`:
`fix_eqpx_b.md`, `review_eqpx_r2.md` (`fix_eqpx.md` and `review_eqpx_r1.md` were already there and
`cmp`-IDENTICAL to the live progress files — re-checked, not re-copied), and `briefs/` with SIX
briefs: `BRIEF_common`, `BRIEF_fix_eqpx`, `BRIEF_review_eqpx_r1`, `BRIEF_fix_eqpx_b`,
`BRIEF_review_eqpx_r2` + `BRIEF_fix_eqpx_c` (my own — the brief said "the five"; leaving out the
brief for the round this commit IS would make the record incomplete). `BRIEF_clearance_eqpx.md` is
NOT copied — it is the orchestrator's, with the clearance record.
NOT WRITTEN, per brief: the session README (it still lists 3 files and does not mention
`fix_eqpx_b.md` / `review_eqpx_r2.md` / `briefs/`) and NEXT_SESSION_PROMPT — both the orchestrator's.
NEXT: step 6 — rebuild (running), currency, `cmp`, `lit --filter inplace_rail`, commit.

## 2026-09-06 step 6 — the round's own re-read caught two ASSERTED numbers  [DONE]
Re-reading the appended subsection against its own artefacts found two numbers I had written
without measuring — the exact failure this round exists to fix:
* *"a file-qualified-only regex misses 4 of the 10"* — GUESSED. MEASURED by re-running that exact
  regex over `beb34e0`'s notes: **FINDS 8, MISSES 2** (`:428` in §3.14's reader row, `:2617` in its
  fan-out row — the two written as bare continuations). Corrected in the notes.
* the verdict file is **71** rows (62 BEFORE-run + 9 `QUOTED`), not 62 and not "61-row". Corrected.
Also: the appended text NAMED the retired numbers so a reader can find them, which made the sweep
read them as 10 fresh citations. They are QUOTATIONS; the script gained a `QUOTED` class, the text
says so, and the two REAL-line claims the append had minted (`:469`/`:556`, `:3280`/`:3483`) are
replaced by function names — a doc pass about stale line numbers must not mint new ones.
The instrument is now COMMITTED (`inc1-records/session-7bbdb89e/citation_sweep/`: script, 71-row
verdict file, BOTH raw runs, README naming its TWO limits) so this round's number is re-derivable —
F-E2-1's complaint was exactly a measurement the record could not reproduce.

---

# ── HAND-BACK — fix_eqpx_c (DOCS-ONLY ROUND 3; branch `eqpx-fix`, NOT pushed) ──

## 1. What shipped

Three commits on `eqpx-fix`, on top of `beb34e0`:

| commit | what |
|---|---|
| `3a519ae` | F-E2-1 (`tu_exth.c` + the README's per-symbol two-TU table), F-E2-2 (10 stale citations -> FUNCTION NAMES), F-E2-3 (the `strictimm` partition), F-E2-4 (the `CLAUDE.md` antecedent), notes §3.16's round-2 subsection, and the record copies |
| `cc51ab4` | the citation sweep committed as a record artefact + the `QUOTED` classification of this subsection's own retellings |
| `727e8e1` | two numbers in that subsection that were asserted rather than measured |

`git diff --stat beb34e0 HEAD` = **18 files, +1544 / -12** — 1 source (ONE comment line), 3 docs,
1 new one-line TU, and 13 new record files.

**HARD SCOPE HELD, verified after every build:**
* `git diff 1333278 -- ir-pass/src ir-pass/include | grep '^[+-]' | grep -v '^[+-]\s*//' |
  grep -v '^+++\|^---'` -> **EMPTY**
* `cmp build/ir-pass/cq-opt $SP/bin/eqpx-1333278/cq-opt` -> **BYTE-IDENTICAL**; so is `libCQPass.so`
* `git diff --stat beb34e0 -- ir-pass/test tests/e2e runtime tools include` -> **EMPTY**
  (no fixture body, no fixture header, no golden, no ABI)
* corpus counts unchanged: `ls ir-pass/test/*.ll` **1707**, `ls tests/e2e/*.expected.log` **323**,
  `ctest -N` **367**

## 2. What I ran

| # | command | result |
|---|---|---|
| 1 | `git log -1` / `git status --porcelain` / `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` | `beb34e0`, EMPTY, EMPTY |
| 2 | `grep -oh 'ext_[a-z_0-9]*' *.c \| sort \| uniq -c` in `eqpx_reproducers_r1/` | **30 `ext_f` · 5 `ext_h`**, no third symbol; `ext_h` only in `d03`/`d05` |
| 3 | same in `session-82e6b530/eqpx_reproducers/` | `ext_f` **63**, `ext_h` **0** — that README needs no change |
| 4 | `cp` + `cmp` `tu_exth.c` vs the lens's file; `od -c` | **BYTE-IDENTICAL**, `int ext_h(int a){ return a+3; }\n` |
| 5 | `run.sh <D>/d03_classical_phi_imm.c {main,fix} <D>/tu_exth.c` | `ACCEPT … lines=6 imm=0 run=0` **both**; `cmp` trace **BYTE-IDENTICAL** |
| 6 | `run.sh <D>/d05_classical_call_imm.c {main,fix} <D>/tu_exth.c` | `ACCEPT … lines=6 imm=0 run=0` **both**; `cmp` trace **BYTE-IDENTICAL** |
| 7 | `citation_sweep.py <wt> main citation_verdicts.txt` on the **pre-edit** tree (edits `git stash`ed) | **62 scanned — 43 OK, 10 MISS-INTRODUCED, 9 MISS-PREEXISTING, 0 UNADJUDICATED** |
| 8 | the same on the **final** tree | **61 scanned — 43 OK, 0 MISS-INTRODUCED, 9 MISS-PREEXISTING, 9 QUOTED, 0 UNADJUDICATED** |
| 9 | naive file-qualified-only regex re-run over `beb34e0`'s notes (python) | of the 10 introduced misses it **FINDS 8, MISSES 2** (`:428`, `:2617`) |
| 10 | `awk` enclosing-function check for `:2227` / `:2657` / `:968` / `:3280` / `:3483` / `:556` | `tryCaseA` / `collapseRailPhisIn` / `collectRailGates` / `invariantRegisterRootsImpl` / `markIfRailLocal` / `lowerOps` — every replacement NAME verified against the tree |
| 11 | `awk` classifier over the lens's `strict_fix_fixtures.txt` (82 rows) | **42 `sub` · 19 `load volatile` · 16 `add` · 3 `cqrt_measure_i32` · 2 Argument = 82**; `grep -c 'ptr @g,'` **1**, `grep -c 'load volatile'` **19** -> the `@g` load IS one of the 19 |
| 12 | `git show main:CLAUDE.md \| grep -n 'That last one'` + context | on `main` the antecedent WAS the eqpx member — F-E2-4 confirmed before fixing |
| 13 | `cmake --build build -j8` ×3 (background, logs `$SP/progress/fix_eqpx_c_build{1,2,3}.log`) | `BUILD_EXIT=0` each; currency EMPTY each |
| 14 | `cmp` `cq-opt` / `libCQPass.so` vs `$SP/bin/eqpx-1333278/` after every build | **BYTE-IDENTICAL** both, 3/3 times |
| 15 | `lit ir-pass/test --filter 'inplace_rail'` ×3 | **16 selected · 16 Passed** each |
| 16 | line-count discipline: `wc -l` before/after on every edited file | `OpcodeLowering.cpp` 581 = 581 · `CLAUDE.md` 2505 = 2505 · notes 2836 = 2836 (before the pure EOF append) |
| 17 | `ls ir-pass/test/*.ll` / `ls tests/e2e/*.expected.log` / `ctest -N` | **1707 / 323 / 367** — unchanged |
| 18 | `cmp` the 4 copied progress files vs `$SP/progress/` | 4/4 **IDENTICAL** |

**NOT RUN, and I claim nothing about them:** the full `ctest` (the orchestrator's; I quote its
`367/367, 350.23 s, TIP=beb34e0` from `$SP/progress/orch_full_ctest_eqpx.log` and label it READ);
`ctest -R ir-pass-lit`; `ctest -j6 -R '^e2e-'`; `frontend-lit`; `runtime`; `e2e-loop-twin-matrix`;
`cq_opt_equivalence`; any mutant build; any new adversarial probing of the lowering.
The binary is `cmp`-identical to the one round 1 and round 2 measured, so their numbers carry —
but that is an argument from byte-identity, not a re-run.

## 3. Findings that are NOT mine to decide

### `## OWNER QUESTION` — none of my own.
I did not touch the implementer's OQ-1 (keep the `InPlaceRailIdx` plumbing) or `fix_eqpx_b`'s OQ
(a header note on the pre-existing `(1b)` template fixture `control_phase_kickback_reject_preloop_commit_stale.ll`).

### For the ORCHESTRATOR, not owner questions
1. **The session README is now INCOMPLETE and it is yours.** My brief says the orchestrator writes
   `session-7bbdb89e/README.md` and `NEXT_SESSION_PROMPT`, so I did not touch it — but its file
   table still lists only 3 entries and does not mention `fix_eqpx_b.md`, `review_eqpx_r2.md`,
   `briefs/` or `citation_sweep/`, and its prose says "THE THREE DOC/FIXTURE items are CLOSED"
   when there are now seven (F-E1-1..3 + F-E2-1..4). Please refresh it.
2. **I copied SIX briefs, not five.** The five the brief named plus `BRIEF_fix_eqpx_c.md` — leaving
   out the brief for the round this commit IS would make the record incomplete.
   `BRIEF_clearance_eqpx.md` is deliberately NOT copied; it is yours with the clearance record.
3. **NINE PRE-EXISTING citation misses are left UNTOUCHED**, per the brief, and are named in
   §3.16 so nobody re-finds them: `OpcodeLowering:263` (×4) and `:350` (×2) — on `main` that
   file's two real `InPlaceRailOps` readers were `:341`/`:428`, so those citations were already
   wrong before this branch — and §3.14's `LoopLowering.cpp:3214` / `:3412-3413` for the two
   `peelInPlaceBase(…, AsLowered=true)` sites, really in `invariantRegisterRootsImpl` and
   `markIfRailLocal`. If the owner wants them fixed it is a separate, `main`-scoped docs change.

## 4. What is left

* **Rule 13 is STILL not satisfied.** Three rounds on this fix have all been DOCS; the binary has
  not moved since round 1. Two lenses on a docs pass are not a clearance, and this function's
  history is nine findings over seven adversarial rounds, two INTRODUCED BY A FIX.
  `BRIEF_clearance_eqpx.md` exists and has not been run.
* The full `ctest` gate, the push, the bd close and the README/NEXT_SESSION_PROMPT are the
  orchestrator's. I did none of them and never touched `/Users/sorenwilkening/Desktop/CQ_lang`.
* The citation sweep's two limits are stated in its committed README and neither can turn a MISS
  into an OK: a continuation that wraps to the next SOURCE LINE is not scanned, and a verdict key
  (`<citing file>:<line>`) goes stale when the citing text is re-wrapped.
