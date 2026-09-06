# BRIEF_common — bd epic test_C_libtooling-3qlq "retire the swap route", SESSION 2 (2026-09-05, session adc5590a)

You are ONE agent in a multi-agent session. An orchestrator wrote this brief and will judge
your output; the owner is NOT watching. Read this file completely, then your own brief.

## Paths (absolute; nothing is on PATH except `lit`, `python3`, `cmake`, `git`, `bd`)
- LLVM 19 tools:   `/usr/local/opt/llvm@19/bin/{clang,opt,FileCheck,not,llvm-link}`  (use absolute paths)
- Main checkout:   `/Users/sorenwilkening/Desktop/CQ_lang`  — branch `3qlq-inc1` at **542d588**, build CURRENT
  (measured: nothing under ir-pass/ is newer than build/ir-pass/cq-opt). **This is the PRE-FIX SUBJECT for
  every red-green in this round. NOBODY edits it, NOBODY rebuilds it. Its binary is the baseline.**
    - `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`, `.../build/ir-pass/libCQPass.so`
    - `/Users/sorenwilkening/Desktop/CQ_lang/build/runtime/libcq_templates.a`, `.../libcq_runtime.a`
- Scratchpad (THIS session): `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/adc5590a-9105-4747-800e-e1da5cf70700/scratchpad`
  — call it `$SP`. Briefs in `$SP/briefs/`, progress files in `$SP/progress/`, worktrees in `$SP/wt/`.
- Previous session's scratchpad (STILL ON DISK, read-only for you; call it `$SP0`):
  `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/0a61aa31-6fbe-43af-b2fd-a09b6d203ae5/scratchpad`
    - ORACLE (pre-3qlq, commit 52d7764, BUILT):  `$SP0/wt/pre-3qlq` (`build/ir-pass/cq-opt`, `build/ir-pass/libCQPass.so`,
      `build/runtime/libcq_{templates,runtime}.a`). The runtime is IDENTICAL for every binary in this epic
      (owner decision D3, no new symbol) so any build's archives link any build's IR.
    - ROUND-1 SUBJECT (fa96336, BUILT): `$SP0/wt/r1-subject`.
    - INC 2 (87a90d7, base dfb8e83, BUILT): `$SP0/wt/inc2`.
    - The clearance review's harness + ~96 reproducers: `$SP0/progress/clearance_work/{run.sh,p/,out/}`
      (`run.sh <file.c|.ll> <subj|r1s|orac> [extra TUs]` = stage 1 → 2 → 2b STRICT → 3 → 4; `subj` there
      means the MAIN CHECKOUT, i.e. the pre-fix subject; copy it and add your own binary as a 4th case).
- Your own worktree + branch: named in your brief. NEVER edit a worktree that is not yours.
- Progress file: `$SP/progress/<your-agent-name>.md` — append a dated line after EVERY step.
  If you are killed mid-task a fresh agent resumes from this file and your branch.

## The record of session 1 (all committed, read from the repo)
`docs/prd/phase-04-swap-route-control/inc1-records/session-0a61aa31/`:
`clearance.md` (the BLOCK verdict, C-1's root cause + population, the B3 fixture, the unpinned shapes),
`OWNER_QUESTIONS.md` (OQ-1..OQ-29, Q-R1-1..5, Q-R2-1..3), `fix_r1.md` (F-L5-1 = `invariantRegisterRoots`),
`fix_r2.md` (F-R1-1 = clause (ii-b) + the second collapse pass), the eight round-1 and two round-2 lens
reports, `review_flips.md`, `briefs/` (every brief of session 1), `clearance_c1/` (C-1's reproducer pair +
both traces + the B3 plain-C reproducer and its stage-1 module).
Design of record: `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` (§0 ERRATA FIRST — it wins
over the body; §2 = owner decisions D1–D7; §12 = the assumed owner answers Q1–Q4), and
`RETIRE_SWAP_ROUTE_INC1_NOTES.md` (§1 round 1, §2 round 2 incl. the ⭐ once-only-stage table at line ~962).
If a finding CONTRADICTS a §2 decision or a §12 assumption, STOP that thread, write it in your progress
file under `## OWNER QUESTION`, and report it — do not decide it.
bd: `bd show test_C_libtooling-3qlq` and children `.1`–`.8`. Do NOT close or edit bd issues; the
orchestrator does that. You MAY `bd remember` a hard-won LLVM-19 fact.
bd memories to read (`bd prime | sed -n '/^### <key>$/,/^### /p'`): `rolled-idiom-needs-body-gate-or-invariant-root`,
`once-only-stage-round2-false-premise`, `kickback-gate-must-be-opaque-to-the-spine`,
`fixture-repairs-propagate-to-every-family`, `3qlq-inc1-not-landed-clearance-block-2026-09-05`,
`inloop-control-rolled-8h7d5`, `provably-before-per-activation`, `rail-record-set-is-the-rail-not-the-chain`.

## CLAUDE.md rules that bind you (read the file; these are the load-bearing sentences)
* Prime Directive: over-declining is safe; over-accepting is a verify-clean SILENT MISCOMPILE, the one
  unforgivable bug. When a precondition is unproven, decline loudly (`DiagnosticInfoUnsupported`, `opt`
  exits non-zero) and lower nothing.
* Rule 17: for the TARGET shape of this round a decline is NOT the escape hatch. If the lowering is
  genuinely ambiguous, stop and write an OWNER QUESTION.
* Rule 12: every accept ships with a decline fixture whose `RUN: not ... | FileCheck` mirrors the diagnostic
  string character-for-character. Red-green: write the fixture, watch it fail on the pre-fix subject,
  implement minimally, watch it pass.
* Rule 13: this is the Rule-13 core (`LoopLowering`/`Uncomputation`/`FreePoint`). A green suite does not
  clear it; an independent lens and a clearance do.
* Rule 19: run the layer that can WITNESS your edit (one fixture 1.5 s; one slice 1.7 s; `ir-pass-lit`
  60–105 s). NEVER run the full `ctest` as a heartbeat; the orchestrator runs it once at the gate. Report
  only what you ran: "lit green (N)", never "tests pass".
* THE 8h7d.5 LESSON, asked of every widening: "when you widen a set, ask what OTHER set was computed over
  the same closure" (F-1 widened the gates and not the records; F-3 was that omission, found one round later).
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
with the hand-unrolled twin's.

## Build (only in YOUR worktree; the main checkout is never rebuilt this round)
```
cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release
cmake --build build -j8            # builds BOTH CQPass and cq-opt. NEVER `--target CQPass` alone:
                                   # lit runs build/ir-pass/cq-opt, a SEPARATE target, and a CQPass-only
                                   # rebuild gives FALSE GREEN (measured: 100% pass on a broken pass).
cd build && lit ir-pass/test --filter '<name>'           # one fixture
ctest --test-dir build -R ir-pass-lit --output-on-failure # all fixtures (~60–105 s) — BACKGROUND
ctest --test-dir build -R '^e2e-slice-<name>$'            # one slice
```

## Full pipeline for one .c (mirrors tests/e2e/run_slice.sh; LLVM=/usr/local/opt/llvm@19/bin)
```
$LLVM/clang -I<repo>/include -include CQ.h -O1 -emit-llvm -S file.c -o s1.ll            # 1 frontend
<cq-opt> -load-pass-plugin <libCQPass.so> -passes=cq-lowering -S s1.ll -o s2.ll          # 2 lowering (exit != 0 = loud decline)
python3 <repo>/tools/free_pairing_check.py s2.ll                                         # 2b Rule-6 free pairing (STRICT)
$LLVM/clang s2.ll <build>/runtime/libcq_templates.a <build>/runtime/libcq_runtime.a -o a # 3 link (templates BEFORE runtime)
./a > trace.log                                                                          # 4 trace
```
The three `ld: warning: object file ... built for newer 'macOS'` lines are pre-existing noise.

## Anti-stall rules (agents have been killed by the 600 s stream watchdog and by an API rate limit)
1. Anything that may take > 2 min (a build, a full lit run, a matrix, a sweep) runs with
   `run_in_background: true`, writing to a log under `$SP/progress/`; poll the log with `tail`.
   Never block the foreground on it.
2. Append to your progress file after EVERY step (what you ran, the measured result, the next step).
   Numbers in the progress file are MEASURED, with the command that measured them.
3. Use non-interactive flags always: `cp -f`, `mv -f`, `rm -f`, `rm -rf`.
4. Do not run the full `ctest`. Do not `git push`. Do not commit to `main` or to `3qlq-inc1`. Commit on
   YOUR branch, as often as you like, with a one-line message prefixed `wip(3qlq):`.
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
