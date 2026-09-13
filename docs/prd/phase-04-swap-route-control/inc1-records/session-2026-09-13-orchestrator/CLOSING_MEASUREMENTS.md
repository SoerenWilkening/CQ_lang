# CLOSING_MEASUREMENTS — session 2026-09-13, step 5 (the one rebuild, the one full gate)

Agent: closing (step 5). Checkout `/Users/sorenwilkening/Desktop/CQ_lang`, `main` at **59ac5b7** (the
third and last squash of the session). This is the record the docs pass quotes: **every command below
was RUN by me on this box, and its output is pasted verbatim** (Rule 19 — report only what you ran).

`git status --porcelain` at start showed exactly one untracked path, `…/NEXT_SESSION_PROMPT.md`; no
tracked file was modified by me. I wrote **three** files: this one, `owner_file_final.trace`, and the
session-level `GATES.md`. No commit, no push, no bd write.

```
$ git log --oneline -1
59ac5b7 feat(control): bd boi6 D-B / bd 8xaw — the REGION-MERGE-φ rail leaf for the 4.4 DATA SELECT (squash of branch mphi-rail-leaf, tip 7c9b05e = gated tree 54079b6 = 4971b73 merged with main 94c085e): THE OWNER'S example/grover/grover_oracle_uncompute.c of 2026-09-13 ('if (b1) a -= 3;' after a bool-controlled state prep of b1) COMPILES AS WRITTEN — exit 0, stderr 0 bytes, 29 trace lines, STRICT stage 2b '8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven'

$ git status --porcelain
?? docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/NEXT_SESSION_PROMPT.md
```

---

## §0 THE HEADLINE, and the one finding worth its own line

**Zero findings. The rebuilt primary is BIT-IDENTICAL to Track M's merge-and-gate binary.**

```
BEFORE (the session ORACLE, frozen since 2026-09-11 22:23, built from e96f89c)
  cq-opt        fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661
  libCQPass.so  40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93
AFTER (this rebuild, from main 59ac5b7)
  cq-opt        f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc
  libCQPass.so  f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d
```

The BEFORE pair matches `PROTOCOL.md`'s ORACLE line character-for-character — nobody rebuilt the
oracle during the session. The AFTER pair is **the same 64 hex digits** as `trackM/MERGE_M_1.md` §5's
MERGED binary (`f7b65d8ccd7bc472…` / `f9e898badfd4207a…`), which was built in a *different worktree*
(`/Users/sorenwilkening/Desktop/CQ_mphi`) from the merge commit. So the three squashes onto `main`
reproduce the gated tree **bit for bit**: the code that was reviewed and gated is the code that is on
`main`, and every number in `MERGE_M_1.md` is a statement about this binary and not merely about one
like it. That is not a cited gate — I re-ran the full suite, the equivalence sweep and all nine counts
anyway, and they reproduce. It is the strongest possible form of the PROTOCOL's "a gate result is a
fact about a BINARY, not about a moment".

The owner's real file `example/grover/grover_oracle_uncompute.c` is **byte-identical** to the session
snapshot `probes/owner_file_2026-09-13.c` (`diff` silent, exit 0) — the owner did not edit it again —
and it compiles as written: exit 0, stderr 0 bytes, 29 trace lines **byte-identical** to
`tests/e2e/slice_control_cascade_two_bools.expected.log`.

---

## §1 STEP 1 — hashes BEFORE (the ORACLE, unbuilt and unwritten all session)

```
$ date "+%Y-%m-%d %H:%M:%S"
2026-09-13 14:57:06
$ shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661  build/ir-pass/cq-opt
40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93  build/ir-pass/libCQPass.so
```

Matches `PROTOCOL.md` exactly. **No other agent was running** (orchestrator guarantee); nothing was
measuring against this build while I relinked it, and I never `pkill`ed anything (bd memory
`never-relink-or-pkill-under-measurement`).

---

## §2 STEP 2 — the ONE rebuild (reconfigure first; BOTH targets)

`CMakeLists.txt` moved in all three landings, so the reconfigure is not optional.

```
$ cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release
-- cq_lang: using LLVM 19.1.7 from /usr/local/opt/llvm@19/lib/cmake/llvm
-- ir-pass/test: using LIT (/Users/sorenwilkening/.pyenv/shims/lit)
-- tests/frontend: using LIT (/Users/sorenwilkening/.pyenv/shims/lit)
-- cq e2e: python /Users/sorenwilkening/.pyenv/shims/python3 -> /Users/sorenwilkening/.pyenv/versions/3.11.9/bin/python3
-- cq e2e: stage-1 cache key eb624df85f201600718b0fec60dc8a3100e375325dee8b10d30489b97a573368
-- cq e2e: stage-3 link via derived /Users/sorenwilkening/Desktop/CQ_lang/build/tests/e2e/cq_link.sh
-- Configuring done (2.5s)
-- Generating done (0.5s)
-- Build files have been written to: /Users/sorenwilkening/Desktop/CQ_lang/build
cmake -S . -B build …   1,32s user 0,47s system 57% cpu 3,129 total     [exit 0]
```

`CQ_LD` was re-derived by the reconfigure (`cq_link.sh`) — CLAUDE.md says it must be, and that it
fails loudly if stale; it did not fail.

```
$ cmake --build build -j8            # NEVER --target CQPass alone (the false-green trap)
… [ 92%] Built target CQPass
… [100%] Built target cq-opt
cmake --build build -j8  352,22s user 38,03s system 742% cpu 52,525 total     [exit 0]
```

**52.525 s wall, exit 0, 0 errors.** Warnings: the same **4** pre-existing ones, each emitted twice
(once per target, which is why `uniq -c` shows 2):

```
$ grep -E 'warning:' build.log | sort | uniq -c
   2 ir-pass/src/RegionTreeDetect.cpp:173:14: warning: unused variable 'OuterNeg' [-Wunused-variable]
   2 ir-pass/src/RegionTreeDetect.cpp:174:14: warning: unused variable 'InnerNeg' [-Wunused-variable]
   2 ir-pass/src/TaintPropagation.cpp:1988:33: warning: unused parameter 'M' [-Wunused-parameter]
   2 ir-pass/src/TaintPropagation.cpp:255:64: warning: unused parameter 'PhiFns' [-Wunused-parameter]
   1 ld: warning: ignoring duplicate libraries: '…libLLVMAnalysis.a', … (the cq-opt link, pre-existing)
```

**No new warning** — the same four files/lines `MERGE_M_1.md` §5 names, none in a file any track
touched.

```
$ date "+%Y-%m-%d %H:%M:%S"; shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
2026-09-13 14:58:17
f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  build/ir-pass/cq-opt
f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d  build/ir-pass/libCQPass.so
```

Re-hashed again after the equivalence target rebuilt its dependencies (§4) — **unchanged**, so every
measurement in §§3–7 is a fact about `f7b65d8ccd7bc472`.

---

## §3 STEP 3 — the full suite, ONCE

```
$ ctest --test-dir build -j6 --output-on-failure
…
420/420 Test   #8: ir-pass-lit .......................................................   Passed   54.54 sec

100% tests passed, 0 tests failed out of 420

Total Test time (real) = 393.20 sec
ctest --test-dir build -j6 --output-on-failure  1113,36s user 175,65s system 327% cpu 6:33,27 total
```

**100% tests passed, 0 tests failed out of 420.** Test time 393.20 s; wall 6:33.27; exit 0.
`grep -c 'Failed'` over the whole log = **0**, so nothing had to be re-run serially (CLAUDE.md:
contention causes false FAILURES, never false passes — there were none to discount). Within
CLAUDE.md's 130–230 s quiet-box band? No: 393 s, because the long pole moved — see below.

The eight slowest entries, and the gates worth naming:

```
355/420 Test #318: e2e-loop-twin-matrix ........................  Passed  349.47 sec   <- the long pole
420/420 Test   #8: ir-pass-lit .................................  Passed   54.54 sec
345/420 Test #296: e2e-fixture-guard-liveness ..................  Passed   19.95 sec
349/420 Test   #9: cq-opt-equivalence (sampled, --stride 8) ....  Passed   19.26 sec
401/420 Test   #4: runtime_link_smoke_selftest .................  Passed   10.00 sec
402/420 Test  #10: frontend-lit ................................  Passed    8.08 sec
  5/420 Test #274: e2e-slice-libm-real-lgamma ..................  Passed    7.18 sec
340/420 Test #217: e2e-slice-control-spec-chained-ctl ..........  Passed    7.05 sec
360/420 Test #295: e2e-loop-twin-quarantine-selftest ...........  Passed    1.10 sec
400/420 Test #294: e2e-free-pairing-selftest ...................  Passed    3.87 sec
363/420 Test #298: e2e-census-slice-sync .......................  Passed    0.33 sec
```

`e2e-loop-twin-matrix` at **349.47 s** is 89 % of the wall clock and 135 s slower than the 214.33 s
`MERGE_M_1.md` measured on the same 288 cells and the same binary — **the cells did not change**
(§5: 259 + 29 = 288, unchanged), so the delta is the box (load and stage-1 cache warmth, which this
reconfigure reset), not added work; CLAUDE.md's own band for this entry is 180–400 s and 349 s sits
inside it. It is the only instrument in the tree that can see a leaked TEMPLATE-minted rail, and it
Passed. `e2e-free-pairing-selftest`,
`e2e-loop-twin-quarantine-selftest` and `e2e-census-slice-sync` — the three pure-Python RECORD gates
that each exist because a number once measured the wrong program — all Passed.

---

## §4 STEP 4 — `cq-opt-equivalence-full`, ONCE (owed: three landings moved decline strings and analysis sites)

```
$ cmake --build build --target cq-opt-equivalence-full
[100%] cq-opt vs stock opt: full all-fixture equivalence sweep
cq_opt_equivalence: compared 1928 fixtures, 0 mismatch(es)
[100%] Built target cq-opt-equivalence-full
cmake --build build --target cq-opt-equivalence-full  685,20s user 43,90s system 756% cpu 1:36,34 total
```

**1928 fixtures, 0 mismatch(es)**, 96.34 s wall, exit 0. This compares stdout, stderr **and** exit
code of `%cq-opt` against stock `opt -load-pass-plugin` on every fixture — the gate that keeps the
fast harness binary from drifting from the real one, and the reason a moved diagnostic string is safe
to rely on.

---

## §5 STEP 5 — the nine counts, BY COMMAND

```
$ ls ir-pass/test/*.ll | wc -l                                  1928
$ ls tests/e2e/*.expected.log | wc -l                            367
$ ctest --test-dir build -N | tail -1                            Total Tests: 420
$ ctest --test-dir build -N -R '^e2e-' | tail -1                 Total Tests: 410
$ ctest --test-dir build -N -R '^e2e-slice-' | tail -1           Total Tests: 365
$ ctest --test-dir build -N -R twin-identical | tail -1          Total Tests: 34
$ grep -c '^add_test' tests/e2e/CMakeLists.txt                    410
$ grep -c '^m_' tools/loop_twin_matrix.expected.txt               259
$ grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt           29
```

| count | `e96f89c` (CLAUDE.md) | `MERGE_M_1.md` predicts | **measured here** |
|---|---|---|---|
| `ls ir-pass/test/*.ll` | 1893 | 1928 | **1928** ✓ |
| `ls tests/e2e/*.expected.log` | 355 | 367 | **367** ✓ |
| `ctest -N` | 403 | 420 | **420** ✓ |
| `ctest -N -R '^e2e-'` | 393 | 410 | **410** ✓ |
| `ctest -N -R '^e2e-slice-'` | 353 | 365 | **365** ✓ |
| `ctest -N -R twin-identical` | 30 | 34 | **34** ✓ |
| `grep -c '^add_test' tests/e2e/CMakeLists.txt` | — | 410 | **410** ✓ |
| twin-matrix cells `m_` + `cell ` | 259 + 29 = 288 | 288 | **259 + 29 = 288** ✓ (unchanged) |
| `cq-opt-equivalence-full` | 1893/0 | 1928/0 | **1928/0** ✓ |

All nine reproduce on the rebuilt primary. `ctest -N` 420 and `grep -c '^add_test'` 410 are
independent readings (CMake's registry vs the file's text) and they are consistent: 410 e2e +
`ir-pass-lit` + `frontend-lit` + `cq-opt-equivalence` + 7 runtime entries = 420.

**CLAUDE.md's Build & Test counts block stated the `e96f89c` column when I started** and was stale on
every line. I did not edit it (I am allowed to write three files, none of them CLAUDE.md) — and by
15:09 the session's concurrent docs pass had already rewritten it to exactly these nine numbers,
citing this file. See §9: that pass was writing the checkout while my gates ran.

---

## §6 STEP 6 — THE OWNER'S REAL FILE

### 6a. It is unchanged since the snapshot — checked FIRST, as the brief requires

```
$ ls -l example/grover/grover_oracle_uncompute.c
-rw-r--r--@ 1 sorenwilkening  staff  5890 12 Sep. 11:02 example/grover/grover_oracle_uncompute.c
$ diff example/grover/grover_oracle_uncompute.c $SES/probes/owner_file_2026-09-13.c && echo IDENTICAL
IDENTICAL
```

**No diff to report.** The file is git-excluded, so this is the only way to know; the owner did not
edit it after the session snapshot was taken. Its live body (everything below the long comment) is:

```c
int main(void) {
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;

    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;

    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;

    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
```

No `int` workaround, no `cq_*` function the owner had to be told about, and the second guard is the
bare `if (b1)` — the region-merge-φ rail leaf this session's landing 3 exists for.

### 6b. `show_pipeline.sh` (the command the file's own header tells the owner to run)

`tools/show_pipeline.sh` is the visible-intermediates twin of `tests/e2e/run_slice.sh`: same four
stages, but with stock `$LLVM/opt` rather than `%cq-opt`, and it writes `s0.O0.ll`, `s1.O1.ll`,
`s2.lowered.ll` and the linked `slice` into `build/pipeline-out/<name>/` instead of diffing a golden
in a tempdir. It does **not** run stage 2b, which is why §6c re-runs the pipeline by hand.

```
$ ./tools/show_pipeline.sh example/grover/grover_oracle_uncompute.c
show_pipeline exit=0        stderr bytes=0
```

Its STAGE 4 trace is byte-identical to §6c's (the only difference my extraction shows is the trailing
blank line `hr()` prints before the closing banner).

### 6c. The PROTOCOL.md four-stage pipeline, on the rebuilt primary

```
$ "$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S example/grover/grover_oracle_uncompute.c -o s1.ll
stage1 clang exit=0  stderr_bytes=0
$ build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S s1.ll -o s2.ll
stage2 cq-opt exit=0  stderr_bytes=0
VERDICT: ACCEPT
$ python3 tools/free_pairing_check.py s2.ll                       # STRICT — no --allow-unproven
free_pairing_check: 1 file(s), 8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven
stage2b exit=0
$ "$LLVM/clang" s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o a
stage3 link exit=0
$ ./a > trace.log
stage4 run exit=0        trace lines=29
```

**exit 0 · stderr 0 bytes · STRICT 2b `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s):
2 verified, 0 violation(s), 0 unproven` · 29 trace lines** — character-for-character what the squash
message 59ac5b7 claims and what `MERGE_M_1.md` §4 recorded on the merge worktree.

### 6d. The diffs

```
$ diff $SES/owner_file_final.trace tests/e2e/slice_control_cascade_two_bools.expected.log
(no output)   diff exit=0     -> BYTE-IDENTICAL, 29 lines
$ diff <(head -16 $SES/owner_file_final.trace) <(head -16 $SES/probes/va.trace)
(no output)   diff exit=0     -> the first 16 gates are va's first 16 gates, unchanged
```

⚠ Read the second one precisely: `probes/va.trace` is **19** lines (16 gates + its own 3 measures), so
the identity is `head -16` against `head -16`, not the owner's first 16 lines against the whole file.
`MERGE_M_1.md` §4's "lines 1–16 BYTE-IDENTICAL to `probes/va.trace`" means exactly this and nothing
stronger — a whole-file diff there is 3 lines of measures, which is not a finding.

The full 29 lines are in `owner_file_final.trace` beside this record. Its shape, and the one invariant
to read it by (`h0` = `b0`, `h1` = `b1`, both USER registers):

```
alloc_i1(0)->h0; ry_i1(h0,0.5)                                        S on b0
alloc_i1(0)->h1; ry_i1(h1,0.5); ry_i1_controlled(h0,h1,-0.5)          bool-controlled prep of b1
alloc_i1(0)->h2; cnot(h0,h2)                                          rail root -> CNOT-COPY ancilla
  alloc_i32(0)->h3; alloc_i32(2)->h4; copy_i32_controlled(h2,h4,h3); x(h2)
  alloc_i32(5)->h5; copy_i32_controlled(h2,h5,h3); x(h2)              the peeled `a`-mux (landing of 2026-09-11)
  cnot(h0,h2); free(h2)                                               x XOR x = 0 -> a proven-|0> free
add_i32_hl(h3,-3)->h6                                                 `a -= 3` hoisted out of the second arm
alloc_i1(0)->h7; cnot(h1,h7)                                          the SECOND rail leaf — landing 3
  alloc_i32(0)->h8; copy_i32_controlled(h7,h6,h8); x(h7)
  copy_i32_controlled(h7,h3,h8); x(h7); cnot(h1,h7); free(h7)         the second merge-φ select
measure_i1(h0); measure_i1(h1); measure_i32(h8)
```

`h0` and `h1` are read **only as controls** — never `cqrt_x`-bracketed, never freed, because
`Ry(θ)|0⟩ ≠ |0⟩` (Rule 6). The four `cqrt_x` are on the two CNOT-copy ancillas `h2`/`h7`, each of
which returns to `x ⊕ x = 0` before its `cqrt_free`; that is exactly what stage 2b's **`2 verified`**
witnesses, and the 6 left allocated are the two user rails plus the four `i32` value rails the
qubits-not-scarce regime permits (Rule 6: left allocated, never freed dirty).

---

## §7 STEP 7 — the seven probes on the rebuilt primary

Same four-stage pipeline, one line each (verdict · trace lines · STRICT 2b), every one matching what
`MERGE_M_1.md` §4 recorded on the pre-squash merge worktree.

| # | probe | verdict | lines | STRICT stage 2b | cross-check |
|---|---|---|---|---|---|
| 1 | `probes/va.c` | **ACCEPT** exit 0, stderr 0 B | **19** | `6 rail mint(s) of which 5 left allocated, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven` | **byte-identical to `probes/va.trace`** |
| 2 | `probes/vb.c` | **ACCEPT** exit 0, stderr 0 B | **29** | `8 mint(s) / 6 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven` | **byte-identical to the owner's trace** |
| 3 | `probes/vc.c` | **ACCEPT** exit 0, stderr 0 B | **29** | `8 mint(s) / 6 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven` | **byte-identical to the owner's trace** |
| 4 | `probes/vd.c` | **DECLINE** exit 1, 238 B | — | — | `vd.c:10:14: … cq controlled lowering: state prep seed is proven equal to the condition register under quantum control` |
| 5 | `trackC/probes/owner_2026-09-11_2218.c` | **ACCEPT** exit 0, stderr 0 B | **15** | `5 mint(s) / 4 left allocated, 1 free: 1 verified, 0 violation(s), 0 unproven` | **byte-identical to `tests/e2e/slice_measure_classical_bool.expected.log`** |
| 6 | `trackR/probes/b_A_intb0_boolb1.c` | **ACCEPT** exit 0, stderr 0 B | **22** | `5 mint(s) / 5 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven` | **byte-identical to `tests/e2e/slice_control_stateprep_bool_under_int_compare_fused.expected.log`** |
| 7 | `trackL/probes/a_loop_n3.c` | **DECLINE** exit 1, 196 B | — | — | `a_loop_n3.c:10:26: … cq taint escape: tainted value stored to memory` |

Verbatim, the two declines (both loud `DS_Error`, both source-located with `!dbg`, `opt` exit 1 — Rule 1):

```
$ cq-opt … probes/vd.c
error: …/probes/vd.c:10:14: in function main i32 (): cq controlled lowering: state prep seed is proven equal to the condition register under quantum control

$ cq-opt … trackL/probes/a_loop_n3.c
error: …/trackL/probes/a_loop_n3.c:10:26: in function main i32 (): cq taint escape: tainted value stored to memory
```

Both are the declines the session SCOPED, not regressions:

* **`vd`** is F2, the state-prep fence, refusing the third region whose downstream compare `-O1` can
  pin FALSE. `MERGE_M_1.md` §4 records the same verdict at the same `10:14`, and `C2′`
  (`trackR/probes/v_vd_guard_neg.c`, the same program with `a >= -5`) ACCEPTS at 42 lines — so the
  decline is the fence, not the shape. Widening it is the owner's R-2 ruling, deliberately not folded
  in.
* **`a_loop_n3`** is the ARRAY spelling (`bool b[3]`), and the probe's own header predicted this
  string on the ORACLE. It is unchanged on the new primary: an array element is memory, so taint
  escapes before any control question is reached — a Prime-Directive decline that no landing this
  session was scoped to move. Its retirement trigger (L8) stands as written in the probe header.

Every accepting probe re-lowered through STRICT stage 2b with `0 violation(s), 0 unproven`; **no
`--allow-unproven` anywhere in this record**.

---

## §8 WHAT I DID NOT DO

* **No commit, no push, no bd write, no squash.** Those belong to the session close and to the docs
  pass; I wrote only the three files the brief names.
* **No second full suite and no second equivalence sweep.** One of each, both on `f7b65d8ccd7bc472`.
* **No corpus sweep, no injection matrix, no twin matrix of my own, no duplicate-body scan.** Those
  are the merge-and-gate row's gates and `MERGE_M_1.md` ran them on a binary whose hash I re-measured
  as identical to this one (§0) — I cite them there rather than re-running them, and I do not restate
  their numbers as if I had.
* **No edit to any tracked file**, including CLAUDE.md's stale Build & Test counts (§5) and
  `README.md` — flagged for the docs pass, not silently fixed.
* **I did not rebuild anything twice.** The `cq-opt-equivalence-full` target re-entered `cq-opt` and
  `CQPass` as dependencies but relinked nothing: the post-sweep hashes are identical to the
  post-build ones (§2).

---

## §9 ONE FINDING, and it is about the SESSION, not the compiler — the checkout was written while the gates ran

My brief and `PROTOCOL.md` both promise **"no other agent is running"** while the closing agent
rebuilds and gates the primary. That was **not true**. `git status --porcelain` at 14:57 (§0) showed
exactly one untracked path; at 15:13, after my last probe, it showed:

```
 M CLAUDE.md
 M ROADMAP.md
 M docs/labreport/sessions.tex
 M docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md
?? docs/labreport/figures/005/
?? docs/labreport/sessions/005-2026-09-13-cascade.tex
?? …/CLOSING_MEASUREMENTS.md   ?? …/GATES.md   ?? …/owner_file_final.trace   [mine]
?? …/NEXT_SESSION_PROMPT.md                                                  [pre-existing]
```

with mtimes **14:59:44 → 15:03:17** — i.e. inside the window of my full `ctest` run (started ~14:58:20,
finished ~15:05). The session's docs pass was running concurrently. (Its CLAUDE.md edit already
carries the nine counts from this file, so it is the intended docs agent, not an unknown writer.)

**Why this does NOT invalidate anything above, stated as a measurement and not as a reassurance:**

* Every path it touched is documentation: `git status --porcelain | grep -v '^??'` filtered to
  non-`docs/`, non-`CLAUDE.md`, non-`ROADMAP.md` paths is **empty**. `git diff --stat` = 4 files,
  275 insertions, 6 deletions, **none under `ir-pass/`, `include/`, `runtime/`, `tests/`, `tools/`**.
  No source, no fixture, no golden, no harness file moved, so no gate's *input* moved.
* **No gate reads those documents at run time.** Every `grep`-match for `CLAUDE.md` / `ROADMAP.md`
  under `tools/` and `tests/` is a comment or a docstring, and
  `grep -rnE "open\([^)]*(CLAUDE|ROADMAP)" tools tests` is **empty**. The lab report is explicitly
  not a ctest gate (CLAUDE.md: "TeX is not a suite dependency").
* **Nothing relinked a binary under my measurements**: the primary's two hashes are identical before
  and after the full suite, the equivalence sweep and all eight probe runs (§2). The hazard the rule
  exists for — bd `never-relink-or-pkill-under-measurement`, where a rebuild in flight turns a gate
  into `FileNotFoundError … /build/ir-pass/cq-opt` and trains you to discount a real red — did not
  occur, and there was no `***Failed` of any kind (§3).

**But the rule was still broken, and the reason to write it down is that the next time the concurrent
writer may not be docs-only.** A parallel agent that had touched `tools/`, a golden or a fixture
between 14:58 and 15:05 would have produced a suite result that is a fact about **no single tree** —
and it would have been green, because a mid-run edit to an already-executed test is invisible.
Concurrency causes false FAILURES, never false passes, *only* when the tree is held still; a mutating
tree defeats that guarantee in the other direction. The cheap fix is the one this session already
uses for binaries: the closing agent should re-run `git status --porcelain` and `git diff --stat`
**after** the full suite and record them — which is what produced this finding — and the orchestrator
should hold the docs pass until the closing agent reports, or let the docs pass run first.

⚠ **For the docs pass reading this file:** the nine counts, the full-suite line, the equivalence line
and the owner's-file line above are the measured source. Nothing in this record was copied from
`MERGE_M_1.md`; where I cite it (§8) I say so and I name the hash that makes the citation legitimate.
