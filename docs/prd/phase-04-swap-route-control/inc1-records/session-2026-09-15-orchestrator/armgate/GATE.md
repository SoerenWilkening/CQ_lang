# ARM group gate — GATES (hash-keyed; PROTOCOL.md *"a gate result is a fact about a BINARY"*)

Format: `<gate> | <sha256 of the measured cq-opt, first 16> | <result verbatim> | <who> | <date time>`

## Binaries

| role | commit / state | `cq-opt` sha256 | `libCQPass.so` sha256 |
|---|---|---|---|
| **ORACLE** (`/Users/sorenwilkening/Desktop/CQ_lang/build`, read-only, never rebuilt) | `main` `74eabd2c` | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` |
| **MERGED** (`/Users/sorenwilkening/Desktop/CQ_ARM/build`) | `arm-group-gate` = P′ `28b9eb01` (which already contains F′ `3637fdd2`) **+ this gate's six fixes** | `7916923f56fb36af90dfd05efe0b8c45317db5dc30d4d90ec56f8ffadba56e72` | `b8ec28927c3beff425554b75adca6474e928af535b6d78cbf8110390227ea8e7` |

```
oracle hash check (shasum -a 256)   | 0e280fc62a91cec2 | cq-opt AND libCQPass.so both match PROTOCOL.md's corrected oracle block character-for-character | armgate | 2026-09-15 03:26
```

## ⚠ THE MERGED BINARY IS **BIT-IDENTICAL** TO TRACK P′'s SUBJECT — and that is the single most load-bearing fact in this file

`7916923f56fb36af90dfd05efe0b8c45317db5dc30d4d90ec56f8ffadba56e72` is, character-for-character, the
`cq-opt` sha256 Track P′ recorded in `trackP/GATES.md`; `b8ec2892…` is likewise its `libCQPass.so`.
Two things follow, and the second is what makes this gate cheap:

1. **This gate's six fixes are proven behaviour-neutral by the strongest available witness.** Not "we
   believe comments don't change the binary" — the binary is the same bytes. Independently checked
   at the source level too: `git diff -U0 -- ir-pass/src ir-pass/include` filtered for lines that are
   not `//` comments or blank returns **nothing**, and the same for `ir-pass/test` with `;`.
2. **Every gate line Track P′ keyed on `7916923f…` is a fact about THIS binary**, so it is CITED here
   rather than re-run (PROTOCOL's non-redundancy rule). What P′ recorded as ABSENCES — the full
   `ctest`, `^e2e-`, and `cq-opt-equivalence-full` — are the ones this gate owes and RAN.

⚠ The build is reproducible ACROSS WORKTREES (different absolute paths, same bytes), which is itself
worth recording: it is what licenses (2), and it is not something a Release build has to give you.

---

## RAN — this gate

```
build MERGED (cmake --build build -j6, BOTH targets, no --target)  | 7916923f56fb36af | exit 0; 0 errors; 9 warnings, all pre-existing -Wunused in RegionTreeDetect/TaintPropagation | armgate | 2026-09-15 03:38
source-identity: every ir-pass/ edit is COMMENT-ONLY                | 7916923f56fb36af | git diff -U0 over ir-pass/src + ir-pass/include, minus `//`-lines and blanks: EMPTY. Same over ir-pass/test minus `;`-lines: EMPTY | armgate | 2026-09-15 03:37
bit-identity vs Track P' SUBJECT                                    | 7916923f56fb36af | cq-opt AND libCQPass.so both EQUAL trackP/GATES.md's SUBJECT hashes | armgate | 2026-09-15 03:38
lit --filter (27-fixture pinning family)                            | 7916923f56fb36af | Passed 27, Failed 0 (4.04 s) | armgate | 2026-09-15 03:39
per-probe R-1 on the ORACLE (m1 / m1c / m2)                         | 0e280fc62a91cec2 | m1 exit=1 F2 'state prep seed is proven equal to the condition register'; m1c exit=1 same string; m2 exit=0 (49-line module) AND prints `warning: ... non-diagonal gate over a live derived record`. m2's stream carries a never-_unc'd cq_template_trunc_i64_to_i32 then cqrt_ry_i32(%h1,0.9) then cqrt_measure_i32(%h1) -- the hazardous circuit ALREADY SHIPS FROM main | armgate | 2026-09-15 03:27
per-probe R-6 on the ORACLE (r1 / r2)                               | 0e280fc62a91cec2 | BOTH rejected by the VERIFIER: 'Instruction does not dominate all uses!' -- the dtzb xor on the arm theta's name is NOT EXPRESSIBLE, which is R-6's stronger ground, re-measured rather than inherited | armgate | 2026-09-15 03:27
```

### R-3 — SOURCE MUTATION over `availableAtAnF2Slot` (the gate Track F′ never shipped)

Harness `probes/source_mutation.sh`. **Each mutant was measured over ALL 2047 fixtures, not over the
27-fixture family**, because "flips nothing in 27" and "flips nothing in 2047" are different facts and
only the second one is worth reporting.

```
MA  body -> `return false;` (nothing truncates)  | cfcc74bdc6e01507 | full lit 2047: Passed 2045, XFAIL 1, FAILED 1 -- control_inplace_ry_reject_stateprep_backedge_phidesc_collider.ll. CAUGHT | armgate | 2026-09-15 03:35
MB  body -> `return true;`  (everything truncates)| 475ffd2a079e5484 | full lit 2047: Passed 2041, XFAIL 1, FAILED 5 -- acyclic_nondominated_phi{,_accept}, phidesc_collider_accept, mbeta_base_oncone_accept, round2_phidesc_collider_accept. CAUGHT | armgate | 2026-09-15 03:42
MC  PRED clause deleted (ARM clause kept)        | 192a0a2424599055 | full lit 2047: Passed 2046, XFAIL 1, FAILED 0. **MISSED -- a measured coverage HOLE, reported as a hole and not as a pass (PROTOCOL S3)** | armgate | 2026-09-15 03:37
MD  ARM clause deleted (PRED clause kept)        | 655768ad587a9c0d | full lit 2047: Passed 2046, XFAIL 1, FAILED 0. **MISSED -- the same hole, mirrored** | armgate | 2026-09-15 03:40
RESTORE + rebuild + hash                          | 7916923f56fb36af | source byte-identical to the pre-mutation copy (`diff -q`), and BOTH binaries rebuild BIT-IDENTICAL to the pre-mutation build. Every row keyed on 7916923f is therefore a fact about the SHIPPED source. Done TWICE (after MD and after MB) | armgate | 2026-09-15 03:41, 03:45
```

**MA's direction, measured rather than inferred** (on the MA binary, `cfcc74bd…`):
`backedge_phidesc_collider` goes from `state prep seed is proven equal to the condition register` to
**`control flow inside a loop body`** — the F2 witness is gone (the back-edge collider was swallowed
by the un-truncated exclusion set) and a second, independent fence catches the module. The fixture is
red because it pins the string **character-for-character**, which is what makes a doubly-covered
decline fixture non-vacuous. ⚠ **Residual, said out loud**: for *this* module the over-accept is a
decline-string change, not a silent accept. No shipped fixture exhibits the same over-accept where the
second fence is absent.

⚠ **`backedge_nonphidesc_collider` did NOT flip under MA, and that is CORRECT.** R-3's literal
phrasing — *"confirm **both** back-edge fixtures go red"* — is **wrong for that file**, and the file
says so itself: *"`%v` here is NOT in `PhiDesc`, so no exclusion of any kind applies to it and F2 must
fire on EVERY binary in this family. It therefore carries no information about the narrowing itself —
which is exactly its job: it is the control."* The PAIR is the tripwire; one half is the member and
one is the isolating control, which is precisely the discrimination the pair exists to provide. Taken
at face value, R-3's wording would have made me report a correct result as a failure.

⚠ **MC and MD are the finding of this section.** Deleting **either** clause of `availableAtAnF2Slot`
alone leaves the entire 2047-fixture suite green: the two clauses are **mutually redundant over the
shipped corpus**, and only deleting BOTH (MA) is witnessed. So neither clause is individually pinned.
That is consistent with the source header's claim that the ARM clause is redundant today (three
reasons given) — and it shows the converse holds too, which the header does not claim. **Filed, not
fixed**: writing a fixture that distinguishes them would require a region whose arm slot is available
where the pred slot is not, which the header argues is unreachable for three independent reasons; a
fixture cannot be written for an unreachable shape (Rule 12 can supply no input), so the honest
disposition is a recorded hole plus the retirement trigger already in the header.

### The corpus sweep — ONE, on the combined binary, movers attributed per track

```
corpus sweep ORACLE-vs-MERGED, FULL | 7916923f56fb36af | 3975 modules x 2 binaries (2047 shipped ir-pass/test fixtures + 1928 session probe modules). Rows: probes/gate_sweep_7916923f.txt; attribution: probes/attribute.out | armgate | 2026-09-15 03:48
```

Attribution is **JOINED** from the Rule-13 round's four-binary file rather than re-derived (rebuilding
BASE_F and P_ALONE would have produced no new information), and the join's precondition — the two
independently measured ORACLE columns must agree — is **checked, not assumed**.

| | measured here | REVIEW.md §7 expected baseline |
|---|---|---|
| shipped fixtures joined | 2046 (+1 excluded, see below) | 2047 |
| identical on ORACLE and MERGED | **2041** (+1 excluded) | 2042 |
| **F′-only** | **2** | 2 |
| **P′-only** | **3** | 3 |
| **COMPOSED** | **0** | 0 |
| **REVERSION** | **0** | 0 |
| **UNATTRIBUTED** | **0** | 0 |
| **MERGED == SUBJ_P** | **2046 / 2046** | — |
| `EMPTY` (0-byte module) | **1** (`h0_empty.ll`), scored EMPTY, never ACCEPT | 0 in that sweep's scope |

**The baseline reproduces exactly.** The 2 F′-only rows are
`control_inplace_ry_{reject_,}stateprep_acyclic_nondominated_phi{,_accept}.ll`; the 3 P′-only rows are
`control_phase_kickback_{reject_mergephi_cross_block, mergephi_two_leaves_cross_block,
mergephi_inloop_outside_prep}.ll`. Every one is a fixture the owning track added or converted
deliberately, in the direction it claimed.

**The one excluded row** is `lowering_predmux_purecallee_deep_chain.ll`, and the difference is
cosmetic and mine: this gate's hasher appends a trailing newline to reproduce `grep`'s output, which
differs from `md5 -q` of a **truly empty** lowered module (md5 of `"\n"` vs md5 of `""`). Same verdict,
different byte. Reported rather than silently normalised away.

**1928 probe-corpus rows have no row in the R-13 file** (that sweep covered `ir-pass/test` only).
**24 of them move**, and all 24 are named and expected: F′'s own `r20` (×2 copies), `acc1`, and X5's
`c2{,_live}`; P′'s own `a1`, `a2`, `a3`, `d5`, `p19`, `r18`, `r21`, `fxp1`, `fxp1c`, `fxp2`; and the
Rule-13 round's `c1`, `c1a`, `c2`, `c2t`, `o1`, `o2`, `o3`, `m1`, `x2c`. **Zero unattributed.**

Three of those 24 need their exit class named rather than their hash:
* `fxp1` / `fxp1c` go `D exit 1` → **`D exit -6`** (SIGABRT) — they move INTO the **pre-existing**
  broken-module crash bd `y65i`, which `COMPOSITION.md` §2 already files as a customer each track
  adds. Not new here.
* `fxp2` is **`D exit -6` on BOTH** binaries; its hash differs only because crash output still varies
  after the `Stack dump` / argv noise filter. **The VERDICT CLASS is unchanged** — do not read that
  row as a mover.
* `m1_malign_leak_then_rotate_measure.ll` goes `D exit 1 (F2)` → **ACCEPT**. That is R-1's
  over-accept, reproduced by this gate's own sweep and filed on bd `s82e`.

### ⚠ A FINDING AGAINST THE REVIEW'S OWN COMMITTED INSTRUMENT (L10)

```
sweep4.sh column label | (instrument, not a binary) | COLUMNS 3 AND 4 ARE TRANSPOSED WITH RESPECT TO THE LABEL. Corrected in place + erratum appended | armgate | 2026-09-15 03:49
```

`review_r13_armclassify/probes/sweep4.sh` labels its rows `relpath|ORACLE|BASE_F|P_ALONE|SUBJ_P`, and
REVIEW.md §7 copies that label — but the loop that writes them visits
`CQ_lang/build`, `CQ_F/build`, **`CQ_P/build`**, **`$SCR/R4/build`**, and `CQ_P` is the **COMPOSED**
worktree while `$SCR/R4` is `main`+P′ alone. The emitted order is
`ORACLE|BASE_F|SUBJ_P|P_ALONE`.

Measured over all 2047 committed rows — which is why this is a fact and not a reading:

```
AS LABELLED  O|BF|PA|SP : identical 2042, REVERSION 2, P'-only 3
AS EMITTED   O|BF|SP|PA : identical 2042, F'-only  2, P'-only 3
REVIEW.md §7 REPORTS    : identical 2042, F'-only  2, P'-only 3, 0 REVERSION
```

⚠ **Only the emitted order reproduces the reported counts**, so the reviewer's CONCLUSIONS are correct
and only the label is wrong — the classification was applied with the true semantics and the header
was mis-transcribed. REVIEW.md §6's own *"(mine, four binaries, ORACLE/BASE_F/SUBJ_P/P_ALONE)"* uses
the **true** order, which is the second piece of evidence for that reading.

**Why it is worth an erratum and not a shrug**: read as labelled, the two genuine F′-only rows come out
as **REVERSION** — the one classification REVIEW.md says *"must not happen"*. This gate's own first
attribution run printed exactly that, and it would have been reported as a regression in the merged
binary. Corrected at the source (line 2 rewritten, full erratum appended at EOF) and carried in
`probes/attribute.py`'s header, per L7-with-a-twist. **The rows themselves are sound; they were not
regenerated.**

### The L8 duplicate-body scan

```
duplicate-body scan (sha-256 over non-comment lines, 4 normalisations, verdict read off the RUN lines) | 7916923f56fb36af | 2047 fixtures. N1 13 groups / N2 13 / N3 15 / N4 15 duplicate-body groups, **0 with MIXED verdicts** in all four. 1 MIXED-SELF file (lowering_predmux_purecallee_deep_chain.ll -- legal: it generates two modules and runs one accept + one decline). PASS | armgate | 2026-09-15 03:31
```

⚠ **The scan's first spelling produced THREE FALSE "MIXED" GROUPS and was corrected before use.**
Canonicalising `@global`/`@function` names as well as `%local` ones collapsed
`lowering_intrinsic_sqrt_f64.ll` with `lowering_reject_libm_direct_cbrt_no_inject.ll` — genuinely
different modules whose only textual difference is the callee NAME. An instrument that cries wolf is
an instrument people stop reading (L10), so N3/N4 now canonicalise `%` only, and the reason is in the
script's header rather than in this file alone.

### The mandatory suites

```
cq-opt-equivalence-full | 7916923f56fb36af | compared 2047 fixtures, 0 mismatch(es). OWED because this landing moves an analysis site and a decline population, and recorded by BOTH tracks as an ABSENCE | armgate | 2026-09-15 03:52
full ctest -j6          | 7916923f56fb36af | **100% tests passed, 0 tests failed out of 442**. Total Test time (real) = **832.29 s**. ⚠ LOAD: 29.44 at start, **168.52 at end** -- another agent's work ramped up under it, which is why the wall-clock is ~2x the 436.73 s of the 2026-09-14 gate. Contention causes false FAILURES and never false passes, so a GREEN here is trustworthy and the TIMING is not comparable | armgate | 2026-09-15 04:11
```

### PROTOCOL S1's three post-union checks — **N/A, with the reason**

`git diff --stat 74eabd2c -- tests/` is **EMPTY**: neither track touched `tests/`, this gate added no
e2e slice, and there was no union to perform in the first place (P′ was branched from F′). The three
checks on `tests/e2e/CMakeLists.txt` (0 duplicate `add_test` names; count reconciles; the
`get_property` sweep still LAST) have no subject here. ⚠ Recorded as N/A-with-a-reason rather than
omitted, because "we didn't run it" and "there was nothing to run it on" are different statements.

---

## CITED — facts about `7916923f…` established by Track P′ and NOT re-run

Per PROTOCOL: *"if the binary hash is unchanged and the gate is recorded, do NOT re-run it — cite the
line."* The MERGED binary is bit-identical to P′'s SUBJECT, so these are facts about it:

```
cited: ctest -R ir-pass-lit (FINAL fixture set) 1/1 Passed, 62.52 s over 2047 fixtures @ 7916923f (trackP impl, 01:12)
cited: injection matrix (FINAL fixture set) 51 mutations, MISSED 0, N/A 6 @ 7916923f (trackP impl, 01:14)
cited: injection matrix empty-argv control -- exits 1 with a refusal @ 7916923f (trackP impl, 01:14)
cited: source mutation S-M1/S-M2/S-M3 + RESTORE bit-identical @ 7916923f (trackP impl, 01:05-01:06)
cited: stage 2b STRICT on all 7 new accepts -- 0 violation(s), 0 unproven @ 7916923f (trackP impl, 00:39)
cited: bd 52og rolled-vs-unrolled twin traces BYTE-IDENTICAL; K-independence 44 = 44 lines @ 7916923f (trackP impl, 00:40-00:41)
```

⚠ `ir-pass-lit` was **also independently re-run three times by this gate** as the RESTORE control for
the mutation matrix (2046 PASS + 1 XFAIL on MC, on MD, and implicitly inside the full `ctest`), so the
citation is corroborated rather than merely trusted.

⚠ **NOT cited, deliberately**: Track F′'s `shared vacuity.py` row. Both tracks recorded it as
NOT CITED (bd `jdec`: hardcoded to a dead worktree, matches only handle-form negatives, and even
repaired prints `checked 0`, which PROTOCOL S3 calls a HOLE not a pass). This gate does not upgrade
that to a pass either.

### Counts, re-measured at this gate (CLAUDE.md's block updated to match)

```
ctest --test-dir build -N                       442
ctest -N -R '^e2e-'                             432
ctest -N -R '^e2e-slice-'                       381
ctest -N -R 'twin-identical'                     40
ls ir-pass/test/*.ll | wc -l                   2047   <-- the ONLY one that moved (was 1994)
ls tests/e2e/*.expected.log | wc -l             383
twin matrix: 309 (expected) + 29 (quarantine) = 338 cells
```

⚠ Only the fixture count moved, and that is a check rather than a remark: neither track touched
`tests/`, so a change in the e2e, golden or twin-matrix rows would have been a finding.

---

## What this gate did NOT do — ABSENCES, stated as absences

* **It did not re-derive `c1` / `c2`** (R-2's composed accepts). It records them, files them on
  bd `oej0`, and states their status: **cleared by measurement, by no review.**
* **It did not build BASE_F or P_ALONE.** Per-track attribution is JOINED from the Rule-13 round's
  four-binary file, whose ORACLE column this gate re-measured independently as the join's
  precondition (2046/2047 agree; the one exclusion is this gate's own cosmetic newline).
* **It did not construct R-5's residual** — a round-2-only-tainted theta in the gap. The source
  paragraph says "probably empty", names what is not covered, and carries the trigger. Nobody has
  built the input.
* **It did not write a fixture distinguishing `availableAtAnF2Slot`'s two clauses** (the MC/MD hole).
  The header argues the distinguishing shape is unreachable for three independent reasons, and
  Rule 12 can supply no fixture for an unreachable shape.
* **It did not attack** a multi-latch or irreducible loop body against the back-edge clause, the
  512-block budget's decline path, or the `declineClassicalMuxes` route the reviewer named as where
  it would attack next. Those remain open in bd `hlhh`.
* **It added no e2e slice and no decline.** R-1 is filed, not fenced, deliberately.
