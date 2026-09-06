# review_eqpx_r2 — NARROW LENS round 2 (fixture/record integrity + the two gates round 1 did not run)

SUBJECT: `$SP/wt/eqpx` branch `eqpx-fix` @ **beb34e0** (round-1 code tip `1333278` + the docs/fixtures round).
BINARIES: `main` = `$SP/bin/main-16b15b3/`, `orac` = `$SP0/wt/pre-3qlq`, `fix` = `$SP/wt/eqpx/build/ir-pass/`,
`fix-r1` = `$SP/bin/eqpx-1333278/`. Work dir `$SP/progress/review_eqpx_r2_work/` (`W=`).

## 2026-09-06 step 0 — read + subject currency  [DONE]
* Read WHOLE: BRIEF_common, BRIEF_review_eqpx_r2, BRIEF_fix_eqpx, BRIEF_review_eqpx_r1, BRIEF_fix_eqpx_b,
  progress/fix_eqpx.md, progress/review_eqpx_r1.md, progress/fix_eqpx_b.md.
* **ITEM 1 — CODE DID NOT MOVE: PASS.** MEASURED in `$SP/wt/eqpx`:
  * `git log --oneline -1` -> `beb34e0`; `git status --porcelain` -> **EMPTY**;
    `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` -> **EMPTY**.
  * `git diff 1333278..beb34e0 -- ir-pass/src ir-pass/include | grep '^[+-]' | grep -v '^[+-][[:space:]]*//' |
    grep -v '^+++\|^---'` -> **EMPTY** (comment-only).
  * `cmp build/ir-pass/cq-opt $SP/bin/eqpx-1333278/cq-opt` -> **BYTE-IDENTICAL**; same for `libCQPass.so`.
  * `git diff --stat 1333278..beb34e0` -> 67 files, +1750/-43 (4 sources comment-only, 16 fixtures, 4 docs,
    43 record files under `session-7bbdb89e/`).
* Orchestrator's full ctest is RUNNING in the subject build tree (`orch_full_ctest_eqpx.log`, no `EXIT=` yet)
  — I will NOT start a ctest there. My own lit/harness runs only.
* NEXT: item 4 (writer enumeration), item 5 ((A) in-source), item 3 (decline fixtures + M-B), item 2 (injections).

## 2026-09-06 step 1 — item 4 (F-E1-1) + item 5 ((A) in-source)  [DONE]
* **ITEM 4 — PASS.** MEASURED in `$SP/wt/eqpx`:
  `grep -n 'markInPlaceRailOp(' ir-pass/src/LoopLowering.cpp` -> the four CALLERS at
  **`:1738 :2321 :2719 :3124`** (+ the def `:191` and two comment lines).
  `grep -rn 'InPlaceRailOps.insert' ir-pass/src ir-pass/include` -> **ONE** real site,
  `LoopLowering.cpp:193`, inside the helper (the other 3 hits are comment prose about it).
  The three enumerating comment blocks — `LoopLowering.cpp:159-188`, `OpcodeLowering.cpp:377-386`,
  `TaintPropagation.h:398-412` — all cite the SAME command (`markInPlaceRailOp(`), the same four
  FUNCTION NAMES and the same four numbers, and each says the names are the durable key. AGREES.
* **ITEM 5 — PASS.** `ArithLowering.cpp:337-372` carries the three-fact argument
  ((1) one call site, (2) every Phase-2 `Tainted` mutation is `promote`, (3) the one non-`promote`
  RAUW) and a "STATUS, STATED HONESTLY" paragraph: agrees with `TL` on every corpus program
  (M2+M3 moves 0 of 1707), LIVE when WRONG (M-E reddens 23), therefore "ARGUED DEFENCE-IN-DEPTH,
  not a fence with a red-green of its own", + "break (2) with a program, not with an argument".
  Every cited line VERIFIED by command: call site `OpcodeLowering.cpp:557` ✓; `promote` defs
  `ArithLowering.cpp:49` / `CastLowering.cpp:38` / `CompareLowering.cpp:44` /
  `IntrinsicLowering.cpp:204` ✓; `Site->replaceAllUsesWith(Handle)` `ArithLowering.cpp:162` ✓;
  the third computation `ArithLowering.cpp:375` ✓.

## 2026-09-06 step 2 — item 2 (F-E1-3, injections + my two new ones)  [DONE — 0 MISSED]
`$W/inject3.sh` (the lens's `inject2.sh` + (d) `constxorc` and (e) `constaddc`), run on the SUBJECT
binary over the 8 accept fixtures: **5 injections x 2 positions x 8 fixtures = 80,
INJECTIONS=80 MISSED=0, NOT-APPLIED=0**, and **CLEAN-CONTROL green=8 red=0** (every prefix passes
on the un-injected output). Per kind, all 16/16 caught: `railimm` `outofplace` `extrafree`
`constxorc` `constaddc`. The lens's original 3-injection subset is the 48 inside that run — also
0 MISSED, so F-E1-3's 28 -> 0 REPRODUCES independently.
`grep -n 'NOROUTE-COUNT' <the 16 new fixtures>` -> **EMPTY** (the Inc-3 F-L6-1 rule holds).
Log: `$SP/progress/r2_inject3.txt`.

## 2026-09-06 step 3 — item 3 (F-E1-2), M-A / M-B RE-MEASURED on the CURRENT fixtures  [DONE]
* All 8 decline fixtures carry a header block naming the mechanism (the `not` inversion), labelling
  the IR-text negatives DOCUMENTATION OF THE FORBIDDEN OUTPUT, and (the two W1 ones) saying their
  three `break reverse-play` negatives ARE live because they name STDERR.
* **stdout-on-decline probe, SUBJECT binary**: rc 1, **stdout 0 bytes**, one stderr line. REPRODUCED.
* **lit-pipeline emulation (`set -o pipefail; not <bin>/cq-opt … 2>&1 | FileCheck <fixture>`) over the
  8 declines, on THREE binaries** (the fixtures are the beb34e0 ones, not 1333278's):
  | binary | result |
  |---|---|
  | SUBJECT `$SP/wt/eqpx/build/ir-pass` | **8 Passed / 0 RED** |
  | **M-A** `$SP/bin/r1-mut-MA` (tripwire disabled) | **0 Passed / 8 RED**, each accepting rc 0 with `railInImm` 1 (six) or **2** (the two W1 cells, MEASURED `cqrt_xorc_i32(%h2, %out)` twice) |
  | **M-B** `$SP/bin/r1-mut-MB` (SILENT out-of-place fallback) | **0 Passed / 8 RED** — six accept rc 0 emitting ONE out-of-place `cq_template_{xor,add}_i32` and **zero** in-place gates; the two W1 cells exit rc 1 with a DIFFERENT diagnostic (`cq loop lowering: break reverse-play could not re-derive the lowered body`), which is what their three live STDERR negatives catch |
  So F-E1-2's claim is exact: the "no silent fallback" property is pinned, by the `not` inversion for
  six and by the live break-reverse-play negatives for the other two.

## 2026-09-06 step 4 — item 7, THE FULL ctest (READ, not run)  [DONE]
`$SP/progress/orch_full_ctest_eqpx.log`, header `TIP=beb34e0 START=… 15:45:23`, footer
`EXIT=0 END=… 15:51:14`. Summary line: **`100% tests passed, 0 tests failed out of 367`**,
`Total Test time (real) = 350.23 sec`. Rows the brief names:
| entry | result |
|---|---|
| `e2e-loop-twin-matrix` (#318) | **Passed 350.21 s** — the suite's whole wall time |
| `frontend-lit` (#10) | **Passed 5.13 s** |
| `ir-pass-lit` (#8) | **Passed 45.19 s** |
| `runtime_*` (7 entries: trace_test, header_compile, link_smoke, link_smoke_selftest, generated_drift, core_abi_link, core_abi_link_selftest) | **all Passed** (4.06 / 0.22 / 4.30 / 2.97 / 0.44 / 0.48 / 0.32 s) |
No `Failed` / `Timeout` / `Exception` / `***` line anywhere in the log.
**AFTER that run**, MEASURED by me in `$SP/wt/eqpx`: `git status --porcelain tests/ tools/` **EMPTY**,
`git status --porcelain` (whole tree) **EMPTY**, `git diff --stat main..beb34e0 -- tests runtime tools
include` **EMPTY** — 0 golden churn, 0 matrix churn, 0 tool churn.
`ctest -N` **367** / `-R '^e2e-'` **357** / `-R '^e2e-slice-'` **321** — matches `CLAUDE.md`'s claim.
`ls ir-pass/test/*.ll | wc -l` **1707**; `ls tests/e2e/*.expected.log | wc -l` **323**.

## 2026-09-06 step 5 — item 6 (record truth) + item 8 (the accept-direction sweep)  [DONE]
* **Census re-run, MY OWN, from the PUBLISHED record dir** (`eqpx_reproducers_r1/`), 15 members +
  20 controls x {main, fix} (`$SP/progress/r2_census.log`):
  * **all 15 members reproduce the README/§3.16 tables EXACTLY** — `x01` A 24 imm=1, `x02` 21/1,
    `x03` 21/1, `x04` 21/1, `x08` 223/2, `x11` 21/1, `x12` 24/2, `x14` 24/1, `x15` 29/1,
    `y05` 27/1, `y06` 24/1, `y07` 24/1, `y08` 53/1 on `main`; `x09`/`x10` **rc 134** on `main`
    — and every one DECLINES on `fix` with the mirrored string.
  * **all 20 controls ACCEPT on BOTH** with identical `lines`/`imm`; **trace `cmp` 20/20
    BYTE-IDENTICAL**. ZERO over-declines.
  * ⚠ TWO of the 20 need a TU that is NOT in the record — see **F-E2-1**.
* **Item 8, the accept-direction sweep on the SUBJECT binary:**
  * all **1707** fixtures: **accepts=841 declines=866 nonstd-rc=0** (reproduces the lens);
    `strictimm.py` over the 841 accepts -> **82 non-constant immediates**, `immcheck.py` ->
    **0 rail producers** (0 non-zero lines).
  * the reproducer corpus (43 originals + the lens's 43, incl. the 20 controls): 18 + 20 = **38
    accepts on `fix`**, `strictimm` **32** non-constant immediates, `immcheck` **0 rail producers**;
    every one hand-adjudicated classical (loop-counter phis/adds, break-counter negations, volatile
    and plain global loads, a `zext i8`, `ext_h`/`@run` call results, an Argument).
  * TOTAL: **879 accept modules on the subject, 0 rail producers.**

## 2026-09-06 step 6 — item 5's honesty claim, RE-MEASURED by me on the CURRENT tree  [DONE]
The in-source status at `ArithLowering.cpp:361-370` says the index "agrees with `TL` on every program
in the corpus — mutant M2+M3 … moves ZERO of 1707 fixtures". I re-ran that myself rather than
inheriting it: `$SP/bin/eqpx-m23/{cq-opt,libCQPass.so}` over all **1707** fixtures ->
**accepts=841 declines=866 nonstd=0**, and against the subject's own sweep output
**identical=841 · OUTDIFF=0 · only_m23=0 · only_fix=0**. The claim is EXACT.

## 2026-09-06 step 7 — M-E re-measured, and the citation sweep  [DONE]
* **M-E** (`$SP/bin/r1-mut-ME`, the recorded index FLIPPED + the Phase-1 re-verify off) over all
  1707 fixtures vs the subject's own sweep output: **identical=817 · OUTDIFF=10 ·
  accept→decline=14 · decline→accept=0** — **24 fixtures move**. That CORROBORATES the in-source
  "LIVE when WRONG — M-E reddens 23" (mine is an OUTPUT-level count, not a lit-red count; I did
  not run lit under M-E). Together with the M2+M3 result the honest status in
  `ArithLowering.cpp` is exactly right: inert when REMOVED, live when WRONG.
* **F-E2-2, the citation sweep** — see the finding below. MEASURED with a script over every
  `LoopLowering(.cpp)?:<n>` citation with n>156 in the notes, PRD, `CLAUDE.md`, `ROADMAP.md` and
  the three fix sources, comparing `main`'s line n against the subject's line n and n+40.

---

# ── HAND-BACK — review_eqpx_r2 (NARROW LENS, round 2) ──

## VERDICT: **CLEAR-WITH-ITEMS**

The docs+fixtures round closed F-E1-1/2/3 and adjudications (A)/(B) **honestly and, for F-E1-3,
with margin** (my superset injection matrix is 0 MISSED where the pre-edit fixtures miss 47/80).
The two gates round 1 did not run are **GREEN**: the orchestrator's full `ctest` is
`100% tests passed, 0 tests failed out of 367` and the tree is byte-clean afterwards.
Three DOC items, one of which is the F-E1-1 class recurring inside the very increment that closed it.

## FINDINGS

### F-E2-1 — DOC / RECORD (reproducibility): the published reproducer corpus is missing a one-line TU, and the README's two-TU rule names the wrong symbol for two of its files
`docs/prd/.../inc1-records/session-7bbdb89e/eqpx_reproducers_r1/README.md` says: *"Every program
whose source mentions `ext_f` is a TWO-TU program and needs
`../../session-82e6b530/eqpx_reproducers/tu_extf.c`."* MEASURED: **two of the 20 published
over-decline controls reference `ext_h`, not `ext_f`** — `d03_classical_phi_imm.c` and
`d05_classical_call_imm.c` — and **`tu_exth.c` is committed NOWHERE in the tree**
(`find $SP/wt/eqpx -name 'tu_ext*.c'` → 5 files, all `tu_extf.c`/`tu_extfg.c`; the file exists only
in the round-1 lens's scratchpad at `$SP/progress/review_eqpx_r1_work/p/tu_exth.c`, one line:
`int ext_h(int a){ return a+3; }`). The lens's own `census_a.sh` supplied three TUs
(`tu_extf`/`tu_extg`/`tu_exth`); only the first was published.
* Following the README verbatim, both programs **LINKFAIL** on BOTH binaries
  (`Undefined symbols … "_ext_h"`, MEASURED, `$W/out/d0{3,5}_*.{main,fix}.link.err`), so the
  README's claim *"All 20 ACCEPT on BOTH binaries with identical `lines`/`imm` and a byte-identical
  trace (`cmp` 20/20)"* is **not reproducible from the record** for those two rows.
* The CLAIM ITSELF IS TRUE, and I verified it two ways: (i) at the pass level both ACCEPT on both
  binaries with the lowered module byte-identical `main` vs `fix` (modulo `ModuleID`) and
  `railInImm=0`; (ii) re-running them with a one-line `tu_exth.c` I reconstructed gives exactly the
  recorded `ACCEPT … lines=6 imm=0` on both, traces `cmp` BYTE-IDENTICAL.
* Binaries: `main` = `$SP/bin/main-16b15b3`, `fix` = `$SP/wt/eqpx/build/ir-pass`.
* **Grade DOC.** Fix: commit `tu_exth.c` beside the programs (or into
  `session-82e6b530/eqpx_reproducers/`) and change the README's rule to name `ext_f` **and**
  `ext_h`. No compiler behaviour is involved.

### F-E2-2 — DOC (record truth): the F-E1-1 class RECURS — six `LoopLowering.cpp:<n>` citations that were CORRECT on `main` are stale on the subject, and TWO of them are in text this increment WROTE
The increment inserts **+40 lines at `LoopLowering.cpp:156`** (`markInPlaceRailOp` + its Rule-0
block; MEASURED, `git diff main..beb34e0 -- ir-pass/src/LoopLowering.cpp | grep '^@@'` →
`@@ -156,6 +156,46 @@`), so every line below 156 moves by +40. The round-2 doc pass re-synced the
**four writer lines** and the **`ArithLowering.cpp:646-648` → `:695-696`** G5 citation, and did not
sweep the rest.

| citation | what it names | real line on the SUBJECT | correct on `main`? | cited from |
|---|---|---|---|---|
| `LoopLowering.cpp:206` | `railValueConsumerDisposition`'s `InPlace` cell (`if (taint.InPlaceRailOps.count(BO) \|\| Claimed.count(BO))`) | **`:246`** | YES | **`ir-pass/src/OpcodeLowering.cpp:426` — the FIX'S OWN 8h7d.5 Rule-0 comment** and **notes §3.16 `:2508` — the increment's OWN 8h7d.5 paragraph** |
| `LoopLowering.cpp:212-213` | the one `return RailValueUse::OutOfPlace` | **`:252-253`** | YES | notes §3.14 table, `:2073` — **the same table cell whose `ArithLowering` half the doc pass DID fix** |
| `LoopLowering:2187` | the round-1 Rule-8 fan-out guard | **`:2227`** | YES | notes `:2073` |
| `:2617` | the round-2 Rule-8 fan-out guard | **`:2657`** | YES | notes `:2073` |
| `LoopLowering:928` | `collectRailGates`' `OnThisRail = railValueConsumerDisposition(…)` | **`:968`** | YES | notes `:2074` |
| `LoopLowering.cpp:2922` | "this fence's own comment" (the `(A) DIRECTION` block) | **`:2962`** | YES | notes §3.11 `:1589` |

MEASURED by script over every `LoopLowering(.cpp)?:<n>` with n>156 in the notes, the PRD,
`CLAUDE.md`, `ROADMAP.md` and the three edited sources, comparing `git show main:…` line n against
the subject's line n and n+40, then hand-adjudicated (the four writer lines and `:1568-1570`,
`:2452` are CORRECT on the subject — they were updated).
⚠ **NOT in the finding, because it is PRE-EXISTING:** notes `:2075`'s `LoopLowering.cpp:3214` /
`:3412-3413` for the two `AsLowered=true` sites was ALREADY wrong on `main` (real sites there
`:3240` / `:3438-3439`; on the subject `:3280` / `:3482-3483`).
* **Grade DOC.** No behaviour, no unitary. It matters because it is the *same* class the doc pass
  was convened to close, and because §3.16 and `markInPlaceRailOp`'s own header both state the
  correct rule — *"cite the NAMES; the numbers move"* — while two NEW citations broke it.
  Fix: name the FUNCTION (`railValueConsumerDisposition`'s `InPlace` cell / its one `OutOfPlace`
  return / `collectRailGates` / the two fan-out guards) instead of a line, in all six places.

### F-E2-3 — DOC (trivial): §3.16's `strictimm` breakdown partitions 82 one item differently from the measurement
§3.16 reads *"82 non-constant immediates … 42 `sub i32 0, %k` …, 15 `add` counter steps, 19
`load volatile`, 3 `cqrt_measure_i32` results, 2 Arguments, 1 `@g` load"* (= 82). MEASURED by me
over the same 841 accepts: **42 `sub`, 16 `add`, 19 `load volatile` (the `@g` load IS one of the
19 — it is `load volatile i32, ptr @g`), 3 `cqrt_measure_i32`, 2 Arguments** = 82. The error is
self-cancelling and the load-bearing number (**ZERO rail producers**) reproduces exactly. Grade
DOC-trivial.

### F-E2-4 — DOC (trivial): an antecedent drifted in `CLAUDE.md`
The ⭐ FIXED clause is inserted between *"…but the same class one writer over."* and the
pre-existing *"**That last one** also RETIRES a sentence that had been doing bounding work in three
places…"*. On `main` "that last one" was the eqpx member; after the insertion the nearest
antecedent is the round-1 lens's `0 over-declines` parenthetical. The retired sentence is still
about eqpx, so the meaning survives; the pointer does not. Grade DOC-trivial.

## WHAT I VERIFIED CLEAR (the brief's items, one by one)

| # | item | result |
|---|---|---|
| 1 | **code did not move** | `git diff 1333278..beb34e0 -- ir-pass/src ir-pass/include` non-comment lines **EMPTY**; `cmp build/ir-pass/cq-opt $SP/bin/eqpx-1333278/cq-opt` **BYTE-IDENTICAL** (and `libCQPass.so`); `git status --porcelain` EMPTY; currency EMPTY. **PASS** |
| 2 | **F-E1-3 closed** | my `inject3.sh` = the lens's 3 injections + (d) `constxorc` + (e) `constaddc`, 5 x 2 positions x 8 fixtures = **80 injections, MISSED=0, NOT-APPLIED=0**, CLEAN-CONTROL **green 8/8**. The lens's 3-kind subset inside it is **48, 0 MISSED**. On the PRE-edit fixtures (`git show 1333278:`) the same script reads **28/48 MISSED** (reproducing the lens exactly) and **47/80** overall — my two new kinds would have missed **19 more**. `grep -n 'NOROUTE-COUNT'` over the 16 new fixtures **EMPTY**. **PASS, with margin** |
| 3 | **F-E1-2 closed honestly** | all 8 decline headers name the mechanism and label the IR-text negatives as documentation; stdout-on-decline **0 bytes** re-measured; lit-pipeline emulation on 3 binaries: SUBJECT **8 Passed**, **M-A 8 RED** (each accepting with `railInImm` 1 or 2), **M-B 8 RED**. The two W1 cells go red under M-B via their **live** `break reverse-play` stderr negatives (M-B rc 1, `cq loop lowering: break reverse-play could not re-derive the lowered body`). **PASS** |
| 4 | **F-E1-1 closed** | `grep -n 'markInPlaceRailOp(' ir-pass/src/LoopLowering.cpp` → **four callers `:1738 :2321 :2719 :3124`**; `grep -rn 'InPlaceRailOps.insert' ir-pass/src ir-pass/include` → **ONE** real site (`:193`, in the helper). The three enumerating blocks agree with each other and with the tree. **PASS** (but see F-E2-2 for the citations the same pass did not sweep) |
| 5 | **(A) in-source** | `ArithLowering.cpp:337-372` carries the three-fact argument with every cited line verified by command (`OpcodeLowering.cpp:557`; `promote` at `ArithLowering:49` / `CastLowering:38` / `CompareLowering:44` / `IntrinsicLowering:204`; `ArithLowering:162`; the third computation at `:375`) and an honest status. I **re-measured both halves**: M2+M3 (`$SP/bin/eqpx-m23`) over 1707 → accepts=841/declines=866 and **identical=841, OUTDIFF=0** vs the subject (inert when REMOVED); M-E over 1707 → **24 fixtures move** (10 OUTDIFF + 14 accept→decline) (live when WRONG). **PASS** |
| 6 | **record truth** | census re-run from the PUBLISHED dir: **15/15 members reproduce their `main` rows exactly** and all decline on `fix`; **20/20 controls accept on both, traces `cmp` 20/20 identical**. §3.12's ADD row is KEPT with a dated FALSIFIED note. The `y07` and `x09`/`x10` sentences say exactly what the brief requires, and I MEASURED `x09`/`x10` **rc 134** on `main` / rc 1 decline on `fix`. No sentence claims the class is closed beyond the four writers (§3.16's "WHAT IS NOT COVERED" says the fence is exactly as wide as G2). Every published `.c` has a README row. `ctest -N` 367/357/321, lit 1707, goldens 323 — all match. **PASS except F-E2-1/2/3/4** |
| 7 | **the two gates** | **READ, not run.** `100% tests passed, 0 tests failed out of 367`, 350.23 s, `EXIT=0`, `TIP=beb34e0`. `e2e-loop-twin-matrix` Passed 350.21 s · `frontend-lit` Passed 5.13 s · `ir-pass-lit` Passed 45.19 s · all 7 `runtime_*` Passed. No failure line. **AFTER the run**: `git status --porcelain tests/ tools/` EMPTY, whole tree EMPTY, `git diff --stat main..beb34e0 -- tests runtime tools include` EMPTY. **PASS** |
| 8 | **accept-direction sweep** | subject over **1707** fixtures: accepts=841, declines=866, nonstd-rc=0; `strictimm.py` **82** non-constant immediates, `immcheck.py` **0 rail producers**. Reproducer corpus (43 originals + the lens's 43): **38 accepts**, `strictimm` **32**, `immcheck` **0 rail producers**, each hand-adjudicated classical. **TOTAL 879 accept modules, 0 rail producers.** **PASS** |

## OWNER QUESTIONS
None of my own. I did not touch the implementer's OQ-1 (keep `InPlaceRailIdx`) or fix_eqpx_b's
OQ (a header note on the pre-existing (1b) template fixture) — both remain the owner's, and my
M2+M3 / M-E measurements above are new evidence for the first.

## WHAT I RAN
| # | command | result |
|---|---|---|
| 1 | subject currency + `cmp` vs `$SP/bin/eqpx-1333278/{cq-opt,libCQPass.so}` | `beb34e0`, status EMPTY, currency EMPTY, **BYTE-IDENTICAL** both |
| 2 | `git diff 1333278..beb34e0 -- ir-pass/src ir-pass/include` non-comment filter | **EMPTY** |
| 3 | `grep -n 'markInPlaceRailOp('` / `grep -rn 'InPlaceRailOps.insert'` | **4 callers** / **1 site** |
| 4 | `$W/inject3.sh` on the SUBJECT fixtures (5 kinds x 2 pos x 8) | **80 injections, 0 MISSED**, clean control 8/8 green |
| 5 | `SRCDIR=$W/orig8 $W/inject3.sh` (fixtures restored with `git show 1333278:`) | **80 injections, 47 MISSED**; orig-3 subset **28/48** — reproduces the lens |
| 6 | stdout-on-decline probe on the subject | rc 1, **stdout 0 bytes**, 1 stderr line |
| 7 | lit-pipeline emulation over the 8 declines on SUBJECT / M-A / M-B | **8 Passed / 8 RED / 8 RED** |
| 8 | census of the PUBLISHED `eqpx_reproducers_r1/` (15 members + 20 controls) x {main, fix} | 15 members reproduce exactly + decline on fix; 20 controls accept both, **trace `cmp` 20/20 identical** |
| 9 | d03/d05 re-run with a reconstructed `tu_exth.c` | `ACCEPT … lines=6 imm=0` on both, traces byte-identical (F-E2-1) |
| 10 | subject sweep over all **1707** fixtures + `strictimm.py` + `immcheck.py` | 841/866/0; **82** non-constant immediates; **0 rail producers** |
| 11 | reproducer sweep on `fix` (43+43) + `strictimm` + `immcheck` | 38 accepts; **32**; **0 rail producers** |
| 12 | M2+M3 binary (`$SP/bin/eqpx-m23`) over 1707, diffed against the subject sweep | 841/866/0; **identical=841 OUTDIFF=0 only_m23=0 only_fix=0** |
| 13 | M-E binary (`$SP/bin/r1-mut-ME`) over 1707, same diff | **identical=817 OUTDIFF=10 accept→decline=14 decline→accept=0** |
| 14 | `LoopLowering(.cpp)?:<n>` citation sweep (script + hand adjudication) | **6 introduced-stale citations** (F-E2-2), 1 pre-existing excluded |
| 15 | `ctest -N` / `-R '^e2e-'` / `-R '^e2e-slice-'`; `ls ir-pass/test/*.ll`; `ls tests/e2e/*.expected.log` | **367 / 357 / 321**; **1707**; **323** |
| 16 | `git status --porcelain tests/ tools/` and whole tree, AFTER the orchestrator's full ctest | **EMPTY** both |
| 17 | source/doc read: the whole `git diff main..beb34e0`, `ArithLowering.cpp:307-400`, `LoopLowering.cpp:143-200`, `OpcodeLowering.cpp:370-460,550-560`, `TaintPropagation.h:375-425`, notes §2 ⭐ row / §3.11 / §3.12 / §3.14 / §3.16 whole, PRD §0 E13, `CLAUDE.md`, `ROADMAP.md`, both new READMEs | see findings |

## NOT RUN — I make no claim about these
* **The full `ctest`: READ, not run.** I read `$SP/progress/orch_full_ctest_eqpx.log` (the
  orchestrator's run on the subject build tree) and did not start a second one.
* `lit` itself on the subject build tree (I emulated the RUN lines with `FileCheck` + `not` +
  `pipefail` to avoid contending with the orchestrator's `ir-pass-lit`); so my "8 Passed / 8 RED"
  figures are pipeline-equivalent measurements, not lit's own verdicts. Round 1 and `fix_eqpx_b`
  both report `lit -s` 1707 / 1706 / 1 XFAIL, which I did NOT re-run.
* `cq_opt_equivalence`, the `--epic` golden multiset audit, any new mutant BUILD (I reused the
  round-1 lens's saved M-A/M-B/M-E/M-m23 binaries, attributed), any e2e slice of my own, and any
  simulation/statevector reasoning (Rule 2 forbids it).
* A THIRD adversarial pass on the lowering itself — my brief scoped me to fixture/record integrity
  and the two gates. **Rule 13 is still not satisfied: two lenses on a docs pass are not a
  clearance, and this function's history is nine findings over seven rounds, two introduced by a fix.**
* I did NOT edit, rebuild or `git`-mutate `$SP/wt/eqpx` or `/Users/sorenwilkening/Desktop/CQ_lang`.

## Housekeeping
Work dir `$SP/progress/review_eqpx_r2_work/` (`inject3.sh`, `sweep_fix.sh`, `sweep_m23.sh`,
`sweep_ME.sh`, `census_r2.sh`, `repro_fix.sh`, `strictimm.py`, `orig8/`, `tu_exth.c`, `out/`,
`sw_{fix,m23,ME}/`). Logs: `$SP/progress/r2_{inject3,inject3_before}.txt`,
`r2_{census,sweep_fix,sweep_m23,sweep_ME,repro_fix}.log`. I created **no** git worktree.
