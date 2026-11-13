# musl libc sweep on the flat memory model (2026-11-08)

Branch `flat-memory` at 8c3b8d5, CQ_spec 4d08ffa, LLVM 19.1.7, K = 4. Per-row results: [`libc_results.tsv`](libc_results.tsv).
A row is one libc function, or one function@mask when the mask names which inputs are quantum. The check is `cqcheck user --light` (16 samples): a smoke test, not a proof, and once it hid a miscompile.

## Update 2026-11-12: 807 PASS, 6 PASS (STRUCTURE ONLY), 0 FAIL of 813

`libc_results.tsv` now holds the state at `flat-memory` a56e6b09 (CQ_spec dfec094), after the owner rulings of 2026-11-11 and 2026-11-12. Everything below this section is history.

| of 813 | 6e4b744c | a56e6b09 |
|---|---|---|
| PASS | 813 | **807** |
| PASS (STRUCTURE ONLY) | – | **6** |
| FAIL | 0 | 0 |

The three numbers are never added. PASS (STRUCTURE ONLY) means no sample was compared with the C program and the lowered run alone shows no violation, leak or dirty free (CR §6, owner 2026-11-12).

**The six structure-only rows.**
- fegetenv, feholdexcept, fegetexceptflag@0, fegetexceptflag@01: the host fenv call writes a QUANTUM cell of the object, rule 16's stated deviation, so every sample is excluded under Q2 (rule 23 "Environment objects").
- fwide, fopen: every sample reads the result rail of a deferred host call (ruling cq-dbtpi).

**What is checked on an excluded sample, and what is not.** Checked: our-side violations, known-basis frees, uncomputation, the leak rule. Not checked: everything that needs the C reference (returns, measured values, memory, host output, the tape against C) and the measurement-site rule, which §6 defines against the C run's path. Three allowances apply to excluded samples only (owner 2026-11-12):
- any i32 holding exception bits only is accepted as the fenv flags rail;
- the leak rule is skipped when our run ends in a host exit with no abort flag set;
- "structure varies with quantum inputs, nothing measured" is skipped.

The verdict was made to fail on purpose: an all-excluded program with a planted dirty free, and one with a planted leak, both come out FAIL (`tests/usercheck`, `dall_dirty_free` and `dall_leak`).

**Seven PASS rows compare only part of their 16 samples** (the rest read a deferred result rail and are structure-checked): clock 9, fclose 6, freopen 10, ftell 9, malloc 9, setbuf 7, tmpfile 9.

**Rows that compared nothing before.** At 6e4b744c, 58 of the 813 PASS rows compared zero samples and 24 compared only some; no guard existed. Now no row with zero compared samples is shown as PASS. The eight printf rows compare 16 of 16: an output call's result is computed in the circuit (owner 2026-11-12).

**Q2 exclusion, measured.** Of 133 candidate rows (a bodiless callee handed a pointer), 92 were measured and none excluded a sample; the four fenv rows above are the only rows Q2 excludes.

**How it was made.**
- All 778 non-output, non-heavy rows were swept once on b29a1c12, and the 18 output rows and `abs` singly. 22 rows did not PASS (19 FAIL, 3 killed by a full disk); all were fixed afterwards.
- On 6213d213 every one of the 797 non-heavy rows was lowered again. 589 rows have byte-identical lowering and use no name whose checker treatment changed: they keep the sweep's PASS (`source` b29a1c12). The other 208 were re-checked.
- The 16 heavy rows ran singly on 6213d213 (120 s per sample, 2400 s, 7 GB or 5 GB cap): all PASS, 16 of 16 compared.
- The six structure-only rows and the seven partial rows were run again on a56e6b09, after the excluded-input rule changed.
- The check is still the light one (16 samples from one classical group). The strftime and wcsftime rows still run with `CQ_K(__strftime_fmt_1, 1)`.
- stdin is one finite stream with the same bytes on both sides (Q5); the bundle omits every public function that reads or writes a FILE it did not create (Q6).

**Selftest.** Run 1 (a56e6b09, 2 jobs): all 42 mutants rejected, all 26 controls passed, 138 of 213 empty-output checks passed, then killed by its 6144 MB memory cap (the parent kept every verdict; fixed in c4e97964). Run 2 (4f553a03, CQ_spec 5a055f9, 2 jobs, after the checker changes for cq-743m, cq-p9pty and cq-025xt): all 42 mutants rejected, all 26 controls passed, all 213 empty-output checks passed, none failing. The process had not exited when the 2 hour limit killed it, so it printed no final acceptance line; what it was doing after the last check is not known (cq-p9pty stays open).

**Not done in this round.** The pass work for Q4, Q7 and Q10; `%n` on the lowered side (cq-jp8qu).

## Update 2026-11-11: 813 of 813 comparable rows PASS

`libc_results.tsv` now holds the state at `flat-memory` 6e4b744c (CQ_spec 96c7bc5). The sections below describe 8c3b8d5 and are kept as history.

| of 813 | 8c3b8d5 | 6e4b744c |
|---|---|---|
| PASS | 774 | **813** |
| FAIL | 8 | 0 |
| ERROR | 4 | 0 |
| DEFERRED | 27 | 0 |

How it was made. All 813 rows were swept once on 834d317c in three shards, except 16 heavy rows that were run singly before it. 24 rows whose sweep chunk was killed at 800 s were rerun singly on the same build. Seven rows were rerun on 6e4b744c after their fixes. The `source` column names the commit of each row's verdict.

What to keep in mind when reading the PASS column:
- The check is still the light one (16 samples from one classical group).
- The 16 heavy rows (strftime and wcsftime at three masks, asctime, swprintf and vswprintf at three masks, swscanf, vswscanf, vsnprintf@0) ran with 120 s of CPU per sample instead of 30 s (owner 2026-11-10), 2400 s for the check and a 7 GB cap. The 24 single reruns used the same 120 s allowance.
- The six strftime and wcsftime rows ran with `CQ_K(__strftime_fmt_1, 1)` in the caller, so the pass and the C oracle both cut that recursion at 1 (owner ruling cq-1dds4).
- Eight rows compare nothing: printf, fprintf, vprintf, vfprintf, wprintf, fwprintf, vwprintf, vfwprintf. Every sample is excluded as rule 16's stated deviation, so their PASS says only that the row builds, lowers and runs.
- The scanf family reads an empty input on both sides; CR does not define stdin under the checker.
- The checker changed heavily since its last complete selftest. On the state just before the stream fixes all 42 mutants were rejected and 28 controls passed; 181 of the 213 empty-output checks had not been run when this was written.

What changed the verdicts: rule 8 inside K-loop trips (cq-jws5r), stream calls by name as host calls on both sides (cq-pt57w, cq-xkmrm, cq-tgl3i, cq-xdscs), the evaluator and its kept lists (about 10 times faster per runtime call, cq-v0u99), lowering time (cq-g3h1i, cq-4tkb4), measurement sites identified per register and per classical group (cq-v8cn7, cq-1ye9c), and a carried switch case atom's type (cq-7jd1z).

## Numbers at 8c3b8d5 (813 comparable rows)

There are 829 rows. The 16 SKIP rows can get no verdict whatever the pass does (listed below), so they are left out of the comparison; they are the same 16 before and after.

| of 813 | before (old memory model, main) | after (8c3b8d5) |
|---|---|---|
| PASS | 426 (52.4%) | **774 (95.2%)** |
| FAIL | 74 | 8 |
| ICE (internal error) | 285 | 0 |
| ERROR | 28 | 4 |
| DEFERRED (no verdict yet) | – | 27 |

The final plugin lowers all 813 non-SKIP rows with no internal error and no timeout (1500 s per row).

How the after column was made: all 829 rows were swept once on the new model. Then 230 rows were re-checked on 8c3b8d5: every row without a PASS, every PASS row whose lowering changed (116), and 10 PASS rows whose earlier lowering ran out of time and so had no hash to compare. **The other 583 PASS rows keep the older checker's verdict:** their lowering on 8c3b8d5 is byte-identical to the lowering that passed. No row went from PASS to anything else.

## Rows without a PASS

**Deferred batch (2026-11-09, checker at 33f4804 with exact clone replay).** The 40 rows deferred above ran two at a time with a 7 GB footprint cap per row, 2400 s for the check stage and 300 s per sample.
- PASS, 4 rows: snprintf@0, sprintf@0, vsnprintf@0, vsprintf@0.
- FAIL, 8 rows (cq-usir7): snprintf, sprintf, vsnprintf and vsprintf at masks @1 and @01. Our side leaves 5 rails live at exit (for example i64 = 0x7fffffff and an i1), which CR §6 item 1 calls a leak. These rows never had a verdict before, so this is a first finding, not a regression.
- ERROR, 1 row: ctime, no sample inside the C program's domain, like localtime and mktime.
- DEFERRED, 27 rows, still no verdict: 26 hit the 7 GB footprint cap (printf, fprintf, vprintf, vfprintf, the wprintf family of 10 rows, strftime@0/1/01, wcsftime@0/1/01 and the 6 wscanf rows), and asctime ran past 2400 s.

**ERROR, 4 rows** (ctime above, and:)
- localtime and mktime: no sample is inside the C program's domain. This is correct, not a defect.
- setvbuf: its one sample is outside the C domain. This is probably the oracle; it is unconfirmed.

**SKIP, 16 rows: no verdict by design.**
- Does not return (exit-like), 5 rows: _Exit, quick_exit, abort, exit and thrd_exit.
- No definition in the IR build (asm only, or outside the swept directories), 10 rows: aligned_alloc@0/1/01, longjmp, setjmp, system, thrd_current, thrd_detach, thrd_equal and tss_get. aligned_alloc should have a body and needs a follow-up.
- No quantum input and no observable result, 1 row: thrd_yield.

## Deviations and caveats

- **K-loops:** loops with a quantum exit are emitted as K copies (cq-9kcq). Rule 14 asks otherwise; K stays 4 and this is a recorded deviation.
- **fmal:** the fmal rows reach `llvm.fma.f80`, not the lowered `@fmal` body, so their PASS does not exercise it (cq-1vnp2). Other math rows may share this.
- **Measurement identity:** the checker identifies a measurement by its call site (cq-47f8h). This is weak when one site measures values of different shape.
- **Rule 18:** "program paths" is read as the paths of the lowered program.

## Checks

- **Combined example run:** the checker has changed since the last combined run over the CQ_spec examples. That run was at 3e5a052: 211 ok, 117 UNCOVERED, and 175 fail only against the C oracle. It moves to the later batch, together with `tests/determinism` and the 40 deferred rows.
- **Self-test on 8c3b8d5's checker:** passed. 39/39 mutants were rejected, 213/213 empty outputs were rejected and 23/23 controls are green. It needed `HEAVY_MAX_MB=10240` with two jobs: at 6 GB with four jobs the process tree grew past its cap.

## Spec issues

One entry is open in SPEC_ISSUES.md: §1.4, rule 2, 211, "`_t` measures the argument rail itself". The entries this branch added (95, 73, 114, 164) are settled by CQ_spec 4d08ffa and were pruned in 018f2d2.

## Open correctness beads

After the 2026-11-07 triage, 195 beads are open. 253 were closed as outdated (old memory model), already fixed, or not about correctness; each carries the label `triage-2026-11-07` and a reason. A re-check at full sampling confirmed these live:
- cq-wyu4: wrong circuit; a direct `cq_theta` in a classical loop gives `unc_after_nondiagonal` and a dirty free.
- cq-2p9g: internal error, cyclic uncompute through rule 6.

Other open beads reported live, but not re-checked at full sampling:
- cq-qasj: rule 6 dead-after check ignores lane and field aliases.
- cq-qzj6, cq-nyf1, cq-8qs3j, cq-f725, cq-09a5, cq-4ka4, cq-m5f7 and cq-ejne: internal errors or crashes.
- cq-v1fu and cq-8amx: wrong output.
- cq-4yzy: verifier failure.
- cq-v2ad7: a tail entered by a quantum skip and a classical edge.

Checker beads that could give a wrong verdict:
- cq-jqjf, cq-4df2, cq-743m and cq-xidq: false accepts.
- cq-vv8d and cq-dh3d: oracle cache keys.
- cq-xgh5: false FAIL from the matching budget.
- cq-rcorc: the per-sample limit.
- cq-rjagm: the trip cap in `test_terminations`; options are with the owner.
