# BRIEF_common — bd epic test_C_libtooling-3qlq "retire the swap route" (2026-09-05)

You are ONE agent in a multi-agent session. An orchestrator wrote this brief and will judge
your output; the owner is NOT watching. Read this file completely, then your own brief.

## Paths (absolute; nothing is on PATH except `lit`, `python3`, `cmake`, `git`, `bd`)
- LLVM 19 tools:   `/usr/local/opt/llvm@19/bin/{clang,opt,FileCheck,not}`  (use absolute paths)
- Main checkout:   `/Users/sorenwilkening/Desktop/CQ_lang`  (branch `3qlq-inc1`; ONLY the Inc-1 implementer edits here)
- Scratchpad:      `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/0a61aa31-6fbe-43af-b2fd-a09b6d203ae5/scratchpad`  (call it `$SP`)
- ORACLE (pre-3qlq, commit 52d7764, BUILT):  `$SP/wt/pre-3qlq`
    - `$SP/wt/pre-3qlq/build/ir-pass/cq-opt`, `.../build/ir-pass/libCQPass.so`
    - `$SP/wt/pre-3qlq/build/runtime/libcq_templates.a`, `.../libcq_runtime.a`
      (the runtime is IDENTICAL for every binary in this epic — owner decision D3, no new
      symbol — so the oracle's archives link the subject's IR too)
- Your own worktree + branch: named in your brief. NEVER edit a worktree that is not yours.
- Progress file: `$SP/progress/<your-agent-name>.md` — append a dated line after EVERY step.
  If you are killed mid-task a fresh agent resumes from this file and your branch.
- Briefs: `$SP/briefs/`.

## Plan of record (read before doing anything)
- PRD: `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` (343 lines). §2 = the
  seven owner decisions D1–D7. §12 = four owner questions with ASSUMED answers
  (Q1 declarations deleted at the freeze, not now; Q2 no remark on deleting an
  uncontrolled cq_phi; Q3 run-time angle arms ADMITTED for the Rz angle select; Q4 bare-i1
  condition is Inc 1b, not Inc 1). Proceed on those assumptions. If an implementation or
  review finding CONTRADICTS a §2 decision or a §12 assumption, STOP that thread, write it
  in your progress file under `## OWNER QUESTION`, and report it — do not decide it.
- bd: `bd show test_C_libtooling-3qlq` and children `.1`–`.7`. Do NOT close or edit bd issues;
  the orchestrator does that. You MAY `bd remember` a hard-won LLVM-19 fact.
- `CLAUDE.md`: Prime Directive, Rules 12, 13, 17, 19. Key sentences:
  * Over-declining is safe; over-accepting is a verify-clean SILENT MISCOMPILE, the one
    unforgivable bug. When a precondition is unproven, decline loudly
    (`DiagnosticInfoUnsupported`, `opt` exits non-zero) and lower nothing.
  * Rule 17: for the TARGET shapes of this increment a decline is NOT the escape hatch. If
    the lowering is genuinely ambiguous, stop and write an OWNER QUESTION.
  * Rule 12: every accept ships with a decline fixture whose `RUN: not ... | FileCheck`
    mirrors the diagnostic string character-for-character. Red-green: write the fixture,
    watch it fail, implement minimally.
  * Rule 19: run the layer that can WITNESS your edit (one fixture 1.5 s; one slice 1.7 s;
    `ir-pass-lit` 60–105 s). NEVER run the full `ctest` as a heartbeat; the orchestrator runs
    it once at the gate. Report only what you ran: "lit green (N)", never "tests pass".
- HARD RULE OF THE EPIC: **NO new `cqrt_*` or `cq_template_*` symbol.** The emitted Rz set
  becomes `cqrt_rz_i1` only. Do not touch `tools/opcode_table.yaml` or `runtime/`.
- bd memories to read (`bd memories <key>` prints a truncated line; the full text is in
  `bd prime` output — run `bd prime | sed -n '/^### <key>/,/^### /p'`):
  `grover-goldens-are-identity-tensored-rz-2026-09-05`,
  `cq-phi-register-free-decisions-2026-09-05`, `drbq-inc4-review-pattern`,
  `drbq-inc3-compile-the-twin-first`, `f2-syntactic-enumeration-loses-to-instcombine`.

## The physics, in one paragraph (PRD §3)
`cqrt_rz_<W>` is TENSORED (Rz on each qubit), so a controlled/routed W-bit Rz puts phase
(-1)^popcount(target) on the marked branch and can never mark |0..0>: every shipped Grover
golden is the identity on q. The fix: `void cq_phi(double θ)` = "multiply the amplitude of
the CURRENT BRANCH by e^{iθ}". Under a tainted condition it is KICKBACK: mint the flag f =
c(x) into a |0> ancilla (the existing compare mint), `cqrt_rz_i1(f, θ)` UNCONTROLLED, then
the existing compare `_unc` strip returns f to |0> on every branch, `cqrt_free(f)`. A `¬f`
arm keeps the `cqrt_x(f)` bracket. Uncontrolled / classically-controlled `cq_phi` is a global
phase and is DELETED (D2). The Ry stem (`cq_theta`, `cqrt_ry_<W>[_controlled]`) is untouched.

## Build (only the Inc-1 implementer builds; everyone else uses the ORACLE binary)
```
cmake --build build -j8            # builds BOTH CQPass and cq-opt. NEVER `--target CQPass` alone:
                                   # lit runs build/ir-pass/cq-opt, a SEPARATE target, and a
                                   # CQPass-only rebuild gives FALSE GREEN (measured: 100% pass
                                   # on a broken pass, 49 reds once cq-opt was built).
cd build && lit ir-pass/test --filter '<name>'           # one fixture
ctest --test-dir build -R ir-pass-lit --output-on-failure # all 1582 fixtures (~60–105 s)
ctest --test-dir build -R '^e2e-slice-<name>$'            # one slice
ctest --test-dir build -R frontend-lit                    # CQ.h surface under clang -O1
```
Running lit WITHOUT a configured build dir (prep agents, in their worktree, against the oracle):
```
CQ_OPT=$SP/wt/pre-3qlq/build/ir-pass/cq-opt CQ_PASS=$SP/wt/pre-3qlq/build/ir-pass/libCQPass.so \
FILECHECK=/usr/local/opt/llvm@19/bin/FileCheck lit -v ir-pass/test --filter '<name>'
```
(`ir-pass/test/lit.cfg.py` lines 8–10 read exactly those env vars; `not` resolves from the
FileCheck dir.)

## Full pipeline for one .c (mirrors tests/e2e/run_slice.sh; LLVM=/usr/local/opt/llvm@19/bin)
```
$LLVM/clang -I<repo>/include -include CQ.h -O1 -emit-llvm -S file.c -o s1.ll            # 1 frontend
<cq-opt> -load-pass-plugin <libCQPass.so> -passes=cq-lowering -S s1.ll -o s2.ll          # 2 lowering (exit != 0 = loud decline)
python3 <repo>/tools/free_pairing_check.py s2.ll                                         # 2b Rule-6 free pairing (STRICT)
$LLVM/clang s2.ll <build>/runtime/libcq_templates.a <build>/runtime/libcq_runtime.a -o a # 3 link (templates BEFORE runtime)
./a > trace.log                                                                          # 4 trace
```
The three `ld: warning: object file ... built for newer 'macOS'` lines are pre-existing noise.

## Anti-stall rules (two agents were killed by the 600 s stream watchdog in drbq Inc 3)
1. Anything that may take > 2 min (a full lit run, a build, a matrix, a sweep) runs with
   `run_in_background: true`, writing to a log under `$SP/progress/`; poll the log with
   `tail`. Never block the foreground on it.
2. Append to your progress file after EVERY step (what you ran, the measured result, the
   next step). Numbers in the progress file are MEASURED, with the command that measured them.
3. Use non-interactive flags always: `cp -f`, `mv -f`, `rm -f`, `rm -rf`.
4. Do not run the full `ctest`. Do not `git push`. Do not commit to `main`. Commit on YOUR
   branch, as often as you like, with a one-line message prefixed `wip(3qlq):`.
5. No TodoWrite, no markdown TODO lists, no MEMORY.md. Progress file + bd only.

## Verification claims
Quote counts with the command that produced them. Distinguish MEASURED from analytic. Say
"declines with `<exact string>`" and "accepts, trace N lines", never "works". When you compare
two binaries, name both paths. When something is not verified, say so first.

## Hand-back format (last section of your progress file AND your final message)
1. What shipped (files, counts, commit hashes on your branch).
2. What you ran (commands + results).
3. Findings that are NOT yours to decide (`## OWNER QUESTION`), each with the reproducer.
4. What is left.
