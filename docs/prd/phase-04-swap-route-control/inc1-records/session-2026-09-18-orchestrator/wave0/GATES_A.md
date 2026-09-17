# GATES — Wave 0-A (session 2026-09-18). Binary: build/ir-pass/cq-opt sha256 first 16 = 9bd01598d574b344

ORACLE re-verified at agent open:
`shasum -a 256 build/ir-pass/cq-opt` -> `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` — MATCHES the PROTOCOL block.
No rebuild, no source edit, no commit. Every line below was RUN by wave0-A; nothing here is cited from another track.
Per §6.1: `$SES/GATES_INFLIGHT.md` was empty of every gate below at the moment each was started; IN-FLIGHT and DONE lines were appended for the three `ctest` entries.

gate | cq-opt | result verbatim | who | when
--- | --- | --- | --- | ---
ctest -R '^e2e-loop-twin-quarantine-selftest$' | 9bd01598d574b344 | Passed 2.42 sec (1/1) | wave0-A | 2026-09-17 11:43
python3 tools/loop_twin_matrix_quarantine_test.py | 9bd01598d574b344 | `loop_twin_matrix_quarantine_test: 52 case(s), 0 failure(s)` exit 0 | wave0-A | 2026-09-17 11:44
ctest -R '^e2e-free-pairing-selftest$' | 9bd01598d574b344 | Passed 10.34 sec (1/1) | wave0-A | 2026-09-17 11:45
python3 tools/free_pairing_check_test.py | 9bd01598d574b344 | `30 positive fixture(s), 2 free-order pair(s), 1 cost bound(s), 77 named mutant(s), 10 memory mutant(s)/refusal(s), 5 Case-A negative(s), 19 census case(s), 315 proof-targeted mutant(s) (4 exempt by rule), 0 failure(s)` | wave0-A | 2026-09-17 11:45
ctest -R '^e2e-negative-vacuity-selftest$' | 9bd01598d574b344 | Passed 22.65 sec (1/1) | wave0-A | 2026-09-17 11:57
python3 tools/negative_vacuity_check_test.py | 9bd01598d574b344 | `6 hole case(s), 4 positive(s), 10 mutant(s)/control(s), 0 failure(s)` | wave0-A | 2026-09-17 11:58
twin-matrix cell counts (`grep -c`) | 9bd01598d574b344 | expected.txt `^m_` = 330; quarantine `^cell ` = 29; total 359; `bank_cells()` = 21; `cells_of_matrix()` = 359 | wave0-A | 2026-09-17 11:38
ONE-CELL twin run, m_none_kprep_none_none_kflat | 9bd01598d574b344 | MEASURED `ACCEPT-IDENTICAL` == COMMITTED `ACCEPT-IDENTICAL`, report None | wave0-A | 2026-09-17 11:39
ONE-CELL twin run x3: k2b_kflat / kiprep_kflat / kidx_kflat | 9bd01598d574b344 | `ACCEPT-IDENTICAL` / `UNROLLED-ONLY cq rail bank: array mixes a rail cell access with an unrecognized one` / `DECLINE-BOTH cq QRAM access: array address has aliasing fan-out` — all 3 == committed | wave0-A | 2026-09-17 11:40
gfsk header contract, unit level over COPIES in scratch | 9bd01598d574b344 | unmarked copy: `resolve_header` -> header None + REFUSAL, sha256 before==after `38d5da071f7c24ce`; marked copy: `preserved 462 header line(s) ... byte-for-byte`, hand prose survived a write; missing file: seeded, seed carries the marker | wave0-A | 2026-09-17 11:41
marker present in all 4 committed tables (`grep -n 'END OF HEADER'`) | 9bd01598d574b344 | expected.txt:459, quarantine.txt:175, expected.register.txt:229, quarantine.register.txt:126 | wave0-A | 2026-09-17 11:41
per-probe pipeline, rixk `w1_flat_prep_only.c` | 9bd01598d574b344 | opt exit 0; 6 static `call i32 @cqrt_alloc` sites in s2.ll; census `3 rail mint(s) of which 3 left allocated, 0 template rail mint(s) of which 0 left dirty, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven`; `./a \| grep -c cqrt_alloc` = 3 | wave0-A | 2026-09-17 11:48
regression pin, `tests/e2e/slice_control_cascade_three_bools.c` | 9bd01598d574b344 | `9 rail mint(s) of which 7 left allocated, 2 template rail mint(s) of which 1 left dirty, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven`; golden has 9 `cqrt_alloc` / 3 `cqrt_free` | wave0-A | 2026-09-17 11:49
free_pairing_check on the 5 `j1739_*` probes | 9bd01598d574b344 | `j1739_undef_pairing.ll` -> `0 verified, 0 violation(s), 1 unproven` `T1-undef-literal-pairing`; `j1739_undef_a2_bracket.ll` -> `1 unproven` `A-undef-literal-pairing`; 3 real-literal controls -> `1 verified, 0 unproven` | wave0-A | 2026-09-17 11:51
PRE-FIX checker (`git show 95949550^:tools/free_pairing_check.py`) on the same probes | 9bd01598d574b344 (subject binary irrelevant: pure python) | `j1739_undef_pairing.ll` -> `1 verified, 0 violation(s), 0 unproven` rc=0; rixk probe -> `6 rail mint(s)`; three_bools -> `9/7, 3 verified` (unchanged); x5b -> no template segment at all | wave0-A | 2026-09-17 11:52
wave0-A probe `divergent_literal.ll` (hole 2 AS FILED: 73896 vs 1401299752) | 9bd01598d574b344 | HEAD **and** PRE-FIX both: `UNPROVEN T1-no-reversal ... 1 unproven` rc=1; matched-literal control verifies clean on both | wave0-A | 2026-09-17 11:53
per-probe pipeline, `j_gzgs_m28_VACUOUS_merge.c` | 9bd01598d574b344 | opt exit 0; 29 trace lines; `8 rail mint(s) of which 6 left allocated, 1 template rail mint(s) of which 1 left dirty, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`; trace BYTE-IDENTICAL to the committed `j_gzgs_m28.trace` | wave0-A | 2026-09-17 11:55
per-probe pipeline, `j_gzgs_x5b_LIVE_merge.c` | 9bd01598d574b344 | opt exit 0; 28 trace lines; same census line; trace BYTE-IDENTICAL to committed `j_gzgs_x5b.trace`; `diff` of m28 lines 6..29 vs x5b lines 5..28 EMPTY | wave0-A | 2026-09-17 11:55
negative_vacuity_check.py, no fixture argument | 9bd01598d574b344 | `no fixtures given — nothing was checked, which is a HOLE, not a pass` rc=2 | wave0-A | 2026-09-17 11:56
negative_vacuity_check.py, 5 fixtures with NO `-NOT:` directive | 9bd01598d574b344 | `ZERO directives were evaluated over a non-empty batch — the matcher selected nothing, which is a HOLE, not a pass (bd test_C_libtooling-jdec)` ... `0 directive(s) evaluated` ... `[cq-opt 9bd01598d574b344]` rc=2 | wave0-A | 2026-09-17 11:56
negative_vacuity_check.py, real 25-fixture batch | 9bd01598d574b344 | `25 fixture(s), 166 directive(s) evaluated, 0 VACUOUS, ... 7 latent header collision(s), 9 declining module(s), ... universe 16 module(s)  [cq-opt 9bd01598d574b344]` rc=0, 21.8 s | wave0-A | 2026-09-17 11:57
the OLD `trackM/probes/impl/vacuity.py`, from the MAIN checkout | 9bd01598d574b344 | `FileNotFoundError: [Errno 2] No such file or directory: '/Users/sorenwilkening/Desktop/CQ_mphi/build/ir-pass/cq-opt'` | wave0-A | 2026-09-17 11:57
per-probe pipeline, trackT `s3_live_rootmint_region{,_un}.c` | 9bd01598d574b344 | rolled `1 rail mint / 2 template rail mint(s) of which 0 left dirty / 4 verified`; unrolled `1 rail mint / 4 template / 8 verified`; traces 22 == 22 IDENTICAL. PRE-FIX on the same two: `2 rail mint(s)`, no template segment | wave0-A | 2026-09-17 11:59

NOT run by wave0-A: `ctest -R e2e-loop-twin-matrix` (the ~11-minute gate — merge-and-gate agent's), `ir-pass-lit`, `^e2e-`, the full suite, the equivalence sweep, any corpus sweep, `--regenerate` against any committed table.
