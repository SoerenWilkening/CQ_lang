# Track M — gate ledger (`../PROTOCOL.md` §3.1)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`.
**A gate result is a fact about a BINARY, not about a moment.** Read this file before running any
gate; if the hash is unchanged and the gate is recorded, CITE the line instead of re-running it.

A cited line whose hash does not match the binary on disk is a FINDING.

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| per-probe pipeline (stages 1,2,2b,3,4) over `probes/` — 27 probes | `fbbe0820ef4b176a` (ORACLE, `e96f89c`) | 9 ACCEPT (`m03` 23, `m07` 23, `m09` 23, `m11` 28, `m12` 31, `m17` 28, `m18` 29, `m19` 28, `m26` 25 trace lines; every one STRICT stage 2b `0 violation(s), 0 unproven`) / 18 DECLINE with the anchors in `probes/README.md` | M-scope | 2026-09-13 12:4x |

**Not run by this agent, by protocol (the "scoping" column):** any build, `lit`, any `ctest` entry,
`cq-opt-equivalence`, the corpus sweep, the injection matrix, any twin matrix. The ORACLE hash was
verified by `probes/run.sh` before each sweep and matched `PROTOCOL.md`.
| per-probe pipeline (1,2,2b,3,4) over `probes/` + the session `probes/` — 32 modules | `fbbe0820ef4b176a` (impl worktree, UNMODIFIED — byte-identical to the ORACLE) | reproduces `probes/README.md` EXACTLY: 9 ACCEPT (m03 23, m07 23, m09 23, m11 28, m12 31, m17 28, m18 29, m19 28, m26 25; all STRICT 2b `0 violation(s), 0 unproven`) / 18 DECLINE with the recorded strings; va ACCEPT 19; vb/vc = m01; vd/ve as recorded | M-impl | 2026-09-13 14:1x |
| `lit --filter control_swap_accept_select_rail_after_prep` (the T1 pins, written BEFORE any pass edit) | `fbbe0820ef4b176a` | 2/2 PASS | M-impl | 2026-09-13 14:2x |
| per-probe pipeline over `probes/` + session `probes/` | `2fd12991d3e91d10` (SUBJECT: grammar + ladder + gate-2c seed + H-1 + H-7) | 11 DECLINE→ACCEPT (m01/m02/m04/m06/m10/m13/m15 + owner file + vb/vc + U1), 1 decline-string move (m05 → `condition measured before the control route`), 0 ACCEPT→DECLINE; **owner file ACCEPT 29 lines = the T1 prediction 29/29**, STRICT 2b `8 mints / 6 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven`; va unchanged ACCEPT 19 | M-impl | 2026-09-13 14:5x |
| H-1 counterfactual (`Cond = R.Condition` restored, ONE line, nothing else) | `4a8d52d4defc583d` (throwaway, reverted) | m01/m02/m04 ACCEPT→`control flow` exit 1, deterministic over 3 repeat runs ⇒ the emitter was walking the ERASED φ | M-impl | 2026-09-13 14:4x |
| H-6 discriminator on the FROZEN ORACLE (`m15u` = m15 in the rail-leaf spelling, `m15i` = compare spelling, `s04` = the shipped S†) | `fbbe0820ef4b176a` (ORACLE) | `m15u` **ACCEPT 29, 2b clean**; `s04` **ACCEPT 16, 2b clean**; `m15i` DECLINE `condition predates a non-diagonal gate` | M-impl | 2026-09-13 15:0x |
| H-9 control on the FROZEN ORACLE (`h9_ctl` = m17 + `cq_invert` brackets) | `fbbe0820ef4b176a` (ORACLE) | ACCEPT exit 0, STRICT 2b clean, then LINKFAIL `___cq_invert_begin`/`___cq_invert_end` ⇒ m13's new disposition is the PRE-EXISTING Phase-8 state | M-impl | 2026-09-13 15:0x |
| `lit --filter mergephi` (the 7 decline fixtures) | `2fd12991d3e91d10` | 7/7 PASS; `..._measure_before.ll` separately verified RED on the ORACLE `fbbe0820` for the OLD string | M-impl | 2026-09-13 15:1x |
| `ctest -R ir-pass-lit` (ONCE, at hand-off) | `2fd12991d3e91d10` | 1894 PASS / 1 XFAIL / **7 FAILED — ALL a worktree-PATH artefact, 0 regressions**: each carries a bare `NOROUTE-NOT: phi` that matches "phi" inside the module path `.../CQ_mphi/...`. Re-run from a path with no "phi": **7/7 PASS and 7/7 lowered IR byte-identical to the ORACLE**. Effective: 1901 PASS / 1 XFAIL / 0 regressions. Filed in IMPL_M.md §7.5 | M-impl | 2026-09-13 15:2x |
| corpus sweep ORACLE-vs-SUBJECT (ONCE, at hand-off) — `ir-pass/test/*.ll` + every `PROTOCOL.md` session probe dir | `2fd12991d3e91d10` vs `fbbe0820ef4b176a` | **2681 rows: 2668 unchanged, 11 DECLINE→ACCEPT (every one `control flow` at a select), 2 decline-string moves (m05 + its fixture → `condition measured before the control route`), 0 ACCEPT→DECLINE, 0 both-accept lowered-IR changes.** Artifact `probes/impl/corpus_2fd12991d3e91d10.txt` | M-impl | 2026-09-13 15:3x |

**NOT run by this agent, by protocol (the "implementation" column):** `ctest -R '^e2e-'`, the full `ctest`,
`cq-opt-equivalence`, any twin matrix, the duplicate-body fixture scan.
**NOT run because the H-6 STOP deferred the work that would be their subject:** the injection (mutation)
matrix and the three e2e slices — the ACCEPT fixtures and slices they run over were deliberately not written
(`IMPL_M.md` §7).

### After the orchestrator's H-6 = ADMIT ruling (2026-09-13 pm) — binary `ae216b3727f5b1ec`

The rung-0 predicate dropped its `RailLadderProven` conjunct (ruling item 2), so the binary moved
`2fd12991d3e91d10` → `ae216b3727f5b1ec`. Every row below is on the NEW binary; rows above it are facts about
the OLD one and stay as the record of how it got here.

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| item-2 measurement: the compare-guarded prep customer (`i2_cmpladder.c`, single-φ merge, no peel ⇒ F2/rb9x not reached) | `fbbe0820` ORACLE / `2fd12991` subject | BOTH `control flow`; the region is CLAIMED (exactly ONE diagnostic, at the select) and was refused by the `RailLadderProven` conjunct ALONE | M-impl | 2026-09-13 16:0x |
| item-2 after the change | `ae216b3727f5b1ec` | `i2_cmpladder` **ACCEPT 21 lines**, STRICT 2b `6 mints / 5 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven`; `i2_otherclass` (a claimed VALUE-class region) still DECLINES `control flow` on BOTH binaries | M-impl | 2026-09-13 16:1x |
| bd `3d8q` sibling probe (two SIBLING readers of the pre-rotation name) | `fbbe0820` ORACLE | `p3d8q_sibling_rail` (rail-leaf spelling) **ACCEPT 30 lines, 2b clean** ⇒ the hole is PRE-EXISTING; `p3d8q_sibling` (φ spelling) DECLINE `control flow` | M-impl | 2026-09-13 16:0x |
| bd `3d8q` sibling probe | `ae216b3727f5b1ec` | `p3d8q_sibling` **ACCEPT 31 lines** ⇒ Track M ADDS CUSTOMERS to bd `3d8q`; no fence built (ruling) | M-impl | 2026-09-13 16:1x |
| whole probe set re-run | `ae216b3727f5b1ec` | identical to `2fd12991` on every probe EXCEPT `m16` (run-time `a`), which moves DECLINE → **ACCEPT 31 lines**, 2b `3 free: 3 verified, 0 violation(s), 0 unproven` — the item-2 widening's own customer | M-impl | 2026-09-13 16:1x |
| `NOROUTE-NOT: phi` hygiene fix, 7 fixtures | `ae216b3727f5b1ec` | all 7 re-anchored to `{{= phi }}`; `lit --filter` GREEN **from the `CQ_mphi` worktree path**, where they previously failed; anchor re-validated against a module that DOES carry a surviving `phi` (it reddens) | M-impl | 2026-09-13 16:2x |
| `lit --filter` per new fixture (16 new: 8 accept, 8 decline) | `ae216b3727f5b1ec` | 16/16 PASS. Header scan for directive-looking prose before the first RUN line: 0 hits (one was found and fixed — a literal `CHECK:` inside a comment IS a directive) | M-impl | 2026-09-13 16:3x |
| **injection (mutation) matrix**, 8 accept fixtures × 7 mutations | `ae216b3727f5b1ec` | **56 applied, 0 MISSED, 0 N/A.** First pass was 43 applied / 1 MISSED / 13 N/A — the MISSED was a missing `RYCNT` prefix, the 13 N/A were the MUTATORS not tolerating `, !dbg !N`; both fixed and re-run. Artifact `probes/impl/injection_matrix_ae216b37.txt` | M-impl | 2026-09-13 16:4x |
| the 4 e2e slices, each `ctest -R '^e2e-slice-<name>$'` | `ae216b3727f5b1ec` | 4/4 PASS — `cascade-two-bools` **29**, `_base` **19**, `_uncond` **28**, `_int` **28** lines, every one STRICT stage 2b `0 violation(s), 0 unproven`. The 29 lines equal the T1 prediction 29/29 | M-impl | 2026-09-13 16:5x |
| the 2 new CMake gates + their MUTANT VALIDATION | `ae216b3727f5b1ec` | `base-prefix-identical` and `twin-identical` PASS; **5 mutations, 5 correct verdicts, and the two gates are COMPLEMENTARY** (prefix-half perturbation reddens only the prefix gate; select-half copy swap reddens only the twin gate; a truncated golden, an `h1`→`h10` alias attempt and a dropped line all redden loudly) | M-impl | 2026-09-13 16:5x |
| `ctest -R ir-pass-lit` (ONCE, at hand-off; pass source changed) | `ae216b3727f5b1ec` | **PASSED, 50.77 s. 1908 discovered / 1907 PASS / 1 XFAIL / 0 FAILED** — the 7 path-artefact failures are gone (fixed, not masked) | M-impl | 2026-09-13 17:0x |
| corpus sweep ORACLE-vs-SUBJECT (ONCE, at hand-off; hash changed) | `ae216b3727f5b1ec` vs `fbbe0820ef4b176a` | see IMPL_M.md §6 — artifact `probes/impl/corpus_ae216b3727f5b1ec.txt` | M-impl | 2026-09-13 17:1x |

**Counts after Track M** (measured, not quoted): `ls ir-pass/test/*.ll` **1908** (was 1893) ·
`ls tests/e2e/*.expected.log` **359** (was 355) · `ctest -N` **409** (was 403).

**STILL not run by this agent, by protocol:** `ctest -R '^e2e-'` as a whole, the full `ctest -j6`,
`cq-opt-equivalence` (⚠ **OWED at merge**: a decline string moved and analysis sites changed — see
`PROTOCOL.md`'s "iff a decline string / analysis site changed"), any twin matrix, the duplicate-body scan.

| new decline fixture `..._mergephi_chained_arm.ll` (= boi6 probe `p20`, the probe this increment is NAMED after) | `ae216b3727f5b1ec` / `fbbe0820` ORACLE | RED on the ORACLE (`control flow` — the leaf grammar pre-empts), GREEN here (`condition predates a non-diagonal gate` — rung (iii)/gate 2c). Added AFTER the corpus sweep, so its two verdicts were measured directly on both binaries rather than swept | M-impl | 2026-09-13 17:2x |
| rebuild after a COMMENT-ONLY edit to `SelectClassify.cpp` | `ae216b3727f5b1ec` | hash UNCHANGED — confirms the build is deterministic and that the corpus sweep's binary is the one on disk | M-impl | 2026-09-13 17:2x |

### Round-1 FIX (F-M1 / F-M3 / F-M6 / F-M5 / F-M7) — binary `0d3105d0eb9d476a`

`ControlRegion::PrepRegionIdx` + its ONE precedence edge moved the binary
`ae216b3727f5b1ec` → **`0d3105d0eb9d476a`**. Comment-only edits after that re-hashed identically (verified).

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| the 24 round-1 review probes, re-run | `0d3105d0eb9d476a` | **`r03` DECLINE → ACCEPT 33 lines**, STRICT 2b `8 mints / 6 left allocated, 3 free: 3 verified, 0 violation(s), 0 unproven`. **Every other probe identical to `review_M_r1.md`'s table** (r18 40, r05 43, r12 41, r13 31, r14 21, r15 31, r17 29, r22 43, r07 31, r08/r09 29; r01/r16 the wire string, r04 `control flow`, r21 the loop string, r02 `rotation angle`, r10/r11 the seed string, r19/r20 `control flow`) | M-fix | 2026-09-13 18:0x |
| **F-M1 counterfactual** (the edge disabled, one statement, nothing else) | `253a80e6d9d45f16` (throwaway, reverted) | `r03` ACCEPT → `control flow` exit 1 (the H-1 backstop), while `r18` (inert third construct) ACCEPT 40 and `r17` (owner file) ACCEPT 29 are UNAFFECTED ⇒ the edge is exactly what fixes `r03` and changes nothing else | M-fix | 2026-09-13 18:1x |
| the four customers, re-measured | `0d3105d0eb9d476a` | owner file **29** (trace byte-identical to the committed golden), `m16` **31**, `i2_cmpladder` **21**, `va` **19** — all STRICT 2b `0 violation(s), 0 unproven`; the 4 cascade e2e slices still PASS | M-fix | 2026-09-13 18:2x |
| **F-M6** K-independence (`clang -O1`, no `-g`) | `0d3105d0eb9d476a` | `r22` lowered IR **78 lines / 19 gate calls at K=3 AND at K=1000** ⇒ ROLLED, not unrolled | M-fix | 2026-09-13 18:2x |
| **F-M6** the rolled-vs-hand-unrolled twin | `0d3105d0eb9d476a` | both slices ACCEPT **43** lines, traces **BYTE-IDENTICAL** (`compare_files`); gate mutant-validated (copies swapped in trip 2 ⇒ REDDENS) | M-fix | 2026-09-13 18:3x |
| `lit --filter` per new/touched fixture (3 new: `_rail_then_kickback`, `_inloop_outside_prep`, `_inplace_arm`) | `0d3105d0eb9d476a` | 3/3 PASS; the two new DECLINE-side ones verified RED on the ORACLE `fbbe0820` for the OLD string | M-fix | 2026-09-13 18:3x |
| **VACUITY CHECK (new instrument)** over every accept's named pure negatives | `0d3105d0eb9d476a` | first run **5 VACUOUS across 3 fixtures** (a `NOX`/`NOFREE` naming a handle the module never defines — incl. the non-negotiable `NOX` on a SECOND user register); all fixed; re-run **56 named negatives across 10 fixtures, 0 VACUOUS**. Instrument `probes/impl/vacuity.py` | M-fix | 2026-09-13 18:4x |
| **injection matrix**, 10 accept fixtures × 8 mutations (an 8th added for F-M6: a gate HOISTED OUT of the loop body) | `0d3105d0eb9d476a` | **79 applied, 0 MISSED, 1 N/A** (`rail-handle-in-imm-slot` has no shape in the in-loop module). ⚠ It was the matrix that caught the vacuous `NOX`: `x-on-user-register` reddened `XCNT` but NOT `NOX` on two fixtures. After the fix `NOX` catches it in **all 10**. Artifact `probes/impl/injection_matrix_0d3105d0.txt` | M-fix | 2026-09-13 18:4x |
| `ctest -R ir-pass-lit` (ONCE, at hand-off) | `0d3105d0eb9d476a` | **PASSED, 39.26 s. 1912 discovered / 1911 PASS / 1 XFAIL / 0 FAILED** | M-fix | 2026-09-13 18:5x |
| corpus sweep ORACLE-vs-SUBJECT (ONCE after the fix; now also covering `trackM/review_M_r1_probes/`) | `0d3105d0eb9d476a` vs `fbbe0820ef4b176a` | see `FIX_M_R1.md` §6 — artifact `probes/impl/corpus_0d3105d0eb9d476a.txt` | M-fix | 2026-09-13 19:0x |

**Counts after the fix:** `ls ir-pass/test/*.ll` **1912** · `ls tests/e2e/*.expected.log` **361** ·
`ctest -N` **414**.

**STILL not run, by protocol (row "fix"):** `ctest -R '^e2e-'` as a whole, the full `ctest -j6`,
`cq-opt-equivalence` (⚠ **OWED at merge** — decline strings moved and analysis sites changed), any twin
matrix, the duplicate-body scan.

| the `G6` mover pinned + final matrices | `0d3105d0eb9d476a` | `control_swap_accept_select_mergephi_quantum_arm_then_prep.ll` (= the 2026-09-11 integration probe `G6_quantum_mux_values.c`, ACCEPT 26 lines, 2b `3 free: 3 verified`); vacuity **63 named negatives / 11 accept fixtures / 0 VACUOUS**; injection **87 applied / 0 MISSED / 1 N/A** | M-fix | 2026-09-13 19:1x |
| `ctest -R ir-pass-lit` (final) | `0d3105d0eb9d476a` | **PASSED, 40.15 s. 1913 discovered / 1912 PASS / 1 XFAIL / 0 FAILED**. Counts: fixtures **1913**, goldens **361**, `ctest -N` **412** | M-fix | 2026-09-13 19:1x |

### MERGE-AND-GATE, landing 3 — `mphi-rail-leaf` × `main` e625f30 — binary `f7b65d8ccd7bc472`

The merge (no conflict) + the round-2 review items F2-1/F2-2/F2-3 moved the binary
`0d3105d0eb9d476a` → **`f7b65d8ccd7bc472`** (`libCQPass.so` `f9e898badfd4207a`). The merged binary
also carries landing 1's `MeasureLowering` and landing 2's `TaintPropagation.h` `PeelClones`, so
**nothing from any earlier row was citable** — every row below was RUN. Gated tree: `54079b6`.
Full record: `MERGE_M_1.md`.

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| pre-merge hash check (the reviewer's one obligation, repeated before touching anything) | `0d3105d0eb9d476a` on disk / `fbbe0820ef4b176a` + `40e9c7a51e8120bb` ORACLE | both MATCH `GATES.md` and `PROTOCOL.md`; no cited line stale | M-merge | 2026-09-13 14:2x |
| `git merge main` (e625f30) | — | **0 conflicts**; union checked 3 ways — `grep -c '^add_test'` 393 base / 402 branch / 401 main / **410 merged** (393+9+8 exactly); the `get_property` sweep is still the LAST statement; `git diff --name-status e625f30 2251621` outside `docs/` = Track M's 49 paths and nothing else | M-merge | 2026-09-13 14:3x |
| items A (F2-1 CHECK + rz mutation, F2-2 comment, F2-3 negatives) | `f7b65d8ccd7bc472` | **rz mutation 4 mutants / 4 CAUGHT** (was 0/4 MISSED by all 11 prefixes), unmutated control still green, exactly ONE prefix (`CHECK`) catches each; **negcoverage 11 fixtures / 0 gaps** (was 11/11 NOX-missing, 8/11 NOFREE-missing); **vacuity 84 named negatives / 11 fixtures / 0 VACUOUS** (was 63/11/0); `lit --filter 'mergephi\|rail_after_prep'` **20/20 PASS**; the `ir-pass/src` edit is mechanically comment-only (0 non-comment +/- lines) | M-merge | 2026-09-13 14:3x |
| `cmake --build build -j8` (BOTH targets, after reconfigure) | `f7b65d8ccd7bc472` / `f9e898badfd4207a` | 52.511 s wall; 4 warnings, ALL pre-existing in files no track touched (`RegionTreeDetect.cpp:173/174`, `TaintPropagation.cpp:255/1988`); no new warning | M-merge | 2026-09-13 14:3x |
| **full `ctest --test-dir build -j6 --output-on-failure`** (ONCE, this landing's only full run) | `f7b65d8ccd7bc472` | **100% tests passed, 0 tests failed out of 420.** Total Test time (real) = **388.40 sec** (wall 6:28.47). `ir-pass-lit` Passed 62.00 s · `frontend-lit` Passed 9.44 s · `e2e-loop-twin-matrix` Passed 214.33 s · `e2e-free-pairing-selftest` Passed · `e2e-loop-twin-quarantine-selftest` Passed · `e2e-census-slice-sync` Passed. No failure ⇒ nothing re-run serially | M-merge | 2026-09-13 14:4x |
| `cmake --build build --target cq-opt-equivalence-full` (**OWED** — decline strings moved, analysis sites changed) | `f7b65d8ccd7bc472` | `cq_opt_equivalence: compared 1928 fixtures, 0 mismatch(es)` — 93.13 s | M-merge | 2026-09-13 14:5x |
| corpus sweep ORACLE-vs-MERGED (ONCE, all corpora the template names + item C's additions) | `f7b65d8ccd7bc472` vs `fbbe0820ef4b176a` | **3113 rows: 79 DECLINE→ACCEPT (46 `control flow` = M, 10 F2's seed string = R-1, 23 the lossy-rendered 21mg string = C), 10 decline-string moves (8 M: 6→`condition predates a non-diagonal gate`, 2→`condition measured before the control route`; 2 R-1), 0 ACCEPT→DECLINE, 0 both-accept lowered-IR changes.** Artifact `probes/merge/corpus_f7b65d8c.txt` | M-merge | 2026-09-13 14:5x |
| STRICT stage 2b over every accepting mover | `f7b65d8ccd7bc472` | **79/79: `0 violation(s), 0 unproven`**, no `--allow-unproven`. Artifact `probes/merge/stage2b_movers_f7b65d8c.txt` | M-merge | 2026-09-13 14:5x |
| decline-side FULL-stderr delta (landing 2's F-R1 blind spot, re-measured not inherited) | `f7b65d8ccd7bc472` vs `fbbe0820ef4b176a` | **1593 rows, 92 differ = 89 visible + 3 INVISIBLE to the string recipe**; all 3 are landing 1's declared `cq_measure_<sfx> operand is an undef/poison literal; …`, still `DS_Error` exit 1. **No M or R-1 string was hidden.** Interleave artefact of landing 2's copy FIXED (per-row files, concatenated sorted) ⇒ no serial re-run needed. Artifact `probes/merge/decline_delta_f7b65d8c.txt` | M-merge | 2026-09-13 15:0x |
| duplicate-body fixture scan (0 renames on either side; run anyway) | `f7b65d8ccd7bc472` | `files=1928  same-body groups=9` — exactly the 8 pre-existing deliberate pairs + landing 1's declared pair; Track M's 20 new fixtures create **no** group. Also: 16 fixtures carry `NOROUTE-NOT: {{= phi }}`, **0** carry the bare `phi` anchor | M-merge | 2026-09-13 15:0x |
| the customers, full 4-stage pipeline | `f7b65d8ccd7bc472` | **owner file ACCEPT exit 0, stderr 0 bytes, STRICT 2b `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`, 29 lines BYTE-IDENTICAL to `slice_control_cascade_two_bools.expected.log`, lines 1–16 BYTE-IDENTICAL to `va.trace`**; `va` 19 = `va.trace`; `vb`/`vc` 29 each, both BYTE-IDENTICAL to the owner's trace; `vd` **DECLINE** F2 at `vd.c:10:14`; `v_vd_guard_neg` **ACCEPT 42**, 2b `3 verified`; `m16` 31; `i2_cmpladder` 21; `b_A_intb0_boolb1` 22 = its golden; `owner_2026-09-11_2218` 15 = its golden; `G6_quantum_mux_values` 26; `ve` DECLINE taint escape. Every accept `0 violation(s), 0 unproven` | M-merge | 2026-09-13 15:0x |

**Counts after landing 3** (measured, not quoted): `ls ir-pass/test/*.ll` **1928** · `ls
tests/e2e/*.expected.log` **367** · `ctest -N` **420** · `-R '^e2e-'` **410** · `-R '^e2e-slice-'`
**365** · `-R twin-identical` **34** · `grep -c '^add_test' tests/e2e/CMakeLists.txt` **410** · twin
matrix cells 259+29 = **288** (unchanged) · `cq-opt-equivalence-full` **1928/0**.

**NOT run by this agent, by protocol (row "merge-and-gate"):** the injection matrix (an
implementation-row gate; `87 applied / 0 MISSED / 1 N/A @ 0d3105d0` is a fact about the PRE-merge
binary and is NOT cited for `f7b65d8c`), any twin matrix outside the full run, and any second full
suite. No squash, no push, no bd write.
