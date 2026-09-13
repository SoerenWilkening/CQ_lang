# Rule-13 REVIEW, round 2 — Track M, on the round-1 FIX (`FIX_M_R1.md`)

Subject worktree `/Users/sorenwilkening/Desktop/CQ_mphi`, branch `mphi-rail-leaf`.
Review row of `../PROTOCOL.md`: **no build, no `ctest`, no `lit`** was run by this agent (I did not need
even the one permitted spot-check — every question below was answerable by the per-probe pipeline, which
the review row grants in full, plus static reading). Everything reported is either `ran:` by me or
`cited:` from `GATES.md`.

## VERDICT — CLEAR-WITH-ITEMS

The Rule-13 core change (ONE precedence edge in `lowerControlRegions`' `hcrg` graph) is **sound**, and its
soundness argument survives adversarial reading: a `SelectRegion` is a SINK in that graph (this edge is
the only way it acquires one, and it points INTO it), so no cycle can be created; Kahn either satisfies
every edge simultaneously or declines loudly; and the emitted STREAM is source-ordered independently of
the schedule, because every emitter inserts positionally. I found **no over-accept** and **no
miscompile**. The three items are a Rule-12 fixture gap on the increment's own new construct, a comment
whose premise its own commit falsified, and a negative-coverage gap.

## Build-side obligation (my ONE gate)

`ran: shasum -a 256 /Users/sorenwilkening/Desktop/CQ_mphi/build/ir-pass/cq-opt` →
`0d3105d0eb9d476a72ddb77a4e62e7899075dd6bb357b8b5ac3686171eac2d53` — **matches** the
`0d3105d0eb9d476a` that every round-1-FIX row of `GATES.md` names. `ran: shasum -a 256` on the ORACLE →
`fbbe0820ef4b176a…` / `libCQPass.so` `40e9c7a5…`, both **matching `PROTOCOL.md`**. No cited line is
stale.

Cited, not re-run: `ir-pass-lit` 1913 discovered / 1912 PASS / 1 XFAIL / 0 FAILED @ `0d3105d0` (M-fix,
19:1x); injection 87 applied / 0 MISSED / 1 N/A @ `0d3105d0` (M-fix, 19:1x); vacuity 63 named negatives /
11 fixtures / 0 VACUOUS @ `0d3105d0` (M-fix, 19:1x); corpus 2723 rows, 0 ACCEPT→DECLINE, 0 both-accept IR
changes, one mover `G6` @ `0d3105d0` vs `fbbe0820` (M-fix, 19:0x).

---

## Item 1 — the edge and Kahn

### 1(a) Can a `SelectRegion` acquire an OUTGOING edge? NO — and the `Kind` early-out is not what
### guarantees it

There is **no `Kind` test in the alias pre-flight at all**; the guarantee is the null block fields plus
`if (!Doomed) continue;`. Both directions check out, and I verified the premise rather than the comment:

* as `A` (outgoing): the loop tests `A.Pred/Arm/ArmFalse/MergeBB == Doomed` against a **non-null**
  `Doomed`; `classifySelectRegion` (`SelectClassify.cpp:1279-1300`) constructs a default `ControlRegion`
  and sets only `Kind`, `Merge`, `Condition`, `RailLadderProven`, `PrepRegionIdx` — all four block fields
  stay null, so no comparison can ever be true. `ran: grep -rn "Kind = ControlRegion::SelectRegion"` → **two**
  sites, `SelectClassify.cpp:1281` and `SwapRouteEmit.cpp:590`; the second is `emitValueRegion`'s
  synthesized region, which never enters `plan.Regions` and never reaches the graph.
* as `B` (incoming from the alias loop): `doomedBlocks(B)` yields `{null, null, null}`, every one skipped.

So the fix's structural claim — "this is the ONLY way a `SelectRegion` acquires an edge, and every such
edge points INTO it" — is **correct**, and a node with no outgoing edge cannot lie on a cycle. The Kahn
backstop keeps exactly the population it had.

### 1(b) `reorderable()`, and a FOURTH region before the prep

`reorderable()` is unchanged and still admits only `BranchRegion`/`PhaseKickback`; the prep is a
`BranchRegion`, so the compare-guarded prep customer (`i2_cmpladder`) is unaffected — it has no chain
alias at all.

I tried **three** constructions of the brief's "fourth region whose `MergeBB` IS the prep's `Pred`", and
**all three decline on BOTH binaries**, i.e. the shape is unreachable at HEAD and the edge has no such
customer today (`ran: ./review_M_r2_probes/run.sh`):

| probe | SUBJECT | ORACLE |
|---|---|---|
| `q01_kickback_before_prep.c` (bare-`i1` kickback before the prep) | DECLINE `branch phase on a bare i1 condition` | identical |
| `q04_region_before_prep.c` (compare kickback before the prep) | DECLINE `control flow` (anchor: the `cq_theta_i1`, via `CQ_CTRL_DBG=1`) | identical |
| `q06_rail_kickback_before_prep.c` (rail kickback before the prep) | DECLINE `control flow` | identical |

These are **pre-existing over-declines**, not regressions — named here because the owner wants them named
(ruling 2026-09-11), not because Track M caused them.

What I could measure instead is the ordering property itself, on the three shapes that DO accept. In each
the Kahn emission order differs from source order and the emitted STREAM is nevertheless source-ordered,
because each emitter inserts positionally (kickback → before its own `Pred`'s terminator; select → before
the `select` instruction; prep → hoisted into `Pred`, then flatten SPLICES the merge block in):

| probe | SUBJECT | ORACLE | stream order |
|---|---|---|---|
| `r03_order_third_region.c` (F-M1's own customer) | ACCEPT 33, 2b `3 free: 3 verified, 0 violation(s), 0 unproven` | DECLINE `control flow` | a-mux · prep · select · kickback = SOURCE order |
| `q03_select_phi_is_kickback_pred.c` (prep carries TWO outgoing edges, two kinds) | ACCEPT 34, 2b `3 verified, 0 violation(s), 0 unproven` | DECLINE `control flow` | + the second kickback's `cqrt_rz_i1(h0, 0.9)` LAST |
| `q02_two_selects_one_phi.c` (1(c), two selects on ONE φ) | ACCEPT 45, 2b `4 verified, 0 violation(s), 0 unproven` | DECLINE `control flow` | select#1 · kickback · select#2 = SOURCE order |

### 1(c) Two selects on one prep φ

`q02` is the case: `preppedRailPhiRegionIdx` returns the same index for both, so `Precedes[prep]` gains
two entries and `Pending` two increments — one prep, two sinks, still acyclic. The emitted stream gives
each select its **own** CNOT-copy ancilla (`h7` and `h10`), each X-bracketed, each un-copied and freed at
a proven `|0⟩`; the prep rail `h5` is read only as a control, never bracketed, never freed. Correct. The
F-M1 shape with a select whose φ region is also a following kickback's `Pred` is `r03` itself, re-measured
above.

### 1(d) ROUND-2 PLAN-INDEX CONSISTENCY — ANSWERED: **consistent by construction; a cross-round index
### cannot exist**

Measured statically, three ways, then probed:

1. `ran: grep -rn "PrepRegionIdx" ir-pass/src ir-pass/include` → exactly **ONE writer**
   (`SelectClassify.cpp:1299`, inside `classifySelectRegion`) and **ONE reader**
   (`SwapRouteEmit.cpp:2642`, inside `lowerControlRegions`). Everything else is comment.
2. `ran: grep -rn "Regions\.\(erase\|pop_back\|clear\|resize\|insert\)\|sort(.*Regions" ir-pass/src ir-pass/include`
   → **no hits**; 12 `Regions.push_back` sites. `plan.Regions` is append-only, so an index is stable for
   the life of the plan object.
3. `ran: grep -rn "detectControlRegions(" ir-pass/src` → three call sites, each of which constructs a
   **FRESH** plan and hands *that same object* to `lowerControlRegions` on the next line:
   `CQLoweringPass.cpp:455/456`, `:942/943`, and the round-2 fixpoint
   `TaintPropagation.cpp:1431 ControlPlan plan2 = detectControlRegions(…); :1434 lowerControlRegions(…, plan2)`.
   No `ControlPlan` outlives its own round and none is passed across rounds.

Therefore `PrepRegionIdx` is **always** an index into the plan of the round that wrote it. The brief's
"if a round-1 select survives into round 2's plan" cannot arise for a stronger reason than "it was emitted
in round 1": a round-2 select is a **newly classified** region, `classifySelectRegion` re-runs rung 0
against the **round-2** `plan`, and writes a fresh index. Even the pathological case where round 1's
`lowerControlRegions` returns early ("lower NOTHING") is safe — that plan is simply dropped, and round 2
re-derives from scratch. The `P >= N || P == i` re-check at `:2644` is therefore belt-and-braces, and its
`declineRegion` + `return` (rather than a silent `continue`) is the right disposition per Rule 1.

Probed as well: `q07_round2_third_region.c` = r20's 6.5-`%out` window **plus a third region after the
select**, so a round-2 plan would hold ≥2 regions. `ran:` SUBJECT **DECLINE `control flow`, exactly ONE
`error:` line**, ORACLE identical — i.e. round 1 still owns and refuses this window (round-1 finding F-M4
reproduces with the third construct present). The round-2 window has no accepting customer, so the index
question has no empirical subject either way.

---

## Item 2 — the unitary of the new accepts, re-derived

**`r03` (33 lines).** Source: `b0 = Ry(.5)|0⟩`; `a = b0 ? 2 : 5`; `b1 = (a>=3) ? Ry(.5)|0⟩ : |0⟩`;
`a = b1 ? a-3 : a`; `if (a==2) P(0.3)`. Emitted (`ran:` stage-4 trace): `alloc_i1→h0; ry_i1(h0,.5)` ·
the a-mux as the rail-root CNOT-copy merge on `h0` (`bf=h1`, `out=h2`, `copy_i32_controlled(h1,2,h2)`,
`x(h1)`, `copy_i32_controlled(h1,5,h2)`, `x(h1)`, `cnot`, `free(h1)`) · the prep by ADDITIVITY
(`alloc_i1→h5; ry_i1(h5,.5); ry_i1_controlled(h0,h5,−.5)`, i.e. `b1` is rotated exactly when `¬b0`, and
`a>=3 ⟺ a==5 ⟺ ¬b0` — `-O1` folds the compare on the two-constant select to `xor b0, true`, so the
condition IS the rail) · the hoisted arm chain `add_i32_hl(h2,−3)→h6` on the ORIGINAL register · the
merge-φ select's copy merge on `h5` (`bf=h7`, `out=h8`) · then **`icmp_eq_i32_hl(h8, 2)→h9`**.
**The brief's question: YES — the kickback's flag is minted from `h8`, the select's OUT rail, i.e. the
POST-select `a`, which is what the source's `a` denotes at that line.** `rz_i1(h9, 0.3)` fires on the
minted FLAG, never on a user register; the `_unc` strip returns `h9` to `|0⟩` and it is freed. The three
measures read `h0`, `h5`, `h8` — the post-select `a`. Rule 6: the only frees are `h1`, `h7`, `h9`, each an
ancilla returned to `|0⟩` by `x⊕x`/`_unc`; `h0`, `h5`, `h2`, `h6` are left allocated (`Ry(θ)|0⟩ ≠ |0⟩`,
plus the known B-keep leftover). **Correct.**

**`G6` (`control_swap_accept_select_mergephi_quantum_arm_then_prep.ll`, 26).** A QUANTUM select arm then a
prep. `ran:` lowered on the subject: users `%h`, `%h2`, `%h3`, `%out`; freed `%bf`, `%h_cmp`, `%h_cmp1` —
three ancillas, three frees, no user register freed, no `cqrt_x` on a user register (two X, both on `%bf`).
Consistent with the fix's `3 free: 3 verified`. **Correct.**

**The in-loop `r22` pair (43 = 43).** The brief asks whether the CNOT ancilla is freed every trip or minted
once. **Freed EVERY trip and re-allocated**, and the golden says so mechanically:
`ran: grep -c cqrt_alloc tests/e2e/slice_control_cascade_select_in_loop_outside_prep.expected.log` → **14**,
`grep -c cqrt_free` → **3**, over 3 trips — i.e. 2 pre-loop mints (`h0`,`h1`) + 4 mints × 3 trips, and one
free per trip, on distinct handles (`h2`, `h6`, `h10`). Each trip's ancilla is `alloc_i1(0)` →
`cnot(h1,·)` → bracketed → `cnot(h1,·)` → `free`, so `x⊕x = 0` makes every free a proven-`|0⟩` one.
**And the K-independence measurement proves nothing about this**: "78 lowered IR lines / 19 gate calls at
K=3 and at K=1000" is a **static** property of the emitted IR and witnesses only that the loop stayed
ROLLED — a rolled body executes the *same* `cqrt_alloc_i1` instruction on every trip, and whether that
yields a *fresh* rail is a RUNTIME property of `cqrt_alloc`. Only the trace (43 lines, distinct handles)
and the rolled-vs-unrolled byte-identity can witness it. The two gates are complementary and the record
should not let the static number stand in for the dynamic one.

---

## Item 3 — did the vacuity fix weaken any negative? **NO** — but it answered only half its own question

`ran: python3 ./review_M_r2_probes/negcoverage.py` over all **11** Track M accept fixtures. It derives the
USER REGISTERS mechanically from the LOWERED IR (a handle that is a `cqrt_ry_*` target or a `cqrt_measure_*`
operand and is never `cqrt_free`d) and the ANCILLAS (freed handles), then asks of each `NOX-NOT`/`NOFREE-NOT`
whether it (a) names an undefined handle, (b) points at an ancilla, (c) leaves a user register uncovered.

* **(a) 0 undefined** across 11 fixtures — the vacuity fix holds on the binary on disk.
* **(b) 0 point at an ancilla.** The brief's specific worry — "a negative that is non-vacuous but asks the
  wrong question" — is **not present**: every named handle (`%h`, `%h2`, `%h3`, `%h4`, `%h8`, `%out`,
  `%h_op`) is a user register or a left-allocated chain rail, never a `%bf`/`%h_cmp` ancilla.
* **(c) a gap, in all 11**: the merge-OUT rail — `%out3` (and `%out5` in `_two_selects`), the register the
  user's variable actually ends up in and the one every fixture MEASURES — is named by **no `NOX-NOT` in
  any of the 11**, and by no `NOFREE-NOT` in 8 of 11. An *extra* X or free is still caught by
  `XCNT`/`FCNT`, and a *substituted* one is caught by the ordered positive `CHECK` stream (which does pin
  every X and free operand by capture) — so this is defence-in-depth debt rather than a hole **on its own**.
  It stops being harmless exactly where the positive stream stops naming the gate: see F2-1.

---

## Item 4 — round 1's thin spots

**`p20` / F-M3, now GRADED: OVER-DECLINE (defect to remove, not a safety margin).** Re-derived from the
state vector rather than taken on trust. For `r16_p20.c` (`q = Ry(.2)`, `b = Ry(.4)`, `if (q>3) b =
cq_theta(b,.9)`, `a = b ? 2 : 5`): there is ONE physical rail for `b` — `lowerRotations` RAUWs the
pre-rotation name and the arm theta to the SAME `i32` handle (`Chained`), M-β RAUWs the merge φ to the arm
theta, and `SelectMergeEmit` inserts its ENTIRE stream immediately before the `select`, i.e. **after** the
hoisted `ry_i1_controlled`. So the CNOT copy reads exactly the basis `b` denotes at the source's `b ? 2 : 5`
— the circuit is valid and the compiler refuses it. The refusal comes from the SEED SET, not from the
physics: `condProvenance(φ)` walks the φ's operand edges and drags the PRE-rotation name into `RailProv`,
on whose wire the arm's own (non-diagonal) theta sits BEFORE the read point, and the DT prong only admits a
gate provably AFTER the select. **I endorse the fix's disposition**: pin it as a DECLINE
(`control_swap_reject_select_mergephi_inplace_arm.ll`, whose header states the over-decline in those words
and carries the bd `3d8q` retirement trigger) and do NOT narrow the seed — the same cone is the only thing
that catches a pre-rotation SIBLING reader, which is precisely the `3d8q` hole.

**Item 6's `3d8q` list.** `p3d8q_sibling.c` / `r15_p3d8q_sibling.c` are correctly recorded as reproducers,
and `GATES.md` records the measurement that matters: the rail spelling ACCEPTs on the **ORACLE** (30 lines,
2b clean) while the φ spelling moved DECLINE→ACCEPT here — i.e. the hole is PRE-EXISTING and Track M ADDS
CUSTOMERS to it. Nothing to add beyond confirming the framing is the honest one (a population change, not
a new defect).

---

## Item 5 — did the fix regress the `hcrg` sequential-region customers? **NO**

`ran:` both binaries over four `hcrg` customers, lowered IR compared byte-for-byte:

| fixture | subject exit | oracle exit | lowered IR |
|---|---|---|---|
| `control_swap_accept_seq_diamond_chain.ll` | 0 | 0 | **IDENTICAL** |
| `control_swap_accept_seq_ifelse_then_diamond.ll` | 0 | 0 | **IDENTICAL** |
| `control_swap_inloop_seq.ll` | 0 | 0 | **IDENTICAL** |
| `control_swap_accept_two_iterations.ll` | 0 | 0 | **IDENTICAL** |

Consistent with the cited corpus row (0 both-accept IR changes over 2723). I also checked the one place the
re-read could have changed a SHIPPED path: `emitValueRegion` synthesizes its region as
`Sel = SelectInst::Create(Cond, …); S.Condition = Cond` (`SwapRouteEmit.cpp:524,591`), so
`Sel->getCondition() == R.Condition` by construction and the H-1 re-read is a no-op for the value arm.

---

## Findings, graded

| id | grade | one line | reproducer |
|---|---|---|---|
| F2-1 | **MEDIUM — Rule-12 fixture gap** | the branch phase's `cqrt_rz_i1` has neither its TARGET nor its ANGLE pinned in the ONE Track M artifact that emits one: moving it onto `%h` (b0), `%h4` (the prepped b1) or `%out3` (the user's `a`), or changing 0.3→0.9, is MISSED by **all 11** prefixes; no e2e golden in this increment carries an `rz` at all | `review_M_r2_probes/rz_mutation.sh` |
| F2-2 | **LOW — DOC (premise falsified by its own commit)** | the F-M7 retirement-trigger comment (`SwapRouteEmit.cpp:2526-2536`) asserts "every region this lambda can be called with is block-carrying … the Kahn backstop skips a `SelectRegion` … it is always scheduled" — the fix's OWN new loop calls `declineRegion(Regions[i])` on a `SelectRegion` (`:2645`), and `Pending[select] ≥ 1` now lets a select be `!Done`. No live hazard (all three sites run BEFORE any emission, so `A.Condition` is live and both diagnose arms are available) | read `SwapRouteEmit.cpp:2526-2536` against `:2637-2650` |
| F2-3 | **LOW — negative-coverage gap** | the merge-OUT rail (`%out3`/`%out5`) — the user's answer register, measured by every fixture — is named by no `NOX-NOT` in 11/11 accepts and no `NOFREE-NOT` in 8/11; 0 negatives are vacuous and 0 point at an ancilla, so the vacuity fix itself is sound | `review_M_r2_probes/negcoverage.py` |
| F2-4 | **over-declines, PRE-EXISTING (named, not charged to Track M)** | the item-1(b) "region before the prep" shape declines on BOTH binaries under three constructions; the two-prep chain hits the F2 state-prep seed fence; the round-2 window still declines | `q01`, `q04`, `q06`, `q05`, `q07` |
| — | **no defect** | the edge cannot create a cycle; round-2 index consistency holds by construction; `hcrg` customers byte-identical; the value arm's re-read is a no-op; `r03`/`q02`/`q03` unitaries re-derived correct | above |

### Suggested dispositions (for the orchestrator, not decisions of mine)

* **F2-1** is a one-line fixture edit — `; CHECK: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 3.000000e-01)`
  between the existing `:204` mint and `:205` `_unc` lines of
  `control_swap_accept_select_mergephi_rail_then_kickback.ll` (the capture `%[[H_CMP]]` is already bound at
  `:204`), plus an `rz-target` row in the injection matrix. Worth doing inside this track: the gate it
  leaves unpinned is the exact one whose misplacement made every shipped Grover golden the identity
  (CLAUDE.md CORRECTNESS RISK §0), and the shape has no e2e golden to fall back on.
* **F2-2** is a comment correction at `SwapRouteEmit.cpp:2526-2536`: say that `declineRegion` IS now
  reachable with a `SelectRegion`, that it is safe because every call site runs before any emission, and
  that the F-M7 trigger is about the EMISSION-time readers instead.
* **F2-3**: add the `%out*` handles to `NOX`/`NOFREE` in the 11 accepts, or record in the fixture headers
  why the ordered positive stream is held to be sufficient for them.
