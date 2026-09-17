# GATES — Track V (bd `test_C_libtooling-vsr6`), session 2026-09-18

Worktree `/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abab679cc6af1707e`,
branch `twinmatrix-nested-axis`, off `main` `cff8f7ac`.

**The worktree binary is BIT-IDENTICAL to the session ORACLE**, measured at 11:55 after
`cmake --build build -j2` (BOTH targets), pass source untouched:

```
9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3  build/ir-pass/cq-opt
3e3dc35d471aae6b53067ffc374745f8cd9f148870a1879d971c8bdab831695d  build/ir-pass/libCQPass.so
```

Both equal `PROTOCOL.md`'s ORACLE block character-for-character, so the build is reproducible and
every gate recorded at `9bd01598` anywhere in this session is CITABLE here.

gate | cq-opt | result verbatim | who | when
--- | --- | --- | --- | ---
`cmake -S . -B build … && cmake --build build -j2` (BOTH targets) | 9bd01598 | exit 0; `cq-opt` and `libCQPass.so` sha256 EQUAL to the ORACLE | trackV | 2026-09-17 11:55
`probes/source_identity.py --tools <main>/tools --dump` then `--tools <wt>/tools --check` | 9bd01598 | `718 baseline pair(s), 764 in this run, 46 NEW, 0 MOVED` | trackV | 2026-09-17 11:54
`probes/nest_cells_only.py` (the 23 new cells, `--jobs 4`, through `main()`) | 9bd01598 | 8 ACCEPT-IDENTICAL, 7 UNROLLED-ONLY, 8 TRACE-DIVERGENCE (counted by `uniq -c`, not read); `q_nestinline` measured ACCEPT-IDENTICAL; wall 2:26 at load ~45 | trackV | 2026-09-17 11:59
`probes/nest_diverge_detail.py` (the 8 divergences, full diffs + digests) | 9bd01598 | 8 signatures measured; `probes/nest_divergences_9bd01598.txt` | trackV | 2026-09-17 12:01
`probes/attribution.py` (5 isolations) | 9bd01598 | `single_bitrail` AI 13==13 · `single_bitrail_interfered` AI 14==14 · `inline_noninterfered` AI 35==35 · `inline_iic` TD (2,2,12)/30 both · `single_iic_loop` TD (2,2,8)/20 vs (1,1,7)/17 | trackV | 2026-09-17 12:04
`python3 tools/loop_twin_matrix_quarantine_test.py` | 9bd01598 | `58 case(s), 0 failure(s)` (52 on `main`, measured on both trees) | trackV | 2026-09-17 12:15
`probes/mutants.py` (L10 — made to fail on purpose) | 9bd01598 | `13 applied, 13 CAUGHT, 0 MISSED, 0 NOT-APPLIED` | trackV | 2026-09-17 12:15
`ctest --test-dir build -R '^e2e-loop-twin-quarantine-selftest$'` | 9bd01598 | `1/1 Test #295 … Passed 1.72 sec — 100% tests passed, 0 tests failed out of 1` | trackV | 2026-09-17 12:21
`loop_twin_matrix.py --phi-surface void --jobs 6 --regenerate` (382 cells) | 9bd01598 | PENDING | trackV | —
`ctest --test-dir build -R '^e2e-loop-twin-matrix$'` | 9bd01598 | PENDING | trackV | —

## CITED, not re-run (PROTOCOL §6.1 — same hash ⇒ same result)

* `$THIS/GATES.md`: `n1 / n2 / n3 nested (loopfix probes) | 9bd01598 | rolled DECLINE ×3 (same
  string as s2); twins ACCEPT 42 / 34 / 48 | claude | 2026-09-17 11:05`. This is the disposition
  `IMPL_V.md` §2 checks the GENERATED cells against, and it is why no probe of `n1`/`n2`/`n3`
  themselves was re-run here.
* `$THIS/GATES.md`: `s2_live_derived_region / _un | 9bd01598 | DECLINE 'rolled body leaks a rail
  entangled with a rotated register' / ACCEPT 25`, the source of the diagnostic string the seven
  `UNROLLED-ONLY` rows carry.

## ANNOUNCED IN `$SES/GATES_INFLIGHT.md` BEFORE RUNNING

Every gate above that is longer than a single entry was announced first, and **no matching
`IN-FLIGHT` line existed at hash `9bd01598` for any of them when it started**.

## NOT RUN — and not claimed

* the full `ctest -j6`
* `ctest -R ir-pass-lit`
* `ctest -j6 -R '^e2e-'`
* `cq-opt-equivalence-full` / `cq-opt-equivalence`
* any ORACLE-vs-SUBJECT corpus sweep

None of them can witness a `tools/`-only change whose compiler is byte-identical to `main`'s, and
the PROTOCOL matrix gives all five to the merge-and-gate agent. **A skipped layer is a deferred
cost, not a saved one** (Rule 19).

## ⚠ DISCLOSED DEVIATION — I edited the script under a running measurement

`CLAUDE.md` Rule 19: *never relink a binary under a running measurement*. The Python analogue of
that is editing the module a running matrix is importing, and I did it: while the 382-cell
`--regenerate` was in flight I made three edits to `tools/loop_twin_matrix.py` — `INDEXED_REGION`
derived from the region text with `\bi\b` instead of a `startswith("l2n")` prefix, and two comment
corrections (the "rolled two, twin one" sentence, which is FALSE, and the `l2b` rail's opcode pair).

Why it is very probably harmless, and why "probably" is not good enough on its own:

* the semantic edit is a **proven no-op** — the derived `INDEXED_REGION` set is EQUAL to the prefix
  one over `N_REGION`, checked directly (`set(new) == set(old)` → `True`), and
  `source_identity.py --check` after the edits still reports **`718 baseline pair(s), 764 in this
  run, 46 NEW, 0 MOVED`**, so no generated source moved by a byte;
* `ProcessPoolExecutor` on macOS Python 3.11 SPAWNs its workers, and all six are created when
  `ex.map` submits the 382 tasks — i.e. at run start, minutes before the first edit — so every
  worker in that run holds the pre-edit module, and so does the parent.

**The authoritative check is the one that runs afterwards, not the argument above**: the
`ctest -R '^e2e-loop-twin-matrix$'` line re-measures all 382 cells against the committed table with
the FINAL file, so a table that disagreed with the final module would be a red there. Recorded here
rather than left as an unexplained coincidence if it ever is.

## Load, recorded with every timing (Rule 19)

The box carried other tracks throughout: `uptime` 1-minute load averages measured at 26 (session
open), 73, 127, 44, 88 across this track's runs. Wall-clock figures above are NOT comparable with a
quiet-box figure and are quoted with their load.
