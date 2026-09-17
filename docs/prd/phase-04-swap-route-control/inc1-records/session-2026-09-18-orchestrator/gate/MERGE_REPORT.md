# MERGE REPORT — session 2026-09-18 GROUP GATE (Group 1 + Track D)

> ⚠ **THIS FILE RECORDS TWO PASSES AND NEVER MERGES THEIR NUMBERS.**
> **PASS 1** = `main` + Group 1 `f1a7857a` + Track D `460ecefe`, SUBJECT `96d74fe6008133b8`.
> **PASS 2** = PASS 1 + the Group-1 fix for `review_r13_group1` F-1, at its own hash.
> A number in one pass is never quoted for the other. PASS 2 begins at §10.

---

# PASS 1 — SUBJECT `96d74fe6008133b843cf5fc5f9ab2f3f96fb4f7986f905676044ce39e676a4bb`

`libCQPass.so` `f9acb293a76af15a09a65b7f8c7ff69ef525849da48e5a897dc330e22ca77a74`
ORACLE `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` — re-verified on disk
**twice** during the gate (open and mid-run), unchanged, equal to `PROTOCOL.md`'s block.

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

## 8. `cq-opt-equivalence-full`

*(see GATES.md for the verbatim line)*

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
