# BRIEF_common — bd epic test_C_libtooling-3qlq "retire the swap route", SESSION 3 (2026-09-06, session 82e6b530)

You are ONE agent in a multi-agent session. An orchestrator wrote this brief and will judge
your output; the owner is NOT watching. Read this file completely, then your own brief.

## Paths (absolute; nothing is on PATH except `lit`, `python3`, `cmake`, `git`, `bd`)
- LLVM 19 tools:   `/usr/local/opt/llvm@19/bin/{clang,opt,FileCheck,not,llvm-link}`  (use absolute paths)
- Main checkout:   `/Users/sorenwilkening/Desktop/CQ_lang` — branch `main` at **b99b853** (= origin/main; the last
  CODE commit is **258d974**, Inc 2 landed; b99b853 is docs-only). Build CURRENT for 258d974 (measured:
  `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` is EMPTY). **This is the PRE-FIX baseline for
  this session's red-greens: NOBODY edits it, NOBODY rebuilds it, NOBODY runs `git` mutations in it.**
    - `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`, `.../build/ir-pass/libCQPass.so`
    - `/Users/sorenwilkening/Desktop/CQ_lang/build/runtime/libcq_templates.a`, `.../libcq_runtime.a`
    - a frozen COPY of that binary (in case main is ever rebuilt this session): `$SP/bin/main-258d974/{cq-opt,libCQPass.so,libcq_templates.a,libcq_runtime.a}`
- Scratchpad (THIS session): `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/82e6b530-868e-4e27-af33-b46b44956ecb/scratchpad`
  — call it `$SP`. Briefs in `$SP/briefs/`, progress files in `$SP/progress/`, worktrees in `$SP/wt/`, saved binaries in `$SP/bin/`.
- Session-2 scratchpad (STILL ON DISK; call it `$SP1`):
  `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/adc5590a-9105-4747-800e-e1da5cf70700/scratchpad`
    - **C-1 ROUND 4 worktree**: `$SP1/wt/c1d`, branch `c1-round4` at **59f6a95** (base a3c1513; BUILT and current).
      Its pre-rebase binary is frozen at `$SP/bin/c1d-59f6a95/{cq-opt,libCQPass.so}` (runtime archives are
      identical across every build of this epic — owner D3, no new symbol — so link with main's).
    - `$SP1/wt/fix-c1` (c17c466, tree-identical to a3c1513, BUILT) — the Inc-1-landed / pre-Inc-2 binary.
    - every session-2 progress file, lens harness and population: `$SP1/progress/*.md`, `$SP1/progress/*_work/{run.sh,p/,out/}`
      (dirs with `p/`: fix_c1_work 133, review_c1_work 191, fix_c1b_work 211, review_c1b_work 263, fix_c1c_work 271,
      review_c1c_work 306, clearance2_work p 306 + p2 89 + p3 23, review_inc2_r2_work 69, fix_inc2_r2_work 32,
      clearance_inc2_work 89, fix_c1d_work 30, review_c1d_work 118). `review_c1d_work/run.sh <file> <main|prefix|fix|orac|inc2|fix2|<tree-root>>`
      = stage 1 → 2 → 2b STRICT → 3 → 4; COPY it into your own work dir and re-point `W=` and the case table.
- Session-1 scratchpad (STILL ON DISK; call it `$SP0`):
  `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/0a61aa31-6fbe-43af-b2fd-a09b6d203ae5/scratchpad`
    - **ORACLE** (pre-3qlq, commit **52d7764**, BUILT): `$SP0/wt/pre-3qlq` (`build/ir-pass/cq-opt`, `build/ir-pass/libCQPass.so`, `build/runtime/libcq_{templates,runtime}.a`).
- Your own worktree + branch: named in your brief. NEVER edit a worktree that is not yours.
- Progress file: `$SP/progress/<your-agent-name>.md` — append a dated line after EVERY step.
  If you are killed mid-task a fresh agent resumes from this file and your branch.

## The record (all committed on `main`, read from the repo)
`docs/prd/phase-04-swap-route-control/inc1-records/session-adc5590a/` — `README.md`, `NEXT_SESSION_PROMPT.md`,
`clearance2.md` (Inc 1 re-clearance), `inc2/clearance_inc2.md` (Inc 2 clearance), `c1-round4/{fix_c1d,review_c1d}.md`
(round 4 and its lens: **CLEAR-WITH-ITEMS**, items F-C1D-1..4), `briefs/` (every brief of session 2).
Design of record: `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` (§0 ERRATA FIRST — E1–E12, it wins
over the body; §2 = owner decisions D1–D7), `RETIRE_SWAP_ROUTE_INC1_NOTES.md` (§3.1–§3.14; §2's ⭐ once-only-stage
table at ~line 962; **§3.14 = round 4**, incl. the 8h7d.5 closure table at ~line 2047), `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1–§5.
If a finding CONTRADICTS a PRD §2 decision, STOP that thread, write it in your progress file under
`## OWNER QUESTION`, and report it — do not decide it.
bd: `bd show test_C_libtooling-3qlq` (epic), `test_C_libtooling-7yd0` (round 4), `test_C_libtooling-eqpx` (P1).
Do NOT close or edit bd issues; the orchestrator does that. You MAY `bd remember` a hard-won LLVM-19 fact.
bd memories to read (`bd prime | sed -n '/^### <key>$/,/^### /p'`): `3qlq-c1-round4-pending-2026-09-06`,
`3qlq-inc1-landed-2026-09-06`, `3qlq-inc2-landed-2026-09-06`, `fix-that-predicts-a-later-stage-must-reverify-there`,
`rolled-idiom-needs-body-gate-or-invariant-root`, `once-only-stage-round2-false-premise`, `drbq-inc4-review-pattern`.

## CLAUDE.md rules that bind you (read the file; these are the load-bearing sentences)
* Prime Directive: over-declining is safe; over-accepting is a verify-clean SILENT MISCOMPILE, the one
  unforgivable bug. When a precondition is unproven, decline loudly (`DiagnosticInfoUnsupported`, `opt`
  exits non-zero) and lower nothing.
* Rule 17: for the TARGET shape of this round a decline is NOT the escape hatch. If the lowering is
  genuinely ambiguous, stop and write an OWNER QUESTION.
* Rule 12: every accept ships with a decline fixture whose `RUN: not ... | FileCheck` mirrors the diagnostic
  string character-for-character. Red-green: write the fixture, watch it fail on the pre-fix baseline,
  implement minimally, watch it pass.
* Rule 13: this is the Rule-13 core (`LoopLowering`/`OpcodeLowering`/`ArithLowering`/`Uncomputation`/`FreePoint`).
  A green suite does not clear it; an independent lens and a clearance do.
* Rule 19: run the layer that can WITNESS your edit (one fixture 1.5 s; one slice 1.7 s; `ir-pass-lit`
  35–105 s). NEVER run the full `ctest` as a heartbeat; the orchestrator runs it once at the gate. Report
  only what you ran: "lit green (N)", never "tests pass".
* THE 8h7d.5 LESSON, asked of every widening: "when you widen a set, ask what OTHER set was computed over
  the same closure" (F-1 widened the gates and not the records; F-3 was that omission, found one round later).
* THE C-1 LESSON (eight findings over six rounds on ONE function, two INTRODUCED by a fix): a stage that PREDICTS a
  later stage's decision must have a MONOTONE commit-time fence plus a LOUD tripwire at the consumer that re-asks the
  SAME predicate under final state (bd memory `fix-that-predicts-a-later-stage-must-reverify-there`).
* HARD RULE OF THE EPIC: **NO new `cqrt_*` or `cq_template_*` symbol** (owner D3). Do not touch
  `tools/opcode_table.yaml` or `runtime/`.

## The physics, in one paragraph (PRD §3)
`cqrt_rz_<W>` is TENSORED (Rz on each qubit), so a controlled/routed W-bit Rz can never mark |0..0>: every
pre-3qlq Grover golden was the identity on q. `void cq_phi(double θ)` = "multiply the amplitude of the
CURRENT BRANCH by e^{iθ}". Under a tainted condition it is KICKBACK: mint the flag f = c(x) into a |0>
ancilla (the existing compare mint), `cqrt_rz_i1(f, θ)` UNCONTROLLED, then the existing compare `_unc`
strip returns f to |0> on every branch, `cqrt_free(f)`; a `¬f` arm keeps the `cqrt_x(f)` bracket; a
DERIVED condition (`(q>>i)&1`) mints template rails (`lshr_hl`, `and_hl`) that must be `_unc`'d and freed
after the strip — a leaked one is a which-path record of q, and a later non-diagonal gate on q (a
diffusion) then interferes branches carrying DISTINCT ancilla labels: a DIFFERENT UNITARY, at `opt` exit
0, verify-clean, and STRICT stage 2b `0 violation(s)` (2b is structurally blind: a template-minted rail
has no `cqrt_alloc` to count). The witness for every in-loop claim is BYTE IDENTITY of the rolled trace
with the hand-unrolled twin's. Since Inc 2 a VALUE arm is the CONTROLLED-COPY MERGE (hoist the pure chain
to the pred, mint the flag, two `cqrt_copy_<W>_controlled` into a |0> out-rail, chain `_unc`, strip, one free);
the chain-final rail is LEFT ALLOCATED and entangled (PRD E1). The merge's `%out` rail has TWO WRITERS before any
reader — which is exactly why `hasOneUse` refused it (bd 7yd0).

## Build (only in YOUR worktree; the main checkout is never rebuilt this session)
```
cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release
cmake --build build -j8            # builds BOTH CQPass and cq-opt. NEVER `--target CQPass` alone:
                                   # lit runs build/ir-pass/cq-opt, a SEPARATE target, and a CQPass-only
                                   # rebuild gives FALSE GREEN (measured: 100% pass on a broken pass).
cd build && lit ir-pass/test --filter '<name>'           # one fixture
ctest --test-dir build -R ir-pass-lit --output-on-failure # all fixtures (~35–105 s) — BACKGROUND
ctest --test-dir build -R '^e2e-slice-<name>$'            # one slice
```
Before trusting ANY binary: `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` must be EMPTY.

## Full pipeline for one .c (mirrors tests/e2e/run_slice.sh; LLVM=/usr/local/opt/llvm@19/bin)
```
$LLVM/clang -I<repo>/include -include CQ.h -O1 -emit-llvm -S file.c -o s1.ll            # 1 frontend
<cq-opt> -load-pass-plugin <libCQPass.so> -passes=cq-lowering -S s1.ll -o s2.ll          # 2 lowering (exit != 0 = loud decline)
python3 <repo>/tools/free_pairing_check.py s2.ll                                         # 2b Rule-6 free pairing (STRICT)
$LLVM/clang s2.ll <build>/runtime/libcq_templates.a <build>/runtime/libcq_runtime.a -o a # 3 link (templates BEFORE runtime)
./a > trace.log                                                                          # 4 trace
```
The three `ld: warning: object file ... built for newer 'macOS'` lines are pre-existing noise.
Counting convention for the C-1 class: "rolled a/b" = `and|lshr _hl` MINTS / `_hl_unc` DISCHARGES in the rolled
trace; the witness is `cmp` of the rolled trace against the hand-unrolled twin's.

## Anti-stall rules (agents have been killed by the 600 s stream watchdog and by an API rate limit)
1. Anything that may take > 2 min (a build, a full lit run, a matrix, a sweep) runs with
   `run_in_background: true`, writing to a log under `$SP/progress/`; poll the log with `tail`.
   Never block the foreground on it.
2. Append to your progress file after EVERY step (what you ran, the measured result, the next step).
   Numbers in the progress file are MEASURED, with the command that measured them.
3. Use non-interactive flags always: `cp -f`, `mv -f`, `rm -f`, `rm -rf`. Use `bash -c` for word-splitting loops
   (zsh does not word-split — a session-2 lens scored declines as accepts because of it).
4. Do not run the full `ctest`. Do not `git push`. Do not commit to `main`. Commit on YOUR branch, as often as
   you like, with a one-line message prefixed `wip(<round>):`.
5. No TodoWrite, no markdown TODO lists, no MEMORY.md. Progress file + bd only.

## Verification claims
Quote counts with the command that produced them. Distinguish MEASURED from analytic. Say
"declines with `<exact string>`" and "accepts, trace N lines", never "works". When you compare
binaries, name every path. When something is not verified, say so first.

## Hand-back format (last section of your progress file AND your final message)
1. What shipped (files, counts, commit hashes on your branch).
2. What you ran (commands + results).
3. Findings that are NOT yours to decide (`## OWNER QUESTION`), each with the reproducer.
4. What is left.
