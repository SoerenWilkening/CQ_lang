# GATES — MERGE-AND-GATE agent, session 2026-09-18, worktree `agent-ac2acfdde3461becc`
#
# Format (`$SES/PROTOCOL.md`, the non-redundancy protocol):
#   <gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>
#
# Every `ran:` line below was checked against `$SES/GATES_INFLIGHT.md` for a matching IN-FLIGHT
# row AT THE SAME HASH before it started. The combined binary `96d74fe6008133b8` did not exist
# until this agent built it, so no other agent can have held a gate at this hash: every line here
# is a first run, and none is a re-run of another owner's gate (§6.1).

## Binary chain

| # | cq-opt sha256 (full) | libCQPass.so (first 16) | what is in it |
|---|---|---|---|
| ORACLE | `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` | `3e3dc35d471aae6b` | the session ORACLE, the primary `build/`, READ-ONLY. Re-verified on disk TWICE during this gate (at open and mid-run): unchanged, and character-for-character `PROTOCOL.md`'s block |
| SUBJECT | `96d74fe6008133b843cf5fc5f9ab2f3f96fb4f7986f905676044ce39e676a4bb` | `f9acb293a76af15a` | **the COMBINED binary**: `main` `b1b1dc02` + Group 1 `tu9q-hoisted-template` `f1a7857a` + Track D `drbq12-hoisted-compare-p4` `460ecefe`. `cmake --build build -j4`, BOTH targets, exit 0 |

## Merge integrity (no binary involved)

gate | cq-opt | result | who | when
--- | --- | --- | --- | ---
merge 1 `tu9q-hoisted-template` | — | clean, **0 conflicts** (merge commit `c81f70e0`) | m&g | 2026-09-17 14:37
merge 2 `drbq12-hoisted-compare-p4` | — | clean, **0 conflicts** — including `tests/e2e/CMakeLists.txt`, which git auto-merged (merge commit `bba8ecaa`). ⚠ An auto-merge is NOT proof of a correct union, which is why the three post-union checks below are the evidence and the absence of a conflict is not | m&g | 2026-09-17 14:38
post-union check 1 — duplicate `add_test` names | — | `grep -o 'add_test(NAME [A-Za-z0-9_-]*' … \| sort \| uniq -d` → **EMPTY** | m&g | 2026-09-17 14:38
post-union check 2 — count reconciles | — | **452**. Derived, not asserted: base `cff8f7ac` **447** + Group 1 **+2** + Track D **+3** = **452** ✓ | m&g | 2026-09-17 14:38
post-union check 3 — sweep still LAST | — | `tail -3` = `get_property(_E2E_ALL_TESTS …)` / `set_tests_properties(…)` ✓ | m&g | 2026-09-17 14:38
branch content preserved (Group 1) | — | `git diff tu9q-hoisted-template HEAD -- LoopLowering.cpp Uncomputation.cpp LoopPlan.h` → **EMPTY** | m&g | 2026-09-17 14:52
branch content preserved (Track D) | — | `git diff drbq12-hoisted-compare-p4 HEAD -- ArmClassify.cpp` → **EMPTY** | m&g | 2026-09-17 14:52
Track D's `460ecefe` is records-only, verified not assumed | — | `git diff 832ce900 460ecefe -- ir-pass/src ir-pass/include` → **EMPTY**; over `ir-pass/test`, every added/removed line is a `;` comment → **0 non-comment lines**. So trackD2's gates at `5ee9d144` remain facts about the shipped lowering | m&g | 2026-09-17 14:53
**L8 duplicate-body scan** | — | **2095 fixtures scanned, 9 duplicate-body groups (all pre-existing), 0 CONTRADICTORY-VERDICT groups**, 0 involving either branch's 13 new fixtures. Matches `trackT2`'s own count of 9 at 2086. SELF-ATTACKED IN BOTH DIRECTIONS before use: rc=2 on an empty universe (refuses to report a clean 0), and rc=1 with the group named on a planted same-body/opposite-verdict pair | m&g | 2026-09-17 14:40
⚠ L8 scan — 1 EMPTY-BODY module flagged | — | `lowering_predmux_purecallee_deep_chain.ll` has no IR body. **Adjudicated a NON-finding**: it is a GENERATOR fixture whose module is built at RUN time by `Inputs/gen_deep_pure_chain.py 60000`; an all-comment `.ll` is by design there, not the `empty-module-accepts` vacuity trap | m&g | 2026-09-17 14:41

## THE COMPOSITION MEASUREMENT (R20) — full record in `COMPOSITION.md`

gate | cq-opt | result | who | when
--- | --- | --- | --- | ---
probe copies identical to the review's originals | — | `dD1`/`dD4`/`dD5` in `trackD2/probes` **byte-identical** to `review_r13_trackD/probes` (3/3 `diff` empty) — so the measurement is on the filed reproducers | m&g | 2026-09-17 14:44
**`dD1` — R20's decision probe** | 96d74fe6008133b8 | **ACCEPT, `opt` exit 0, stderr 0 BYTES** (no live-record warning); STRICT 2b `2 rail mint(s) of which 2 left allocated, 2 template rail mint(s) of which **0 left dirty**, 2 cqrt_free site(s): 1 verified, 0 violation(s), 1 unproven`; the hoisted rail is DISCHARGED — `cq_template_and_i32_hl_unc(h2,h0,1)` + `cqrt_free(h2)` **strictly before** `cqrt_ry_i32(h0, 0.9)`; 22 trace lines | m&g | 2026-09-17 14:45
`dD1` direction confirmed on the ORACLE | 9bd01598d574b344 | exit 1, `cq controlled lowering: condition predates a non-diagonal gate under quantum control` — DECLINE. So the combined binary turns F-1's P1 over-accept into an accept **with the discharge** | m&g | 2026-09-17 14:47
**`dD1` vs `dD4` multiset, computed mechanically** | 96d74fe6008133b8 | **22 == 22 trace lines, MULTISET IDENTICAL** (`diff` of the two sorted `uniq -c` censuses empty). Sole divergence: ONE `cqrt_free(h4)` position, on a rail DISJOINT from the `and_unc`/`free(h2)` pair it crosses — they commute | m&g | 2026-09-17 14:46
**`dD5` — the PRE-EXISTING reference** | 96d74fe6008133b8 vs 9bd01598 | ORACLE: exit 0, `warning: … non-diagonal gate over a live derived record` (148 B), `2 template rail mint(s) of which **1 left dirty**`, 16 lines. COMBINED: exit 0, **stderr 0 bytes**, `**0 left dirty**`, 18 lines. ⇒ **the composition closes a pre-existing member of bd `s82e`'s class**, which neither track could claim alone | m&g | 2026-09-17 14:47
`a1_apost` (Group 1's composition probe) | 96d74fe6008133b8 | rolled **28** == twin **28**, **MULTISET IDENTICAL**, sole divergence one `cqrt_free(h6)` position. Reproduces `trackT2/GATES.md`'s figure at this new hash | m&g | 2026-09-17 14:48
`6n1s` triple — `t5j` (RED) | 96d74fe6008133b8 | exit 0; **4 `ashr` mints / 4 `_unc` / 4 `cqrt_free`**, `3 template rail mint(s) of which **0 left dirty**` — ORACLE was 4 mints / **0** `_unc` / **0** free. The `6n1s` leak is CLOSED. Residual: 2 `warning: … non-diagonal gate over a live derived record` on the **measured** `and` bit-rails (pre-existing bd `s82e`/`lyyf` class). ⚠ The brief predicted an `A→D` here; it did NOT occur and should not have — `6n1s`'s fix DISCHARGES rather than declines | m&g | 2026-09-17 14:49
`6n1s` triple — `t5i` (GREEN control) | 96d74fe6008133b8 | exit 0, stderr 0 bytes, `3 template rail mint(s) of which 0 left dirty`, `2 verified, 0 violation(s), 0 unproven`, 32 lines — **UNMOVED** from the ORACLE | m&g | 2026-09-17 14:49
`6n1s` triple — `t5k` (DECLINE control) | 96d74fe6008133b8 | exit 1, `cq loop lowering: rolled body leaks a rail entangled with a rotated register` — **UNMOVED** | m&g | 2026-09-17 14:49

## The g8 triple (coordinator addendum) — `review_r13_group1` F-1, on the COMBINED binary — PASS 1

gate | cq-opt | result | who | when
--- | --- | --- | --- | ---
**`g8_arm_use_derived_owned_rot`** | 96d74fe6008133b8 | **ACCEPT exit 0, warning only** (`cq rotation lowering: non-diagonal gate over a live derived record`, ×2), 19 trace lines, STRICT 2b `4 template rail mint(s) of which **2 left dirty**, **0 cqrt_free site(s)**`, **0 `_unc`**. Trace: four `cq_template_ashr_i32_hl(h0,k) -> hK`, none discharged, then `cqrt_ry_i32(h0, 0.9)` and `cqrt_measure_i32(h0)`. ⇒ **F-1 REPRODUCES ON THE COMBINED BINARY — the P1 is LIVE after the merge**, and Track D's half does not touch it | m&g | 2026-09-17 15:10
`g8a_arm_measured_directly_control` (one-token delta) | 96d74fe6008133b8 | ACCEPT exit 0, STRICT 2b `3 template rail mint(s) of which **0 left dirty**`, 2 free sites ⇒ **MOVES**, so the discriminant really is "the arm mints an INTERIOR rail" | m&g | 2026-09-17 15:11
`g8k_arm_use_derived_unmarked_control` (marking refused) | 96d74fe6008133b8 | **DECLINE** exit 1, `cq loop lowering: rolled body leaks a rail entangled with a rotated register` ⇒ **the marking is the door** | m&g | 2026-09-17 15:11

⚠ All three reproduce `review_r13_group1/REVIEW.md` F-1's numbers character-for-character on the
combined binary. The P1 is NOT a composition artefact and is NOT closed by Track D.

## Suite gates — PASS 1 (see `MERGE_REPORT.md` for the readings)

gate | cq-opt | result | who | when
--- | --- | --- | --- | ---
**full `ctest --test-dir build -j6 --output-on-failure`** | 96d74fe6008133b8 | `99% tests passed, 1 tests failed out of 462` · `Total Test time (real) = 740.30 sec` · `The following tests FAILED: 318 - e2e-loop-twin-matrix (Failed)`. ⚠ **Quoted with its load (Rule 19): 28 → 316 → 5**, self-inflicted (`-j6` plus the matrix's own workers); NOT comparable with a quiet-box figure. PID 35379 recorded at launch. Announced in `GATES_INFLIGHT.md` 14:48; no IN-FLIGHT line existed at this hash | m&g | 2026-09-17 15:01
`e2e-loop-twin-quarantine-selftest` (inside the suite) | 96d74fe6008133b8 | `Passed 1.58 sec` | m&g | 2026-09-17 15:01
`cq-opt-equivalence` (the SAMPLED `--stride 8` ctest entry, inside the suite) | 96d74fe6008133b8 | `Passed 97.16 sec`. ⚠ **This is the SAMPLE, not the full sweep** | m&g | 2026-09-17 15:01
**`e2e-loop-twin-matrix`** | 96d74fe6008133b8 | `***Failed 424.44 sec` — **382 cells**, `183 ACCEPT-IDENTICAL, 79 DECLINE, 120 other; 37 quarantined, 4 boundary controls`; `FAILED (95)` report entries = **56 distinct cells**, all adjudicated in `MATRIX_ADJUDICATION.md`. **NOT regenerated** — three contract refusals make green unreachable; `expected.txt` / `.quarantine.txt` byte-UNCHANGED | m&g | 2026-09-17 15:01
matrix cells re-measured BY HAND past the 2b abort (`gate/probes/cellprobe.py`) | 96d74fe6008133b8 | the 6 class-A `oder` cells: line counts EQUAL (27/29/29/29/27/28), **MULTISET-EQUAL all six**, `0 left dirty` all six, `sqrt_f64_unc` on BOTH sides (ORACLE: 0 vs 1). Fresh diff signatures `edbcfc8b1220486e` ×3, `9131e3d52bbe9b4c`, `117f0f19902d9672`, `e58056996a9e7ded`. ⇒ **bd `1m5p` fixed in substance; residue POSITIONAL** | m&g | 2026-09-17 15:07
4 of the 15 new-divergence cells probed | 96d74fe6008133b8 | `m_none_eq_none` 11 vs 8, `m_none_gt_none` 11 vs 8, `m_none_eq0_none` 11 vs 8, `m_none_eq_rz` 11 vs 12 — rolled mints a FRESH FLAG PER TRIP, unrolled CSEs to one flag with the `rz`s stacked; same conditional phase. ⚠ an ARGUMENT, not a clearance; 11 of 15 unprobed | m&g | 2026-09-17 15:08
**CORPUS SWEEP ORACLE `9bd01598` vs SUBJECT `96d74fe6`** | 96d74fe6008133b8 | **6981 rows in 23 m 43 s** (15:03:44→15:27:27, `-P 3`), 6972 scored, 2 CLANGERR, 7 EMPTYMOD. **137 movers: A→D 0 · D→A 79 · A→A md5 32 · A→A stderr 5 · D→D string 14 · D→D stderr-only 7.** **0 UNATTRIBUTABLE.** Records the FULL first `error:` line + a sha of the WHOLE stderr, closing PROTOCOL S3's `cq_measure_<sfx>` blind spot | m&g | 2026-09-17 15:27
D→A attribution RE-MEASURED on the ORACLE (not read off the truncated sweep row) | 9bd01598d574b344 | **79 movers: 75 `condition predates a non-diagonal gate`, 4 `control flow`. UNATTRIBUTABLE: 0.** Both are Track D's expected strings | m&g | 2026-09-17 15:28
**g8 BLAST RADIUS over the shipped-slice set** | 96d74fe6008133b8 | **383 of 386 slices scored** (3 `*_lib.c` halves skipped): `CLEAN 223 · DIRTY-NO-TRAILING-GATE 152 · DECLINE 6 · **G8-SHAPE 2**`. **Both hits are REGISTERED SHIPPING GOLDENS.** Probe half: 227 of ~2449 then STOPPED (task `bkgwiuf3r`; orphan killed by recorded PID 66488) — recorded as an ABSENCE. ⚠ The detector reported a FALSE CLEAN on its first run (`-q` suppresses the census) and was caught by a known positive | m&g | 2026-09-17 15:22
**`cmake --build build --target cq-opt-equivalence-full`** | 96d74fe6008133b8 | `cq_opt_equivalence: compared 2095 fixtures, 0 mismatch(es)` — exit 0, **3 m 36 s** (15:28:20→15:31:56). Licensed because Track D moved an ANALYSIS SITE and Group 1 moved a PLACEMENT. ⚠ Its `Built target cq-opt` lines were up-to-date NO-OPS, not a relink: re-hashed immediately after and both binaries are **unchanged**, so every line in this file stays a fact about the binary on disk | m&g | 2026-09-17 15:32
ORACLE re-verified on disk, 3rd time, after all sweeps | 9bd01598d574b344 | `9bd01598d574b344` — unchanged; SUBJECT `96d74fe6008133b8` — unchanged. Both sweeps ran against the intended binaries throughout | m&g | 2026-09-17 15:27
