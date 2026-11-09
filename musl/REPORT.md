# musl libc sweep on the flat memory model (2026-11-08)

Branch `flat-memory` at 8c3b8d5, CQ_spec 4d08ffa, LLVM 19.1.7, K = 4. Per-row results: [`libc_results.tsv`](libc_results.tsv).
A row is one libc function, or one function@mask when the mask names which inputs are quantum. The check is `cqcheck user --light` (16 samples): a smoke test, not a proof, and once it hid a miscompile.

## Numbers (813 comparable rows)

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
