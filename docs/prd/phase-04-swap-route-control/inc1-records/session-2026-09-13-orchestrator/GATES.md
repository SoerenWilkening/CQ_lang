# GATES.md — session 2026-09-13, SESSION LEVEL (the primary `build/` after the three squashes)

`PROTOCOL.md` row format, one line per gate:

```
<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>
```

The four `track*/GATES.md` files record gates on the TRACK worktrees' binaries. **This file records
gates on the PRIMARY checkout's `build/`** (`/Users/sorenwilkening/Desktop/CQ_lang/build`), which was
the frozen ORACLE `fbbe0820ef4b176a` for the whole session and was rebuilt **exactly once**, by the
closing agent, from `main` **59ac5b7** (the third squash).

**The binary identity that makes every track record citable for `main`:**

| | `cq-opt` sha256 | `libCQPass.so` sha256 |
|---|---|---|
| ORACLE (before, e96f89c, 2026-09-11 22:23) | `fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661` | `40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93` |
| **PRIMARY (after, 59ac5b7, 2026-09-13 14:58)** | **`f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`** | **`f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`** |
| Track M merge worktree (`CQ_mphi`, gated tree 54079b6) | `f7b65d8ccd7bc472…` — **the same 64 digits** | `f9e898badfd4207a…` — **the same 64 digits** |

The rebuilt primary is **BIT-IDENTICAL** to the binary `trackM/MERGE_M_1.md` gated. The three squashes
onto `main` therefore reproduce the reviewed-and-gated tree exactly, and every `f7b65d8ccd7bc472` row
in `trackM/GATES.md` is a fact about the binary now on `main`. (Measured, not assumed — §0 of
`CLOSING_MEASUREMENTS.md`. The full suite, the equivalence sweep and all nine counts were re-RUN here
anyway; the corpus/injection/duplicate-body gates were not, and are CITED to Track M rather than
restated.)

## Rows RUN by the closing agent on the NEW primary `f7b65d8ccd7bc472`

| gate | hash | result verbatim | who | when |
|---|---|---|---|---|
| `shasum -a 256 build/ir-pass/cq-opt` BEFORE the rebuild | `fbbe0820ef4b176a` | matches `PROTOCOL.md`'s ORACLE line character-for-character — **nobody rebuilt the oracle during the session** | closing | 2026-09-13 14:57 |
| `cmake -S . -B build -DLLVM_DIR=… -DCMAKE_BUILD_TYPE=Release` (owed: CMakeLists moved in all 3 landings) | — | exit 0, 3.129 s; stage-1 cache key `eb624df8…`; `CQ_LD` re-derived (`build/tests/e2e/cq_link.sh`), no staleness error | closing | 2026-09-13 14:57 |
| `cmake --build build -j8` (**BOTH** targets — never `--target CQPass` alone) | `f7b65d8ccd7bc472` / `f9e898badfd4207a` | exit 0, **52.525 s** wall, 0 errors; **4 warnings, ALL pre-existing** (`RegionTreeDetect.cpp:173/174` `-Wunused-variable`, `TaintPropagation.cpp:255/1988` `-Wunused-parameter`), each emitted once per target; **no new warning** | closing | 2026-09-13 14:58 |
| **full `ctest --test-dir build -j6 --output-on-failure`** (the session's second and last full run; the first was Track M's on the same binary) | `f7b65d8ccd7bc472` | **`100% tests passed, 0 tests failed out of 420`** · `Total Test time (real) = 393.20 sec` · wall `6:33.27` · `grep -c Failed` = **0**, so nothing was re-run serially. `e2e-loop-twin-matrix` Passed **349.47 s** (the long pole, 288 cells, unchanged) · `ir-pass-lit` Passed 54.54 s · `frontend-lit` Passed 8.08 s · `cq-opt-equivalence` (sampled) Passed 19.26 s · `e2e-free-pairing-selftest` Passed 3.87 s · `e2e-loop-twin-quarantine-selftest` Passed 1.10 s · `e2e-census-slice-sync` Passed 0.33 s | closing | 2026-09-13 15:05 |
| `cmake --build build --target cq-opt-equivalence-full` (**OWED** — all three landings moved decline strings / analysis sites) | `f7b65d8ccd7bc472` | **`cq_opt_equivalence: compared 1928 fixtures, 0 mismatch(es)`** — 96.34 s wall, exit 0 (stdout + stderr + exit code, `%cq-opt` vs stock `opt -load-pass-plugin`) | closing | 2026-09-13 15:07 |
| the nine counts, BY COMMAND | `f7b65d8ccd7bc472` | `ls ir-pass/test/*.ll` **1928** · `ls tests/e2e/*.expected.log` **367** · `ctest -N` **420** · `-R '^e2e-'` **410** · `-R '^e2e-slice-'` **365** · `-R twin-identical` **34** · `grep -c '^add_test' tests/e2e/CMakeLists.txt` **410** · `grep -c '^m_'` **259** + `grep -c '^cell '` **29** = **288** (unchanged) · equivalence **1928/0**. **All nine reproduce `MERGE_M_1.md` §6 exactly.** Cross-check: 410 e2e + 10 non-e2e (`ir-pass-lit`, `frontend-lit`, `cq-opt-equivalence`, 7 `runtime_*`) = 420 | closing | 2026-09-13 15:08 |
| **the owner's REAL file** `example/grover/grover_oracle_uncompute.c` (git-excluded), `diff` vs the session snapshot FIRST | `f7b65d8ccd7bc472` | **IDENTICAL to `probes/owner_file_2026-09-13.c`** (`diff` silent, exit 0) — the owner did not edit it again. `show_pipeline.sh` exit 0, stderr 0 bytes. Four-stage pipeline: **ACCEPT, opt exit 0, stderr 0 bytes**, STRICT 2b **`8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`**, **29 trace lines BYTE-IDENTICAL to `tests/e2e/slice_control_cascade_two_bools.expected.log`**; `head -16` byte-identical to `head -16 probes/va.trace`. Trace archived as `owner_file_final.trace` | closing | 2026-09-13 15:10 |
| the seven step-7 probes, full 4-stage pipeline | `f7b65d8ccd7bc472` | `va` **ACCEPT 19** (`6/5, 1 free: 1 verified, 0/0`) = `probes/va.trace` · `vb` **ACCEPT 29** (`8/6, 2 verified, 0/0`) = the owner's trace · `vc` **ACCEPT 29** (`8/6, 2 verified, 0/0`) = the owner's trace · `vd` **DECLINE exit 1** `vd.c:10:14 … state prep seed is proven equal to the condition register` (F2, as scoped) · `trackC/owner_2026-09-11_2218` **ACCEPT 15** (`5/4, 1 verified, 0/0`) = `slice_measure_classical_bool.expected.log` · `trackR/b_A_intb0_boolb1` **ACCEPT 22** (`5/5, 2 verified, 0/0`) = `slice_control_stateprep_bool_under_int_compare_fused.expected.log` · `trackL/a_loop_n3` **DECLINE exit 1** `a_loop_n3.c:10:26 … cq taint escape: tainted value stored to memory` (the array spelling, unchanged — its L8 trigger stands). **Every accept STRICT, `0 violation(s), 0 unproven`, no `--allow-unproven`** | closing | 2026-09-13 15:12 |

## Rows CITED, not re-run (facts about the same 64 hex digits)

| gate | hash | result | source |
|---|---|---|---|
| corpus sweep ORACLE-vs-MERGED, 3113 rows | `f7b65d8ccd7bc472` vs `fbbe0820ef4b176a` | 79 DECLINE→ACCEPT, 10 decline-string moves, **0 ACCEPT→DECLINE, 0 both-accept lowered-IR differences** | `trackM/MERGE_M_1.md` §3 (M-merge, 14:5x) |
| STRICT stage 2b over all 79 accepting movers | `f7b65d8ccd7bc472` | **79/79 `0 violation(s), 0 unproven`** | `trackM/MERGE_M_1.md` §3 |
| decline-side FULL-stderr delta, 1593 rows | `f7b65d8ccd7bc472` vs `fbbe0820ef4b176a` | 92 differ = 89 visible + 3 invisible to the string recipe (all landing 1's `cq_measure_<sfx> operand is an undef/poison literal`, still `DS_Error` exit 1) | `trackM/MERGE_M_1.md` §0 |
| duplicate-body fixture scan | `f7b65d8ccd7bc472` | `files=1928  same-body groups=9` — the 8 pre-existing deliberate pairs + landing 1's declared pair; no merge artefact | `trackM/MERGE_M_1.md` §2 |
| injection (mutation) matrix | `0d3105d0eb9d476a` (**PRE-merge**) | `87 applied / 0 MISSED / 1 N/A` — **a fact about the pre-merge binary, deliberately NOT cited for `f7b65d8c`** | `trackM/GATES.md` |

## NOT run by this agent, and why

* **No third full suite, no second equivalence sweep** — `PROTOCOL.md` allows one full gate per
  landing and this one covers all three landings' code on the squashed tree.
* **No corpus sweep / injection matrix / twin matrix / duplicate-body scan of my own** — merge-and-gate
  row gates, cited above against an identical hash rather than restated as mine.
* **No commit, no push, no bd write, no squash, no edit to any tracked file.** The closing agent wrote
  exactly three files: `CLOSING_MEASUREMENTS.md`, `owner_file_final.trace` and this one.
