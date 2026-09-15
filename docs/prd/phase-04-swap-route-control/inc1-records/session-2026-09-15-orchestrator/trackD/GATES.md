# Track D — GATES.md (hash-keyed; PROTOCOL non-redundancy)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>`

A gate result is a fact about a BINARY. Before running a gate, read this file; if the
binary hash is unchanged and the gate is recorded, CITE the line instead of re-running it.

## Binaries

| label | `cq-opt` sha256 | `libCQPass.so` sha256 | what it is |
|---|---|---|---|
| ORACLE | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | `main` `74eabd2c`, the frozen session oracle (`/Users/sorenwilkening/Desktop/CQ_lang/build`), re-verified by `shasum` at session open and UNMOVED |
| BASE | `15f6a75a50faba7a2c99a969497044ca6211293ea00ad6388510c6cc17bff96d` | `e39dba218d4ba6988fedb66ace582c82af2e9214963ad07f3501a90367579ef2` | `dephase-fence-r2` `6882685b` — Track S′'s tip, this worktree's base. ⚠ NOT `main`: a mover against the ORACLE may be S′'s, which is why every row below is three-way where it can be. ⚠ **BIT-IDENTICAL to Track S′'s own recorded SUBJECT(final)** (`trackS/GATES.md`), so it is provably the binary S′ gated and every S′ gate line at that hash is citable here |
| SUBJECT | `dd5887fc2852612cf471ac0f90b5e2fd973f070dd369e3aee1b477dcaee06dc9` | `d4bf79c1473ea26d368fd2cce26a7ec69ccb8c9a8e16628e8a9c4932fa4e9345` | BASE + the bd `bbu0` (D) deferral instrument |

⚠ **The two SUBJECT targets are recorded separately and both were exercised**, because Track T
measured on this same day that `cq-opt` can segfault while `libCQPass.so` from the **same**
build works and `make` reports up to date. The discriminator is running the same module
through both; the row is below.

## Gate lines

lit --filter loop_leak_dephase_reject_inloop_rotation (RED, Rule-12 red-green) | 15f6a75a50faba7a | Failed Tests (1): loop_leak_dephase_reject_inloop_rotation.ll — `check:84 X~~~ error: no match found` on the marker line; the CHECK half (the decline) MATCHED on the same run, so the RED is exactly the gap and nothing else | impl | 2026-09-15 03:12
base build reproduces Track S′'s gated binary BIT-FOR-BIT | 15f6a75a50faba7a | `shasum -a 256` on the first build of this worktree: cq-opt `15f6a75a50faba7a2c99a969497044ca6211293ea00ad6388510c6cc17bff96d`, libCQPass.so `e39dba218d4ba6988fedb66ace582c82af2e9214963ad07f3501a90367579ef2` — character-for-character `trackS/GATES.md`'s SUBJECT(final). Verified, not assumed (Rule 11) | impl | 2026-09-15 03:12
ORACLE hash re-verified before first use (PROTOCOL) | 0e280fc62a91cec2 | cq-opt `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`, libCQPass.so `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` — UNMOVED | impl | 2026-09-15 03:05
population scan, brief's minimum scope (BASE) | 15f6a75a50faba7a | `ir-pass/test/*.ll` + session-2026-09-15 probe corpora, 2100 scanned: **FENCE 17** (= 12 distinct programs), ACCEPT 1047, OTHERDECLINE 1030, VACUOUS 6. The 7 fixtures found are exactly the 7 that mirror the fence literal under `grep -l` — an independent check that the fixture half is complete | impl | 2026-09-15 03:13
**THE MEASUREMENT** (SUBJECT, stock opt + plugin) | libCQPass.so d4bf79c1473ea26d | **17 rows: WARNED 17 · SILENT 0 · PREEMPTED 0 · CRASH 0 · INSTRUMENT-BROKEN 0 · CONTROL-BROKEN 0 · CLANGERR 0**; 12 distinct programs; `marker=1` and `fence=1` and `exit=1` on every row | impl | 2026-09-15 03:16
**THE MEASUREMENT, re-run through `cq-opt`** (Track T's two-binary discriminator) | dd5887fc2852612c | identical buckets; `diff` of fields 1-6 against the stock-opt+plugin run is EMPTY — the two targets agree on all 17 rows | impl | 2026-09-15 03:16
three-way ORACLE controls over the same 12 programs | 0e280fc62a91cec2 | 5 ACCEPT on the ORACLE with warn 1·1·2·1·2 — **identical to the SUBJECT's gated counts**, five empirical controls that the deferral does not perturb the warn stage; 7 DECLINE at the fence's OLD literal with warn 0 BY PREEMPTION — the `†` rows of `QUESTION_bbu0.md` §1, all seven of which WARN once the preemption is removed | impl | 2026-09-15 03:16
lit --filter loop_leak_dephase (GREEN) | dd5887fc2852612c | Passed 7 of 7 (4 reject + 3 accept), 1.07 s — including the new `DEFER` prefix and the unchanged `CHECK` half | impl | 2026-09-15 03:17
**corpus sweep BASE-vs-SUBJECT, env UNSET (the NO-VERDICT-MOVED gate)** | dd5887fc2852612c | `ir-pass/test/*.ll` + EVERY session's `track*/probes` and `*_probes`: **5289 rows swept, MOVERS 0** (BASE-accept 2324, BASE-decline 2412, VACUOUS 551, CLANGERR 2). A row = exit code + md5 of the lowered IR when accepting + **SHA-256 of the FULL STDERR**, both binaries on the SAME stage-1 file; the stderr hash is what makes a decline→decline STRING move visible, which the inherited `corpus.sh` tag regex would hide (PROTOCOL S3) | impl | 2026-09-15 03:35
population scan, FULL corpus (derived from the same sweep's FENCE column) | 15f6a75a50faba7a | **FENCE 21 rows = 14 distinct programs by content.** ⚠ The brief's MINIMUM scope (17/12) was a floor, not the answer: the full corpus adds **two SHAPES nobody had counted** — `b3_ctrl_ry_after.c` (controlled-Ry-after) and `b8_angle_select_after.c` (angle-select-after), both from `session-2026-09-14c/review_r1b/probes` | impl | 2026-09-15 03:36
**THE MEASUREMENT at FULL-CORPUS scope** | dd5887fc2852612c | **21 rows: WARNED 21 · SILENT 0 · PREEMPTED 0 · CRASH 0 · INSTRUMENT-BROKEN 0 · CONTROL-BROKEN 0 · CLANGERR 0**; 14 distinct programs; `marker=1`, `fence=1`, `exit=1` on every row. Both new shapes WARN (warn=1 and warn=2) | impl | 2026-09-15 03:36
ctest -R ir-pass-lit (hand-off) | dd5887fc2852612c | `1/1 Test #8: ir-pass-lit ...... Passed 95.78 sec` / `100% tests passed, 0 tests failed out of 1` / `Total Test time (real) = 95.84 sec`. ⚠ VERBATIM, and it is the CTEST line: with `--output-on-failure` a passing entry prints no lit breakdown, so this track does **NOT** claim a "2041 / 1 XFAIL" figure it did not see. `ls ir-pass/test/*.ll \| wc -l` = **2042** is a separate measurement (files on disk), not a pass count. ⚠ Run at a MEASURED load average of 119-146 with other tracks on the box; contention causes false FAILURES, never false passes, so a GREEN under load is if anything the stronger reading | impl | 2026-09-15 03:20

## NOT run, and why (Rule 19 — report only what you ran)

* **full `ctest -j6`**, **`ctest -R '^e2e-'`**, **`cq-opt-equivalence-full`**, the **twin
  matrices** — PROTOCOL's matrix assigns none of these to the implementer row. ⚠ This track
  **does** owe the merge agent a note: it adds **no decline string and no new analysis site**
  (the instrument reuses `kMsgLoopLeakDephases` verbatim and is inert with the variable
  unset), so the "iff a decline string / analysis site changed" trigger for
  `cq-opt-equivalence-full` is **not** fired by Track D. The 0-mover sweep above is the
  evidence for that claim, not the claim itself.
* **an injection (mutation) matrix over new accepts** — this track adds **no accept**. Its one
  fixture change is a second RUN line on a module that declines in both modes.
