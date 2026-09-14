# Track T — GATES.md (bd `uq96`, the `_Bool` axis for `e2e-loop-twin-matrix`)

Format (PROTOCOL.md): `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <date time>`

**Binary identity.** Track T changes NO pass source, so its build must reproduce the session ORACLE.
Measured after `cmake --build build -j8` in `/Users/sorenwilkening/Desktop/CQ_twinbool`:

```
$ shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  build/ir-pass/cq-opt
f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d  build/ir-pass/libCQPass.so
```

Both are **BIT-IDENTICAL** to the ORACLE recorded in `$SES/PROTOCOL.md`
(`f7b65d8c…`/`f9e898ba…`, built from 59ac5b7). So every verdict below is a fact about the
ORACLE binary, and a later track may cite it as such.

⚠ Box load during this session was extreme (`uptime` load average **153** at 10:44, six agents
building in parallel). Wall-clock figures below are NOT comparable to the ~180–400 s
`e2e-loop-twin-matrix` band `CLAUDE.md` quotes for a quiet box, and are recorded only so the next
reader knows why.

## Gate lines

```
build (cmake -S . -B build -DLLVM_DIR=... -DCMAKE_BUILD_TYPE=Release; cmake --build build -j8)
                               | f7b65d8ccd7bc472 | BUILD_OK; cq-opt AND libCQPass.so BIT-IDENTICAL to the ORACLE | Track T impl | 2026-09-14 10:37
probes/source_identity.py (OLD vs NEW generator, all 288 committed cells x 2 surfaces x 2 sides)
                               | f7b65d8ccd7bc472 | OLD cells 288  NEW cells 328  added 40; PASS: all 288 OLD cells BYTE-IDENTICAL; sha256 over the 1152 old-cell texts 8b54c28e1525329b4b655bacc43b94e0 | Track T impl | 2026-09-14 11:05
clang -fsyntax-only -Wall -Wextra over the 40 new cells x 2 sides (probes/syncheck.py)
                               | f7b65d8ccd7bc472 | new bool cells: 40; compile failures: 0; 0 warnings other than -Wunused-parameter | Track T impl | 2026-09-14 11:06
ctest -R '^e2e-loop-twin-quarantine-selftest$'
                               | f7b65d8ccd7bc472 | 1/1 Test #295 Passed 1.92 sec; 100% tests passed, 0 tests failed out of 1 | Track T impl | 2026-09-14 10:42
loop_twin_matrix.py --out (MEASUREMENT run, widened generator, committed table untouched)
                               | f7b65d8ccd7bc472 | 326 cells — 146 ACCEPT-IDENTICAL, 73 DECLINE, 107 other; 29 quarantined (pinned signatures), 2 boundary controls; TRACE-DIVERGENCE 29 (== the 29 quarantined, so ZERO new divergences); FAILED (38): all 38 are `NEW CELL, not in the expected table` — i.e. every pre-existing cell matched its committed verdict; controls q_noregion ACCEPT-IDENTICAL / q_armoncond TRACE-DIVERGENCE at its pinned signature; 19:07 wall | Track T impl | 2026-09-14 11:00
probes/probe_cells.log (4 compound-condition spellings + the bare-rail phase cell, by hand)
                               | f7b65d8ccd7bc472 | bphi ACCEPT-IDENTICAL 8 lines; `b && a==off` DECLINE-BOTH nested control flow; `b && a==5` UNROLLED-ONLY; `b & (a==off)` ACCEPT-IDENTICAL 22 lines | Track T impl | 2026-09-14 11:12
loop_twin_matrix.py --regenerate (DELIBERATE, once, to write the 40 new rows — never to turn a red green)
                               | f7b65d8ccd7bc472 | regenerated tools/loop_twin_matrix.expected.txt (299 cells; 29 quarantined and omitted); no refusal printed, i.e. no un-quarantined divergence and no moved boundary control; 19:12 wall | Track T impl | 2026-09-14 11:19
ctest -R '^e2e-loop-twin-quarantine-selftest$'  (re-run after the final generator edits)
                               | f7b65d8ccd7bc472 | 1/1 Test #295 Passed 0.75 sec; 100% tests passed, 0 tests failed out of 1 | Track T impl | 2026-09-14 11:22
```
```
probes/probe_wx8g.log — the FLAT stream for the two bd-wx8g subject shapes, so the 9 UNROLLED-ONLY rows have a concrete target
                               | f7b65d8ccd7bc472 | m_none_bry_none_none_binv: rolled exit=1 `control flow inside a loop body under quantum control`, UNROLLED exit=0 and emits `cqrt_ry_i32_controlled(h2, h1, 0.9)` TWICE with h2 = the bare `_Bool` rail as the CONTROL | Track T impl | 2026-09-14 11:52
ctest -R '^e2e-loop-twin-matrix$'  (THE GATE, on the widened 328-cell matrix)
                               | f7b65d8ccd7bc472 | 1/1 Test #318: e2e-loop-twin-matrix ... Passed 998.03 sec; 100% tests passed, 0 tests failed out of 1 | Track T impl | 2026-09-14 11:48
ctest -R '^e2e-loop-twin-quarantine-selftest$'  (FINAL, after the B_SECOND refactor)
                               | f7b65d8ccd7bc472 | 1/1 Test #295 Passed 0.67 sec; 100% tests passed, 0 tests failed out of 1 | Track T impl | 2026-09-14 11:53
```

## Gates NOT run, and why

Per BRIEF_T.md §4 and `PROTOCOL.md`'s matrix, Track T owns exactly the two `ctest` entries above.
**Not run, deliberately:** the full `ctest -j6`, `^e2e-`, `ir-pass-lit`, `cq-opt-equivalence*`, the
corpus sweep, the injection matrix. Track T touches no pass source, no fixture, no decline string and
no slice, so no other layer can witness its change — and the combined group gate (Track T + Track W)
is the merge-and-gate agent's, not mine.

⚠ **Every line above is a fact about the ORACLE binary `f7b65d8ccd7bc472…`**, because this branch's
build reproduced it bit-for-bit. A later track may cite them as such.

## SECOND PASS — the 10 ITERATION-LOCAL cells (bd `wx8g` clause (c)), 338 cells

⚠ Binary **re-verified, unchanged**: nothing was rebuilt (no pass source touched), and
`shasum -a 256 build/ir-pass/{cq-opt,libCQPass.so}` is still
`f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc` /
`f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d` — the ORACLE. Box load had
dropped to ~55–90 by the final gate, which is why its wall clock is half the first pass's; the two
numbers are not comparable and neither is comparable to a quiet box.

```
probes/source_identity.py (first-pass commit c12a2afe vs NOW)
                               | f7b65d8ccd7bc472 | OLD cells 328  NEW cells 338  added 10; PASS: all 328 OLD cells BYTE-IDENTICAL; sha256 over the 1312 old-cell texts 4c907fd93eff3b6ef4aaa1ac7e67183b | Track T impl | 2026-09-14 12:14
clang -fsyntax-only -Wall -Wextra over all 50 `_Bool` cells x 2 sides (probes/syncheck.py)
                               | f7b65d8ccd7bc472 | new bool cells: 50; compile failures: 0; 0 warnings other than -Wunused-parameter | Track T impl | 2026-09-14 12:17
loop_twin_matrix.py --regenerate (DELIBERATE, once, to write the 10 B7 rows)
                               | f7b65d8ccd7bc472 | regenerated tools/loop_twin_matrix.expected.txt (309 cells; 29 quarantined and omitted); no refusal printed, i.e. no un-quarantined divergence and no moved boundary control; 7:15 wall | Track T impl | 2026-09-14 12:26
HEADER-SURVIVAL CHECK (the §6 EXPECTED_HEADER fix, exercised by the SECOND regeneration)
                               | f7b65d8ccd7bc472 | header lines: main(pre-uq96) 222 | c12a2afe 283 | now 316; MISSING vs c12a2afe 0; MISSING vs pre-uq96 main 0 | Track T impl | 2026-09-14 12:28
ctest -R '^e2e-loop-twin-quarantine-selftest$'
                               | f7b65d8ccd7bc472 | 100% tests passed, 0 tests failed out of 1 (0.98 s) | Track T impl | 2026-09-14 12:30
ctest -R '^e2e-loop-twin-matrix$'  (THE GATE, on the final 338-cell matrix)
                               | f7b65d8ccd7bc472 | 1/1 Test #318: e2e-loop-twin-matrix ... Passed 464.29 sec; 100% tests passed, 0 tests failed out of 1 | Track T impl | 2026-09-14 12:38
```

**NOT run in the second pass either**, and one of them by explicit instruction: the full `ctest -j6`,
`^e2e-`, `ir-pass-lit`, `cq-opt-equivalence*`, and **the corpus sweep** (one per session, owned by the
merge gate).
