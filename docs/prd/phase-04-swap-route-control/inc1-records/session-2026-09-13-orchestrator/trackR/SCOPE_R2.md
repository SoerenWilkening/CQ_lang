# SCOPE — Track R increment R-2: the RIVAL AUDIT for *"a pinned value that is the condition of a conditional `br` is not an F2 collider"* (`vd`'s collider)

Written 2026-09-13 by the R-2 scoping agent. **READ-ONLY, measure-first**: nothing was built,
no suite was run, no file outside `trackR/` was touched (`../PROTOCOL.md`, row "scoping").
Every number carries its command; line numbers are `81956a2` (docs-only over the pass at
`e96f89c`).

```
shasum -a 256 build/ir-pass/cq-opt       fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661  == session ORACLE
shasum -a 256 build/ir-pass/libCQPass.so 40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93  == session ORACLE
ls docs/…/trackR/probes/r2/x_*.ll | wc -l                                          24   (5 ACCEPT, 19 DECLINE)
```

---

## HEADLINE — three sentences, and the second one is the finding

**(1) The audit is 14 rows and finds 0 HOLES**: in every spelling where R-2 would remove F2's
decline, a different shipped fence declines the rival, measured and named per row.
**(2) But the fence is NEVER 2c.** `condWireDisposition`'s prongs fire in **0 of the 24 probes**;
what actually declines the rivals is **R3** (`ArmClassify.cpp:4102-4103`, `control flow`) in 9
rows, **R6** (`:4420`, `stale rail record read past a controlled Ry`) in 1, and the
condition-data-use fence (`:3257`) in 1. The brief's premise — *"the rival puts a non-diagonal
gate between a compare and its own branch, which 2c declines unconditionally"* — is **not what
the binary does**, so R-2 spelled with that ground would be an argument nothing implements
(lesson L7's shape: a justification that hardens by repetition).
**(3) A strictly stronger and better-grounded narrowing fell out of the measurement** — the
**ONE-EDGE** rule of §0.4 — which closes `vd` by a *complete case analysis over F1* instead of by
a syntactic property of a `br`. It is not free: it flips ≥11 shipped decline fixtures, so it is
an owner decision, not a swap-in. **§4 recommends: do not build R-2 as spelled.**

---

## §0 THE RIVAL AUDIT

### 0.1 What a rival is, stated so the rows can be judged

F2 declines a module `%rm = phi [ %rt = cq_theta(K, θ), %arm ], [ K, %pred ]` (a controlled state
prep, seed `K`) when some live tainted `X` of the same type is provably `== K` on one edge of the
branch. The decline exists because that module can be `-O1`'s image of a **rival source** in
which the author wrote a REGISTER where the module now shows `K` — an in-place Ry on `X`'s rail,
a different unitary from preparing a fresh wire. R-2 removes the decline for a subclass of `X`.
It is admissible only on the 2026-09-11 α-form ground: *where the narrowing removes the decline,
the rival has no lowering to be robbed of.* A row where R-2 removes the **only** decline of a
**lowerable** rival is a HOLE.

Two structural facts decide almost every row, and both are measured here rather than assumed:

* **F1 pins the pred slot.** The subject's straight-through incoming is the literal `K`, and F1
  requires it to be pointer-identical to the seed. So a rival source folds into the subject only
  if **both** its uses of `X` became `K`: the arm's use (needs `X ≡ K` on the arm edge) **and**
  the merge's pred-edge use (needs `X ≡ K` on the pred edge).
* **R3 refuses the cross-handle rival.** `if (Routed && RotBase != Routed)` —
  `ArmClassify.cpp:4102-4103` — declines `control flow` when the rotated base is a register and
  the straight-through incoming is a literal. Measured both ways in one bisection:
  `x_B1` (pred slot `true`, base `%d`) DECLINES `control flow`; `x_B5`, the same module with the
  pred slot changed to `%d`, **ACCEPTS** (2b `1 mint, 1 verified, 0 violation(s), 0 unproven`).

### 0.2 The audit table — 14 rows

`SUBJECT` = the module R-2 makes lower. `RIVAL` = the unfolded source it could be `-O1`'s image
of. `fence` = what declines the rival TODAY, with the string verbatim. Probe files and the exact
commands are in `probes/r2/README.md`; cited rows are from `probes/README.md` at the same ORACLE
hash (PROTOCOL.md forbids re-running a recorded gate on an unchanged binary).

| # | spelling of "X is pinned AND X is a conditional `br`'s condition" | SUBJECT | RIVAL | fence that declines the rival | HOLE? |
|---|---|---|---|---|---|
| 1 | X = off-wire compare flag, ONE-edge pin, br AFTER the region (`…_second_flag_i1.ll` + a br) | `x_S1` F2 | `x_A1` | **R3** `control flow` (`:4103`) | no |
| 2 | the same with no br (the rival the shipped fixture header itself names) | `…_second_flag_i1.ll` F2 | `x_A2` | **R3** `control flow` | no (R-2 does not fire) |
| 3 | X = a **`trunc`-minted i1 rail** (not a compare), ONE-edge pin, br after | `x_B3` F2 | `x_B4` | **R3** `control flow` | no |
| 4 | X = a **merge-block** compare on the condition's wire (`vd` / `r_R6b` — THE customer) | `v_vd`, `r_R6b` F2 *(cited)* | `w_W2`, `w_W4` *(cited)* | `control flow`; `w_W4`'s stage-1 IR shows `-O1` DELETING the compare | no |
| 5 | the same rival spelled with the register in the pred slot | — | `w_W1` *(cited)* | **F1** `state prep seed does not match the merge incoming` | no |
| 6 | X = a **BOTH-edge** pinned rail (`icmp slt %q, INT_MIN`), br AFTER the region | `x_C7` F2 | `x_C5` | **R6** `stale rail record read past a controlled Ry` (`:4420`), anchored **on the `br` itself** | no |
| 7 | the same, X also measured after the region | `x_C1` F2 | `x_C2` | R6 (anchored on the measure) | no |
| 8 | the same, **no br at all** — the control that proves the collider class is real | `x_C4` F2 | `x_C6` **ACCEPTS** (2b clean) | *none — the rival LOWERS* | **not a hole: R-2 does not fire** (no br), and F2's decline is exactly right here |
| 9 | X = BOTH-edge pinned, its br runs **BEFORE** the prep region (so R6 cannot see it) | `x_D1` F2 | `x_D2` | **condition data use neither escaped nor measured** (`:3257`) | no |
| 10 | the same, with X measured before the prep region (an attempt to satisfy that fence) | — | `x_D3` | same fence, unmoved | no |
| 11 | X's br is **degenerate** (`br i1 %x, label %m, label %m`) — syntax, no region | `x_E1` **ACCEPTS today** | `x_E2` **ACCEPTS today** | *neither declines* | **not an R-2 row**: F2 never fires (the pass deletes `%x`; the lowered IR has no `icmp_slt` template), so R-2 has nothing to remove. Pre-existing pair, §0.5 |
| 12 | X's br sits in a block **not reachable from entry** | `x_E3` F2 | `x_E4` | **R3** `control flow` | no |
| 13 | BOUNDARY — X is a **switch scrutinee**, not a br condition | `x_F1` F2 | — | R-2 does not fire; F2 stands | n/a |
| 14 | BOUNDARY — X is a **select condition** | `x_G1` F2 | — | R-2 does not fire; F2 stands | n/a |

**Two spellings the brief lists and this audit did NOT measure, said plainly rather than
implied:** (a) *X branched on in a different function* — R-2's predicate says "in this function",
so an un-inlined callee's `br` does not count and the row is a boundary like 13/14; at `-O1` a
`static` callee is inlined and the row collapses into #1. (b) *X's br inside a loop* — every
in-loop state prep declines `control flow inside a loop body` before F2 is asked
(`ArmClassify.cpp` R7's loop half, quoted at `:4201-4206`), so the row has no subject today; it
becomes live only if bd `wx8g` lands, and it is a **retirement trigger**, not a measured row.

### 0.3 What the audit actually proves, and the part that is a complete argument

Rows 1–5 and 12 — **every collider a C program can produce**, `vd`'s included — are safe for a
reason that has nothing to do with the `br`: a **ONE-EDGE** pin admits only two rival spellings
and **both** are declined, exhaustively, by case analysis on F1's pred slot:

* pred slot = the literal `K` ⇒ the rotated base ≠ the straight-through incoming ⇒ **R3**
  `control flow` (`x_B1`, `x_A1`, `x_A2`, `x_B4`, `x_E4`, and the four cited `w_W2…W5`);
* pred slot = the register `X` ⇒ a tainted pred incoming ⇒ **F1**
  `state prep seed does not match the merge incoming` (cited `w_W1`), and that module is **not**
  the subject module at all.

There is no third spelling: F1 requires the pred incoming to be the seed *constant*, and a
one-edge pin cannot fold a register on the other edge. `x_B5` is the witness that this is a
statement about **folding**, not about lowerability — the one-edge rival with a matching pred
slot is a perfectly lowerable program (ACCEPT, 2b clean); it simply cannot become the subject.

Rows 6–10 are the ones where F2 is genuinely load-bearing: a **BOTH-edge** pin (a value provably
`== K` on both edges but still a distinct tainted rail) folds in both slots, and its rival
**lowers** (`x_C6` ACCEPT). There R-2's safety comes down to R6 and the condition-data-use fence,
and to *where the `br` sits relative to the region* — a position-dependent margin one CFG edge
wide. That is the thin part of R-2 and §4 weighs it.

### 0.4 The narrowing the measurement suggests instead (**R-2′**, for the owner, not for this increment)

> *A collider pinned on only **ONE** of the branch's two edges is not a collider, because F1
> makes the rival unfoldable: the rival's straight-through use of `X` would have to fold to the
> seed on the other edge too, and a one-edge pin does not.*

It closes `vd` (its `%9` is pinned on the TRUE edge only — surgeries S1/S2 and `r_R6c`, cited),
closes bd `rb9x` without R-1's record, and is grounded in a **case analysis**, not in a syntactic
property of a `br`. **It is not cheap and must not be treated as a swap-in:** it would flip the
≥11 `range_forward_*` / `sideways_*` / `merge_edge_sideways` / `step_cap_over` fixtures and
`…_second_flag_i1.ll` — all shipped, Rule-13-cleared DECLINES that are the recorded findings of
F2 rounds 2–3. Spot-measured, one of them is a one-edge pin
(`control_inplace_ry_reject_stateprep_range_forward_add.ll`: `%t = and %q, 1`, `%c = icmp eq %t, 0`,
`%fwd = add %t, 5` = the seed `6` on the FALSE edge only), so it would flip. Whether that is an
over-decline being removed or an over-accept being opened is exactly the owner's call, and
answering it is a scoping increment of its own.

### 0.5 A pre-existing pair the audit surfaced, filed rather than folded in (row 11)

`x_E1` and `x_E2` **both ACCEPT** and emit **different** streams — `alloc_i1(false)` +
`ry_i1_controlled` versus `ry_i1_controlled` onto the `icmp_slt` template rail — for two hand-IR
modules that differ only in whether a provably-constant flag is spelled into the two phi slots.
It is **not** an R-2 hole (F2 never fires; the pass deletes the flag in `x_E1`) and at the C level
`instcombine` deletes such a flag before the pass ever sees it, so no C source reaches it. It is
recorded here because it is the one place a `br` that R-2 would trust is provably adjudicated by
nobody, and because Rule 11 says to report what was measured, not what was expected.

---

## §1 THE 2c ARGUMENT, READ FROM THE SOURCE — and measured to be the wrong door

`condWireDisposition` is `ir-pass/src/ArmClassify.cpp:1976-2011`. Its prongs, in order:

| prong | site (81956a2) | kind | what it refuses |
|---|---|---|---|
| P4 (cross-block) | `:1982-1983` | structural | `Cond->getParent() != R.Pred` — an unbounded gap; `DeclineNow` |
| **P5 (the positional scan)** | `:1989-1998` | **position-AWARE, same-block only** | a `cq_theta_*` with a tainted arg-0 lexically between the compare and the branch, **even on another wire** |
| the position-FREE walk | `:2001-2003` | position-free | no gate at all ⇒ `None`, the ordinary accept |
| P2 `ShareCondFlag` | `:2004-2005` | structural | a flag that outlives the region |
| the position-AWARE walk | `:2008-2009` | position-aware (`provablyBefore` via `DT` + `!isPotentiallyReachable`) | a wire gate **not** provably after the whole emitted stream ⇒ `DeclineNow` |
| — | `:2010` | | `ProvenPostRegion`, carried to P1 and admitted for a homogeneous PHASE arm only |

**Measured: 0 of 24 probes decline through any of them** (`grep -c "condition predates a
non-diagonal gate"` over the 24 `CQDBG=1` anchors = 0). The reason is structural and worth
writing down: P5 is **same-block** and every rival puts its `cq_theta` in an *arm* block, while
the two wire walks are seeded from `condProvenance` and an `icmp` **mints a fresh rail**, so a
forward walk from the condition's provenance never reaches a theta whose arg-0 is a *compare
result*. `x_C6`'s ACCEPT is the direct witness: `%x = icmp slt %q, INT_MIN` rotated in place with
the branch condition `icmp sgt %q, 100` on the same `%q` lowers to `ry_i1_controlled(h_cmp,
h_cmp1, .9)` — neither 2c nor R4 (`:4207-4217`, `BaseWireOrder ∩ CondRails`) sees it.

**Therefore the retirement trigger cannot be written against `xqgx`.** Read from `bd show xqgx`,
A.2's three widenings are (1) `SelectClassify.cpp:946` (the DT prong for compare seeds),
(2) P1's `SawValueArm` clause (bd's `:3720` is an older tree; at 81956a2 the shipped
clause is `ArmClassify.cpp:4802`), (3) `SelectClassify.cpp:782`
(`AllowLogicalSelect` for data selects). **None of the three touches R3, R6 or the
condition-data-use fence**, so A.2 landing would neither retire R-2 nor endanger it. The
retirement condition for R-2 as spelled must instead be written as, verbatim and as three
`file:line` statements:

> R-2 becomes an OVER-ACCEPT the day any of these stops declining:
> `ArmClassify.cpp:4102-4103` (R3 — if a cross-handle merge of a rotated register against a
> literal ever lowers); `ArmClassify.cpp:4420` (R6 — if a post-region read of the pre-Ry name
> ever stops declining, or if a `BranchInst` user stops counting as a read); or
> `ArmClassify.cpp:3257` via `condDataUseDisposition` (if a `cq_theta` data use of a region's own
> condition ever becomes `ShareOk`). Re-derive §0.2 rows 1–5/12, 6–7 and 9–10 respectively.

---

## §2 THE SPELLING, if the owner builds it anyway

**Where.** One more conjunct at `f2SeedPinnedByLiveRegister`'s single test,
`ArmClassify.cpp:1616` — beside `!CondWire.count(V)` and R-1's `!Taint.PeelClones.count(V)` — so
all three exclusions filter an ANSWER and none prunes the WALK (`:1611-1615` states why, and
SCOPE_R §5's `control_peel_reject_fp_stateprep.ll` is the measured red-green witness that pruning
flips a deliberate capability cost into an unargued fp-mux accept). Order among the three
conjuncts is irrelevant: they are pure predicates over `V` with no side effects and no shared
state, and `&&`'s short-circuit only changes which one answers first.

**How "is a conditional `br`'s condition" is computed.** `any_of(V->users())` for a `BranchInst
*BR` with `BR->isConditional() && BR->getCondition() == V`. Three measured cautions:

* **It is SYNTAX, and the protection it buys is SEMANTIC.** `x_E1` (`br i1 %x, label %m, label
  %m`) and `x_E3` (a `br` in a block unreachable from entry) both satisfy the predicate while no
  region will ever be detected on them. Neither is a hole today (row 11 has no subject; row 12's
  rival dies at R3), but both are holes *in the argument*, so the predicate must additionally
  require `BR->getSuccessor(0) != BR->getSuccessor(1)` **and**
  `DT->isReachableFromEntry(BR->getParent())`. That is two extra clauses whose only purpose is to
  make the syntax match the semantics — which is L5's warning ("a syntactic answer to a semantic
  question loses") arriving before the increment rather than after it.
* **In THIS function only.** `V->users()` is module-wide for a `Constant`; `V` here is always an
  `Instruction`, so its users are function-local by construction — but say it, because R4's own
  comment (`:4193-4196`) records a `ConstantInt`'s use list spanning the module as a live hazard.
* **Round 2 can change the answer (L1).** `repropagateControlMerges` re-runs detection to a
  fixpoint, and `RegionFlatten` **erases** branches between rounds, so a `V` that was a branch
  condition in round 1 may not be one in round 2 — the predicate can flip from exclude to
  include. Because the flip direction is *towards declining*, it is safe as a decline but it means
  the two rounds can disagree; per L1 the answer must be **RE-ASKED in both entry points**, never
  recorded once, and a fixture must pin a `V` whose br is erased by round 1's emission.

**Interaction with R-1.** Independent: R-1 excludes `cq.peel.cond` (a value with no source
preimage), R-2 excludes a br condition (user code). They share only the site. R-1 does not touch
`vd` (SCOPE_R §4) and R-2 does not touch `rb9x`'s peeled clone (the clone's users are the peeled
`select`, not a `br`).

---

## §3 WHAT THE INCREMENT WOULD OWE

**New ACCEPT fixtures:** `r_R6b_downstream_cmp_branch.ll` (the minimal `vd` shape, hand IR — full
positive `CHECK`s for the emitted stream plus whole-file pure negative prefixes and the
`ACNT/FCNT/XCNT/RYCNT/CCNT` counts, modelled on
`control_inplace_ry_stateprep_bool_seed_int_cond.ll`), and `x_C7` (the both-edge pin with a br —
the row whose only protection is R6, so it must be a *fixture*, not a probe).
**Kept DECLINES, each with a RETIREMENT-TRIGGER header line naming R-2 (L8):**
`control_inplace_ry_reject_stateprep_second_flag_i1.ll` (`%d` measured, never branched on — the
row R-2 must NOT flip), `r_R6a_downstream_cmp_data.ll` (the same flag as DATA only), and one of
the `range_forward_*` / `sideways_*` family. **New DECLINE fixtures pinning the rivals** — this is
where the audit says the corpus is thinnest: R3 is cited by 9 rows and pinned as a *rival* by
none, so commit `x_A1` (R3) and `x_C5` (R6) as
`control_inplace_ry_reject_stateprep_rival_br_{crosshandle,postregion_read}.ll`. IMPL_f2's Q4b
records the same counter-argument about the 2026-09-11 narrowing and chose citation over
commitment; R-2 rests on *three* fences instead of two and should not repeat that choice.
**Injection matrix** over the two new accepts (an injected uncontrolled `cqrt_ry` on the
condition register after the flag's free), MISSED count reported.
**e2e slice.** `tests/e2e/slice_control_cascade_three_bools.c` = `probes/vd.c`, but **only after
Track M** — measured, `vd` needs M's wall gone as well (SCOPE_R §6). Its golden is Track M's
29-line stream plus the third region's kickback group (`icmp` flag mint → `cqrt_rz_i1` → the
`_unc` strip → one `cqrt_free`); compose it, then MEASURE it on the subject — never commit a
composed golden unread.
**Cost / rounds.** One conjunct + two syntax clauses + 2 accept fixtures + 3 kept declines + 2
rival declines + 1 slice + 1 matrix. **Budget 2 Rule-13 rounds**, and name round 2's assignment
in the brief: rows 6–10 (the both-edge family, where the margin is one CFG edge) and the round-2
flip of §2's predicate.

---

## §4 RECOMMENDATION TO THE OWNER

**Do not build R-2 as spelled; take R-2′ (§0.4) to a ruling instead, and leave `vd` declining
until then.** The audit found 0 holes over 14 rows, so R-2 is not *unsafe* — but its stated
ground is wrong (2c fires in 0 of 24 probes; the work is done by R3, R6 and the
condition-data-use fence), its predicate is syntactic in a way that needs two extra clauses to
stop meaning something it does not mean (`x_E1`, `x_E3`), and for the one family where F2 is
genuinely load-bearing — a collider pinned on **both** edges, whose rival demonstrably lowers
(`x_C6` ACCEPT) — the whole protection is *where the `br` happens to sit* relative to the region:
after it, R6 declines (`x_C5`); before it, the data-use fence does (`x_D2`); and the day either
moves for its own reasons, R-2 silently becomes an over-accept with no diagnostic anywhere. The
same measurement handed us a better instrument: for a **one-edge** pin — which is every collider
a C program produces, `vd`'s `%9` included — the rival is unfoldable by a **complete case
analysis over F1's pred slot** (literal ⇒ R3 `control flow`; register ⇒ F1 `seed does not match
the merge incoming`), so the decline can be removed with an argument, not with a syntactic
proxy. The cost is that R-2′ is a much bigger blast radius than R-2: ≥11 shipped decline
fixtures plus `…_second_flag_i1.ll` would flip, each one a recorded finding of F2 rounds 2–3, and
one of them (`range_forward_add`) is spot-measured as a one-edge pin, so the flip is real and not
hypothetical. That is precisely the kind of trade the owner rules on and an agent must not: the
2026-09-11 ruling says an over-decline is a defect to remove, and this is a candidate for
removing a dozen of them at once — or for discovering that the dozen were load-bearing. Either
way, `vd` is behind Track M as well (SCOPE_R §6), so nothing is blocked by waiting; R-1 (bd
`rb9x`) is independent, argued and should proceed on its own.
