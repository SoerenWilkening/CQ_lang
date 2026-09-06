# fix_eqpx_b — FIX ROUND 2 (DOCS + FIXTURES ONLY) progress

Worktree `$SP/wt/eqpx`, branch `eqpx-fix` at `1333278`. Work dir `$SP/progress/fix_eqpx_b_work/`.
HARD SCOPE: no non-comment `.cpp`/`.h` change; rebuilt `cq-opt` must `cmp` byte-identical to
`$SP/bin/eqpx-1333278/cq-opt`.

## 2026-09-06 step 0 — read + subject currency  [DONE]
* Read BRIEF_common, BRIEF_fix_eqpx_b, BRIEF_fix_eqpx, BRIEF_review_eqpx_r1,
  progress/fix_eqpx.md (314 lines, whole), progress/review_eqpx_r1.md (329 lines, whole).
* `git log --oneline -1` -> `1333278`; `git status --porcelain` -> EMPTY;
  `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` -> EMPTY. Binary current.
* NEXT: F-E1-1 (stale line numbers), then F-E1-2, F-E1-3, (A), F-E1-4/(B).

## 2026-09-06 step 1 — F-E1-1 (stale grep + stale line numbers)  [DONE]
MEASURED on the subject tree: `grep -n 'InPlaceRailOps.insert(' ir-pass/src/LoopLowering.cpp`
-> **ONE** site (`:193`, inside the helper). `grep -n 'markInPlaceRailOp(' ir-pass/src/LoopLowering.cpp`
-> the four writers at **`:1738 :2321 :2719 :3124`** (they moved +9 from `:1729 :2312 :2710 :3115`
because my own comment edit in `markInPlaceRailOp`'s header added 9 lines; re-measured AFTER the edit).
Fixed in THREE places (comments only):
* `ir-pass/src/LoopLowering.cpp` `markInPlaceRailOp` header — command is now `markInPlaceRailOp(`,
  four names + the post-edit lines, with "cite the NAMES, the numbers move" said explicitly.
* `ir-pass/src/OpcodeLowering.cpp` tripwire Rule-0 block — same, plus WHY `insert(` no longer works.
* `ir-pass/include/TaintPropagation.h` — was RIGHT about the command's names but its four numbers
  were the pre-edit ones; re-synced to `:1738 :2321 :2719 :3124`.
* Fixture headers: `sed` over the 16 new fixtures, `1698->1738 2281->2321 2679->2719 3084->3124`
  (6 hits). HISTORICAL records (`investigate_eqpx.md`, `NEXT_SESSION_PROMPT.md`, `review_c1b.md`)
  left BYTE-UNCHANGED — they are dated statements about the pre-fix tree.

## 2026-09-06 step 2 — F-E1-2 (vacuous CHECK-NOTs in the 8 declines)  [DONE]
REPRODUCED the lens's measurement myself on the frozen subject binary `$SP/bin/eqpx-1333278`:
`cq-opt … -S lowering_reject_inplace_rail_stale_w2_xor_derived.ll >out 2>err` -> `rc=1`,
`wc -c out` = **0**, `err` = one diagnostic line + a blank (`od -c`).
All 8 decline fixtures now carry a header block naming which mechanism pins what (the `RUN: not`
inversion, MEASURED by mutant M-B: 8 RED), and the vacuous pair is KEPT with a two-line label
"DOCUMENTATION OF THE FORBIDDEN OUTPUT, not a live assertion". The two W1 fixtures additionally
say that their three `break reverse-play` negatives ARE live (they name STDERR text, which `2>&1`
does pipe). The pre-existing (1b) fixture `control_phase_kickback_reject_preloop_commit_stale.ll`
is UNTOUCHED (out of scope; recorded in notes §3.16 as the pre-existing house style).

## 2026-09-06 step 3 — F-E1-3 (the 8 accept controls under-assert)  [IN PROGRESS]
Counts DERIVED from each fixture's own pass output (frozen subject binary), not guessed:
| fixture | xorc | addc | cqrt_free | tmpl_xor | tmpl_add |
|---|---|---|---|---|---|
| ctlA | 1 | 0 | 0 | 0 | 0 |
| k01 | 1 | 0 | 0 | 0 | 0 |
| k02 | 0 | 1 | 0 | 0 | 0 |
| k03 | 1 | 0 | 0 | 0 | 0 |
| n02 | 0 | 0 | 2 | 1 | 0 |
| n03 | 0 | 0 | 2 | 1 | 0 |
| n09 | 0 | 0 | 3 | 1 | 0 |
| z36 | 0 | 0 | 4 | 0 | 1 |
⚠ CORRECTION TO THE BRIEF'S PRESCRIPTION, and it is load-bearing: the brief says every accept
gets BOTH stems' `i32 %…, i32 %…` rail-immediate negative because "a Constant immediate prints as
`i32 7`, never `i32 %…`". That is TRUE of `ctlA` and FALSE of `k01`/`k02`/`k03`, whose own
legitimate gate is `cqrt_{xorc,addc}_i32(i32 %h, i32 %1)` with an ARGUMENT / volatile-load
immediate — the non-Constant classical immediate dtzb deliberately accepts, and the very reason
the fix is G2-alone rather than a writer-side `isa<Constant>(Imm)`. Adding that negative there
would have reddened three shipped accept controls. Those three get a whole-file EXACT-COUNT
`XCNT` prefix for their own stem instead (COUNT is the prefix's FIRST directive, so the window is
the whole file and an injection is caught at head AND tail), plus the OTHER stem's rail-immediate
negative. Each fixture also gains an `FCNT` prefix (exact free count, or a pure `FCNT-NOT` where
the count is 0). No positive count is inside NOROUTE (Inc-3 F-L6-1).
* NEXT: rebuild (comments only -> must be `cmp`-identical), `lit --filter inplace_rail`, inject2.
* Rebuild `cmake --build build -j8` -> `BUILD_EXIT=0`; currency EMPTY.
  **`cmp build/ir-pass/cq-opt $SP/bin/eqpx-1333278/cq-opt` -> BYTE-IDENTICAL**, and so is
  `libCQPass.so`. `git diff 1333278 -- ir-pass/src ir-pass/include | grep '^[+-]' |
  grep -v '^[+-]\s*//' | grep -v '^+++\|^---'` -> **EMPTY**. Hard scope holds.
* ⚠ TRAP HIT AND FIXED, worth the record: my first draft of the F-E1-2 header quoted the
  literal tokens `` `CHECK-NOT: cqrt_xorc_i32` `` and `` `RUN: not` `` INSIDE the comment
  prose. lit/FileCheck parse a fixture by SUBSTRING, so those became REAL directives — the
  8 decline fixtures went RED with `.script: line 3: syntax error near unexpected token ')'`
  (lit had built a RUN line out of an English sentence). Never write `RUN:`, `CHECK:`,
  `CHECK-NOT:` or `<PREFIX>-NOT:` inside fixture prose; write the token without its colon.
  `lit --filter inplace_rail` after the fix: **16 selected, 16 Passed**, 0.74 s.
* **INJECTION MATRIX** (the lens's own `inject2.sh`, copied verbatim with `W=` repointed;
  3 injections x 2 positions x 8 accept fixtures = 48):
  * BEFORE (the pre-edit fixtures, restored with `git show 1333278:<path>` into
    `$W/orig8/`): **INJECTIONS=48 MISSED=28** — independently reproduces the lens's figure.
  * AFTER: **INJECTIONS=48 MISSED=0** (`$W/inject2_after.txt`). Clean control = the lit run
    above, which runs the identical prefixes on the un-injected output: 8/8 accepts green.
* Commit `27b7800`.

## 2026-09-06 step 4 — item (A), the in-source argument for the stronger form  [DONE]
Every fact VERIFIED by command before writing it, not copied from the lens:
* `grep -rn 'rewriteInPlaceValueRail' ir-pass/src ir-pass/include` -> 1 def, 1 decl,
  **ONE call site `OpcodeLowering.cpp:557`** (the lens's `:552` + my 5 comment lines), rest comments.
* `grep -rn 'void promote(' ir-pass/src` -> **4** defs: `ArithLowering.cpp:49`, `CastLowering.cpp:38`,
  `CompareLowering.cpp:44`, `IntrinsicLowering.cpp:204`; body is `Tainted.insert(repl); Tainted.erase(orig);`.
* `emitInPlaceReassign`'s `Site->replaceAllUsesWith(Handle)` -> `ArithLowering.cpp:162`.
Added at the `InPlaceRailIdx.find` consume, with the STATUS stated honestly (agrees with `TL` on
every corpus program — M2+M3 moves 0 of 1707; LIVE when WRONG — M-E reddens 23; therefore argued
defence-in-depth, not a fence with its own red-green) and the instruction "break (2) with a
program, not with an argument".
⚠ THREE STALE CODE CITATIONS FOUND AND FIXED while doing it (record truth, my own finding on top
of F-E1-1): (i) `ArithLowering.cpp:646-648` for G5's `LI.getLoopFor(...) || blockCanRepeat(...)`
disjunct pointed at COMMENT PROSE even on 1333278 — the code is `:695-696` after my +33 lines
(fixed in `OpcodeLowering.cpp` and notes §3.7's table + §3.16); (ii) `LoopLowering.cpp:1528-1537`,
which BRIEF_common and the fixtures cited for "Argument and volatile-load immediates dtzb
deliberately accepts", is the (E6)/(E12) break code and says nothing of the kind — the real
grounds are G2 itself (`LoopLowering.cpp:143`, which constrains the immediate ONLY by "not
tainted") and W1's (E10) at `:1568-1570` (*"dtzb accepts ANY untainted immediate"*); (iii) W1's
own immediate test `:1547-1549` is now `:1586-1588`.

## 2026-09-06 step 5 — F-E1-4 + (B): the record  [DONE]
* NEW `docs/prd/phase-04-swap-route-control/inc1-records/session-7bbdb89e/`:
  * `eqpx_reproducers_r1/` — the lens's **39** programs (15 members, 20 boundary controls,
    the 4 `b_n02_*` parity-sweep files that are the evidence for adjudication (B)) + a per-file
    `README.md` with every measured status.
  * `fix_eqpx.md`, `review_eqpx_r1.md` (copied so §3.16's reference is not dangling) + a
    session `README.md`.
* I RE-MEASURED the lens's whole attack corpus MYSELF on both binaries before publishing it
  (`$W/attack_{main,fix}.txt`, 45 programs through my own harness copy): **13 accept-with-
  imm>=1 on `main`, all 13 -> the mirrored decline on `fix`; 23 both-accept with identical
  lines/imm; x09/x10 rc 134 on `main`** (their harness line has an empty message, which is why
  a naive parser shows them as MISSING). 13 + 2 = the 15 F-E1-4 claims. Independent agreement.
* x09's `main` stderr, read directly: `Call parameter type does not match function signature!
  … i8  call void @cqrt_xorc_i8(i32 %h2, i32 %h_op)` / `LLVM ERROR: Broken module found`.
* The `n02` parity claims re-measured on `fix` by counting `cq_template_xor_i32(` inside
  `@slice`: K=2 **0**, K=3 **1**, K=4 **0**, K=5 **1**; `cmp n02.trace b_n02_unrolled.trace`
  **BYTE-IDENTICAL**. Adjudication (B) structurally re-derived: U4 clause (a) IS
  `inPlaceValueRailOperand` (`LoopLowering.cpp:2452`), and the prepass runs at
  `CQLoweringPass.cpp:271` vs `lowerLoops` at `:363` — same round-1 taint, so the claim sets
  are disjoint in both directions.
* Docs: notes §3.16 round-1-lens subsection (+ its writer table and §2's ⭐ row re-synced to
  `:1738 :2321 :2719 :3124`); PRD §0 **E13** extended; `CLAUDE.md` eqpx clause + lit-count line;
  `ROADMAP.md` eqpx paragraph. `$SP/briefs/BRIEF_common.md` NOT edited (the orchestrator's).

## 2026-09-06 step 6 — VERIFICATION OWED  [DONE]
| # | command | result |
|---|---|---|
| 1 | `cmake --build build -j8` (x3, background) | `BUILD_EXIT=0` each; currency `find … -newer build/ir-pass/cq-opt` EMPTY each |
| 2 | `cmp build/ir-pass/cq-opt $SP/bin/eqpx-1333278/cq-opt` | **BYTE-IDENTICAL** (and `libCQPass.so` too) |
| 3 | `git diff 1333278 -- ir-pass/src ir-pass/include \| grep '^[+-]' \| grep -v '^[+-]\s*//' \| grep -v '^+++\|^---'` | **EMPTY** — comment-only, twice-verified |
| 4 | `lit ir-pass/test --filter 'inplace_rail'` | **16 selected · 16 Passed** |
| 5 | `bash $W/inject2.sh` (8 accepts x 3 injections x 2 positions) | **INJECTIONS=48 MISSED=0** (BEFORE, on the pre-edit fixtures via `git show 1333278:`: **28 MISSED**) |
| 6 | `ctest --test-dir build -R ir-pass-lit --output-on-failure` | **Passed, 35.22 s, 0 failed** |
| 7 | `lit -s ir-pass/test` | **1707 Discovered · 1706 Passed · 1 Expectedly Failed · 0 unexpected**, 36.32 s |
| 8 | `git diff --stat 1333278 -- tests/e2e runtime tools/opcode_table.yaml include` | **EMPTY** |
| 9 | `ls ir-pass/test/*.ll \| wc -l` / `ls tests/e2e/*.expected.log \| wc -l` | **1707** / **323** — both UNCHANGED |
| 10 | `git status --porcelain` after commit | EMPTY |
Commits `27b7800` (F-E1-1/2/3) and `beb34e0` (item (A) + the record).

---

# ── HAND-BACK — fix_eqpx_b (FIX ROUND 2, DOCS + FIXTURES ONLY; branch `eqpx-fix`, NOT pushed) ──

## 1. What shipped

Two commits on `eqpx-fix`, both on top of `1333278`:

| commit | what |
|---|---|
| `27b7800` | F-E1-1 (the stale writer grep + four stale line numbers), F-E1-2 (the vacuous decline `CHECK-NOT`s), F-E1-3 (the 8 accept controls: `FCNT`/`XCNT`/rail-immediate negatives, **28 MISSED -> 0**) |
| `beb34e0` | item (A) in source, F-E1-4/(B) in the record (notes §3.16, PRD §0 E13, `CLAUDE.md`, `ROADMAP.md`, the new `session-7bbdb89e/` dir), + three STALE CODE CITATIONS found while verifying it |

`git diff --stat 1333278 HEAD` = **67 files, +1750 / -43** — 4 sources (comments only),
16 fixtures, 4 docs, and 43 new record files.

**HARD SCOPE HELD, verified two ways after every build:**
* `git diff 1333278 -- ir-pass/src ir-pass/include | grep '^[+-]' | grep -v '^[+-]\s*//' |
  grep -v '^+++\|^---'` -> **EMPTY**
* `cmp build/ir-pass/cq-opt $SP/bin/eqpx-1333278/cq-opt` -> **BYTE-IDENTICAL**, and so is
  `libCQPass.so`
* `git diff --stat 1333278 -- tests/e2e runtime tools/opcode_table.yaml include` -> **EMPTY**

## 2. What I ran

| # | command | result |
|---|---|---|
| 1 | subject currency (`git log -1`, `git status --porcelain`, `find … -newer build/ir-pass/cq-opt`) | `1333278`, EMPTY, EMPTY |
| 2 | `grep -n 'InPlaceRailOps.insert(' ir-pass/src/LoopLowering.cpp` | **ONE** site (`:193`, inside the helper) — F-E1-1 reproduced |
| 3 | `grep -n 'markInPlaceRailOp(' …` after my edits | four writers at **`:1738 :2321 :2719 :3124`** |
| 4 | decline stdout probe (`>out 2>err` on `w2_xor_derived`) | rc 1, **stdout 0 bytes**, stderr 1 diagnostic + blank (`od -c`) — F-E1-2 reproduced |
| 5 | `cmake --build build -j8` x3 (background) | `BUILD_EXIT=0`; currency EMPTY each time |
| 6 | `cmp` cq-opt / libCQPass.so vs `$SP/bin/eqpx-1333278/` | **BYTE-IDENTICAL** both, after every build |
| 7 | `lit ir-pass/test --filter 'inplace_rail'` | **16 selected · 16 Passed** |
| 8 | injection matrix BEFORE (`git show 1333278:` -> `$W/orig8/`) | **INJECTIONS=48 MISSED=28** — reproduces the lens |
| 9 | injection matrix AFTER (`bash $W/inject2.sh`) | **INJECTIONS=48 MISSED=0**, clean control green |
| 10 | `ctest --test-dir build -R ir-pass-lit --output-on-failure` | **Passed, 35.22 s, 0 failed** |
| 11 | `lit -s ir-pass/test` | **1707 Discovered · 1706 Passed · 1 Expectedly Failed · 0 unexpected**, 36.32 s |
| 12 | the lens's 45 attack programs, MY OWN run on both binaries | **13 accept-imm>=1 on `main` -> all 13 mirrored-decline on `fix`; 23 both-accept identical; x09/x10 rc 134 on `main`** = the 15 F-E1-4 members, independently agreed |
| 13 | `x09_i8` `main` stderr, read | `Call parameter type does not match function signature! … i8  call void @cqrt_xorc_i8(i32 %h2, i32 %h_op)` / `LLVM ERROR: Broken module found` |
| 14 | `n02` parity on `fix`, `cq_template_xor_i32(` inside `@slice` | K=2 **0** · K=3 **1** · K=4 **0** · K=5 **1**; `cmp` vs the hand-unrolled twin **BYTE-IDENTICAL** |
| 15 | adjudication-(B) structure: `loopHasInPlaceRailStructure` clause (a), prepass wiring | `LoopLowering.cpp:2452` calls `inPlaceValueRailOperand`; `unrollConstTripLoops` at `CQLoweringPass.cpp:271` vs `lowerLoops` `:363` |
| 16 | item-(A) facts: call sites / `promote` defs / the non-`promote` RAUW | 1 call site `OpcodeLowering.cpp:557`; 4 `promote` defs (`:49`, `CastLowering:38`, `CompareLowering:44`, `IntrinsicLowering:204`); `ArithLowering.cpp:162` |
| 17 | file counts | `ls ir-pass/test/*.ll` **1707** · `ls tests/e2e/*.expected.log` **323** — both UNCHANGED |

**NOT RUN, and I claim nothing about them:** the full `ctest`; `ctest -j6 -R '^e2e-'`
(nothing I touched can move a golden — `tests/` diff is EMPTY and the binary is byte-identical —
but I did not execute it); `frontend-lit`; `runtime`; `e2e-loop-twin-matrix`;
`cq_opt_equivalence`; any new mutant (I reused the lens's M-A/M-B/M-E/M-F results, attributed).

## 3. DEVIATION from the brief, with the measurement that forced it

**F-E1-3(i) as written would have reddened three shipped accept controls.** The brief says give
ALL EIGHT the negative `call void @cqrt_{xorc,addc}_i{{[0-9]+}}(i32 %{{.*}}, i32 %{{.*}})`
because "a Constant immediate prints as `i32 7`, never `i32 %…`". True of `ctlA`. FALSE of
`k01`/`k02`/`k03`, whose OWN legitimate gate is `cqrt_xorc_i32(i32 %h, i32 %1)` /
`cqrt_addc_i32(i32 %h, i32 %1)` with an Argument or a `load volatile` immediate — the
non-Constant classical immediate dtzb deliberately accepts, and the very reason this fix is
G2-alone rather than a writer-side `isa<Constant>(Imm)`. Those three get a whole-file
EXACT-COUNT `XCNT` prefix for their own stem instead (COUNT first ⇒ whole-file window ⇒ caught
at head AND tail) plus the OTHER stem's rail-immediate negative. Measured outcome is the same:
0 MISSED. Recorded in the fixtures, in notes §3.16 and in `CLAUDE.md`.

## 4. OWNER QUESTION

### OWNER QUESTION — the (1b) template fixture carries the identical vacuous pair, and it is on `main`
`ir-pass/test/control_phase_kickback_reject_preloop_commit_stale.ll` (LANDED, commit 16b15b3)
has the same `RUN: not … 2>&1 | FileCheck` + IR-text `CHECK-NOT` pattern, so its `CHECK-NOT`s
are equally unable to fire. My brief put it explicitly OUT OF SCOPE and I did not touch it
(`git diff --stat 1333278 -- <that file>` EMPTY). It is not a correctness defect — the `not`
inversion pins the property there too — but it is the same reader hazard, and the house style
will keep propagating. **Owner/orchestrator: is a one-line header note on that file (and on any
future decline fixture) wanted as a separate docs-only change?** Reproducer: the same stdout
probe, `cq-opt … -S <that fixture> >out 2>err` -> rc 1, `wc -c out` = 0.

### Not owner questions, but the orchestrator should know
`BRIEF_common.md`'s own citation *"Argument and volatile-load immediates dtzb deliberately
accepts, `LoopLowering.cpp:1528-1537`"* is wrong on this tree — those lines are
`emitBreakForward`'s (E6)/(E12) dominance/guard code. The real grounds are G2 itself
(`LoopLowering.cpp:143` — it constrains the immediate ONLY by "not tainted") and W1's (E10) at
`:1568-1570` (*"dtzb accepts ANY untainted immediate"*). I used the correct ones. Likewise the
implementer's `ArithLowering.cpp:646-648` for G5 pointed at comment prose even at `1333278`
(code at `:695-696`), and W1's `:1547-1549` is `:1586-1588`. All three corrected.

## 5. What is left

* **Rule 13 is not satisfied.** One adversarial lens is not a clearance. This function's history
  is nine findings over seven rounds, two INTRODUCED BY A FIX; a second round and a clearance
  are still owed on the tripwire itself. Nothing in this doc pass touches that — the binary is
  byte-identical, so round 1's verdict is exactly as strong (and as weak) as it was.
* The full `ctest` gate, the push and the bd close are the ORCHESTRATOR's. I did neither.
* The implementer's OWNER QUESTION 1 (keep the `InPlaceRailIdx` plumbing?) is now argued in
  source and graded DOC by the lens; the OWNER still owns the keep/drop call.
* The capability-preserving SECOND WRITER ROUND (re-marking after `repropagateControlMerges`)
  remains argued down in §3.16 as a better PREDICTION, viable only as a separate increment ON
  TOP of the tripwire and never as the fence.
