# CLOSING REPORT — session 2026-09-18 (orchestrator; started 2026-09-17 11:30 on `main` `cff8f7ac`)

Purpose (owner instruction 2026-09-17): clear the debt in front of bd `zujr`. Read with `DECISIONS.md`
(Q1–Q4, O1), `ROUTING.md` (R14–R21), `MERGE_FILINGS.md` (F-1…F-15), `gate/FILINGS.md` (G-1…G-12) and the
per-track records. Every number below is hash-keyed in `GATES.md` or a track's `GATES.md`.

## 1. What landed on `main`

| landing | commit(s) | what |
|---|---|---|
| Track V — bd `vsr6` | `cc4f5eae` + `b1b1dc02` (ff) | the NESTED-LOOP twin-matrix axis: 359 → 382 cells; 0 MISSED over 13 mutants; found 8 divergences on `main`'s own compiler (classes D bd `3n29` P1 / E bd `eigw` P2) |
| Group 1 — bd `tu9q` hoisted-template half (P1+P2), bd `6n1s`, bd `1m5p` | `014b4381` (merge of `tu9q-hoisted-template` @ `22a0ab11`) | the real MULTIPLICITY test (P1), the LOOP-EXIT anchor for a rail minted outside its consumer's loop (P2 — closes `1m5p`'s six class-A cells and the live `a1_apost` Rule-8 over-accept), the multi-block marked-body fix + the `g8` BACKSTOP `declineUndischargedMarkedBodyRails` (bd `6n1s`); the rolled shipped leak golden converted to a pinned decline |
| Track D — bd `drbq.12` | same merge (`drbq12-hoisted-compare-p4` @ `592fa164`) | P4's unconditional cross-block decline → `crossBlockCompareMintable` (wire-scoped gap walk shared with P′); 87 D→A movers, 0 A→D; 32 row-W twin halves + 3 Rz cells now ACCEPT; the dtzb fence measured as an over-decline and removed |
| Track C — bd `lc6b` | same merge (`freepair-loop-exit-discharge`) | stage-2b rule **(T4) `loop_exit_discharge`** — the checker proves the discharge P2 emits (8 of 9 conjuncts mutant-killed); `--allow-unproven` back to four entries; 24 HARNESS-ERROR matrix cells verdict for the first time |

**NOT landed, deliberately:** P0+P3 of `tu9q` (branch `tu9q-p0-p3-wip` @ `30b80d7f`; DECISIONS Q4 — six
obligations, chief among them that it retires `declineRound2FalsifiedRailGrants`' ONLY fixture); Track X
bd `x5fp` (branch `x5fp-clobber-per-activation` @ `69414276`; no reachable accept until `ej5w`/`3qlq.6`).

## 2. Wave 0 — the tracker, verified by measurement
CLOSED on the oracle `9bd01598`: `rpkr`, `gfsk`, `rixk`, `19vy`, `1739` (filing corrected), `jdec`, `gzgs`,
`fve8`, `8h7d.6`, `kqqv`, `drln` (C2 split to `xutm`), `tu9q.1` (the break-path witness built by the owed
reviewer), `vsr6`. LEFT OPEN with corrected notes: `hlhh` (only half discharged), `58tc` (mis-labelled
in CLAUDE.md, now fixed; source comments still claim closure). Five record corrections from the sweep
are F-1…F-7.

## 3. Rule-13 rounds (five independent, one composition) and what they found
| round | subject | verdict | P1s |
|---|---|---|---|
| `review_r13_loopconv` | the 2026-09-15 conversions + `r3` + `tu9q.1` | FINDING | `6n1s` (multi-block marked body leaks) |
| `review_r13_trackD` | D's P4 widening | CLEAR-WITH-ITEMS | F-1 population widening of `s82e`'s class (`dD1`) — resolved by sequencing D behind Group 1 (R20) |
| `review_r13_group1` | 6n1s + P1 + P2 (+ P0/P3 opinion) | FINDING | `g8` (arm-minted interior rail) — fixed by the backstop; P0+P3 "not landable as it stands" (six obligations) |
| `review_r13_composition` | V + G1 + D + C on one binary | CLEAR-WITH-ITEMS | `5aan` (instrument, latent: switch back edge invisible to the checker) — fixed by Track C before landing |
| merge-and-gate (two passes + final) | the combined binary | GREEN 459/459 | `jlf8` (two shipped goldens pinned a wrong unitary under a green twin gate); `z0cv` (class H: 18 cells first adjudicated — a FOLD, and G-13: Track D ALONE would have left the hoisted chain entangled; Group 1's P2 closes it) |

The hit rate CLAUDE.md Rule 13 records held: **every loop round found a P1 on round 1.** Four of the
session's P1s were found by review, none by a green suite (Rule 2).

## 4. Gate numbers (pass 2 → final; `gate/MERGE_REPORT.md`)
| gate | pass 2 (`07d93784`) | final (`07d93784`, checker `32a8f5eb…`) |
|---|---|---|
| full `ctest -j6` | 458/459 in 1059.19 s (matrix red) | **459/459 in 515.58 s**, load 47→5; matrix `Passed 280.63 s` (312 expected + 70 quarantined = 382) |
| `cq-opt-equivalence-full` | 2099/0 | cited (compiler unchanged) |
| corpus ORACLE-vs-SUBJECT | 7010 rows, 156 movers, 0 unattributable; A→D 6 (all Group 1's `6n1s` fix, one string), D→A 87 (all Track D: 83 `condition predates…` + 4 `control flow`), A→A md5 32 (all P2) | — |
| blast-radius scan (g8 shape) | 383/386 slices, G8-SHAPE 2 → 1 (the loop-free twin, bd `jlf8`) | — |
| composition set | `dD1`/`dD4` 22==22, `dD5` 0 dirty; `g8`/`g8b` A→D; `a1_apost` 28==28; six class-A cells (5,5,7)==(5,5,7) | — |
| primary rebuilt at close | — | **bit-identical**: `07d93784…` / `19dcfde0…` |
| tree counts (`ctest -N`, `ls`) | — | ctest 459 · `^e2e-` 449 · `^e2e-slice-` 392 · `twin-identical` 43 · fixtures 2099 · goldens 394 · `add_test` 449 · `--allow-unproven` 4 usages |

## 5. Beads filed this session (28)
`xutm` `6n1s` `nexz` `vpde` `0kjo` `3n29` `eigw` `hu1c` `jlf8` `tsw0` `lc6b` `svoi` `42yv` `z0cv` `av9x` `uh3j`
`ud0y` `mi43` `ztyc` `5aan` `5j2e` `z8cz` `7xds` (+ `bbu0`/`s82e`/`tu9q`/`x5fp`/`3qlq.6`/`r903`/`a3z7`/
`drbq.12`/`58tc`/`hlhh`/`j5i7` annotated).

## 6. Owner questions carried (DECISIONS.md)
Q1 bbu0 A/B/C (with the addendum that B's "cost" pair was a measured defect); Q2 the wall-5 scoping (the
composition round hand-peeled one wall: item 7 / F-15); Q4 P0+P3 and the fence-subject retirement; O1 the
re-pinned boundary control, flagged for review.

## 7. What the next session must know first
`NEXT_SESSION_PROMPT.md` §0: the loop headline's parts by name, and the owner's program's first two walls
are the SAME construct (the in-loop `_Bool` value arm), with the rail-array wall gone.
