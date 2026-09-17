# P0P3_STATUS — the 8 moved fixtures, and the one fence that loses its LAST pin

Written for the independent reviewer, who builds nothing. Branch **`tu9q-p0-p3-wip`** tip
`30b80d7f`. This file is a RECORD; it lands on `tu9q-hoisted-template` and changes no code.

> **The headline is item 7.** `declineRound2FalsifiedRailGrants` has **exactly ONE** pinning fixture
> in the whole tree, P0+P3 flips it to exit 0, and the fence is then pinned by **NOTHING**. That is
> Rule-12 debt the landing must repay with a new RED fixture — not a footnote.

---

## §0 — BINARIES (both built at `-j2`, BOTH targets)

| what | absolute path to `cq-opt` | sha256 |
|---|---|---|
| **P0+P3 — THE REVIEWER'S BINARY** | `/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/p0p3/build/ir-pass/cq-opt` | `e951d5d1bc072902e28bc0fd8a5d2adf1468bab100c4f1164c4e8f5f5ed21a7e` |
| **P1+P2 — the delivered branch** | `/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ad443b9a480ffb751/build/ir-pass/cq-opt` | `7c1163ad94d0632007566867a4a71bc7de9377352cddc4158425e41532594326` — **re-verified AFTER the p0p3 build, UNCHANGED** |
| session ORACLE (read-only) | `/Users/sorenwilkening/Desktop/Projects/CQ_lang/build/ir-pass/cq-opt` | `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` |

`p0p3/build/ir-pass/libCQPass.so` = `4de7a269d91f4419…` (the e2e layer loads the `.so`, not `cq-opt`).

`p0p3` is a SIBLING worktree of the delivered one, added from `tu9q-p0-p3-wip`, with its OWN
`build/`, configured and built at `-j2`, BOTH targets. **The delivered worktree's checkout and
`build/` were not touched**: its `cq-opt` hash above is the one every gate line in `GATES.md` is
keyed to, re-measured after the sibling build finished.

⚠ **The reviewer's binary is BIT-IDENTICAL to the one every P0+P3 measurement in this file was taken
on** (`e951d5d1bc072902…` — the same hash the 8-mover lit run reported at). So the table below is a
fact about the binary the reviewer will actually run, not about a near-miss of it.

### §0a — the 8 verdicts RE-MEASURED on the reviewer's binary

One `cq-opt` invocation per fixture, run against `p0p3/build` after it was built:

```
loop_leak_dephase_reject_region_derivedbase_live                exit=0
control_phase_kickback_mixed_hoisted_template_leak_control      exit=0
control_phase_kickback_mixed_short_sext_leak_control            exit=0
loop_pairing_reject_root_hoisted_template_data                  exit=0
control_phase_kickback_inloop_reject_hoisted_temp               exit=0
control_phase_kickback_mixed_preheader_add_outofplace_leak_...  exit=0
loop_pairing_reject_round2_falsified                            exit=0
control_inplace_ry_reject_rail_inloop_carried_invariant_read    exit=1
    cq loop lowering: hoisted invariant rail admitted for in-loop discharge was not discharged
```

Seven ACCEPT, one DECLINE-at-the-new-string — matching the P0+P3 column exactly.

---

## §1 — THE 8 MOVERS

Verdict columns: **ORACLE** and **P1+P2** are from the hand-off corpus sweep
(`probes/corpus_7c1163ad94d06320.txt`, 6566 rows) — for all 8 they are IDENTICAL, which is the
first thing to notice: **the delivered branch moves none of these eight verdicts.** The **P0+P3**
column is measured on the branch binary.

`A*` = ACCEPT whose lowered IR differs from the ORACLE's (an IR-only move, no verdict change).

| # | fixture | ORACLE | P1+P2 | P0+P3 | whose fence | what the fixture's own header says it pins | RIGHT direction? |
|---|---|---|---|---|---|---|---|
| 1 | `loop_leak_dephase_reject_region_derivedbase_live.ll` | **D** `rolled body leaks a rail entangled with a rotated register` | **D** same | **ACCEPT** | `declineDephasingUnmarkedLoopRails` (Track S′, bd `s82e` D4) | the INTERIM decline for a hoisted `mul` rail read by the body's condition, with a post-loop interference. Its own L8 trigger names bd `tu9q` as the end state | **YES.** This is the increment's declared customer and the decline was explicitly the interim. Every rail lowers `mint == _unc`. ⚠ It has TWO RUN lines (the second is the `CQ_BBU0_DEFER_DEPHASE_FENCE=1` DEFER prefix) and BOTH move |
| 2 | `control_phase_kickback_mixed_hoisted_template_leak_control.ll` | **D** same string | **D** same | **ACCEPT** | same | same shape; L8 trigger says *"when `tu9q` lands this becomes an ACCEPT again, and the stream to re-derive is the HAND-UNROLLED twin's — `3/3`"* | **YES, and it is the strongest row in the table**: measured rolled **40** == hand-unrolled twin **40**, trace MULTISET IDENTICAL. The trigger was character-for-character correct about the verdict |
| 3 | `control_phase_kickback_mixed_short_sext_leak_control.ll` | **D** same string | **D** same | **ACCEPT** | same | the identical shape with a `cq_template_sext_i16_to_i32` rail instead of the `mul` | **YES.** Same mechanism, `mintsOutOfPlaceTemplateRail`'s `CastInst` arm |
| 4 | `loop_pairing_reject_root_hoisted_template_data.ll` | A | **A\*** (hoisted rail discharges) | **A\*** (per-trip rails discharge too) | — (an ACCEPT-with-`LEAK`-prefix, no fence) | *"IF A `_unc` OR A `cqrt_free` EVER APPEARS IN THIS FILE, clause (ii-c) has over-widened and the multiplicity miscompile above is LIVE"* | **YES**, and the header's stated CAUSE is wrong — see §3. Already converted on the delivered branch for the P2 half; P0+P3 adds the per-trip half |
| 5 | `control_phase_kickback_inloop_reject_hoisted_temp.ll` | A | **A\*** | **A\*** | — (ACCEPT-with-`NOROUTE`) | *"These are the lines that FIRE if `invariantRegisterRoots` is ever widened to admit a hoisted template rail"* | **YES**, same note as #4 |
| 6 | `control_phase_kickback_mixed_preheader_add_outofplace_leak_control.ll` | A | **A\*** | **A\*** | — (ACCEPT-with-`FCNT`/`UCNT`) | *"ONE free in the body: the flag alone (the bit rail is the leak)"* | **YES**, same note as #4 |
| 7 | **`loop_pairing_reject_round2_falsified.ll`** | **D** `round-1 iteration-local marking falsified by round-2 taint` | **D** same | **ACCEPT, exit 0** | **`declineRound2FalsifiedRailGrants`** (bd `tu9q`'s own L1 re-ask) | the L1 WINDOW of the round-1 root-mint grant **and its witness** — *"it PROVES THE WINDOW IS REACHABLE. A fence written for an L1 window nobody can construct is a prediction, not a test"* | **UNDECIDED — and it is not mine to decide.** See §2 |
| 8 | `control_inplace_ry_reject_rail_inloop_carried_invariant_read.ll` | **D** `control flow inside a loop body under quantum control` | **D** same | **D**, but at the (ii-d) POSTCONDITION's new string | `ControlDetect`'s in-loop refusal (bd `wx8g` review F-W1-2) | a bare-`_Bool` rail region on a LOOP-CARRIED rotated register whose body mints a per-trip template rail the spine never discharges | **NO — and its OWN TRIGGER says so.** See §4 |

---

## §2 — ITEM 7: THE FENCE LOSES ITS LAST PIN (the answer the coordinator asked for)

**Grepped, not remembered**, on the delivered tree:

```
grep -rln "round-1 iteration-local marking falsified" ir-pass/test/   -> 1 file
grep -rln "declineRound2FalsifiedRailGrants"          ir-pass/test/   -> 1 file
```

Both hits are the SAME file, `loop_pairing_reject_round2_falsified.ll`. The string appears in
`ir-pass/src/LoopLowering.cpp:4177` and in exactly one fixture.

⇒ **After P0+P3 that fence has ZERO pinning fixtures.** Its documented sibling
(`probes/adv/l1_round2_grow_65arm.ll`) is an ACCEPT by design — *"one file pins the refusal and the
other pins that the refusal is not indiscriminate"* — so removing the refusal side leaves only the
non-refusal side. **The landing must repay this with a new RED fixture**, and the fixture has to
falsify a round-1 marking by a route that is NOT a hoisted template rail, because that route is
precisely what P0+P3 makes legitimate. Candidates, in the fixture's own vocabulary: a round-2 delta
that makes a SUBLOOP carry quantum content; one that produces a tainted-index memop in the body; one
that makes a header phi tainted. None is constructed.

**Two things make this worse than an ordinary conversion, and both are quotes from the file:**

* it is the tree's only demonstration that the L1 window is *constructible at all* — *"A fence
  written for an L1 window nobody can construct is a prediction, not a test (`CLAUDE.md` L10)"*;
* it has **no L8 retirement trigger**. Unlike rows 1–3, nobody predicted this flip, so nothing in
  the tree instructs the next agent on what the correct post-flip state is.

**My reading of whether the flip is the right DIRECTION** — stated separately from the debt, because
they are different questions. The fixture's argument for its own decline is:

> *"`%m2`'s forward gate is in the loop PREHEADER and runs ONCE, while a marked body's discharge
> point runs K times. `Uncomputation.cpp`'s §4/§2.9 pair asks each endpoint SEPARATELY whether it
> repeats and never whether the two repeat EQUALLY … so leaving the grant standing is **K adjoints
> against ONE forward gate** — an over-reversed rail, a wrong unitary, not a leak."*

**P1 is exactly the missing test and P2 is exactly the right point**, and the emitted module says
so: `cq_template_mul_i32_hl(%out1, 2)` is minted ONCE in the preheader and adjointed ONCE in the
loop-EXIT block, with the body's own `lshr` rail minted and discharged per trip. The hazard the
fence names is **refuted by construction**, so the flip is very likely right. **But the fence may
still own shapes P1 does not reach** — that is what the missing RED fixture would establish, and
retiring another owner's Rule-13 fence on my own reading is not an implementer's call. **That is
why P0+P3 is not on the mergeable branch.**

---

## §3 — ROWS 4–6: THE VERDICT WAS PREDICTED, THE CAUSE WAS NOT

All three headers attribute a future `_unc` to **widening the ROOT ADMISSION**. That is false for the
P1+P2 half already landed: those rails discharge with `invariantRegisterRoots` **COMPLETELY
UNCHANGED** and the bodies **UNMARKED**, because the flip is a PLACEMENT (P2's loop-exit anchor). And
the multiplicity is **1 : 1** — one mint in the preheader, one adjoint at the exit — the exact
opposite of the K : 1 that row 4's and `trackT/probes/adv/b1_mixed_nonlive.c`'s headers predict.

The generalisable form is in `IMPL_T3.md` §7a: **a retirement trigger predicts a verdict, and a
verdict has more than one cause.** When one fires, re-derive the mechanism from the binary instead of
reading the cause off the trigger.

---

## §4 — ROW 8: THE FIXTURE'S OWN TRIGGER PREDICTS AN ACCEPT AND P0+P3 DELIVERS A DECLINE

Verbatim from its header:

> *"RETIREMENT TRIGGER (L8): this becomes an **ACCEPT** the day `markIfRailLocal` (or whatever
> succeeds it) can mark a body that reads a loop-invariant tainted rail, or the day the spine
> discharges a per-trip template rail without the marking. Re-derive the stream then — **it is the
> 34-line hand-unrolled twin's, rolled** — do not delete this file."*

Clause (ii-d) is precisely *"`markIfRailLocal` can now mark a body that reads a loop-invariant
tainted rail"*. **The trigger's condition is MET and its predicted outcome is NOT DELIVERED**: P0+P3
grants the marking, the spine then does **not** discharge the rail, and the (ii-d) postcondition
declines the module with a new string.

So this row is not a conversion at all — it is the postcondition catching P3 granting a marking it
could not keep. It still DECLINES, which is the safe direction, and the measurement that matters is
the other one: **with the postcondition removed, that module COMPILES**. The postcondition is holding
a verdict, not decorating a message.

**My reading: NOT the right direction as it stands.** Either (ii-d) should refuse this shape up
front — so the fence that owns it keeps speaking with its own string — or the placement should be
extended to deliver the 34-line stream the fixture predicts. Both are real work and neither is a
fixture edit.

---

## §5 — WHAT THE OTHER TWO AFFECTED FENCES KEEP (so item 7 is not read as typical)

Grepped on the delivered tree, counting only RUN-line declines (`RUN: not %cq-opt`), because a string
in a historical header pins nothing:

| fence | declining fixtures before | moved by P0+P3 | left after |
|---|---|---|---|
| `declineDephasingUnmarkedLoopRails` (`rolled body leaks…`) | **9** | 3 (rows 1–3) | **6** — the four `nested_*`, `preheader_volatile_imm`, and this session's new `loop_leak_dephase_reject_twoblock_unmarked_control` |
| `ControlDetect` (`control flow inside a loop body…`) | **25** | 1 (row 8) | **24** |
| **`declineRound2FalsifiedRailGrants`** | **1** | **1** | **0** ← the debt |

---

## §6 — WHAT THIS FILE DOES NOT CLAIM

* **No suite was run on the P0+P3 binary** — the 8 movers were found with the targeted lit filter
  `loop|uncompute|inloop|kickback_mixed|railbank|break|lowering_` (986 entries, 977 pass + 1 XFAIL +
  8 fail). **A full `ir-pass-lit`, the e2e layer, the twin matrices and a corpus sweep have NOT been
  run on it**, so "8 movers" is a lower bound over the families that filter covers, not a tree-wide
  number. The reviewer now has the binary to change that.
* The P0+P3 branch's own fixtures are **not** converted — that is why it shows 8 failures rather
  than a green suite, and it is the intended state for a branch that is not for merge.
* `IMPL_T3.md` §5 carries the two narrowings of clause (ii-d) that were tried (one KEPT, one
  REJECTED), each recorded at the clause so neither is re-derived as an improvement.
