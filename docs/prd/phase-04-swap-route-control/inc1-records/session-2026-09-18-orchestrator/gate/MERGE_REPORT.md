# MERGE REPORT — session 2026-09-18 GROUP GATE (Group 1 + Track D)

> ⚠ **THIS FILE RECORDS TWO PASSES AND NEVER MERGES THEIR NUMBERS.**
> **PASS 1** = `main` + Group 1 `f1a7857a` + Track D `460ecefe`, SUBJECT `96d74fe6008133b8`.
> **PASS 2** = PASS 1 + the Group-1 fix for `review_r13_group1` F-1, at its own hash.
> A number in one pass is never quoted for the other. PASS 2 begins at §10.

---

# PASS 1 — SUBJECT `96d74fe6008133b843cf5fc5f9ab2f3f96fb4f7986f905676044ce39e676a4bb`

`libCQPass.so` `f9acb293a76af15a09a65b7f8c7ff69ef525849da48e5a897dc330e22ca77a74`
ORACLE `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` — re-verified on disk
**three times** during the gate (at open, mid-run, and after both sweeps), unchanged every time and
equal to `PROTOCOL.md`'s block. The SUBJECT hash was re-verified with it at the end, so **both
sweeps provably ran against the intended binaries from first row to last.**

## 1. The merge

| step | commit | conflicts |
|---|---|---|
| branch `session-2026-09-18-gate` from `main` `b1b1dc02` | — | — |
| merge 1 `tu9q-hoisted-template` `f1a7857a` (Group 1: bd `6n1s` + P1 + P2) | `c81f70e0` | **0** |
| merge 2 `drbq12-hoisted-compare-p4` `460ecefe` (Track D: bd `drbq.12`) | `bba8ecaa` | **0** |

⚠ **`tests/e2e/CMakeLists.txt` auto-merged with no conflict**, against the brief's expectation of a
tail-anchor collision. **An auto-merge is not evidence of a correct union**, so the three post-union
checks below — not the absence of a conflict — are what establish it.

**Post-union checks (PROTOCOL S1):**

| check | result |
|---|---|
| duplicate `add_test` names | **EMPTY** |
| `grep -c '^add_test(NAME'` | **452**, and it *reconciles*: base `cff8f7ac` **447** + Group 1 **+2** + Track D **+3** |
| `tail -3` — sweep still LAST | ✔ `get_property(_E2E_ALL_TESTS …)` / `set_tests_properties(…)` |

**Merge integrity beyond the checks the brief asked for:**

* `git diff tu9q-hoisted-template HEAD -- LoopLowering.cpp Uncomputation.cpp LoopPlan.h` → **EMPTY**
* `git diff drbq12-hoisted-compare-p4 HEAD -- ArmClassify.cpp` → **EMPTY**
* Track D's `460ecefe` verified **records-only, not assumed**: no diff over `ir-pass/src`
  `ir-pass/include`, and **0 non-comment lines** over `ir-pass/test`. Its `5ee9d144` gate lines
  therefore remain facts about the shipped lowering.

**Combined pass-source surface:** 4 files, **+852 / −78** — `ArmClassify.cpp` (D, +374/−…),
`Uncomputation.cpp` + `LoopLowering.cpp` + `LoopPlan.h` (Group 1). Disjoint by track, as scoped.

## 2. L8 duplicate-body scan

**2095 fixtures scanned, 9 duplicate-body groups (all pre-existing), 0 CONTRADICTORY-VERDICT
groups**, none involving either branch's 13 new fixtures. Matches `trackT2`'s own 9-at-2086.

⚠ **The scanner was self-attacked in both directions before it was believed** (L10): it exits rc=2 on
an empty universe rather than printing a clean `0 duplicates`, and it returns rc=1 naming the group on
a planted same-body / opposite-verdict pair.

⚠ **One EMPTY-BODY module flagged and adjudicated a NON-finding:**
`lowering_predmux_purecallee_deep_chain.ll` has no IR body because it is a **generator** fixture whose
module is built at RUN time by `Inputs/gen_deep_pure_chain.py 60000`. Not the
`empty-module-accepts` vacuity trap.

## 3. THE COMPOSITION MEASUREMENT (R20) — **D LANDS**. Full record: `COMPOSITION.md`

All five conditions R20 required of `dD1`, each measured on the combined binary:

| # | condition | measured |
|---|---|---|
| 1 | ACCEPTS | `opt` exit 0 (ORACLE: exit 1, `condition predates a non-diagonal gate`) |
| 2 | hoisted rail DISCHARGED before the Ry | `and_i32_hl_unc(h2,h0,1)` + `cqrt_free(h2)` **strictly before** `cqrt_ry_i32(h0,0.9)` |
| 3 | STRICT 2b `0 left dirty` | `2 template rail mint(s) of which **0 left dirty**`, `0 violation(s)` |
| 4 | stderr 0 bytes | **0 bytes** — no live-record warning |
| 5 | multiset == `dD4`'s | **22 == 22, MULTISET IDENTICAL**, computed mechanically |

`dD1`/`dD4`'s only divergence is ONE `cqrt_free(h4)` position, on a rail **disjoint** from the
`and_unc`/`free(h2)` pair it crosses — they commute, so the unitary is identical.

**And the result neither track could claim alone:** `dD5`, F-1's **pre-existing** reference, went
`1 left dirty` + warning on the ORACLE *and* on Track D's binary, and is **`0 left dirty`, stderr 0
bytes** here. **The composition closes a pre-existing member of bd `s82e`'s class.**

Group 1's own probes: `a1_apost` rolled **28 == 28** twin, MULTISET IDENTICAL. The `6n1s` triple:
`t5j` now **4 `ashr` mints / 4 `_unc` / 4 `cqrt_free`, `0 left dirty`** (ORACLE: 4/0/0);
`t5i` and `t5k` **UNMOVED**.

⚠ **The brief's predicted `A→D` on `t5j` did not occur and should not have** — `6n1s`'s fix
DISCHARGES rather than declines. The expectation was wrong, not the result.

### 3a. The g8 triple (coordinator addendum) — **F-1's P1 is LIVE on the combined binary**

| probe | result on `96d74fe6` |
|---|---|
| `g8_arm_use_derived_owned_rot` | **ACCEPT exit 0, warning only**, 19 lines, `4 template rail mint(s) of which **2 left dirty**, **0 cqrt_free site(s)**`, **0 `_unc`**; four `cq_template_ashr_i32_hl(h0,k)` copies alive across `cqrt_ry_i32(h0,0.9)`, then `cqrt_measure_i32(h0)` |
| `g8a` (one-token delta) | ACCEPT, `3 … of which **0 left dirty**`, 2 free sites — **moves** ⇒ the discriminant is "the arm mints an INTERIOR rail" |
| `g8k` (marking refused) | **DECLINE**, `rolled body leaks a rail entangled with a rotated register` ⇒ **the marking is the door** |

All three reproduce the review's numbers character-for-character. **The P1 is not a composition
artefact and Track D does not touch it.**

## 4. Full `ctest -j6` — **461/462 in 740.30 s**, the single failure is the twin matrix

```
99% tests passed, 1 tests failed out of 462
Total Test time (real) = 740.30 sec
The following tests FAILED:
	318 - e2e-loop-twin-matrix (Failed)
```

Run at load **28 → 316 → 5** (it is its own load: `-j6` plus the matrix's internal workers);
**quoted with its load per Rule 19 and not comparable with a quiet-box figure.**
Announced in `$SES/GATES_INFLIGHT.md` at 14:48 before starting; **no IN-FLIGHT line existed at this
hash** — the combined binary did not exist until this agent built it, so no gate here can be a second
run of another owner's. ctest PID **35379** recorded at launch (never `pkill` by pattern).

**Both tracks' new e2e entries passed**, including Group 1's
`e2e-slice-loop-hoisted-chain-exit-discharge{,-unrolled}` and Track D's
`e2e-slice-control-inplace-ry-inloop-hoisted-cond{,-twin,-twin-identical}`.
`e2e-loop-twin-quarantine-selftest` **Passed 1.58 s**.

## 5. The twin matrix — RED, and it CANNOT be regenerated to green. Full record: `MATRIX_ADJUDICATION.md`

`462/462 Test #318 ***Failed 424.44 sec` — **382 cells**, FAILED (95) report entries = **56 distinct
cells**, every one adjudicated in writing.

| bucket | cells | reading |
|---|---|---|
| **A** `HARNESS-ERROR` — rolled-side stage 2b STRICT reports `UNPROVEN U3-extern-rail` | **24 + 1 control** | the INSTRUMENT met Group 1's P2 and the instrument loses. Every one has `0 violation(s)` and `0 left dirty` |
| **A.1** of which the six class-A `oder` cells, re-measured BY HAND | 6 | **bd `1m5p` FIXED IN SUBSTANCE**; positional residue only |
| **B** NEW, UNQUARANTINED `TRACE-DIVERGENCE` | **15** | **Track D's P4 widening** — exactly `MERGE_FILINGS.md` F-10's prediction |
| **C** `DECLINE-BOTH` → `ACCEPT-IDENTICAL` | **11** | pure win, byte-identical |
| **D** decline-string / one-sided decline | 5 | safe direction |
| **E** nested (classes D/E), class-B `oder`, 3 of 4 controls | **0 moved** | stable |

**Three independent blockers make green unreachable, each a deliberate refusal in the instrument's
own contract:** a `HARNESS-ERROR` is not a verdict there is anything to record; a **pinned boundary
control moved** (`q_armoncond`) and *"`--regenerate` does NOT rewrite these — moving a control is a
human decision"*; and `EXPECTED_HEADER` forbids recording `TRACE-DIVERGENCE` while the quarantine tool
*"can neither add nor remove a cell."* **I did not regenerate, did not re-pin, and added and deleted
no quarantine block.** `tools/loop_twin_matrix.expected.txt` and `.quarantine.txt` are
**byte-unchanged on this branch.**

⚠ **The "QUARANTINE STALE — REMOVE IT" message printed for the six class-A cells is an ARTIFACT** of
the 2b abort preempting the trace comparison, and acting on it would delete the only six cells that
watch class A **on the run in which class A changed**. Measured by hand instead (2b informational):
all six are **line-count-equal, MULTISET-EQUAL, `0 left dirty`, still positionally divergent**, with
`cq_template_sqrt_f64_unc` now on BOTH sides where the ORACLE had 0 vs 1. Correct action is
**RE-PIN, not remove** — and it is blocked behind the boundary control.

**F-9 is answered: 0 of Track V's 8 nested cells moved.** Group 1's P2 does not reach the
nested-loop class.

## 6. Tree counts, measured at this hash (`ctest -N`, `ls`, `grep`)

| metric | merged | main `b1b1dc02` | delta |
|---|---|---|---|
| `ctest -N` total | **462** | 457 | +5 |
| `^e2e-` | **452** | 447 | +5 (G1 +2, D +3) |
| `^e2e-slice-` | **394** | 390 | +4 (2 each) |
| `twin-identical` | **44** | 43 | +1 (D) |
| `ls ir-pass/test/*.ll` | **2095** | 2082 | +13 (D 9, G1 4) |
| `ls tests/e2e/*.expected.log` | **396** | 392 | +4 |
| `grep -c '^add_test(NAME'` | **452** | 447 | +5 |
| matrix cells | **382** = 345 expected + 37 quarantined | 382 | 0 |

⚠ CLAUDE.md's block (442 / 432 / 381 / 40 / 2047 / 383 / 338) is stale by more than this merge;
`MERGE_FILINGS.md` F-3 already routes that to the closing docs pass.

## 7. Gate hygiene / §6.1 redundancy report

* Gates **RAN** by me, each with no matching IN-FLIGHT line at hash `96d74fe6008133b8` when it
  started (the hash is unique to this agent's build): full `ctest -j6`, the twin matrix (inside it),
  the corpus sweep, the per-probe composition measurements.
* Gates **CITED**: none. No prior line exists at this hash.
* `cq-opt-equivalence` (the **sampled** `--stride 8` entry) ran inside the suite: **Passed 97.16 s**.
  The **full** sweep is §8.
* **0 gates run twice at one hash.**

## 8. `cq-opt-equivalence-full` — **2095 fixtures, 0 mismatches**

```
[100%] cq-opt vs stock opt: full all-fixture equivalence sweep
cq_opt_equivalence: compared 2095 fixtures, 0 mismatch(es)
```

Exit 0, **3 m 36 s** (15:28:20 → 15:31:56). Licensed by the brief because **Track D moved an analysis
site and Group 1 moved a discharge placement** — either alone would license it. It compares stdout,
stderr **and** exit code for every fixture under stock `opt -load-pass-plugin` versus `cq-opt`.

⚠ Its output begins `Built target cq-opt` / `Built target CQPass`. **Those were up-to-date no-ops, not
a relink** — verified by re-hashing immediately after: `cq-opt` `96d74fe6008133b8…` and `libCQPass.so`
`f9acb293a76af15a…`, both **unchanged**. This matters because Rule 19 forbids relinking under a
running measurement and because every gate line in `GATES.md` is keyed to that hash; had it moved,
those lines would have needed re-taking.

## 9. Corpus sweep, ORACLE `9bd01598` vs SUBJECT `96d74fe6` — **6981 rows, 137 movers, 0 unattributable, A→D = 0**

Ran 15:03:44 → 15:27:27 (**23 m 43 s**) at `-P 3`, over `ir-pass/test/*.ll` **plus every session
dir's `track*/probes` and `review_*/probes`** (worktree) **plus this session's main-checkout-only
probe dirs** (`review_r13_group1`, `review_r13_loopconv`, `review_r13_trackD`, `trackX`, `wave0`).
Both binaries run on the **same stage-1 file** per row, so the md5s are comparable **within** a row
(PROTOCOL S3). Output: `gate/corpus_96d74fe6.txt`.

**6981 rows written** (the 7012-entry list minus 31 `*_lib.c` / `lib*.c` halves swept with their
caller); **6972 scored**, 2 `CLANGERR`, 7 `EMPTYMOD` — the last of these is the
`empty-module-accepts` trap, reported as its own bucket and **never scored as ACCEPT**.

| bucket | rows | attribution |
|---|---|---|
| **A→D** | **0** | ⚠ the safety property: **this landing introduces no new decline anywhere in the corpus** |
| **D→A** | **79** | **Track D** — *all 79*, re-measured in full (below) |
| **A→A, md5 changed** | **32** | **Group 1's P2** — every one a named customer (below) |
| A→A, stderr changed | 5 | Group 1 (the live-record warning disappearing as rails get discharged) |
| **D→D, decline STRING changed** | **14** | Track D — module still declines, at a **later** fence |
| D→D, stderr-only changed | 7 | ditto |
| **TOTAL MOVERS** | **137** | **0 unattributable** |

### 9a. The D→A attribution is RE-MEASURED, not read off the sweep

⚠ The sweep row stores `cut -c1-200` of the whole error **line**, and a long probe path eats the
message — leaving fragments like `cq controlled lowering: condi`, which is a prefix of **three**
different real strings (`condition predates…`, `condition measured before…`, `condition data use…`).
Attributing from the fragment would have been a guess. So every D→A mover was **re-run on the ORACLE
and its diagnostic read in full** (`gate/probes/attribute.py`):

```
D->A movers: 79
    75  cq controlled lowering: condition predates a non-diagonal gate
     4  cq controlled lowering: control flow
UNATTRIBUTABLE to Track D's two expected strings: 0
```

Both strings are exactly the two the brief names for Track D. **Zero movers in the accept direction
belong to anything else.**

### 9b. The A→A md5 movers are all Group 1's

The 32 include the 5 `ir-pass/test` fixtures Group 1 converted or added
(`control_phase_kickback_inloop_reject_hoisted_temp`,
`…mixed_preheader_add_outofplace_leak_control`, `loop_pairing_accept_hoisted_chain_exit_discharge`,
`loop_pairing_accept_twoblock_body_straddle`, `loop_pairing_reject_root_hoisted_template_data`),
Group 1's own named P2 customers from an earlier session
(`trackT/probes/adv/b1_mixed_nonlive`, `r2_two_functions` — the two its `GATES.md` names), its own
`trackT2/probes/*` (`a1_apost`, the two `m_none_oder_*`, `t5h`, `t5j`, `p2d`, `p2g`, `g1`, `g3`), and
**`trackD2/probes/dD5`** — the pre-existing bd `s82e` reference that Group 1's P2 discharges (§3).

### 9c. The PROTOCOL S3 blind spot was closed, and it found 14 rows

The shared `corpus.sh` tag regex renders the whole `cq_measure_<sfx>` family as an empty `D:`, so a
decline→decline string change inside it is **invisible**. This sweep records the **FULL first
`error:` line plus a sha-256 of the WHOLE stderr**, so a D→D move is visible either way. It found
**14 string changes and 7 stderr-only changes** — every one in the **safe** direction (the module
still declines, at an earlier/different fence, e.g.
`condition predates a non-diagonal gate` → `value-arm swap-route` or
`control flow inside a loop body`), which is Track D's widening letting a module past the condition
fence only for a later fence to refuse it.

---

# PASS 2 — SUBJECT `07d937842bfb5135fe068d1b9bfb1b2cd501e67c152bf4932d9408d5c9fed6b4`

`libCQPass.so` `19dcfde08ffbb69c2c0df50ef5ac318e925288ff37c4b53e24dcc472a2b91040`.
ORACLE unchanged: `9bd01598d574b344…`.

> ⚠ **PASS 2's HASH IS NOT GROUP 1's `df2445fcaf82cf00`, AND THAT IS CORRECT.** Group 1 built that on
> *their* branch, which carries no Track D. Mine is the COMBINED binary — Group 1 (P1+P2+fix) **plus**
> Track D's `ArmClassify.cpp` **plus** Track C. **Consequence, and it is the protocol's whole point:
> Group 1's gate lines at `df2445fcaf82cf00` are NOT facts about this binary, so every number below is
> RE-MEASURED here, never cited from their hand-off.**

## 10. The pass-2 merges — five, zero conflicts

| # | commit | branch tip | what |
|---|---|---|---|
| 1 | `c81f70e0` | `f1a7857a` | Group 1: bd `6n1s` + P1 + P2 |
| 2 | `bba8ecaa` | `460ecefe` | Track D: bd `drbq.12` |
| 3 | `5822ed42` | `22a0ab11` | **Group 1's F-1 fix** — conjunct (1)'s suppression becomes a PROMISE VERIFIED after uncompute |
| 4 | `7fd47544` | `26dff90e` | **Track C** — stage 2b (T4) proves the loop-exit discharge |
| 5 | `a506728d` | `592fa164` | Track D records (`RZ_CELLS.md`), **records-only** |

**Post-union checks, re-run after every merge and again after the G-4 edit:** 0 duplicate `add_test`
names · **449** `add_test` (452 − Group 1's 3 unregistered; their branch's 449→446 differs by exactly
Track D's +3, so it reconciles) · sweep still LAST.
**L8 duplicate-body scan:** 2099 fixtures, 9 pre-existing groups, **0 contradictory-verdict**.
**Counts:** fixtures 2095 → **2099** (+4 new fixtures); goldens 396 → **394** (−2 deleted).

⚠ **A SELF-CORRECTION, recorded because it is the failure mode this gate exists to catch.** Before
merging Track D's records-only tip I ran a check that printed `[empty = safe]` — from an
**unconditional `echo`**, next to a diff taken in the wrong basis that actually listed 30 files. The
label was meaningless. I re-verified properly (`HEAD~1..HEAD`): **610 insertions, 0 deletions, and
nothing under `ir-pass`/`include`/`runtime`/`tools`/`tests`** — records-only confirmed, nothing
reverted. Same species as the blast detector's false CLEAN: *an instrument that reports a pass it did
not measure.*

## 11. G-4 — Track C PROVES it; the `--allow-unproven` exception is REMOVED

Run first, because it is cheap and it gates a `CMakeLists` edit.

| | STRICT stage 2b on `slice_loop_hoisted_chain_exit_discharge.c` |
|---|---|
| **BEFORE** (`96d74fe6…`, pre-(T4) checker) | `1 verified, 0 violation(s), 3 unproven`, **rc=1** — 3× `U3-extern-rail`: `%h_intr` by `cq_template_sqrt_f64`, `%h_op` by `…fadd_f64_hl`, `%h_cast` by `…sitofp_i32_to_f64` |
| **AFTER** (`07d93784…`, (T4) checker) | **`4 verified, 0 violation(s), 0 unproven`, rc=0** |

**All three `U3-extern-rail` unprovens are proven, so the flag came off**, together with its reason
paragraph (replaced by a BEFORE/AFTER block at the site). Actual flag count **5 → 4**, and all four
survivors are the `dtzb whole-loop reverse-play` loop-break entries — **so CLAUDE.md's "Four
`e2e-slice-loop-break*` entries pass `--allow-unproven`" sentence is TRUE again** and filing G-4 is
resolved rather than carried. `ctest -R '^e2e-slice-loop-hoisted-chain-exit-discharge'`: **2/2 Passed**
(1.09 s + 1.06 s) running STRICT.

## 12. The g8 family — F-1's P1 is CLOSED, and its controls are unmoved

| probe | PASS 1 (`96d74fe6`) | **PASS 2 (`07d93784`)** |
|---|---|---|
| `g8_arm_use_derived_owned_rot` | ACCEPT, `2 left dirty`, `0 free`, warning only | **DECLINE exit 1** — `cq loop lowering: rolled body leaks a rail entangled with a rotated register` |
| `g8b_interior_gate_in_header_control` | (not run) | **DECLINE exit 1**, same string |
| `g8a_arm_measured_directly_control` (control) | ACCEPT, `0 dirty` | **ACCEPT** — unmoved |
| `g8k_arm_use_derived_unmarked_control` (control) | DECLINE | **DECLINE** — unmoved |

**The two shipped goldens my blast radius found:**

| slice | PASS 2 |
|---|---|
| `slice_control_inplace_ry_loop_leak.c` (ROLLED) | **DECLINE exit 1** — the Rule-8 wrong unitary no longer compiles |
| `…_unrolled.c` (the TWIN) | **ACCEPT exit 0** — ⚠ **the identical hazard still compiles, loop-free.** New P1, filed by Group 1 |

⚠ **The blast-radius finding is HALF closed.** G-6 reported 2 shipping goldens carrying the hazard;
the rolled one now declines and is pinned by `loop_leak_dephase_reject_inplace_ry_loop_leak_slice.ll`,
and **the unrolled one still compiles it**. Both are unregistered and both goldens deleted, so the
surviving hazard is now observed by **no gate at all** — which is the *correct* disposition (pinning
it would pin a known-wrong stream, exactly what CLAUDE.md forbids for the three `*_leak_control.ll`
fixtures) but means the P1 is **unwitnessed until its fence lands**. The `.c` is kept with a
conversion header carrying an L8 retirement trigger.

⚠ **One limit of my own G-6 report is now CLOSED in the strengthening direction.** I wrote that the
detector *"cannot see whether `cqrt_tape_write_i32` has measurement-like semantics that would collapse
`h3`; if it does, the two hits weaken."* Group 1's fixture header answers it: the tape write **COPIES
and does NOT collapse**, and *"only the tape-write RESULT (h4, h7) is an `OutputRails` member; its
OPERAND h3 is an ordinary interior template rail, so 'it is the program's own output' does NOT excuse
it."* The hits were real.

## 13. The composition SURVIVES the fix — and Track C improves it

| probe | PASS 1 | **PASS 2** |
|---|---|---|
| `dD1` | exit 0, stderr 0 B, `0 left dirty`, `1 verified, 0 violation(s), **1 unproven**`, 22 lines | exit 0, stderr 0 B, `0 left dirty`, **`2 verified, 0 violation(s), 0 unproven`**, 22 lines |
| `dD4` (twin) | `0 dirty`, `3 verified, 0 unproven`, 22 lines | `0 dirty`, `3 verified, 0 unproven`, **22 lines** |
| `dD5` (pre-existing reference) | exit 0, stderr 0 B, `0 dirty`, **1 unproven** | exit 0, stderr 0 B, `0 dirty`, **`2 verified, 0 unproven`** |
| `a1_apost` vs twin | 28 == 28, MULTISET IDENTICAL | **28 == 28, MULTISET IDENTICAL** — unmoved |

**R20's verdict holds after the fix: D still lands.** And the `1 unproven` residue I had to caveat in
pass 1 as "the instrument's stream model, not the rail" is now **0** — Track C's (T4) rule proves it,
so the caveat is retired rather than repeated.

**The `6n1s` triple:** `t5j` exit 0, `3 template rail mint(s) of which 0 left dirty`, 2 unproven, 26
lines, still warning-only · `t5i` exit 0, stderr 0 B, **0 unproven**, 32 lines · `t5k` DECLINE. All
three unmoved in verdict from pass 1.

## 14. The owner's loop program (coordinator addendum) — UNCHANGED, and the README is about a different file

`example/grover/grover_oracle_uncompute.c` (**local-only, untracked; `example/` not edited**):

```
opt exit=1
error: example/grover/grover_oracle_uncompute.c:91:15: in function main i32 ():
       cq controlled lowering: control flow inside a loop body under quantum control
CQ_CTRL_DBG: railbank [Bank] cells=3 abi=i8 trips=3 at: store i8 %cq.bank.stg, ptr %cq.bank.addr…
CQ_CTRL_DBG: decline [control flow inside a loop body] at: %24 = icmp sgt i32 %23, 2
```

**Same string and same site (91:15) as the 2026-09-17 measurement on `9bd01598` — UNCHANGED** by any
of this session's four landings. The rail bank IS recognised first (`cells=3 abi=i8 trips=3`); the
decline then fires at the body's `icmp sgt`.

⚠ **`example/grover/README.md` says this file "is now written as a `for` loop and it RUNS" (bd
`8h7d.5`). That is NOT a contradiction of the measurement above — it is about a DIFFERENT PROGRAM.**
The owner's file is untracked and has since gained a rail bank the README never mentions; the README
describes the committed history of that *filename*. **Do not read the README's tick as a claim about
the file on disk today.**

**The hand-unrolled twin:** `grover_loop_frontier.c` is NOT it (the README calls it the frontier
marker, and it declines). The README names the real pair —
`tests/e2e/slice_control_grover_loop_derived{,_unrolled}.c` — and both **ACCEPT at exit 0 with
45 == 45 trace lines**, `0 left dirty`, `0 unproven` (rolled `5 verified`, unrolled `10 verified`).
⚠ That pair is the twin of the README's version, **not** of the owner's current local file.

## 15. Suite / matrix / equivalence at the pass-2 hash

### 15a. Full `ctest -j6` — **458/459 in 1059.19 s**, the one failure is the twin matrix

```
99% tests passed, 1 tests failed out of 459
Total Test time (real) = 1059.19 sec
The following tests FAILED:
	318 - e2e-loop-twin-matrix (Failed)
```

Started at load **7.09** and ran to **33** — a quieter box than pass 1's, and quoted with its load
per Rule 19. Announced in `GATES_INFLIGHT.md` before starting; no IN-FLIGHT line existed at this hash.
**Run ONCE**, as the plan requires. Both selftests green inside it:
`e2e-loop-twin-quarantine-selftest` **Passed 1.23 s**, `e2e-free-pairing-selftest` **Passed 2.00 s**.

⚠ **Track C's final tip `d9b0f49f` did NOT require a re-run.** I merged `26dff90e`; the delta to
`d9b0f49f` leaves `tools/free_pairing_check.py` **byte-identical** (`7ee74c6c2b257d2c` in both) and
changes only `free_pairing_check_test.py` (+29, one more mutant) and records. **So the running suite
was already measuring C's final checker** — the only entry the delta can witness is
`e2e-free-pairing-selftest`, which is a single `-R`. I deliberately held that merge while the suite
ran rather than editing a script a running measurement imports (this session's own F-8 lesson, and
Track C's own self-disclosure).

### 15b. `cq-opt-equivalence-full` — **2099 fixtures, 0 mismatches**

Exit 0, **2 m 53 s** (17:02:57 → 17:05:50). **RE-RUN rather than cited**: Group 1's fix added no new
decline string, but it and Track D both moved ANALYSIS SITES, which the plan's own rule licenses.
Hash re-verified immediately after: `07d937842bfb5135` — unchanged, so the line is a fact about the
binary the rest of this section describes.

### 15c. The twin matrix — RED, adjudicated in full: `MATRIX_ADJUDICATION.md` (PASS 2)

**The cause of pass 1's red is GONE**: `HARNESS-ERROR` 24 → **0** and `QUARANTINE STALE` 6 → **0**,
because Track C's (T4) proves the loop-exit discharge. **bd `1m5p` class A is FIXED and the instrument
now says so itself** — all six `oder` cells report rolled `(5, 5, 7)` == unrolled `(5, 5, 7)` at equal
line counts, where the ORACLE was `(4, 4, N)` vs `(6, 6, N)` with the rolled side deficient.

What is red now: **49** verdict changed · **33** genuinely unquarantined divergences (two mechanism
groups, both argued) · **6** `QUARANTINED SIGNATURE CHANGED` (the class-A cells — a refresh) · **1**
boundary-control re-pin. Greening it is one large deliberate operation — 33 hand-authored blocks each
needing a bd id, a refresh, a re-pin and a regenerate — and **I did not perform it**;
`expected.txt`/`.quarantine.txt` are byte-unchanged on this branch.

⚠ **Two instrument defects of MINE, both self-caught:** my matrix parser labelled the six class-A
cells `(not quarantined)` (it missed the matrix's second line, `QUARANTINED SIGNATURE CHANGED`), and
`PASS2_PREP` (B)'s retirement trigger compared **my** tool's diff signature against **the matrix's**
pin — different renderings, never comparable, so the trigger misfired. Re-measured, the control's
divergence is byte-identical to pass 1, so the adjudication stands and the value to pin is the
matrix's `d81485c481c5ad07`, never my `3fa9d45cd851c1b3`.

### 15d. Corpus re-sweep + blast-radius re-scan — **IN FLIGHT, recorded as an ABSENCE with their partial readings**

Both were launched at the pass-2 hash and were **still running when this record was written**. Per
the protocol an unfinished gate is recorded as an absence — **never a green, never a red** — so what
follows is a partial reading with its denominator, not a result.

**Corpus sweep** (ORACLE `9bd01598` vs PASS-2 `07d93784`), list rebuilt at **7041 rows** (pass 1 was
7012; +29 from the four landings' new fixtures and probe dirs). At **2215 of 7041 scored**:

| bucket | partial | attribution so far |
|---|---|---|
| **A→D** | **2** | **both are Group 1's OWN new decline fixtures** — `loop_leak_dephase_reject_arm_minted_interior_rail.ll` and `loop_leak_dephase_reject_inplace_ry_loop_leak_slice.ll`, each on `cq loop lowering: rolled body leaks a rail entangled with a rotated register` (the **existing** s82e string — the fix adds none). The intended direction of the F-1 fix, and its own pins |
| D→A | 9 | Track D's P4 |
| A→A md5 | 6 | Group 1's P2 |
| A→A stderr | 1 | warnings disappearing as rails discharge |
| D→D | 0 | — |

⚠ **This is 31 % of the corpus. The full attribution — and any unattributable mover — is NOT
established**, and the pass-1 figure (6981 rows, 137 movers, 0 unattributable, A→D 0) must **not** be
quoted for pass 2: different binary, different denominator.

**Blast-radius re-scan — COMPLETE, not an absence.** Scoped to the **386 shipped e2e slices** (the
decisive set — only these have goldens); **383 scored** in **11 m 30 s** (3 skipped as `*_lib.c`
halves swept with their caller).

| verdict | PASS 1 (`96d74fe6`) | **PASS 2 (`07d93784`)** |
|---|---|---|
| CLEAN | 223 | **223** |
| DIRTY-NO-TRAILING-GATE | 152 | **152** |
| DECLINE | 6 | **7** |
| **G8-SHAPE** | **2** | **1** |

**The two numbers that moved are the same event seen twice**: `DECLINE` 6 → 7 and `G8-SHAPE` 2 → 1,
because `slice_control_inplace_ry_loop_leak.c` left the hit set by becoming a DECLINE. The single
survivor is `slice_control_inplace_ry_loop_leak_unrolled.c`, the loop-free twin — **the cell §12
already reports, not a new hit**, and nothing else in the shipped set acquired the shape.

⚠ So **G-6 is exactly half closed, measured two independent ways** (directly in §12 and by this
sweep), and the surviving half is a slice that is now **unregistered with its golden deleted** — no
gate observes it until the P1's fence lands.

The completed blast output is `gate/blast_g8_07d93784_e2e_complete.txt`; the corpus sweep's partial
is `gate/corpus_07d93784_partial.txt` so the next agent resumes rather than restarts.
