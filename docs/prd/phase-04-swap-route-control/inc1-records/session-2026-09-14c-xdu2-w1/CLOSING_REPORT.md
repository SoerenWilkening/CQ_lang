# CLOSING REPORT — session 2026-09-14c, bd `xdu2` W1 group

**What this agent was for: the CORRECTION and the FINAL GATE, not new capability.** The owner ruled
that all five branches land with **Track S's coverage claims corrected and the residual filed**. No
pass behaviour was changed; the proof of that is mechanical and is in §2.

Worktree `/Users/sorenwilkening/Desktop/CQ_merge`, branch `merge-2026-09-14c`, base `d25990b1`
(the group gate). `main` untouched, nothing pushed, the primary `build/` never written.

---

## 1. WHAT WAS CORRECTED, AND WHERE

The correction is `CLAUDE.md`'s **L7-WITH-A-TWIST**: *a record correction that is not applied to the
SOURCE is not a correction* — a lesson this project learned by having one false clause survive **three**
review rounds because every round fixed the record and none fixed the comment the record was read off.
So every site below is the **source**, and the two record edits are pointers back to it.

The finding being applied is Rule-13 round 1 track β (`review_r1b/REVIEW_R1B.md`, verdict **FINDING**):
**`declineDephasingUnmarkedLoopRails` catches PART of the dephasing class, not the class.**

| # | site | what it said | what it now claims |
|---|---|---|---|
| 1 | `ir-pass/src/LoopLowering.cpp:3772` | Rule-17 paragraph: *"The **refused programs** do not currently receive a valid circuit"* | narrowed to *"the programs this fence was **BUILT for**"*, with the measured counter-example named (bd `2g52`) |
| 2 | `ir-pass/src/LoopLowering.cpp:3787` | — (new block) | **CORRECTION, CLOSING GATE**: the coverage claim, its two surviving members (bd `c767`, bd `7845`, both P1, both **pre-existing**), the one shape it wrongly refuses (bd `2g52`, P2, **new**), and a retirement trigger naming all three |
| 3 | `ir-pass/src/LoopLowering.cpp:3845` | — (new block) | the `warnLiveRecordRotations` cross-reference (§3 below) |
| 4 | `ir-pass/src/LoopLowering.cpp:4050` | conjunct (2), silent about its own scope | ⚠ *the `L->contains(&BB)` skip is a **SCOPE, NOT A PROOF*** — an in-loop interfering rotation is invisible, `Rots` comes back empty, the loop is passed over. bd `c767`, with the 20-vs-24 / 34-vs-42 measurements and the note that the **diagnostic's own wording** ("rotated after the loop") has to move when the skip does |
| 5 | `ir-pass/src/LoopLowering.cpp:4092` | conjunct (3): *"a compare rail **is** the region's own flag, which `emitCondNetwork` strips and frees itself"* | the clause is **quoted and retired in place** as FALSE for a compare used as **DATA** (`CompareLowering` mints an ordinary out-of-place `cq_template_icmp_<pred>_<W>_hl` rail, no region in the module), with the 10-vs-14 measurement, `CLAUDE.md` L4 named, **and what is still true** — so the fix is *not* `isa<BinaryOperator> \|\| isa<CmpInst>`. bd `7845` |
| 6 | `ir-pass/include/LoopPlan.h:331` | *"It is NOT a leak when the copied register is still LIVE after the loop"*, read as a class definition | that paragraph is marked as **this fence's SCOPE, not a coverage claim**, with both P1 residuals, the over-decline, and an instruction not to quote the declaration without the definition's block |
| 7 | `ir-pass/test/loop_leak_dephase_accept_pertrip_dead.ll:28` | *"the joint garbage never touches the retained subsystem, so the two forms agree on every observable"* | the benignity is a property of **this program**, not of the shape any conjunct tests: round 1β took **this very program** (bd `s82e`'s `w2k_noregion_invread`) and **one added line** made it divergent, 20 vs 24, still accepting. The file pins conjunct (2) as a **DISCRIMINATOR**, not as a general proof of benignity — plus why its own verdict survives bd `c767` closing, and an L8 trigger to re-derive it rather than assume it |
| 8 | `ir-pass/test/loop_leak_dephase_accept_marked_rootmint.ll:26` | *"an UNMARKED body's leak is refused; a MARKED body's discharge is not"* | the **first half over-claims** and is corrected; the **second half is exact** and is what this file still pins (conjunct (1), 22 == 22 byte-identical). L8 trigger: a widening of conjuncts (2)/(3) must re-run this file first |
| 9 | `DECISIONS.md:149` | — (appended) | a dated **ERRATUM to D4**. ⚠ The ruling itself is **not rewritten**: what is corrected is the reading that D4's *"live **after the loop**"* is a class boundary. Everything D4 rejected stays rejected and bd `tu9q` stays the end state |
| 10 | `trackS/IMPL_S.md:3` and `:470` | §0's table header (*"the bead's own three programs are the BENIGN half of the class"*) and the row that repeats the false compare clause verbatim | a dated ERRATUM at the head and an inline ⚠ at the row. §0's arithmetic is not retracted; its **scope** is |

**Filed, by the round that found them** (not by this agent): bd `test_C_libtooling-c767` (P1),
bd `test_C_libtooling-7845` (P1), bd `test_C_libtooling-2g52` (P2). The capability that retires the
decline entirely remains bd `test_C_libtooling-tu9q` (P1).

---

## 2. THE REBUILD, AND WHAT IT PROVES

```
cmake --build build -j8            # BOTH targets — never --target CQPass alone
shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
```

```
0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d  build/ir-pass/cq-opt
94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b  build/ir-pass/libCQPass.so
```

**Both are UNCHANGED from the group gate's binary.** This is not a no-op build: `LoopPlan.h` is widely
included, so **100 translation units were recompiled** — `LoopLowering.cpp` and `RotationLowering.cpp`
among them — and **both targets were relinked** (`Linking CXX shared module libCQPass.so`, exit 0), and
the output is still bit-identical. That is the mechanical proof that **every edit in §1 is a comment or
a record and the compiler's behaviour did not move**. Neither file contains `__LINE__` or `__FILE__`, and the build is Release
(`NDEBUG`, no `-g`), so there is no line-number channel into the binary either.

Per **PROTOCOL §S2**, the full suite is therefore **CITED, not re-run**:

* `cited: FULL ctest -j6 442/442 @ 0e280fc62a91cec2 (merge-and-gate, 2026-09-14)`
* `cited: cq-opt-equivalence-full 2039/0 @ 0e280fc62a91cec2 (merge-and-gate, 2026-09-14)`

**Ran, not cited:**

* `ran: lit ir-pass/test --filter loop_leak_dephase @ 0e280fc62a91cec2 — 4 of 2039 discovered, 4 PASS, 2.12 s`
  (both touched fixtures plus their two decline siblings).
* `ran: stray-directive scan over every added fixture comment line — 0 hits for CHECK / RUN: / COUNT / LEAK / RY-`,
  because a `;` comment carrying a directive token would silently become a FileCheck directive.

---

## 3. THE CROSS-REFERENCE THIS GATE ADDED (task item 2), WITH ITS OWN LIMITS

Recorded at **both** sites — `LoopLowering.cpp:3845` (the fence) and `RotationLowering.cpp:1975`
(`warnLiveRecordRotations` itself) — so the next agent finds the relationship instead of re-deriving it.

**MEASURED at this gate**, counting `"non-diagonal gate over a live derived record"` in `opt` stderr:

| probe | ORACLE `5c6f7490…` | MERGED `0e280fc6…` |
|---|---|---|
| `s1_live_shift` (divergent) | exit 0, **warn 2** | **exit 1** at the D4 fence — warn count 0 **by preemption** |
| `s2_live_derived_region` (divergent) | exit 0, **warn 2** | **exit 1** — same |
| `b11_cmp_rail_data` (divergent, bd `7845`) | exit 0, **warn 2** | **exit 0, warn 2** — the member the fence MISSES |
| `s3_live_rootmint_region` (benign) | exit 0, warn 0 | exit 0, warn 0 |
| `w2k_noregion_invread` (benign) | exit 0, warn 0 | exit 0, warn 0 |

A clean 5-of-5 split — and it is **not** a divergence detector, which is the half that had to be
written down. Measured on the same binary: it fires on `slice_control_inplace_ry_loop_leak` (1) **and**
on `…_unrolled` (2), a pair whose traces are byte-identical under the shipped ctest gate
`e2e-inplace-ry-loop-leak-twin-identical`. ⚠ And byte identity cannot prove that pair correct either:
if both halves are wrong the same way the twin witness is blind (`CLAUDE.md` L10's
`m_none_pbitd_none_premark_rypost`, which is exactly that).

It is a **warning by owner ruling bd `lyyf` (2026-08-29)** and the recorded reason is **reporting
completeness** — every offending gate reported instead of the pass ending after one — **not** benignity.
Promoting it to a decline has a measured cost, re-measured here rather than inherited:

```
372 tests/e2e/slice_*.c  →  366 accept · 3 decline · 3 CLANGFAIL
5 of the 366 accepting slices emit it:
  slice_control_angle_select_ry_derived_base (2)  slice_control_inplace_ry_derived_base (4)
  slice_control_inplace_ry_loop_leak (1)          slice_control_inplace_ry_loop_leak_unrolled (2)
  slice_live_record_source_rail_warn (2)
```

⚠ Side-effect of that sweep, reproducing `MERGE_FILINGS.md` **F-6** independently: two of the three
CLANGFAILs are `slice_control_select_{bool,cmp}_round2_window.c`, the record files kept *"so the program
is on record"* that **do not compile** (a nested `/*` in the conversion header). The third is
`slice_multi_lib`, which needs the multi-file recipe.

---

## 4. STATE OF THE INCREMENT — what an owner needs

**LANDED** (five branches, one group gate, `MERGE_REPORT.md`): Track A's rail-bank carve classifier and
Track B's per-activation promoter (bd `xdu2`, composed and wired at `e6946068`), Track S's D4 decline
(bd `s82e`), Track X's X5 re-derivation (bd `om35`), Track I's `free_pairing_check` premise check
(bd `21re`). Gate: **442/442**, equivalence **2039/0**, corpus sweep **6311 rows with 0 DECLINE→ACCEPT**.

**CLAIMED, precisely.** The D4 decline closes the divergent sub-case **it was built for** and nothing
wider. After this correction the tree no longer asserts otherwise anywhere — not in the fence header,
not at either conjunct, not in `LoopPlan.h`, not in the two accept fixtures, and not in D4's own record.

**OPEN, and it is not small:**

* **bd `c767`** (P1) and **bd `7845`** (P1) — two members of the dephasing class that still compile to
  the wrong unitary. **Pre-existing**, so nothing regressed; but round 1β found both **in one round, by
  attacking two named conjuncts**, which is `CLAUDE.md` Rule 13's *"the next round finds something"*
  arriving on schedule. Round 2 is owed and should be budgeted, not hoped for.
* **bd `2g52`** (P2) — a **new over-decline** this increment introduced: a dtzb in-place `xor` mints no
  rail, so there is nothing to leak, and a program whose rolled trace is byte-identical to its twin's
  now declines. By the owner's 2026-09-11 ruling that is a defect to remove. The pre-specified fix is
  one conjunct and it is **not** a comment change: `InPlaceRailOps` is unscrubbed, and this stage runs
  **before** `lowerOps` re-verifies the marking under final taint — L1's predicate species in the
  granting direction.
* **bd `tu9q`** (P1) — the end state: build the in-loop `_unc` + `cqrt_free` pairing so these programs
  compile instead of declining. D4 filed it rather than building it.
* **`MERGE_FILINGS.md` F-1** — a Rule-13 opinion on the **A×B composition** is still owed. The gate
  measured it (63 `Bank` rows agreeing on all seven fields, 20 disagreements all in the stricter
  direction, 0 where the real classifier is looser); Rule 2 says that is *necessary and not sufficient*,
  and **a composition is not cleared by clearing its parts**.
* **F-3** (three Track-B refuse fixtures stopped isolating their clause), **F-5** (bd `s82e`'s D4
  population is 6 record programs, not 3), **F-7** (four twin-matrix cells measured and adjudicated but
  deliberately not added), **F-8**, **F-9** — all carried in `MERGE_FILINGS.md`.
* **ROUTING R1** (the D3 measurement is *unmeasurable today*, which is not *no*) and **R2** (D1's
  byte-identity measurement is owed **with** the accept, not after) are unchanged by this gate.

**NOT DONE, deliberately** (task item 3): nothing was widened, the warning was not promoted, and no
Track A/B/X/I source was touched. Round 2 owns the residual.
