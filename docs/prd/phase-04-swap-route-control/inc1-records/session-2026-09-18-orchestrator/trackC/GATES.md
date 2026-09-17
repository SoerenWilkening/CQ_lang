# Track C — GATES, hash-keyed

**A gate result is a fact about a BINARY.** Every line below is keyed to the
binary it ran against, re-hashed from disk at the time of the run. Track C's
change is **pure Python in `tools/`** — the pass source is untouched — so the
binary hash is a statement about *what the subjects were lowered with*, not about
what was tested.

```
$ shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
96d74fe6008133b843cf5fc5f9ab2f3f96fb4f7986f905676044ce39e676a4bb  cq-opt
f9acb293a76af15a09a65b7f8c7ff69ef525849da48e5a897dc330e22ca77a74  libCQPass.so
```

Both byte-identical to the gate worktree's (`agent-ac2acfdde3461becc`), as
required — same sources, built once at `-j2` in this worktree.

CHECKER ORACLE for every before/after column: `git show 10e95a52:tools/free_pairing_check.py`.

---

## The ONE ctest gate this track owns

Announced `IN-FLIGHT` in the shared `GATES_INFLIGHT.md` (main checkout) before
running, marked `DONE` with the result after.

```
cited: 96d74fe6008133b8
DONE | ctest --test-dir build -R '^e2e-free-pairing-selftest$' --output-on-failure
     | 1/1 Test #294: e2e-free-pairing-selftest ........   Passed    1.55 sec
     | 100% tests passed, 0 tests failed out of 1
     | Total Test time (real) = 1.63 sec
```

Selftest summary line at that run, **re-run, not copied**:

```
free_pairing_check_test: 32 positive fixture(s), 2 free-order pair(s),
  1 cost bound(s), 77 named mutant(s), 10 memory mutant(s)/refusal(s),
  5 Case-A negative(s), 19 census case(s), 18 T4 loop-exit case(s),
  329 proof-targeted mutant(s) (4 exempt by rule), 0 failure(s)
```

Deltas against the pre-change file: positives **30 → 32**, T4 cases **0 → 18**,
proof-targeted sweep **315 → 329**. Every other count is unchanged, which is the
non-churn statement.

⚠ Re-run once more after the two header-docstring corrections landed (the
obligation list and the STREAMS/CFG SCOPE paragraph): **Passed 1.57 sec, 0
failures** — the numbers above are from that final run.

---

## What this track deliberately did NOT run, and why

**Rule 19: report only what you ran.** The pass source is untouched, so no
compiler layer can witness this change.

| layer | run? | why |
|---|---|---|
| `ctest -R '^e2e-free-pairing-selftest$'` | **YES** | the only layer that can witness a checker change |
| `ir-pass-lit` | no | `ir-pass/test/*.ll` does not invoke this checker; `git diff` over `ir-pass/` is EMPTY |
| `ctest -R '^e2e-slice-'` | no | not this track's gate. The four `slice_loop_break*` verdicts were measured **directly on their lowered IR** instead (below) |
| full `ctest -j6` | no | no code, fixture, golden or harness change outside `tools/free_pairing_check*.py` |
| `e2e-loop-twin-matrix` | no | `tools/loop_twin_matrix*` is Track V's exclusively (R14). This track regenerated cell SOURCES read-only via `sources()` and never invoked the matrix |

---

## Measurements (not ctest gates, but the evidence the rule rests on)

All lowered on `96d74fe6008133b8`; ORACLE checker `10e95a52` vs SUBJECT.

### G-C1 — the reproduction set, before → after

18 modules, every one **STRICT exit 0** after:

```
cited: 96d74fe6008133b8 (lowering) / 10e95a52 (oracle checker)
slice_loop_hoisted_chain_exit_discharge  1 verified, 0 violation(s), 3 unproven -> 4, 0, 0
  …_unrolled (twin)                      5, 0, 0 -> 5, 0, 0   UNMOVED
trackT2/probes/a1_apost                  1, 0, 3 -> 4, 0, 0
trackT2/probes/a1_apost_un               5, 0, 0 -> 5, 0, 0   UNMOVED
m_none_oder_none_none_none        (1m5p) 2, 0, 6 -> 8, 0, 0
m_none_oder_none_none_addpost     (1m5p) 1, 0, 3 -> 4, 0, 0
m_none_oder_none_none_rypost      (1m5p) 1, 0, 3 -> 4, 0, 0
m_none_oder_none_none_rypre       (1m5p) 1, 0, 3 -> 4, 0, 0
m_none_oder_none_none_rzpost .void(1m5p) 1, 0, 3 -> 4, 0, 0
m_none_oder_none_rpostmark_none   (1m5p) 1, 0, 3 -> 4, 0, 0
  (their five .unrolled twins)           5, 0, 0 -> 5, 0, 0   UNMOVED
m_none_der_none .void                    2, 0, 6 -> 8, 0, 0
m_none_range_none .void                  2, 0, 2 -> 4, 0, 0
m_none_rder_none_none_rypost             1, 0, 3 -> 4, 0, 0
```

The two ORACLE rows for `m_none_der_none` and `m_none_range_none` match the
gate's `MATRIX_ADJUDICATION.md` per-cell census table character for character.

⚠ `tools/loop_twin_matrix.py`'s `sources()` defaults `surface="register"`; the
matrix runs the **void** surface. On the register surface the `rz`/`der`/`range`
cells emit the two-argument `cq_phi(r, θ)` spelling, a hard compile error in
today's `CQ.h`. `.void` rows were regenerated accordingly — a fact about the
regeneration recipe, not about the cells.

### G-C2 — the three proofs are EXACTLY the gate's three

```
cited: 96d74fe6008133b8
$ python3 tools/free_pairing_check.py --explain <rolled.s2.ll>
OK @slice line 21 [%h_intr] via T4-loop-exit-discharge (witness lines 16,20)
OK @slice line 23 [%h_op]   via T4-loop-exit-discharge (witness lines 15,22)
OK @slice line 25 [%h_cast] via T4-loop-exit-discharge (witness lines 14,24)
OK @slice line 41 [%h_cmp]  via T1-unc-reversal        (witness lines 36,37,39,40)
… 4 cqrt_free site(s): 4 verified, 0 violation(s), 0 unproven
```

line 14 `%h_cast = … @cq_template_sitofp_i32_to_f64`, line 15 `%h_op = …
@cq_template_fadd_f64_hl`, line 16 `%h_intr = … @cq_template_sqrt_f64` — the
gate's `%h_intr`/sqrt, `%h_op`/fadd, `%h_cast`/sitofp, and nothing else. The
per-trip flag `%h_cmp` is still discharged by the ordinary (T1) rule.

### G-C3 — the dtzb rails are UNMOVED (the negative that matters)

Verdict **and** UNPROVEN-class breakdown compared, not just exit codes:

```
cited: 96d74fe6008133b8 / oracle 10e95a52
slice_loop_break            12 verified, 0 violation(s), 4 unproven | 2 A-not-reducible  2 U1-cross-stream  -> IDENTICAL
slice_loop_break_qq         10, 0, 4                               | 2 + 2              -> IDENTICAL
slice_loop_break_qq_derived 10, 0, 4                               | 2 + 2              -> IDENTICAL
slice_loop_break_qq_i64     10, 0, 4                               | 2 + 2              -> IDENTICAL
```

(T4) does not prove the dtzb whole-loop reverse-play; their `--allow-unproven`
still means what it meant.

### G-C4 — the ARM-KILL MATRIX, MISSED 1 of 9

Each conjunct deleted individually from the source, committed selftest re-run:

```
cited: source-level mutation of tools/free_pairing_check.py; no binary involved
T4a-not-a-template-mint            RED  1   t4-alloc-rail-cross-stream-bracket
T4b-undef-forward-operand          RED  1   t4-undef-forward-operand
T4b-unc-operands-match             RED  1   t4-adjoint-with-a-different-literal
T4b-unc-names-this-rail            *** GREEN — ARM SURVIVED ***
T4c-single-write-in-the-function   RED  4   write-in-loop / measured / rotated / two-exit-blocks
T4d-exactly-one-free               RED  1   t4-one-reversal-two-frees
T4f-mint-stream-acyclic            RED  1   t4-mint-inside-the-loop
T4f-free-stream-acyclic            RED  1   t4-k1-reversal-and-free-inside-the-loop
T4g-forward-operands-held-still    RED  2   t4-forward-operand-moved-inside-the-loop
                                           t4-non-lifo-discharge-order (a REAL miscompile: FIFO
                                           instead of LIFO discharge, so the middle rail's
                                           reversal recomputes from an already-zeroed operand)
```

**MISSED 1 of 9.** The survivor restates the key it searches (`r.writes` is keyed
on the `_unc` write slot, which is 0), so no input distinguishes the two
versions. Kept with a retirement trigger in the source; see `IMPL_C.md` §4.

⚠ **Instrument lesson, recorded rather than tidied away.** The first arm-kill run
mutated `tools/free_pairing_check.py` nine times **while a corpus verdict sweep
was reading the same file**. Those sweep results were discarded and the sweep
restarted after the source was final. Same class as *"never relink a binary under
a running measurement"*, one layer down.

### G-C5 — corpus verdict diff, **PARTIAL, recorded as an ABSENCE**

```
cited: 96d74fe6008133b8 / oracle 10e95a52
IN PROGRESS AT HAND-OFF: 231 of ~386 tests/e2e/*.c lowered modules compared,
full finding list (not exit codes), 0 MOVED.
```

This is the measurement that bears on **false positives** — the expensive
direction for a gate — and it is **incomplete**. Do not quote it as a clean
sweep; quote it as *"231 modules, 0 moved, the rest not measured"*. The runner is
`scratchpad/corpus.sh`; throughput ~35 modules/min under this session's load.

---

## Commit

```
branch freepair-loop-exit-discharge (from gate tip 10e95a52)
tip    43039a28
files  tools/free_pairing_check.py (+390), tools/free_pairing_check_test.py (+416)
       2 files changed, 798 insertions(+), 8 deletions(-)
```

Nothing else in the working tree. No push (branch is for the merge agent).
