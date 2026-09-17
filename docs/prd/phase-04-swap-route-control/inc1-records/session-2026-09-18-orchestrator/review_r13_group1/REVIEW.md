# Rule-13 review — Group 1: bd `test_C_libtooling-tu9q`'s hoisted-template half (bd `6n1s` + P1 + P2), and a scoped opinion on P0+P3

# VERDICT (LANDED PREFIX, `tu9q-hoisted-template` @ `f1a7857a`): **FINDING** — one P1 over-accept (F-1), plus five items (F-2…F-6)

# VERDICT (NOT-LANDED P0+P3, `tu9q-p0-p3-wip` @ `30b80d7f`): **NOT LANDABLE AS IT STANDS** — landable this session only under the six obligations in §C.6

> **Read the P1 with its direction, because the direction is unusual and the summary is easy to
> get wrong.** The landed code is a **net improvement** and I found **no module it makes worse**.
> Measured, not remembered — a sha-256 over each probe's lowered IR (`ModuleID`/`source_filename`
> stripped) on both binaries: of my 16 accepting probes, **10 MOVED and all 10 moved
> `leak → discharge`**; 6 were byte-identical; every declining probe kept its exact string. **No**
> probe moved `discharge → leak`, `ACCEPT → DECLINE` or `DECLINE → ACCEPT`. **F-1 is not a regression introduced by this branch.** F-1 is that the
> branch **does not close the bead it is named for**: bd `6n1s`'s P1 — *"a MARKED loop body with
> more than one basic block leaks its interior which-path rails"* — survives, at `opt` exit 0 with
> a live Rule-8 wrong unitary, **one token** away from the witness the branch does close. So the
> code may merge; **bd `6n1s` may not be closed**, and two source claims must be corrected at the
> site before it is (`CLAUDE.md` L7-with-a-twist).

Independent second reviewer. I wrote none of this code, **ran no build, no suite, no corpus sweep,
no matrix and no equivalence run**, edited no source, fixture or test, and wrote only under
`$SES/review_r13_group1/`. Everything below is the `PROTOCOL.md` per-probe pipeline plus
analytic/trace reasoning (no simulation — owner 2026-06-10). Gate lines in `GATES.md`.

## Binaries — verified before any measurement

| role | path | sha256 | verified |
|---|---|---|---|
| ORACLE (read-only) | `$REPO/build/ir-pass/cq-opt` | `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` | matches the brief character-for-character |
| SUBJECT | `.claude/worktrees/agent-ad443b9a480ffb751/build/ir-pass/cq-opt` | `7c1163ad94d0632007566867a4a71bc7de9377352cddc4158425e41532594326` | matches the brief; branch tip `f1a7857a` |
| P0+P3 | `.claude/worktrees/p0p3/build/ir-pass/cq-opt` | `e951d5d1bc072902e28bc0fd8a5d2adf1468bab100c4f1164c4e8f5f5ed21a7e` | **ABSENT when I started Part A; present at 14:42 and measured in Part C.** Branch tip `30b80d7f`, as the brief names. Hash matches `P0P3_STATUS.md` §0 |
| PRE-GROUP (the implementer's, re-used not rebuilt) | `$SCRATCH/pregroup/build/ir-pass/cq-opt` | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | matches `IMPL_T3.md` §1 |

⚠ `p0p3/build/runtime/` contains **no archives**, so every P0+P3 row below is `opt` + stage 2b +
lowered IR only — **no link, no trace**. Stated as an absence, not a pass.

## What I read

`$REPO/CLAUDE.md` (Prime Directive; Rules 2, 5, 6, 8, 11, 13, 14, 19; CORRECTNESS RISK §3 L1–L10
with L1 twice; §5's `s82e` / Q-R1-1 paragraphs). `$SES/PROTOCOL.md` whole including §6.1.
`$SES/trackT2/SCOPE_T2.md` §6 (the eleven lenses) and §7. **`IMPL_T3.md` WHOLE** (§0–§8).
`trackT2/GATES.md`, `P0P3_STATUS.md` whole, `trackT2/probes/`.
`$SES/review_r13_loopconv/REVIEW.md` whole (its F-1 mechanism and its closing paragraph).
`$SES/review_r13_trackD/probes/dD1_*.c`.

**Source, read on disk and not remembered.** SUBJECT: the whole diff
`git diff cff8f7ac..f1a7857a -- ir-pass/src ir-pass/include` hunk by hunk — `markedHeaderOf`,
`multiplicityAgrees`, `useCompleteBeforeDischarge`, `anchorForConsumer` (`Uncomputation.cpp`
`:181–398`), the three `multiplicityAgrees` call sites (`§4 :1240`, `§2.9 :1293`,
`reverseTerminalGroup :784`), `markedBodyRailsHaveInBodyDischargePoint` and conjunct (1)
(`LoopLowering.cpp :4463–4586`, `:4857–4917`), `bodyBlocksMarked` (`:4451`), `railIsInterior`
(`:4224`), conjunct (3) (`:5018–5045`), `loopExitDischargePoint` (`:5099`), `markIfRailLocal`
(`:3739`), `markIfIterationLocal` (`:2422`), `RepeatOracle` (`:161`), and the pipeline order in
`CQLoweringPass.cpp` (both entry points). P0+P3: `git diff f1a7857a..30b80d7f -- ir-pass/src
ir-pass/include` — clause (ii-d), `exitDischargeObligations`, `declineUndischargedExitObligations`,
P0's `sameMultiplicity` merge and the `Borrowed` ordering drop.

---

## A. bd `6n1s` and P1 (the multiplicity test)

Every row is the same program on two (or four) binaries, `-O1 -g`, `cq-opt`, STRICT stage 2b, link
and run. `dirty` = `free_pairing_check`'s `N template rail mint(s) of which M left dirty`.

| # | probe | delta from the witness | PRE-GROUP `0e280fc6` | ORACLE `9bd01598` | SUBJECT `7c1163ad` | right? |
|---|---|---|---|---|---|---|
| A1 | `g1_threeblock_body_rot` | **three**-block marked body (`if / else if`) | **DECLINE** `rolled body leaks…` | ACCEPT 20 lines, **1 dirty**, 0 free | ACCEPT 28, **0 dirty**, 4 `ashr_unc` / 4 free | **YES** |
| A2 | `g2_fourblock_body_rot` | **four**-block body (two sequential `if`s) | — | ACCEPT 26, **1 dirty**, 0 free | ACCEPT 34, **0 dirty**, 4/4 | **YES** |
| A3 | `g5_break_in_threeblock_rot` | a `break` **inside** a 3-block body | — | ACCEPT 18, **1 dirty**, 0 free | ACCEPT 26, **0 dirty**, 4/4 | **YES** |
| A4 | `g6_nest_multiblock_inner_rot` | NESTED loop, **multi-block INNER body** (the `emkg` class) | — | ACCEPT 26, **1 dirty**, 0 free | ACCEPT 38, **0 dirty**, 6 `ashr_unc` / 6 free, both loops still rolled (4 `!llvm.loop`) | **YES** |
| A5 | `g3_arm_mint_join_read_rot` | rail **minted in one arm**, read at the join | — | DECLINE `tainted value muxed by a classical-condition select` | same | **YES** (`-O1` if-converts it out of reach) |
| A6 | `g4_arm_inplace_on_rail_rot` | conditional **in-place** `d ^= 3` | — | ACCEPT, 0 dirty, 6 free verified | **byte-identical** | n/a — `-O1` rewrote the program (`lshr→trunc→xor i1→zext`); the attack does not land from C |
| A7 | `g9_rail_read_only_in_arm_rot` | the rail's ONLY use is inside the arm | — | DECLINE `operand predates a non-diagonal gate` | same | **YES** — bd `3d8q` claims it first |
| A8 | `g7_inplace_carried_twoblock_rot` | in-place loop-carried accumulator + 2-block body | — | DECLINE `loop-carried tainted value crosses iterations` | same | **YES** |
| A9 | `g10_emitter_gate_on_interior_rail` | a rolled in-loop **phase kickback** whose condition reads the interior rail, in a 2-block body | — | ACCEPT 45, **1 dirty**, 4 free | ACCEPT 53, **0 dirty**, 4 `ashr_unc` / 12 free | **YES** |
| **A10** | **`g8_arm_use_derived_owned_rot`** | the arm mints an **INTERIOR** rail (`(d+7) & 2`) | **DECLINE** `rolled body leaks…` | ACCEPT 19, **2 dirty**, **0 free** | **UNMOVED** — ACCEPT 19, **2 dirty**, **0 free** | **NO — F-1** |
| A10a | `g8a_arm_measured_directly_control` | **ONE TOKEN** off A10: `(d+7)` instead of `(d+7)&2`, so the arm's rail is MEASURE-owned | **DECLINE** same | ACCEPT 18, **1 dirty**, 0 free | ACCEPT 26, **0 dirty**, 4/4 | **YES** — isolates A10's discriminant |
| A10b | `g8k_arm_use_derived_unmarked_control` | A10 + an escaping temp ⇒ `railLocalQualifies` refuses the marking | — | **DECLINE** `rolled body leaks a rail entangled with a rotated register` | **DECLINE** same | the **MARKING is A10's door**, by measurement |
| A10c | `g8b_interior_gate_in_header_control` | the arm's `add` written in the header | — | identical to A10 | identical to A10 | **degenerate** — `-O1` **SANK** the `add` back into the arm (Rule 9), so this is the same module. Recorded, not counted |

### A.1 The per-trip unitary argument for the accepts (owner ruling S2–S4: the witness is the argument, not the byte-identity)

**A1/A2/A3 (flat multi-block bodies).** Per trip `k` the SUBJECT emits, in order:
`ashr_i32_hl(h0,k) → hK` · the trip's reads (`and_i32_hl(hK,·) → measure`, one on the straight
path, one or two more on whichever arm ran) · `ashr_i32_hl_unc(hK, h0, k)` · `cqrt_free(hK)`.
`hK` is written exactly twice — by the forward gate and by its own adjoint — with `h0` unchanged
between them, and every intervening gate READS `hK` as a control and writes only its own fresh
rail. Therefore `hK = |0⟩` on **every** path at the free (the arm that did not run wrote nothing),
the state is a product in `hK`, and `cqrt_free` collapses nothing (Rule 6). **Multiplicity 1 : 1
per trip** — the adjoint sits in the join block, which is control-equivalent to the mint's block
(the mint dominates it, it post-dominates the mint), so the two execute equally often. The
trailing `cqrt_ry_i32(h0, 0.9)` then runs with **no** coherent record of `h0` alive, which is
exactly what the ORACLE's `1 dirty / 0 free` denies.

**A4 (nested, multi-block inner body).** Both loops survive as rolled `!llvm.loop` back edges; the
trace shows 6 inner trips, and each is `mint · reads · _unc · free` **within the trip**. The
`markedHeaderOf` key for every endpoint is the INNER header (`LI.getLoopFor`, innermost), so a
discharge one level out would have been refused by P1 rather than emitted — and none was.

**A9 (emitter gates).** The 8 `cqrt_x` and 4 `cqrt_rz_i1` sit on the kickback FLAG (`i1`), the 4
`icmp_eq` leaf rails are minted and stripped per trip, and **no emitter-minted gate writes the
owned `ashr` rail in place**. This is the constructive half of `IMPL_T3.md` §8 item 1 for the
emitter route: a rail root gets a CNOT copy or a diagonal `rz`, never an `X` bracket (`CLAUDE.md`
§4c), so the relaxed leg is never reached by a control-emitter gate on an owned rail.

### A.2 `useCompleteBeforeDischarge`'s case split — where it holds, and the case the split omits

`IMPL_T3.md` §8 item 1 asks me to attack F-R1-3's claim that *"an in-place gate on the owned rail
is always in `D.Calls`"*. **That claim survives every attack I could construct**, and the reason it
survives is structural rather than lucky: **`clang -O1` if-converts a conditional integer
reassignment into a `select`, and a tainted `select` under a classical condition is a loud decline**
(`declineClassicalMuxes`). A3/A6 are the two spellings and both die before the lowering. I could
not reach case (b) from C, and I did not attempt a hand-written `.ll` for it.

**But the split is stated over `R->users()` as if the only question were what the reversal touches,
and A10 shows the live hazard is a different one: what the relaxation lets into `Owned`, §4 then
refuses for a gate that is NOT `U` at all.** In A10 the relaxed leg admits the arm's *read*
(correctly), and the component is then abandoned because the arm's `add` — a **producer** of a
second interior rail, case (a) of the split — fails `DT.dominates(G, At)`. The split calls case (a)
"refused by §4", which is true and is exactly the point: **the component's refusal is the leak**,
and conjunct (1) has already promised the fence that this body discharges.

---

## B. P2 (the loop-exit anchor)

| # | probe | what it attacks | ORACLE | SUBJECT | right? |
|---|---|---|---|---|---|
| B1 | `b1_depth3_nest_hoisted` | the OUTERMOST walk at **DEPTH 3** (`IMPL_T3.md` §8 item 2 — only depth 2 had been measured) | 28 lines, **2 dirty**, 0 free | 30, **1 dirty**, **ONE** `mul_i32_hl_unc` + ONE free, **at trace line 28 — after ALL 8 innermost reads**, 8 `!llvm.loop` | **YES** |
| B2 | `b2_two_sibling_loops` | one hoisted rail, **two sibling loops** | 16, **3 dirty**, 0 free | 18, **2 dirty**, ONE `mul_unc` + free **at line 16, after BOTH loops** | **YES** |
| B3 | `b3_hoisted_read_after_loop` | Rule 6 — the anchor must not free a **live** rail | 17, `mul_unc` present | **UNMOVED**, and the `mul_unc` is at line 14, **after** the trailing `lshr(h1,8)` at line 10 | **YES** |
| B4 | `b4_two_exit_blocks_hoisted` | `loopExitDischargePoint`'s **null** path | 13, **2 dirty**, 0 free | **UNMOVED** | **safe**, but see F-5: `-O1` **merged** my two `return`s into ONE exit block, so this is a 4th neutralised attempt, not a customer |
| B5 | `b1b_depth3_mid_mint` | rail minted in the **MIDDLE** loop, read in the innermost (`r1_triple_nest_mid_rail`, the seed SCOPE_T2 names) | 17, **2 dirty**, 0 free | **UNMOVED** | **safe direction**, and the *correctness* property holds: the anchor walk stops at the INNER loop (the middle loop contains the mint), §2.9 then refuses a repeating unmarked `At`, and the rail leaks — **it is NOT discharged once after the whole nest**, which is the 1-adjoint-against-K-forward wrong unitary. See F-6 |
| B6 | `dD1_hoisted_template_cond_then_ry` (Track D's composition probe, on Group 1 alone) | the `s82e` shape meeting Track D | DECLINE `condition predates a non-diagonal gate under quantum control` | **identical DECLINE** | **as predicted** — D is not merged; recorded for the merge agent |
| B7 | `a1_apost` (the LIVE Rule-8 over-accept P2 closes) | lens 7 | 26 lines, **1 dirty**, WARNING `non-diagonal gate over a live derived record` | 28, **0 dirty**, **stderr 0 bytes** | **YES** — see B.1 |
| B8 | `m_none_oder_none_none_none` (bd `1m5p` class A) | the LIFO inversion | 25, **1 dirty** | 27, **0 dirty** | **YES** |
| B9 | `p2c_parent_gated_inside` (clause (iii), borrowed parent gated inside `L`) | lens 6 | 39, 0 dirty, 4 free verified | **byte-identical** | n/a — `-O1` fully unrolls it, so it has no loop. Confirms `IMPL_T3.md` F-R2-1's third row independently |

### B.1 The three most different lowered-IR deltas, with the per-trip argument (`a1_apost` is the one to read)

**`a1_apost` — ORACLE vs SUBJECT, and the ORACLE is the miscompile.**

```
ORACLE                                     SUBJECT
 7 sqrt_f64(h3) -> h4                       7 sqrt_f64(h3) -> h4
 8 fadd_f64_hl_unc(h3, h2, 3.0)             8..19  the two trips' fcmp/x/ry_controlled/fcmp_unc/free
 9 free(h3)                                20 sqrt_f64_unc(h4, h3)
10 sitofp_unc(h2, h0)                      21 free(h4)
11 free(h2)                                22 fadd_f64_hl_unc(h3, h2, 3.0)
12..23 the two trips                       23 free(h3)
24 ry_i32(h0, 0.7)      <-- h4 STILL LIVE  24 sitofp_i32_to_f64_unc(h2, h0)
25 measure(h0)                             25 free(h2)
                                           26 ry_i32(h0, 0.7)   <-- nothing live
                                           27 measure(h0)
```

*Per activation.* The chain `h2 ⊕= sitofp(h0)`, `h3 ⊕= h2+3`, `h4 ⊕= sqrt(h3)` is three
out-of-place copies, minted **once** in the preheader. Per trip the body mints `h5 ⊕= [h4 > 3]`,
brackets it, fires `ry_i32_controlled(h5, h1, 0.9)`, strips `h5` with its own inverse and frees it
— **1 : 1 within the trip**, and `h4` is only ever an operand, never written. At the loop exit the
SUBJECT adjoints the chain **LIFO** (`h4`, then `h3`, then `h2`), each against a parent that still
holds its forward value, so each reaches `|0⟩` and each free is proven-`|0⟩`. **Multiplicity 1 : 1**
— the forward gates are in the preheader (once), the adjoints in the unique exit block (once).
`cqrt_ry_i32(h0, 0.7)` then runs with **no** record of `h0` alive.
The ORACLE instead discharges `h3` and `h2` **before** the body and never discharges `h4` — the
`1m5p` LIFO inversion — leaving `h4 = sqrt(sitofp(h0)+3)`, a coherent which-path record of `h0`,
standing at a **non-diagonal** gate on `h0` which is then the observable. **That is Rule 8 verbatim
and it is a wrong unitary.** The warning going silent on the SUBJECT is a consequence of the
discharge, not of the warn stage looking away: **the same warning still fires on A1/A2/A3/A4/A10
on the SUBJECT**, where it is a false positive (F-R2-3's `recordIsExemptAt` clause-4 gap). **So the
warning is noisy in BOTH directions and must not be cited as a discriminator for this class** — a
point `IMPL_T3.md` makes for `t5j` only; I measured it on five more modules.

**`b1` (depth 3).** `mul_i32_hl(h0,3) → h1` once; 8 innermost reads, each minting its own
`lshr`/`and` pair; then **one** `mul_i32_hl_unc(h1, h0, 3)` + `free(h1)` **after the whole nest**.
`h1` is written twice (forward, adjoint) with `h0` unchanged between, so `h1 = |0⟩` at the free.
Had `anchorForConsumer` taken `LI.getLoopFor` (innermost) instead of walking to the outermost
non-containing loop, the adjoint would sit at the **inner** exit and run 4× against one forward
gate. It does not. **The OUTERMOST choice is measured at depth 3, not only argued.**

**`b2` (two sibling loops).** One `mul_unc` after **both** loops. A discharge at loop 1's exit
would have zeroed a rail loop 2 then reads — the anchor set is the union over all consumers and
`dagInsertPoint` post-dominates all of them, which is what makes this right rather than lucky.

---

## FINDINGS

### F-1 (**P1 — OVER-ACCEPT / WRONG UNITARY**). bd `6n1s` is **NOT CLOSED**: a MARKED multi-block body whose ARM mints an INTERIOR rail still leaks its coherent which-path records at a non-diagonal gate, and `markedBodyRailsHaveInBodyDischargePoint` returns **TRUE** on it

**Reproducing probe:** `$SES/review_r13_group1/probes/g8_arm_use_derived_owned_rot.c`.
**Isolating controls:** `g8a_arm_measured_directly_control.c` (**one token**), `g8k_arm_use_derived_unmarked_control.c` (the marking).

```c
for (int k = 1; k <= 4; ++k) {
    int d = (y >> k);
    s += cq_measure(d & 1);
    if (k < lim) { int e = d + 7; s += cq_measure(e & 2); }   /* re-joins; NO break */
}
y = cq_theta(y, 0.9);
return s + cq_measure(y);
```

**Measured, four binaries:**

| binary | verdict |
|---|---|
| PRE-GROUP `0e280fc6` | **DECLINE** exit 1, `cq loop lowering: rolled body leaks a rail entangled with a register rotated after the loop` |
| ORACLE `9bd01598` | ACCEPT exit 0, warning only, 19 trace lines, **2 dirty**, **0 `cqrt_free` sites** |
| **SUBJECT `7c1163ad`** | **ACCEPT exit 0, lowered IR byte-identical to the ORACLE's — UNMOVED.** At IR level on both: `exit=0`, **0 `_unc`**, **0 `cqrt_free`**, 2 `cq_template_ashr` mint sites (rolled ⇒ 4 dynamic) |
| **P0+P3 `e951d5d1`** | **ACCEPT exit 0, `2 dirty`, `0 cqrt_free` — UNMOVED there too** |

**So it is a REGRESSION** (from bd `tu9q`.1's third `markIfRailLocal` call site, exactly as for
`t5j`) that **neither** the landed prefix **nor** the WIP branch closes.

**Why it is a wrong unitary and not a Rule-6 accepted leak.** Trace: four
`cq_template_ashr_i32_hl(h0,k) → hK` mints, **zero** `_unc`, **zero** `cqrt_free`, then
`cqrt_ry_i32(h0, 0.9)` and `cqrt_measure_i32(h0)`. Each `hK` is a full 32-bit coherent copy of
`h0 >> k`; only `hK & 1` (and on one trip `(hK+3) & 2`) is measured, so bits `k+1..31` of `h0`
stay entangled in four live registers across a **non-diagonal** gate on `h0`, and `h0` is the
observable. `CLAUDE.md` Rule 8 verbatim, and §5's Q-R1-1 correction in its own words:
*"Where the same register is rotated by a NON-DIAGONAL gate after the loop and then measured, it
is a wrong unitary."* This is the **same defect, same signature and same door** as the P1 the
loopconv review filed as `6n1s`.

**The isolation is a ONE-TOKEN delta, and it names the discriminant.** `g8a` is `g8` with `& 2`
deleted from the arm, so the arm's template rail becomes **measure-owned** instead of **interior**.
`g8a` moves `1 dirty / 0 free → 0 dirty / 4 unc / 4 free` on the SUBJECT. `g8` does not move at
all. **The discriminant is "the arm mints an INTERIOR rail".** `g8k` (same two blocks, marking
refused) DECLINES on every binary with the dephasing string, so **the marking is the door**, by
measurement and not by reading.

**Root cause, read in source (`LoopLowering.cpp:4525-4586`, `Uncomputation.cpp:1240-1245`), with
the block structure of the emitted module (`%4` header / `%9` arm / `%11` join):**

* `markedBodyRailsHaveInBodyDischargePoint` folds one post-dominator over
  `{%4, %4, %9, %9, %9}` = `%11`, checks `LI.getLoopFor(%11) == L` ✔ and
  `IterationLocalBlocks.count(%11)` ✔, and **returns `true`**. Conjunct (1) suppresses the fence.
* `Uncomputation::planInteriorComponent` sets `At` = `%11`, the 6n1s relaxation **correctly**
  admits the arm's *read* of `%h_op` (same marked header; `everyPathReExecutes(%11 ⇝ %9)` goes
  through `%4`, which re-mints it), and then **§4 abandons the whole component** because the arm's
  **producer** gate `%h_op2 = cq_template_add_i32_hl(%h_op, 3)` is in `D.Calls` and
  `DT.dominates(%h_op2, At ∈ %11)` is **false**.
* **The fence models ONE refusal mechanism (a missing post-dominator) out of several, and the one
  a MULTI-BLOCK body produces by construction is not it.** `IMPL_T3.md` §1.2/§6.4 lists the
  mechanisms it does not model as *"clause (d), `preservesBasisUnderRecord`, or a `ReversedGates`
  overlap"* — **§4's per-gate dominance is missing from that list**, and it is the one that matters
  for the very shape class the fix exists for.

**What a fix needs.** The machinery to ask the real question already exists and already runs in the
right place: `emitDeferredDephasingDecline` is called at `CQLoweringPass.cpp:938 / :1331`, **after
`uncompute` (`:872 / :1315`)**, in both entry points. So conjunct (1) can **record** the
suppression and **verify the discharge as a FACT** at the tail of `uncompute` — the
`declineSurvivingIntrinsicCalls` pattern `markedBodyRailsHaveInBodyDischargePoint`'s own header
names as *"the more total alternative, deliberately NOT taken here because it moves the diagnostic's
site"*. **F-1 is the measured reason to take it.** P0+P3's `declineUndischargedExitObligations` is
that pattern, already built and already reachable (§C.4) — it is the right shape, aimed at a
different ledger.

**RED-GREEN PAIR TO WRITE WITH THE FIX:** RED `g8_arm_use_derived_owned_rot.c`, GREEN
`g8a_arm_measured_directly_control.c` (one token), isolating control
`g8k_arm_use_derived_unmarked_control.c` (the marking). All three are in
`$SES/review_r13_group1/probes/`.

**bd-fileable text (I filed nothing):**

> **P1 OVER-ACCEPT — bd `6n1s` is not closed: a MARKED multi-block loop body whose ARM mints an
> INTERIOR template rail still leaks coherent which-path records at a post-loop non-diagonal gate,
> and conjunct (1)'s new `markedBodyRailsHaveInBodyDischargePoint` returns TRUE on it.**
> Found by the independent Rule-13 review of Group 1, session 2026-09-18.
> WITNESS `g8_arm_use_derived_owned_rot.c`: DECLINE on PRE-GROUP `0e280fc6`; ACCEPT exit 0 with
> 4 `cq_template_ashr_i32_hl` mints, ZERO `_unc`, ZERO `cqrt_free`, then `cqrt_ry_i32(h0,0.9)` +
> `cqrt_measure_i32(h0)` on ORACLE `9bd01598`, on SUBJECT `7c1163ad` (bd `6n1s`+P1+P2) **and** on
> P0+P3 `e951d5d1`. Stage 2b `2 left dirty, 0 cqrt_free site(s)` at exit 0 on all three.
> ISOLATION: `g8a_arm_measured_directly_control.c` is ONE TOKEN away (`(d+7)` for `(d+7)&2`, making
> the arm's rail measure-owned instead of interior) and the SUBJECT DISCHARGES it 4/4;
> `g8k_arm_use_derived_unmarked_control.c` (same two blocks, marking refused) DECLINES with
> `rolled body leaks a rail entangled with a rotated register` on every binary — so the MARKING is
> the door and the ARM'S INTERIOR RAIL is the cause.
> ROOT CAUSE: `markedBodyRailsHaveInBodyDischargePoint` models only the "is there an in-body
> post-dominator" refusal; `Uncomputation::planInteriorComponent` §4 abandons this component on the
> per-gate `DT.dominates(G, At)` for the ARM-minted producer, a mechanism a multi-block body
> produces by construction and which `IMPL_T3.md` §1.2/§6.4's disclaimer list omits.
> FIX SHAPE: record the suppression and VERIFY the discharge at the tail of `uncompute` (the
> `declineSurvivingIntrinsicCalls` pattern the predicate's own header names, and the shape P0+P3's
> `declineUndischargedExitObligations` already implements) — `emitDeferredDephasingDecline` already
> runs after `uncompute` in BOTH entry points, so the slot exists.
> RED `g8`, GREEN `g8a`, control `g8k`, all in `$SES/review_r13_group1/probes/`.
> Cross-reference bd `6n1s` (do NOT close it), bd `s82e`, bd `tu9q`.1 (the regression's origin).

### F-2 (P3 — a fence with no measured customer in either direction, and a claim that should say so). `markedBodyRailsHaveInBodyDischargePoint` returned **TRUE on every module I measured**, including the one where TRUE is wrong

`IMPL_T3.md` §6.5 already says *"No module was constructed on which [it] answers `false`"*. I add
the other half, which changes how the conjunct should be described: the implementer's own hand-off
corpus sweep is **6566 rows, 16 movers, ZERO VERDICT FLIPS**, so the conjunct **declined nothing
new anywhere in the tree**; and F-1 is a module where its `true` is a **false negative**. Across
my 19 probes it never once returned `false`.

**Therefore bd `6n1s`'s P1 was closed — for the shapes it *is* closed for — by the USE-SIDE
relaxation alone** (`useCompleteBeforeDischarge` makes the rails actually discharge, so conjunct
(3) never needs to fire). The fence half contributed nothing I could measure. That is not an
argument to delete it — a sufficient condition that is sound in the decline direction is fine to
keep — but the source currently reads as if it were the fix's fence, and `CLAUDE.md` L10 is
explicit that *"a fence with no reachable customer and no failing fixture is a prediction, not a
test"*. **Say that at the site**, with F-1 as the measured reason.

### F-3 (P3 — load-bearing source prose that is incomplete, `CLAUDE.md` L7-with-a-twist). Two claims must be corrected in the same change as F-1

1. `markedBodyRailsHaveInBodyDischargePoint`'s header and `IMPL_T3.md` §1.2/§6.4 enumerate the
   refusals the predicate does not model as *"clause (d), `preservesBasisUnderRecord`, or a
   `ReversedGates` overlap"*. **Add §4's per-gate `DT.dominates(G, At)` on an ARM-minted interior
   rail, and say it is the one a multi-block body produces by construction** — i.e. the one this
   predicate's own shape class generates. Without it the list reads as exhaustive over exotic
   cases while omitting the ordinary one.
2. `IMPL_T3.md` §8 item 1's case split is written over `R->users()` — *"what the reversal
   touches"*. F-1's mechanism is a gate that is **not** a user of `R` at all. **State the split's
   scope**: it argues the relaxation does not admit a *bad adjoint*; it says nothing about whether
   the component the relaxation keeps alive will be **planned at all**, and conjunct (1) has
   already promised the fence that it will be.

This project has paid three rounds on one sentence for exactly this (`CLAUDE.md` L7-with-a-twist):
fix the comment in the same change, or the next round re-derives F-1.

### F-4 (P3 — MY OWN INSTRUMENT, and a PROTOCOL finding for `MERGE_FILINGS.md`). The session scratchpad is SHARED between parallel agents, and another agent's harness overwrote mine mid-review

`CLAUDE.md` L10: *"an instrument's failure mode is to report a pass"*. Mine did.

I wrote `probe.sh` into the session scratchpad at 11:2x. At 14:44 **another agent in this session
wrote its own `probe.sh` to the same path** — a harness hard-coded to worktree
`agent-ac2acfdde3461becc` and a different binary. My next batch ran **that** script: it printed a
plausible, well-formed result block for `g8a` stamped `96d74fe6008133b8` — **a third binary,
neither the ORACLE nor the SUBJECT** — and I came within one glance of recording it. It was caught
only because the output *format* differed from my own. The contributing error was mine and is the
loopconv review's F-4 verbatim: **`set -- $b` in zsh does not word-split**, so my two-field loop
passed one argument and an empty `BUILD`.

Everything in this review was **re-measured from scratch** on a PRIVATE harness
(`$SCRATCH/r13g1_private/gp.sh`) that self-attacks before use (0-byte `.c` → `VACUOUS-EMPTY`,
quantum-free `.c` → `VACUOUS-NOQUANTUM`, both exit 2 — run and recorded in `GATES.md`) and stamps
the binary's sha256 on every row. **No number in this review comes from the shared path.**

**For `MERGE_FILINGS.md`:** `PROTOCOL.md` §6.1 governs *gates*; it says nothing about **shared
writable scratch**. Two agents writing the same filename in one session scratchpad is a silent
cross-contamination channel with no diagnostic. Recommend one line in the protocol: *every agent
works in `$SCRATCH/<its own track or review dir>/`, never at the scratchpad root.*

### F-5 (P3 — an unwitnessed conservative branch, independently re-confirmed). `loopExitDischargePoint`'s null (multi-exit) path still has NO constructed customer

`IMPL_T3.md` F-R2-1 records three C shapes that `-O1` neutralised. I built a **fourth**
(`b4_two_exit_blocks_hoisted.c` — two `return`s with distinct `volatile` side effects and distinct
values) and `-O1` **merged them into one exit block** (`%27`, preds `%6` and `%21`). So the count
is now four attempts, zero customers, and the branch remains a **prediction, not a test**
(`CLAUDE.md` L10, bd `8h7d.10`'s lesson). It is the safe direction — a null result is a leak, never
a wrong unitary — so this is P3, not a blocker. Worth one sentence at the site recording that the
attempt count is four and that the obstacle is `-O1` exit merging, so the next agent does not spend
a round on a fifth C spelling.

### F-6 (P3 — over-decline candidate, per the owner's 2026-09-11 ruling). A rail minted in the MIDDLE loop of a 3-deep nest and read in the innermost leaks on every binary

`b1b_depth3_mid_mint.c`: `2 cq_template_mul_i32_hl` mints, **0** `_unc`, **0** free, on ORACLE and
SUBJECT alike. `anchorForConsumer` correctly stops at the **inner** loop (the middle loop contains
the mint), and §2.9 then refuses a repeating unmarked `At` — the leak is the *safe* answer and the
*correct* one is not reachable because the middle loop's body carries no marking. **The correctness
property holds** (it is emphatically NOT discharged once after the whole nest, which would be one
adjoint against `K_mid` forward gates). Per the owner's ruling that an over-decline of a valid
circuit is a defect to file rather than a safety margin, this is the next rung of P2's capability
and belongs on bd `tu9q`'s follow-on list, not in this landing.

---

## C. P0+P3 — SCOPED OPINION (not a clearance)

Measured on `e951d5d1bc072902`, `opt` + stage 2b + lowered IR only (no runtime archives in that
worktree ⇒ **no link, no trace, no golden**). I ran **no suite** on it.

### C.1 Question 1(a) — is each move the RIGHT direction?

**Mover 7, `loop_pairing_reject_round2_falsified.ll` — YES, and I give the argument off the
emitted module rather than off the implementer's reading.** The fixture's own header justifies its
decline as *"`%m2`'s forward gate is in the loop PREHEADER and runs ONCE, while a marked body's
discharge point runs K times … K adjoints against ONE forward gate"*. The P0+P3 module is:

```
entry:  ... %out1 = cqrt_alloc_i32(0) ... %h_op = cq_template_mul_i32_hl(%out1, 2)      <- ONCE
loop:   %h_op4 = lshr_i32_hl(%h3, %k) ; %h_op5 = and_i32(%h_op, %h_op4)
        lshr_i32_hl_unc(%h_op4, %h3, %k) ; cqrt_free(%h_op4) ; measure(%h_op5)          <- 1:1 per trip
out:    cq_template_mul_i32_hl_unc(%h_op, %out1, 2) ; cqrt_free(%h_op)                  <- ONCE
        cqrt_ry_i32(%h3, 0.9) ; measure(%h3)
```

*Per activation:* `%h_op` is written exactly twice, by its forward gate in the preheader and by its
adjoint in the unique exit block, with `%out1` unwritten between them (the body only READS `%h_op`,
into `%h_op5`), so `%h_op = |0⟩` at the free — **1 : 1, not K : 1**. The body's own `%h_op4` is
minted and stripped within the trip. `%h_op5` is measured (`cqrt_measure_i32` collapses all 32
bits), so it is not a coherent record at the trailing `cqrt_ry_i32(%h3, 0.9)`. **The hazard the
fixture names is refuted by construction; P1 supplies the missing multiplicity test and P2 supplies
the point.** The flip is right.

**Mover 8, `control_inplace_ry_reject_rail_inloop_carried_invariant_read.ll` — NOT the right
direction, and I re-measured it myself rather than citing:** SUBJECT declines at
`cq controlled lowering: control flow inside a loop body under quantum control`; P0+P3 declines at
`cq loop lowering: hoisted invariant rail admitted for in-loop discharge was not discharged`. The
verdict is unchanged (safe), but the fixture's own **L8 trigger** predicts an **ACCEPT** the day
*"`markIfRailLocal` can mark a body that reads a loop-invariant tainted rail"* — clause (ii-d) is
exactly that, **the condition is met and the predicted outcome is not delivered**. P3 grants a
marking the placement cannot keep, and the postcondition retracts it. I agree with
`P0P3_STATUS.md` §4's own reading. ⚠ Note the contrast with F-1, because it is instructive: **here
the design predicts and then VERIFIES, and the verification catches the over-grant. In F-1 the
design predicts and never verifies.** Same increment, two different postures, and the measurement
says which one works.

**Movers 1–6 — YES.** I re-measured 1–3 on both binaries: all three go DECLINE
(`rolled body leaks a rail entangled with a rotated register`) → **exit 0** with
`0 template rails left dirty` under STRICT 2b, i.e. `mint == _unc` on every template rail, **with
the trailing non-diagonal gate still present**. That is Question 3's first half and the answer is
yes. Rows 4–6 are IR-only moves already half-landed on the delivered branch.

### C.2 Question 1(b) — does any fence lose its LAST pinning fixture?

**YES, one: `declineRound2FalsifiedRailGrants`.** Grepped by me on the delivered tree, not cited:

```
grep -rln "round-1 iteration-local marking falsified" ir-pass/test/   -> 1   (loop_pairing_reject_round2_falsified.ll)
grep -rn  "round-1 iteration-local marking falsified" ir-pass/src/LoopLowering.cpp -> 1 (:4349)
```

P0+P3 flips that one file to exit 0 ⇒ **the fence is pinned by NOTHING**. It is also the tree's only
demonstration that the L1 window is *constructible at all*, and it carries **no L8 retirement
trigger**, so nothing instructs the next agent on the correct post-flip state. The other two
affected fences keep 6 of 9 and 24 of 25 respectively (`P0P3_STATUS.md` §5) — so this is not a
typical conversion, it is Rule-12 debt.

⚠ **And the fence is not obviously dead, which is why the debt is real rather than bookkeeping.**
Its refusal covers **any** round-2 falsification of a round-1 marking; P1+P2 handle only the
**hoisted out-of-place TEMPLATE rail** route. A round-2 delta that makes a header phi tainted, that
produces a tainted-index memop in the body, or that admits a `cqrt_alloc`-minted `%out` rail as
in-body data is untouched by P1. **A new RED fixture along one of those routes is the obligation.**

### C.3 Question 2 — is P3's (ii-d) marking RECORDED and RE-ASKED? **NO, at one of its two grant sites**

Read in source on the P0+P3 tree:

* `lowerLoops` (`LoopLowering.cpp:5929-5932`): `invariantRegisterRoots(...) && markIfRailLocal(...)`
  **then `recordRound1RailGrant(L, taint, Roots)`** ✔ — re-asked by
  `declineRound2FalsifiedRailGrants` (`CQLoweringPass.cpp:824 / :1287`, after the fixpoint, in
  **both** entry points).
* `collapseFlattenedLoopRails` (its two `markIfRailLocal` call sites): it **calls
  `invariantRegisterRoots`** — hence **clause (ii-d)** — and then `markIfRailLocal`, with **NO
  `recordRound1RailGrant` at either site**. Its round-1 invocation is `CQLoweringPass.cpp:600`,
  **before `repropagateControlMerges` at `:616`**.

So **P3 adds a new class of admissible root to a predicate that one call site asks at round-1 taint
and nobody re-asks** — `CLAUDE.md` L1's PREDICATE species. This window is **pre-existing** (bd
`0kjo`; SCOPE_T2 §2.5(2) and `IMPL_T3.md` F-R3-1 both name it) and **F-R3-1's statement that the
landed prefix does not widen it is correct** — but P3 does widen it, and `IMPL_T3.md` F-R3-1 says
so in one clause that is easy to read past.

**Partial mitigation, stated with its limit.** The (ii-d) obligation ledger is populated inside
`invariantRegisterRootsImpl`, so the **collapse site's grants are in it**, and
`declineUndischargedExitObligations` runs at the end of `uncompute` — module-scoped, after the
fixpoint. I verified the ledger is not wiped in between: `exitDischargeObligations().clear()` sits
at the **top of `lowerLoops`** (`:5811`), and `repropagateControlMerges` calls
`collapseFlattenedLoopRails` but **not** `lowerLoops`, so round-1 obligations survive to the
postcondition. **But the postcondition is a PRESENCE check** — it inserts `getArgOperand(0)` of
every `*_unc` and `cqrt_free` into one set and asks membership. It does **not** check that the
`_unc` is the matching inverse, and it does **not** check multiplicity. **So it catches "granted
and never discharged" and relies entirely on P1 for "granted and discharged the wrong number of
times".** That composition is sound only while P1 is in the same binary — which is an argument for
landing P0+P3 **on top of** P1+P2 and never separately, and for saying so at the ledger.

### C.4 Question 3 — is the loud postcondition reachable? **YES, and it has a measured customer**

Unlike `markedBodyRailsHaveInBodyDischargePoint` (F-2), `declineUndischargedExitObligations` has a
real `false`-answering customer: mover 8 declines at its string, re-measured by me on
`e951d5d1`. Its slot is well argued and I checked the argument rather than reading it: it is called
from **inside `uncompute(M)`** (`Uncomputation.cpp:2057`), which both entry points call, so it
inherits both call sites instead of needing to be added twice; and it is **outside** the
`for (Function &F)` loop, which its own retirement trigger correctly identifies as load-bearing
(the ledger is module-scoped and self-clearing, so a per-function call would read an emptied ledger
from the second function on — and bd `1yeu` records that every corpus in this tree is one function
per module, so nothing would go red). **That trigger is correct and worth keeping.**

⚠ Two P3 notes on the ledger, neither a blocker: it is a **function-local `static
std::vector<WeakTrackingVH>`**, i.e. mutable module-global state in a pass — not thread-safe under
any parallel module pipeline, and its correctness depends on the clear-at-both-ends discipline
being maintained by hand at three sites. And `declineUndischargedExitObligations` skips a root whose
`WeakTrackingVH` has been nulled (`continue`), which silently converts "the root was erased" into
"no obligation" — sound today, but it deserves the sentence saying why.

### C.5 Does P0+P3 close F-1? **No.** `g8` is byte-identical on `e951d5d1` (`2 dirty`, `0 free`)

Recorded so nobody reads "P0+P3 also fixes the leak family" from its ledger. My Part-B set shows no
regression on P0+P3 either (`b1` 0 dirty / 4 free, `b2`/`b3`/`g6` unchanged vs the SUBJECT).

### C.6 VERDICT — **P0+P3 is landable this session iff ALL SIX hold**

1. **A new RED fixture pins `declineRound2FalsifiedRailGrants`** by a route P1 does not reach
   (`P0P3_STATUS.md` §2 names three candidates; none is constructed). Landing with **zero** pins on
   a live Rule-13 fence is the Rule-12 debt this project has twice paid for.
2. **Mover 8's L8 trigger is corrected at the site** — its condition is met and its prediction is
   falsified; leaving it is `CLAUDE.md` L7-with-a-twist, which cost three rounds on one sentence.
   Either (ii-d) refuses that shape up front or the trigger is rewritten to describe the
   postcondition outcome. A fixture edit alone is not enough; §4 of `P0P3_STATUS.md` says so.
3. **The (ii-d) L1 window is closed or explicitly owner-deferred**: `collapseFlattenedLoopRails`'
   two `markIfRailLocal` sites get `recordRound1RailGrant` (the cure is the pattern and the
   function already exists and takes the same arguments), **or** bd `0kjo` is updated in writing to
   say P3 widened its population and the postcondition is the accepted interim.
4. **The postcondition's reliance on P1 for multiplicity is written at the ledger**, with the
   consequence stated: P0+P3 must never land without P1 in the same binary.
5. **Rows 1–3 get an e2e slice pair.** `IMPL_T3.md` §6.2 already flags the missing
   `slice_loop_pairing_hoisted_template{,_unrolled}` as P3's; these are the increment's only
   `mint == _unc` witnesses at the one layer that LINKS (Rule 16 done-criteria), and stage 2b is
   structurally `U3-extern-rail`-unproven for a loop-exit discharge (§6.3).
6. **A full `ctest -j6`, `ir-pass-lit`, a corpus sweep and the twin matrices run on the P0+P3
   binary.** `P0P3_STATUS.md` §6 is explicit that "8 movers" is a **lower bound over one lit
   filter**, not a tree-wide number. Per `PROTOCOL.md` these are the merge-and-gate agent's, not
   the implementer's or mine.

**My recommendation to the orchestrator**: P0+P3's design is the *right* one — it is the
predict-then-**verify** pattern, and its postcondition is the only fence in this increment with a
real customer. Obligations 1 and 2 are the ones that are genuinely another owner's call; 3–6 are
work. **If the session cannot carry all six, the safe split is to land P0+P3's postcondition
machinery aimed at F-1's ledger first** — it is the fix F-1 needs and it does not touch clause
(ii-d), `declineRound2FalsifiedRailGrants` or mover 8.

---

## What I did NOT attack

I built nothing and ran **no** suite, corpus sweep, injection matrix, twin matrix, duplicate-body
scan, `negative_vacuity_check.py` or `cq-opt-equivalence-full` — so I have **no tree-wide number**
and cannot say whether any shipped fixture, e2e slice or golden is a customer of F-1. **That is the
first thing a fix agent should measure and it decides F-1's blast radius.** I did not attack
irreducible cycles, multi-latch loops, the 512-block budget path, `EmitInverse` / `cq_invert`, or
`reverseTerminalGroup`'s mirrored multiplicity test (which the implementer states is expected never
to fire — I did not construct a module that reaches it, and neither did they). I did not construct
a **hand-written `.ll`** for `useCompleteBeforeDischarge` case (b) — I established only that
`clang -O1` cannot produce one from C, which is a statement about the *reachable* surface and is
bounded by two fences in other files (`declineClassicalMuxes`, bd `3d8q`), either of which could
move. I did not attack the `ANY→ALL` polarity half of the `emkg` fix. I did not attack P0's
component-merge `sameMultiplicity` or its `Borrowed` ordering drop beyond reading them. I did not
run Track V's nested-loop matrix axis against B1/B5, and I did not compose Group 1 with Group 2's
binaries — **a composition is not cleared by clearing its parts**, and three consecutive sessions
have filed on that sentence. Finally: every P0+P3 row is `opt` + 2b + IR only, because that
worktree has no runtime archives — **no trace, no golden, no link** on `e951d5d1`.
