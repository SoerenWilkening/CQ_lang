# THE COMPOSITION MEASUREMENT — session 2026-09-18 group gate (R20)

**Binaries.** ORACLE `9bd01598d574b344…` (re-verified on disk at gate open; character-for-character
the `PROTOCOL.md` block, so nobody rebuilt it). SUBJECT, the COMBINED binary, `cq-opt`
`96d74fe6008133b843cf5fc5f9ab2f3f96fb4f7986f905676044ce39e676a4bb`, `libCQPass.so`
`f9acb293a76af15a09a65b7f8c7ff69ef525849da48e5a897dc330e22ca77a74`.

**Verdict: D LANDS.** All five conditions R20 set are met, each by measurement.

---

## 1. `dD1` — the probe that decided it

`review_r13_trackD` F-1 filed `dD1_hoisted_template_cond_then_ry.c` as a **P1 over-accept**: on
Track D's own binary it went DECLINE → ACCEPT while leaving an entangled which-path TEMPLATE rail
(`cq_template_and_i32_hl(h0,1) -> h2`) alive across a trailing non-diagonal `cqrt_ry_i32(h0, 0.9)`
on the register `h2` copies, with `h0` then measured — Rule 8 dephasing, warning only.

| | ORACLE `9bd01598` | Track D alone `5ee9d144` (from F-1) | **COMBINED `96d74fe6`** |
|---|---|---|---|
| `opt` exit | **1** | 0 | **0** |
| diagnostic | `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | `warning: … non-diagonal gate over a live derived record` | **stderr 0 bytes** |
| template rails | — | `2 … of which 1 left dirty` | **`2 … of which 0 left dirty`** |
| the hoisted rail | — | never `_unc`'d, never freed | **`and_i32_hl_unc(h2,h0,1)` + `cqrt_free(h2)`** |
| …relative to the trailing Ry | — | — | **STRICTLY BEFORE it** |

R20's five required conditions, each measured:

1. **ACCEPTS** — `opt` exit 0. ✅
2. **hoisted rail DISCHARGED before the Ry** — the trace reads
   `… cq_template_and_i32_hl_unc(h2, h0, 1) / cqrt_free(h2) / cqrt_ry_i32(h0, 0x1.ccccccccccccdp-1) /
   cqrt_measure_i32(h0)`. The `_unc` and the free precede the non-diagonal gate. ✅
3. **STRICT 2b `0 left dirty`** — `2 rail mint(s) of which 2 left allocated, 2 template rail mint(s)
   of which 0 left dirty, 2 cqrt_free site(s): 1 verified, 0 violation(s), 1 unproven`. ✅
   ⚠ The `1 unproven` is `U3-extern-rail`, the **instrument's** structural limit, not the rail's:
   `free_pairing_check.py` analyses per straight-line STREAM and a discharge placed at a LOOP EXIT
   is `UNPROVEN` by construction (`trackT2/IMPL_T3.md` §6.3 measures the same asymmetry). `0
   violation(s)`, and the discharge is visible in the trace.
4. **stderr 0 bytes** — no live-record warning. ✅
5. **gate-symbol MULTISET == `dD4`'s** — computed mechanically, not read off a table. ✅

## 2. `dD4`, the hand-unrolled twin — multiset identity, measured

```
A = dD1_hoisted_template_cond_then_ry.c  trace lines: 22
B = dD4_unrolled_twin_of_dD1.c           trace lines: 22
--- multiset diff (empty == IDENTICAL) ---
MULTISET IDENTICAL
--- raw trace diff ---
17d16 < cqrt_free(h4)
19a19 > cqrt_free(h4)
```

22 == 22, multisets identical. The sole divergence is the POSITION of one `cqrt_free(h4)`: the
rolled form frees the second region's flag rail before the `and_unc(h2,h0,1)` + `cqrt_free(h2)`
pair, the twin after it. Those act on **disjoint rails** (`h4` versus `h2`/`h0`), so they commute
and the unitary is the same. This is the same POSITIONAL-only residue `trackT2`'s class-A cells
carry, not a count or content difference.

## 3. `dD5` — the result neither track could have claimed alone

`dD5_loopvariant_cond_oracle_reference.c` is F-1's **pre-existing** reference: the same leak with the
condition made loop-VARIANT so Track D's P4 never fires. It was the evidence that *"the DEFECT is
pre-existing"* — it ACCEPTED on the ORACLE, dirty, with the warning, and Track D's binary reproduced
it byte-for-byte (identical md5).

Measured here:

| | ORACLE `9bd01598` | COMBINED `96d74fe6` |
|---|---|---|
| `opt` exit | 0 | 0 |
| stderr | `warning: … non-diagonal gate over a live derived record` (148 B) | **0 bytes** |
| template rails | `2 … of which **1 left dirty**` | `2 … of which **0 left dirty**` |
| free sites | `1 … 1 verified` | `2 … 1 verified, 0 violation(s), 1 unproven` |
| trace lines | 16 | 18 |

**The composition closes a PRE-EXISTING member of bd `s82e`'s class**, not merely the one Track D's
widening would have added. Group 1's P2 loop-exit discharge reaches the hoisted rail in the
loop-VARIANT spelling too. Neither track could state this alone: on Track D's binary `dD5` is
byte-identical to the oracle's leaking stream, and Group 1 never had a module in which D's P4 admitted
the region.

## 4. Group 1's own composition probes on the combined binary

| probe | result |
|---|---|
| `a1_apost` vs `a1_apost_un` | **28 == 28, MULTISET IDENTICAL**, sole divergence one `cqrt_free(h6)` position. Reproduces `trackT2/GATES.md`'s number at this new hash |
| `t5j_twoblock_noexit_rot` (bd `6n1s` RED) | exit 0; **4 `ashr` mints / 4 `_unc` / 4 `cqrt_free`, `3 template rail mint(s) of which 0 left dirty`** — where the ORACLE emitted 4 mints / **0** `_unc` / **0** free. The `6n1s` leak is CLOSED. Residual: 2 `warning: … non-diagonal gate over a live derived record` for the **measured** `and` bit-rails (the pre-existing bd `s82e`/`lyyf` warning class, not this increment's) |
| `t5i_straddle_nobreak_rot` (GREEN control) | exit 0, stderr 0 bytes, `3 template rail mint(s) of which 0 left dirty`, `2 verified, 0 violation(s), 0 unproven`, 32 trace lines — **UNMOVED** from the ORACLE |
| `t5k_twoblock_unmarked_control` (DECLINE control) | exit 1, `cq loop lowering: rolled body leaks a rail entangled with a rotated register` — **UNMOVED** |

⚠ **The brief's predicted `A→D` on the `t5j` shape did not occur, and should not have.** `6n1s`'s fix
DISCHARGES the rail rather than declining the program; `trackT2`'s own corpus sweep says the same
("ZERO VERDICT FLIPS"). Accepting a program whose rails are all discharged is the correct direction
under the owner's 2026-09-11 ruling; the expectation, not the result, was wrong.

## 5. ⚠ WHAT THIS MEASUREMENT IS NOT

**A composition is not cleared by clearing its parts** — CLAUDE.md's own lesson, and this is the
**third consecutive session** it has to be written down (2026-09-14 F×P, 2026-09-15 F′×P′ `c1`/`c2`,
now Group 1 × D).

* Track D's Rule-13 round saw a binary on which `dD1` **leaks**; it filed F-1 against that binary.
* Group 1's Rule-13 round (`review_r13_group1/`) **has not delivered a verdict** — the directory holds
  nine probes (`g1`–`g9`) and **no `REVIEW.md`** at the time of this gate.
* The accept above — `dD1` compiling to a discharged circuit — was produced by **this gate's
  measurement and by no review at all.**

Rule 2 calls exactly this evidence **necessary and not sufficient**. The gate-symbol multiset, the
byte-level twin comparison and STRICT 2b are the project's strongest available witnesses and they are
all green; none of them is an adversarial reading of the composed lowering. **The final independent
Rule-13 round's subject is the COMPOSITION** (R20), and it is owed.
