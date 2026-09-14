# Track S′ — the dephasing fence, round 2: two P1 over-accepts closed, one over-decline removed

**Subject:** `LoopLowering::declineDephasingUnmarkedLoopRails`, shipped 2026-09-14c under owner
ruling **D4** and its **ERRATUM**. Rule-13 round 1 track β's verdict on it was that its
benign/divergent separation *"holds by accident on the three programs it was built from"*
(`$PREV/review_r1b/REVIEW_R1B.md`). This track closes the three beads that verdict filed.

**Branch** `dephase-fence-r2`, worktree `/Users/sorenwilkening/Desktop/CQ_S`, based on `main`
`74eabd2c`. Files touched under `ir-pass/`: **`src/LoopLowering.cpp`** and
**`include/LoopPlan.h`** only (plus fixtures). ⚠ **Both are shared with Track T** — see §7.

| bd | was | is | pinned by |
|---|---|---|---|
| `test_C_libtooling-c767` (P1, PRE-EXISTING over-accept) | conjunct (2) skipped every in-loop rotation | the `L->contains(&BB)` skip is GONE; the diagnostic no longer claims a position | `loop_leak_dephase_reject_inloop_rotation.ll` |
| `test_C_libtooling-7845` (P1, PRE-EXISTING over-accept) | conjunct (3) scanned `BinaryOperator` on a FALSE rationale | the opcode proxy is replaced by the membership question `mintsOutOfPlaceTemplateRail`, asked of the opcode owners | `loop_leak_dephase_reject_cmp_rail_data.ll` |
| `test_C_libtooling-2g52` (P2, over-decline THIS fence introduced) | a dtzb IN-PLACE `xor` counted as a rail | the same membership question answers "in place ⇒ mints nothing" | `loop_leak_dephase_accept_inplace_volatile.ll` |

---

## 0. The headline measurements

Binaries. **ORACLE** `cq-opt` `0e280fc62a91cec2…` / `libCQPass.so` `94602c7896e7a7ee…`
(= `main` `74eabd2c`; hashed before first use and unmoved).
**SUBJECT** `cq-opt` `15f6a75a50faba7a…` / `libCQPass.so` `e39dba218d4ba698…`.

⚠ **The RED baseline is not a claim, it is a hash.** This worktree's FIRST build came out
**BIT-IDENTICAL to the ORACLE** (`0e280fc6…` / `94602c78…`) because `LoopLowering.cpp.o` was
compiled before my edit landed. So the pre-fix numbers below are ORACLE numbers *by
construction*, and every RED→GREEN delta is attributable to this edit and to nothing else.

```
$ docs/.../trackS/probes/ps.sh <probe>.c        # ORACLE vs SUBJECT, one row each
b7b_w2k_interfered     | ORACLE A:20 lines | SUBJECT D1:…leaks a rail entangled with a rotated register
b7b_w2k_interfered_un  | ORACLE A:24 lines | SUBJECT A:24 lines
b7c_w2h_interfered     | ORACLE A:34 lines | SUBJECT D1:…rotated register
b7c_w2h_interfered_un  | ORACLE A:42 lines | SUBJECT A:42 lines
b11_cmp_rail_data      | ORACLE A:10 lines | SUBJECT D1:…rotated register
b11_cmp_rail_data_un   | ORACLE A:14 lines | SUBJECT A:14 lines
b10_inplace_volatile   | ORACLE D1:…rotated after the loop | SUBJECT A:7 lines
b10_inplace_volatile_un| ORACLE A:7  lines | SUBJECT A:7 lines
```

and `cmp b10_inplace_volatile.sub.trace b10_inplace_volatile_un.sub.trace` is **CLEAN** —
the newly-accepted rolled program's trace is **BYTE-IDENTICAL** to its hand-unrolled twin's:

```
cqrt_alloc_i32(5) -> h0 / cqrt_ry_i32(h0, 0x1p-1) / cqrt_xorc_i32(h0, 1) ×3
cqrt_ry_i32(h0, 0x1.ccccccccccccdp-1) / cqrt_measure_i32(h0) -> 0
```

**Controls, every one UNMOVED** (`ps.sh`, same run):
`s3_live_rootmint_region` 22 == 22 (the positive control conjunct (1) exists for);
the three **D4-ruled-BENIGN** exhibits `w2k` 16, `w2h` 30, `w2h3` 44 and their twins 20 / 38
/ 48; `s1_live_shift` and `s2_live_derived_region` still DECLINE (new string);
`b5_measure_owned` 8 == 8; `b7_pertrip_interfered` 18 == 18; `b4_fpcast_rail` 10 == 10;
`s4_inplace_accum_live` still declines upstream at `cq taint escape`.

⚠ **THE BENIGN THREE NOT MOVING IS THE RESULT THAT MAKES THE WIDENING NARROW**, and it is a
MEASUREMENT where `loop_leak_dephase_accept_pertrip_dead.ll`'s header previously carried a
PREDICTION. The prediction was right and the reason is the one it gave: `int u =
cq_theta(6, 0.4);` has a **classical arg 0**, so it is a **SOURCE** theta, and conjunct (2)
counts only **CHAINED** ones. Their one-line variants (`b7b`, `b7c`) do move. Both fixture
headers now carry the measurement instead of the prediction (`CLAUDE.md` L7-with-a-twist).

---

## 1. bd `c767` — conjunct (2) had a SCOPE, not a proof

`for (BasicBlock &BB : F) { if (L->contains(&BB) || !DT.dominates(L->getHeader(), &BB)) continue; … }`
skipped every in-loop `@cq_theta_*`, so `Rots` came back empty and `if (Rots.empty()) continue;`
passed the loop over.

**The whole edit is deleting `L->contains(&BB) ||`.** The dominance test that remains does the
work by itself: **a natural loop's header dominates every block of the loop**, so one
predicate now spells "inside the loop, or after it on every path". Nothing else in the walk
moves — a SOURCE theta (classical arg 0) is still excluded, `peelInPlaceBase` is still the
one relation that says "which physical rail is this".

**Why an in-loop rotation is the same hazard**, stated so a future round does not re-derive
it: a body that repeats carries trip *k*'s undischarged rail across trip *k+1*'s gate
**whatever the textual order inside the body**, and the hand-unrolled twin discharges it —
measured, the twin's `_unc` + `cqrt_free` pair precedes the rotation in the trace. The
mechanism does not care WHERE the interference sits, only that the leaked rail's partner is
interfered AT ALL.

**⚠ THE DIAGNOSTIC MOVED WITH THE SKIP, and that is part of the fix, not cosmetics.**
`"…entangled with a register rotated after the loop"` → `"…entangled with a rotated register"`.
The old wording *described conjunct (2)'s old scope*; leaving it would be exactly the
L7-with-a-twist defect this project has already paid for three times on one sentence. Five
shipped decline fixtures mirror the literal character-for-character and were updated in the
same change: the two `loop_leak_dephase_reject_*` plus
`control_phase_kickback_mixed_{hoisted_template,preheader_volatile_imm,short_sext}_leak_control.ll`.

⚠ **This is a DECLINE-STRING MOVE and the merge-and-gate agent owes
`cq-opt-equivalence-full` for it** (PROTOCOL's "iff a decline string / analysis site
changed"). It is called out here because no per-track gate covers it.

---

## 2. bd `7845` — conjunct (3) asked an OPCODE CLASS where the question was a SET

The retired test was `!taint.Tainted.count(&I) || !isa<BinaryOperator>(&I)` + a non-empty
`binaryStem`, and its written rationale —

> *"a compare rail is the region's own flag, which `emitCondNetwork` strips and frees itself,
> so it is not a divergence and widening to it would decline shipped accepts."*

— is **true of a FLAG and false of DATA**. `CLAUDE.md` **L4** names this shape exactly: *a
set-membership question answered by a proxy loses.*

**The fix asks the question.** A new anonymous-namespace predicate
`mintsOutOfPlaceTemplateRail(I, taint)` answers *"will `lowerOps` mint an OUT-OF-PLACE
`cq_template_*` rail for this instruction — i.e. is there a rail here for the hand-unrolled
twin to discharge and the rolled body to leak?"* **Every row calls an existing owner
(Rule 14); not one re-derives a verdict this file does not own:**

| row | owner called | why that owner |
|---|---|---|
| binary | `binaryStem`, then `railValueConsumerDisposition` | "is there a template" / "mint or relabel" |
| compare | **`isDataPositionCompare`** + `compareFlagMintable` | ⚠ **this is the answer to the retired rationale**: the FLAG-vs-DATA distinction is a question the compare owner already answers, so it is CALLED, never guessed from an opcode. `CompareLowering.h` exports both. |
| cast | `castInScope` + `abiWidthFromType` | the gate `CastLowering::rewriteCast` itself uses |
| `fneg` | `abiWidthFromType` | same |

⚠ **The second half of the retired clause was never measured wrong, which is why the fix is
NOT `isa<BinaryOperator> || isa<CmpInst>`**: a region FLAG compare must still be excluded,
and it is — by `isDataPositionCompare`, by name.

⚠ **THE CAST / `fneg` ROWS HAVE NO WITNESS EITHER WAY AND I AM NOT CLAIMING ONE.** Round 1β
could not construct a cast-minted divergence (`-O1` folds `fptrunc(fpext t) → t`, LICM
hoists the pair out of the body) and explicitly did NOT claim one unreachable. They are in
the set because the QUESTION admits them; the measured cost is **zero** (`b4_fpcast_rail`
10 == 10 accepts, and the corpus sweep §5). If they are wrong there, the direction of the
error is a DECLINE.

---

## 3. bd `2g52` — an in-place op mints nothing, and reading its marking here is an L1 hazard

`cqrt_xorc_i32` relabels the rail, returns no handle and allocates nothing, so there is no
interior rail, nothing to leak and no divergence to protect against. The same membership
question answers it: `railValueConsumerDisposition(BO, Rail, taint, {}) == InPlace` ⇒ this
instruction mints no rail.

**⚠ THE WARNING THE BRIEF GAVE ME WAS A HYPOTHESIS AND I TESTED IT (Rule 11).** Round 1β's
caution (b) was that this stage runs **BEFORE `lowerOps`**, which re-verifies in-place
markings under FINAL taint — so a suppressing conjunct reads a marking that is **not yet
final**, which is `CLAUDE.md` **L1**'s PREDICATE species **in the GRANTING direction**, the
unsafe one. I read `OpcodeLowering.cpp` rather than trusting the summary, and the resolution
is a **COMPOSITION, not an assertion that the marking cannot move**:

* **(i)** the suppression corroborates with the **same two tests** `lowerOps`' eqpx tripwire
  re-asks — `inPlaceValueRailOperand(BO, taint)` non-null and `taint.InPlaceRailIdx`, where
  it has an entry, still naming that operand. Verbatim from the source I read:
  `bool IdxDisagrees = It != taint.InPlaceRailIdx.end() && BO->getOperand(It->second) != Rail;`
* **(ii)** if the marking HAS gone stale by `lowerOps`, that stage **DECLINES LOUDLY** —
  `diagnosePreLoopCommitStale` for W4's `PreLoopCommittedInPlaceOps`, the eqpx tripwire for
  W1–W3's — and **never falls back silently to out-of-place** (Rule 1, no third path,
  written out at both sites). Verified: `PreLoopCommittedInPlaceOps ⊆ InPlaceRailOps`
  (`LoopLowering.cpp:3157` marks both in adjacent statements), so one membership test covers
  both writers.

So the composition is **total**: either the marking stands and the suppression was right, or
`opt` exits non-zero and no circuit is emitted. **RETIREMENT TRIGGER, in the source by name:**
if either `lowerOps` re-ask becomes a silent fallback, or `InPlaceRailOps` gains a writer that
runs AFTER this stage, half (ii) is gone and this suppression becomes an **OVER-ACCEPT**.

**⚠ RESIDUAL, STATED RATHER THAN MITIGATED AWAY.** Round 1β's caution (a) — `InPlaceRailOps`
is a raw `Instruction *` set **nothing scrubs** — is real and I did **not** close it. The
shape precondition is the only thing in front of it: a recycled allocation would have to land
on a tainted, dtzb-shaped (`add`/`xor`, exactly one tainted operand, integer ≤ 64) binop whose
recorded index still names the right operand. **That is a corroboration and not a proof.** The
proper close is to scrub `InPlaceRailOps`/`InPlaceRailIdx` alongside `Tainted` at the erase
sites; I did not do it because `scrubTaint` is a per-TU mirror at **eight** TUs, it changes
what `lowerOps` and `railValueConsumerDisposition` see for **every** module in the tree, and
under PROTOCOL S1 it would drag five more files into this GROUP. **Filed, not fixed.**

---

## 4. WHAT `ir-pass-lit` CAUGHT THAT NO PROBE DID — the stale-marking CEDE

⚠ **The first GREEN build broke `lowering_reject_inplace_rail_stale_w2_add_derived.ll`**, and
the failure mode was not a wrong verdict — it was a **decline→decline STRING MOVE**. That
fixture is the bd `eqpx` tripwire's own: a marked in-place op whose dtzb shape goes STALE
under final taint. My first draft fell through to `return true` for it (shape null ⇒ "not in
place" ⇒ "a rail"), so **this fence spoke first** and the module printed
`…leaks a rail entangled with a rotated register` instead of
`cq loop lowering: in-place rail op no longer provable at lowering`.

**The fix is a CEDE, not a judgement:** when the op is marked in `InPlaceRailOps` but the
shape no longer holds, this stage says **NOTHING**, because `lowerOps` owns that input and
declines with a strictly more precise diagnosis of the same module. The stage is documented
as a **BACKSTOP AND NEVER A PREEMPTOR** — the same reason it sits after
`declineRecordedStaleQuantumReaders` (`LLVMContext::diagnose` EXITS on the first `DS_Error`,
bd `br4a`) — and this is that contract applied one slot earlier.

**Three things worth carrying out of it:**
1. **An inner loop of probes would not have found it.** No probe of mine, and none of round
   1β's, has this shape; `lit` did, and only because a fixture existed with the exact string.
2. It is the **L2 question** in its usual costume: I widened the *rail* set and did not ask
   what *other* stage's claim on the same instruction I was widening across.
3. It has its own retirement trigger in source: if `lowerOps` ever stops declining on a
   stale marking, the cede becomes a **silent miss**.

---

## 5. Gates — see `GATES.md` for the hash-keyed lines

* **`ir-pass-lit`** (`ctest --test-dir build -R ir-pass-lit`) at `15f6a75a50faba7a`:
  **Passed 2041 / Expectedly Failed 1 / Discovered 2042**, 93.88 s. The pre-cede build at
  `f667cf90436bd31d` was **2040 / 1 XFAIL / 1 FAILED** — the §4 finding.
* **Rule-12 RED**, at the bit-identical-to-oracle build `0e280fc62a91cec2`:
  `Failed Tests (5)` — the three new fixtures plus the two existing rejects whose string
  moved — with the two ACCEPT fixtures PASSING, which is the half that must not move.
* **injection matrix** over all three accept fixtures, `probes/inject_S2.py`,
  `probes/injection_matrix_15f6a75a50faba7a.txt`: **applied 12, MISSED 0, N/A 15**.
  ⚠ **Its FIRST run scored `d_stray_ry` MISSED on the new accept** (an uncontrolled
  `cqrt_ry_i32` injected on the user register before the measurement, caught by nothing) —
  the fixture had no count on the rotation at all. Closed by a new whole-file `RY` prefix
  (`RY-COUNT-4` + `RY-NOT`). A second hole is closed by a new mutation
  `i_add_discharge_inplace`, without which the in-place fixture's pure-negative `LEAK`
  prefix was **UNEXERCISED** — mutation (f) keys on an `lshr` rail an in-place stream does
  not have. **The N/A count is reported, not folded into MISSED 0**: 15 N/A is large because
  the in-place accept genuinely has no `_unc`, no `cqrt_free` and no forward template mint
  to delete, which is the property the fixture asserts.
* **harness self-attack** before any real probe: `ps.sh i0_empty.c i1_noquantum.c` → both
  `VACUOUS-NO-QUANTUM`. Without that guard a 0-byte or quantum-free module scores ACCEPT
  through the passthrough early-out (bd memory `empty-module-accepts-vacuity-trap`).
* **corpus sweep** ORACLE-vs-SUBJECT: `probes/corpus_<hash16>.txt` — see §6.
* **twin matrices**: see §6.
* **NOT run** (PROTOCOL forbids them to this row): full `ctest`, `^e2e-`,
  `cq-opt-equivalence-full`.

---

## 6. Corpus sweep and twin matrices

### 6.1 Corpus sweep — `probes/corpus_15f6a75a50faba7a.txt`

`probes/corpus_S2.sh`, ORACLE `0e280fc62a91cec2…` vs SUBJECT `15f6a75a50faba7a…`, **both
binaries reading the SAME stage-1 file** per row.

```
ir-pass/test (COMPLETE, 2042 of 2042):  oracle-accept 1006 · oracle-decline 1034 · vacuous 2 · MOVERS 8
probe corpora (PARTIAL, 1267 rows):     oracle-accept  492 · oracle-decline  523 · vacuous 251 · MOVERS 0
```

**All 8 movers are attributable, and every one is mine:**

| kind | module | why |
|---|---|---|
| **A→D** | `loop_leak_dephase_reject_inloop_rotation.ll` | bd `c767` closed |
| **A→D** | `loop_leak_dephase_reject_cmp_rail_data.ll` | bd `7845` closed |
| **D→A** | `loop_leak_dephase_accept_inplace_volatile.ll` | bd `2g52` removed |
| D→D ×5 | `loop_leak_dephase_reject_{noregion_live,region_derivedbase_live}.ll`, `control_phase_kickback_mixed_{hoisted_template,preheader_volatile_imm,short_sext}_leak_control.ll` | the decline-STRING move of §1 — same verdict, different literal |

⚠ **THE FIVE D→D ROWS ARE VISIBLE ONLY BECAUSE THIS SWEEP RECORDS A SHA OF THE FULL
STDERR.** The shared `corpus.sh`'s tag regex would have shown all five as unchanged, which is
exactly the S3 instrument lesson (*"a decline→decline string change … is INVISIBLE; close it
with a full-stderr byte-compare"*) — and this track's change IS a decline-string move, so the
inherited instrument would have measured **3 movers and called it complete**.

⚠ **THE SWEEP IS PARTIAL AND I AM SAYING SO RATHER THAN ROUNDING IT UP.** I stopped it
(`TaskStop`, not `pkill` — never by pattern) with the probe-corpus tail unswept, at a measured
**load average of 310**, so that `e2e-loop-twin-matrix` could finish; three concurrent tracks
were on the box. **The half that matters was complete first**: `ir-pass/test` is swept
2042/2042, which is where every decline fixture that mirrors my moved string lives, and the
1267 probe rows that did complete moved **nothing**. The unswept tail is ~2000 rows of the
older session probe dirs. **A skipped layer is a deferred cost, not a saved one** (Rule 19):
the merge-and-gate agent's one sweep on the merged binary covers it, and my expected strings
for attribution are `cq loop lowering: rolled body leaks a rail entangled with a rotated
register` (the only string I emit) plus the five D→D rows above.

### 6.2 Twin matrices

`ctest -R 'e2e-loop-twin-matrix|e2e-loop-twin-quarantine-selftest'` on the SUBJECT.
⚠ **Which version:** the one in THIS worktree, `tools/loop_twin_matrix.py` at `main`
`74eabd2c` (`66428ddc` is its last touching commit), **unmodified** — `git status tools/` is
clean. Track I is editing that script in its own worktree; nothing of theirs is in these
numbers. Cell count on disk: `grep -c '^m_' tools/loop_twin_matrix.expected.txt` = **309**
plus `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` = **29** = **338**.

RESULT: *(below)*

---

## 7. ⚠ THE TRACK-T INTERACTION — answered, because the merge agent and the Rule-13 round need it

Track T is building **bd `test_C_libtooling-tu9q`**, the in-loop `_unc` + `cqrt_free` pairing,
**which owner ruling D4 files as the END STATE of this fence**. We share
`ir-pass/src/LoopLowering.cpp` and `ir-pass/include/LoopPlan.h`, so we are ONE GROUP.

**`tu9q` does not NARROW this decline — it REPLACES it, and the three fixes do not survive it
equally:**

* **bd `c767` and bd `7845` need the PAIRING, not a wider decline.** Both programs receive an
  INVALID circuit today only because the ROLLED body drops a discharge its own straight-line
  spelling performs. If the rolled body discharges in-body, the divergence is gone and both
  **compile correctly**. So the widening I landed is the **INTERIM for exactly the population
  `tu9q` is meant to serve**, and the four `loop_leak_dephase_reject_*` fixtures' L8 triggers
  fire on T's landing: they become ACCEPTs whose streams are their hand-unrolled twins',
  rolled. ⚠ **Do not read that as "S′ was wasted if T lands"** — the widening is what makes
  the population VISIBLE; a member the fence does not see is a member the pairing will not be
  asked to serve either, and `c767`/`7845` were invisible to every instrument in the tree.
* **bd `2g52` is ORTHOGONAL and it SURVIVES `tu9q` — and it becomes MORE load-bearing, not
  less.** An in-place op mints nothing, so the pairing has nothing to pair. If `tu9q` turns
  this stage's membership question into "which rails does the body have to discharge", then
  treating a `cqrt_xorc_i32` as a rail would make the pairing emit an `_unc` and a
  `cqrt_free` **for a rail that was never allocated** — a Rule-6 free of a handle that does
  not exist.
* **CONCRETELY, AND THIS IS THE HAND-OFF:** `mintsOutOfPlaceTemplateRail` **is the predicate
  Track T needs** — *"is there a rail here for the twin to discharge?"* is the same question
  as *"is there a rail here for the pairing to discharge?"*. If T re-derives it, that is a
  second spelling of one predicate, which is the drbq Inc-3 (b′) defect `CLAUDE.md` names by
  name (Rule 14). **T should CALL it.** It is in `LoopLowering.cpp`'s anonymous namespace
  today; promoting it to `LoopPlan.h` is a one-line export and I have deliberately NOT done
  it, because whether it belongs in the header is T's design decision and pre-empting it
  would create the merge conflict I am trying to avoid.
* **I did not build for T's world and I did not assume it lands.** Nothing here is
  conditioned on `tu9q`; the conjuncts are the same fence, widened.
* **Merge mechanics:** both of us edit `LoopLowering.cpp`. My edits are confined to
  `declineDephasingUnmarkedLoopRails`, the new `mintsOutOfPlaceTemplateRail`, the
  `kMsgLoopLeakDephases` literal and one `#include`. I added **no** e2e slice, so
  `tests/e2e/CMakeLists.txt` is untouched and the PROTOCOL S1 tail-conflict warning does not
  apply to me.

---

## 8. Open, and owed

* **bd `bbu0` is a QUESTION FOR THE OWNER, not a fix** — `QUESTION_bbu0.md`, stated as four
  options with measured costs and **explicitly not ruled** (L7). Its load-bearing gap is that
  *"is `warnLiveRecordRotations` silent on anything this fence declines?"* **cannot be
  measured on any binary in the tree**, because the fence preempts the warn stage.
* **the `InPlaceRailOps` scrub** (§3 residual) — filed, not fixed; it is a cross-cutting
  change over eight TUs.
* **no cast/`fneg` witness in either direction** (§2), **no cross-function instance of
  anything** (bd `1yeu` — every instrument in the tree is one function per module), **no probe
  for the superseded-value-rail direction** (`IMPL_S` §11/§16.3's other half), and **no bound
  on how many members the class has**. Round 1β budgeted a round 2 rather than reading three
  green conjuncts as closure; I read four green conjuncts the same way.
* **a Rule-13 round is OWED on this change** — it is a core-lowering change and a green suite
  does not clear it (Rule 13). The round should start at §2's cast/`fneg` rows and §3's
  residual, and should assume, per the measured hit rate, that it finds something.
