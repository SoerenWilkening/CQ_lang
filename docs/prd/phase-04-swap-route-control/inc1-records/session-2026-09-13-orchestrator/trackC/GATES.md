# Track C — GATES.md (hash-keyed gate ledger, PROTOCOL.md §"non-redundancy")

`<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`

Binaries in play:

| role | `cq-opt` sha256 | `libCQPass.so` sha256 | from |
|---|---|---|---|
| ORACLE (read-only) | `fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661` | `40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93` | `/Users/sorenwilkening/Desktop/CQ_lang/build`, e96f89c, both hashes re-verified at session start 2026-09-13, never rebuilt |
| SUBJECT | `c662bd0ca0e7d8a4db70bc8b410521e1ea946098ccce702d0c2c0ed2b2a1761b` | `52d1136c3c7d9049bf0d6de95b84cfe2c3f353a54457b9c30b5c655feb60a510` | `/Users/sorenwilkening/Desktop/CQ_21mg/build`, branch `classical-measure` |

ONE build of the SUBJECT: no pass source was touched after it, so every line below
keys to the same `c662bd0c`.

```
build (cmake --build build -j8, BOTH targets)      | c662bd0ca0e7d8a4 | rc=0, no new warnings (4 pre-existing -Wunused in RegionTreeDetect/TaintPropagation) | impl | 2026-09-13 12:05
lit --filter lowering_reject_measure_undef_operand | c662bd0ca0e7d8a4 | PASS 1/1                                                       | impl | 2026-09-13 12:11
lit --filter lowering_measure_classical_accept     | c662bd0ca0e7d8a4 | PASS 1/1                                                       | impl | 2026-09-13 12:13
lit --filter lowering_measure_classical_mixed_accept | c662bd0ca0e7d8a4 | PASS 1/1                                                     | impl | 2026-09-13 12:16
lit --filter lowering_measure_round2_sixfive_handle | c662bd0ca0e7d8a4 | PASS 1/1                                                      | impl | 2026-09-13 12:18
lit --filter control_measure_classical_bool_owner  | c662bd0ca0e7d8a4 | PASS 1/1                                                       | impl | 2026-09-13 12:20
lit --filter 'measure_classical|measure_round2|measure_undef' | c662bd0ca0e7d8a4 | PASS 6/6 (of 1899 discovered)                       | impl | 2026-09-13 12:28
ctest -R '^e2e-(slice-measure-classical|measure-classical)' | c662bd0ca0e7d8a4 | 4/4 passed, 4.80 s (bool 2.17 / bool-twin 1.36 / twin-identical 0.03 / only 1.21) | impl | 2026-09-13 12:24
injection matrix (probes/inject_C.py, 4 accepts)   | c662bd0ca0e7d8a4 | fixtures=4 mutations=29 MISSED=0 DIRTY=0 n/a=7                  | impl | 2026-09-13 12:28
ctest -R ir-pass-lit                               | c662bd0ca0e7d8a4 | 1/1 Passed, 45.80 s; `lit ir-pass/test` breakdown: 1899 discovered, 1898 Passed, 1 Expectedly Failed, 0 unexpected | impl | 2026-09-13 12:34
corpus sweep ORACLE-vs-SUBJECT (probes/corpusC.sh) | c662bd0ca0e7d8a4 | 3021 rows, 1 MOVER (trackL/probes/t_loop_phase.c, DECLINE->ACCEPT on the 21mg string), 0 ACCEPT->DECLINE, 0 decline-string changes, 0 both-accept md5 differences, 1 pre-existing CLANGERR on both | impl | 2026-09-13 12:33
```

NOT RUN by this row (PROTOCOL.md: they are not the implementer's): full `ctest -j6`,
`ctest -j6 -R '^e2e-'`, `cq-opt-equivalence-full`, the twin matrices, the
duplicate-body fixture scan. The merge-and-gate agent owns the full run;
`cq-opt-equivalence-full` is owed by whoever lands this, because a NEW decline
string was added (`cq_measure_<sfx> operand is an undef/poison literal; a
classical measurement needs a defined value`) — PROTOCOL's "iff a decline string /
analysis site changed" row.

## Landing 1 — merge-and-gate row (2026-09-13, `MERGE_C_1.md`)

⚠ **THE MERGED BINARY HASHES THE SAME AS THE SUBJECT.** `git merge main` was a
fast-forward of docs-only commits; the landing's own source edits (review items
1/2/3/5) are COMMENT-ONLY, and after `cmake -S . -B build … && cmake --build
build -j8` (BOTH targets, from a reconfigure the `tests/e2e/CMakeLists.txt` edit
required) `shasum -a 256 build/ir-pass/cq-opt` is **`c662bd0ca0e7d8a4…`** and
`libCQPass.so` is **`52d1136c3c7d9049…`** — byte-for-byte the implementer's
SUBJECT. That equality is the mechanical proof the edits were comment-only, and
it is why PROTOCOL.md's non-redundancy rule lets the 3021-row corpus sweep above
be CITED rather than re-run (a gate result is a fact about a BINARY). ORACLE
re-hashed before use: `fbbe0820…` / `40e9c7a5…`, matches PROTOCOL.md.

```
git merge main (10fe8b4)                           | c662bd0ca0e7d8a4 | FAST-FORWARD, 0 conflicts, 168 docs-only files, no merge commit | merge | 2026-09-13 13:05
cmake -S . -B build (reconfigure) + build -j8      | c662bd0ca0e7d8a4 | rc=0, hash UNCHANGED (comment-only edits), no new warnings      | merge | 2026-09-13 13:12
lit --filter 'carried_theta_first' (L-0 H-10 pins) | c662bd0ca0e7d8a4 | PASS 2/2 of 1901 discovered, 1.45 s — NO FileCheck edit needed  | merge | 2026-09-13 13:14
ctest -R 'carried-theta-first'                     | c662bd0ca0e7d8a4 | 3/3 passed, 2.27 s (1.15 / 1.07 / 0.02)                         | merge | 2026-09-13 13:15
**full ctest -j6 --output-on-failure**             | c662bd0ca0e7d8a4 | 100% tests passed, 0 tests failed out of 410; Total Test time (real) = 407.77 sec (long pole e2e-loop-twin-matrix 220.61 s) | merge | 2026-09-13 13:23
cq-opt-equivalence-full                            | c662bd0ca0e7d8a4 | cq_opt_equivalence: compared 1901 fixtures, 0 mismatch(es), 92 s | merge | 2026-09-13 13:25
corpus sweep ORACLE-vs-MERGED, DELTA (corpusC_delta.sh) | c662bd0ca0e7d8a4 | 46 rows, 15 movers: 14 DECLINE->ACCEPT all on `operand not recognized`, 1 DECLINE->DECLINE (the new undef string), 0 ACCEPT->DECLINE, 20 both-accept 0 md5 differences, 0 CLANGERR | merge | 2026-09-13 13:27
STRICT stage 2b over all 14 accepting movers       | c662bd0ca0e7d8a4 | 14/14 `0 violation(s), 0 unproven`                               | merge | 2026-09-13 13:29
customers (owner_2026-09-11_2218 / va / owner_file_2026-09-13 / vd) | c662bd0ca0e7d8a4 | 15 lines IDENTICAL to the twin golden · 19 lines IDENTICAL to va.trace · DECLINE `control flow` · DECLINE `state prep seed is proven equal to the condition register` | merge | 2026-09-13 13:31
injection matrix, L-0 pins (probes/inject_L0.py)   | c662bd0ca0e7d8a4 | fixtures=2 mutations=18 MISSED=0 DIRTY=0 n/a=0                   | merge | 2026-09-13 13:36
K-independence re-measure (p2 / p2k1000, no -g)    | c662bd0ca0e7d8a4 | 50 lowered lines at K=3 and at K=1000 (only diff: the trip-count constant); traces 9 / 2003; p2u 42 lines / 9 | merge | 2026-09-13 13:38
duplicate-body fixture scan (sha-256, non-comment) | c662bd0ca0e7d8a4 | 1901 files, 9 same-body groups: 8 pre-existing + 1 NEW and DECLARED (lowering_measure_round2_sixfive_handle.ll ≡ control_classical_call_arm_accept.ll); 0 merge artefacts | merge | 2026-09-13 13:39
```

NOT RUN by this row: the twin matrices as standalone instruments (`e2e-loop-twin-matrix`
IS a gate and ran green inside the full suite); `ctest -R ir-pass-lit` on its own (it ran
inside the full suite); the 3021-row corpus sweep (CITED at the same hash — see above).
