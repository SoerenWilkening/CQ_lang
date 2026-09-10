# PRD §14 DRAFT — Increment 1b-B.1: the 4.4 DATA select on a bare `_Bool` condition

Written for `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md`, in the §13 style
(shape → lowering → ladder → decline partition → measured). The orchestrator merges it.
bd `test_C_libtooling-r9e5`, 2026-09-10, branch `3qlq-inc1b-b-rail-select` off `main` 87d0699.

---

## 14. Increment 1b-B.1 — the 4.4 DATA select on a bare `_Bool` (bd `test_C_libtooling-r9e5`, 2026-09-10)

### 14.1 The shape, and why §13 left it declining

`_Bool b = cq_theta(b0, θ); if (b) a -= 3;` reaches the pass as `select i1 %b, i32 2, i32 5` — the
register ITSELF as the select's condition, with no compare anywhere in the module. `clang -O1` produces
it from every `bool`-guarded straight-line assignment: `if (b) a -= 3`, `b ? q : 9`, `b ? q : p`,
`b ? 1.5 : 2.5`, `b ? c : d` over three `_Bool`s, `(b != c) ? 2 : 5` (an `xor i1` root over two rails),
and the owner's own cascade `int a = 5; bool b0 = 0; if (a >= 3) b0 = cq_theta(b0,.5); if (b0 == 1)
a -= 3;`, which IPSCCP collapses to exactly that select.

§13 admitted the rail as a LEAF of the condition grammar (`CondTree::RailLeaves`, `isCondRailLeaf`) and
lowered it at the three REGISTER-FREE PHASE emitters only; every other consumer declined
`bare i1 register condition` (`kBareRailCondReason`), the 4.4 data select among them, as filed follow-on
1b-B. **This increment is the DATA-SELECT half of that follow-on.** The value arm (`classifyArms` →
`emitValueRegion`) and the 6.5 classical-call arm are 1b-B.2 and still decline —
`control_swap_reject_value_rail_cond.ll` is unchanged and green.

### 14.2 The lowering — the merge stream is the shipped one; only the FLAG changes

The §5a controlled-XOR copy merge (`SelectMergeEmit` steps 1–6, Rule-13-cleared, byte-pinned by the
`control_swap_select_*` fixtures and the `slice_control_select*` goldens) is emitted **instruction for
instruction unchanged**. What changes is where the flag comes from:

```
   bf = cqrt_alloc_i1(0)                    the copy flag, |0>
   cqrt_cnot(h_b, bf)                       Σ_x α_x |x⟩_b |x⟩_bf
   out = cqrt_alloc_<W>(0)                  the |0> result rail          ┐
   cqrt_copy_<W>_controlled(bf, T, out)     writes T iff x = 1           │ the shipped
   cqrt_x(bf)                                                           │ §5a stream,
   cqrt_copy_<W>_controlled(bf, F, out)     writes F iff x = 0           │ verbatim
   cqrt_x(bf)                                                           ┘
   cqrt_cnot(h_b, bf)                       bf back to x ⊕ x = 0
   cqrt_free(bf)                            a proven-|0> free (Rule 6)
```

**WHY A COPIED ANCILLA AND NOT THE REGISTER, and it is the whole design decision.** Step 4 must fire the
second copy on `¬flag`, and the project's only spelling of that is a self-inverse `cqrt_x` bracket. A
rail root is the USER'S REGISTER and may never carry a `cqrt_x` — bd memory
`diagonal-only-on-user-registers-3qlq4` names the three lowered-stream predicates that go wrong or
over-freeze: `Uncomputation::preservesBorrowedParent` admits an uncontrolled `cqrt_rz_` on a borrowed
parent BY NAME and FAILS CLOSED on anything it does not name (a bracket would freeze and leak every
chain that borrows the register — a `zext`, a compare, an `add`), `ChainWalk::isInPlaceGateOn`
deliberately never recovers a `cqrt_x`, and every `ArmClassify` wire fence argues from "this region emits
no non-diagonal gate on any condition register". §13.2's escape — the diagonal identity
`X·P(θ)·X = e^{iθ}·P(−θ)` — exists only for a DIAGONAL gate; a controlled basis COPY has no diagonal form
for its ¬-half. So the flag is copied out of the register instead, and the two gates that touch the
register are `cqrt_cnot(h_b, ·)` with it at ARG 0 — a READ-ONLY control, the SAME gate class §13's nest
already emits on a rail (`cnot(h_b, g)` / `toffoli(h_b, f, g)`, cleared in §13.6/§13.7). **No new gate
class on a user register, no new gate class in the merge, and no new frozen symbol** (owner D3:
`cqrt_alloc_i1`, `cqrt_cnot`, `cqrt_free` and `cqrt_copy_<W>_controlled` all already ship).

**The unitary (analytic — Rule 2).** `bf` is minted `|0⟩`; `cnot(b, bf)` gives `Σ_x α_x |x⟩_b |x⟩_bf`, a
basis-label COPY of a register that STAYS LIVE, so Rule 8 (which forbids freeing a superposed source by
copy+uncompute) has no subject. One copy fires per basis branch, `b` is untouched throughout (the copies
write `out`, the brackets act on `bf`), the second `cnot` returns `bf` to `x ⊕ x = 0` on EVERY branch,
and the free is clean. Net `|b⟩ ⊗ |out = b ? T : F⟩` — the SAME unitary the compare stream realizes with
`c(x) = b`, which is why every §5a invariant (the bracket SCOPE, the `cqrt_x` COUNT, the single free —
bd memory `swap-route-select-merge-invariants`) carries over untouched.

**A NON-ROOT rail leaf needs nothing new.** `(b != c) ? 2 : 5` is `xor i1 %b, %c`, whose tree ROOT is the
xor NODE: `CondTreeEmit` allocates its ordinary ancilla `%g`, writes it with two `cqrt_cnot` whose
CONTROLS are the registers, and the merge brackets `%g`. `RootIsRail` is false, no copy flag is minted.

**Where it lives.** `CondTreeEmit::emitCondNetwork` gains a trailing `bool CopyRailRoot = false` and
`CondNetwork` gains `RailRoot`/`RailRootFlag`, so the ONE network implementation serves 1b-B.2's
emitters too (Rule 14) and every phase caller — which must keep reading `RootIsRail` — is byte-unchanged.
With `CopyRailRoot && RootIsRail` the ancilla is minted AFTER the walk (a bare rail root has no nodes and
no compare leaves, so it is the only thing minted), `Out.Root` becomes the ancilla and `RootIsRail` goes
FALSE; `stripCondNetwork` strips it FIRST (it was minted LAST — exact LIFO).
`SelectMergeEmit`'s pre-emission `kBareRailCondReason` guard is INVERTED: if a rail root ever reaches
step 3 still being the register, bail LOUDLY with `control flow` (Rule 1 — never silently), because the
only alternative is a `cqrt_x` on a user register.

### 14.3 The classifier ladder for a rail leaf (`classifySelectRegion`)

Asked PER RAIL LEAF, root or not, with the **SELECT** as the read point (`SelectMergeEmit` inserts every
gate immediately before it). §13.3's ladder with one substitution, and that substitution is the increment:

1. **tainted** — by construction (`cq_theta_i1` IS the taint source); re-asked as defence in depth.
2. **not measured before the SELECT** — `railMeasuredBeforeReadPoint` (`ArmClassify`, generalised from
   §13.3's `railMeasuredBeforeBranch`; ONE spelling, three callers). String:
   `condition measured before the control route`. **THE READ POINT IS THE SUBSTITUTION.** The kickback's
   gate is emitted AT the branch, so §13 could treat any same-block measurement as "before"; this stream
   is emitted MID-BLOCK, so a same-block measurement must be tested POSITIONALLY. A measure AFTER the
   select is the ordinary downstream case and ACCEPTS (`control_swap_select_rail_measure_after.ll`,
   plain `-O1` C); one line earlier it declines (`..._reject_select_rail_measured_before.ll`). The two
   kickback callers pass `Pred->getTerminator()` and are byte-unchanged by construction — a
   `cq_measure` user is never a terminator, so a same-block one always `comesBefore` it. A measurement
   elsewhere is refused on REACHABILITY, not dominance (§13's F-1b-2 fix, inherited).
3. **the wire question, with the DT prong for RAIL seeds.** Gate 2c now builds TWO seed sets. COMPARE
   seeds keep the POSITION-FREE walk verbatim (the mint point is unrelated to the compare's own
   schedule, so no positional accept is possible), and with no rail leaves the set is the pre-1b-B `Prov`
   insertion-for-insertion — every compare-conditioned select is byte-unchanged. RAIL seeds get
   `railCondWireDisposition`'s spelling: position-free CLEAN ⇒ accept; else no `DT` ⇒ decline (Prime
   Directive — no tree, no proof); else re-ask `findNonDiagonalWireGate` with `EmitPoint = Sel`, so a
   gate not provably after every execution of the select declines and one PROVEN after it is
   `ProvenPostRegion` and ACCEPTS. The P1 argument transfers exactly: the copies read `b`'s basis label
   AT the select, the flag is minted, stripped and freed inside the stream, and nothing of the region
   survives on `b` for a later gate to invalidate. The same-block positional prong stays COMPARE-only,
   and the freeze fence runs over both sets.
   **What this buys, measured:** `if (b) a -= 3; b = cq_theta(b, -0.5);` — the S† the owner's Grover
   cascade writes — declined `condition predates a non-diagonal gate` on `main` and lowers now
   (`control_swap_select_rail_post_ry.ll`, `slice_control_select_bool_sdagger`). It is the same
   over-decline bd `lom0` Inc 4 removed for the flat PHASE region, one construct later.
   **What it does NOT buy:** a theta BETWEEN the rail's def and the select, a SIBLING theta on the same
   physical rail (the §13.6 F-1b-1 class, which the walker's tainted-parent ancestry sees), and any
   in-LOOP body theta (the back edge defeats `provablyBefore`'s reachability half) all keep declining.
4. **its other users are ordinary** — it is the user's register. No `hasOneUse`, no `ShareCondFlag`, no
   "used outside the branch" fence: nothing is minted from it that could outlive the region, and the
   merge writes only `%out`. Two regions may share one register
   (`control_swap_select_rail_{two_regions,then_select}.ll`).
5. **Gates 4 (width), 5 (coherent operand, both halves) and 6 (operand alias) apply UNCHANGED.** They ask
   about the select's RESULT TYPE and its ARM OPERANDS, never about the condition; a rail CONDITION with
   a downstream rotation is fine, exactly as a compare's register is. No "arm operand aliases the
   condition rail" fence was added and none is owed: with the ancilla form the control `f` and any source
   are distinct rails, and `copy_c(f, h_b, out)` is CASE A of the aliased-operand ruling (bd `big5`).
6. **The angle hand-off ORDERING is preserved.** The rail rungs run BEFORE gate 3, so the Rz-stem angle
   select on a rail still reaches `classifyAngleSelect` and lowers (`control_angle_select_phase_rail.ll`)
   and the Ry stem still declines `kBareRailCondReason` INSIDE that classifier (1b-C, bd
   `test_C_libtooling-l4x4` — `control_angle_select_reject_rail_ry.ll`).
7. **`AllowLogicalSelect` stays FALSE for the data select**, so `b && q == 5` as a DATA-select condition
   keeps declining `control flow` (`control_swap_reject_select_i1sel_combinator.ll`). Filed, not built.
8. **In a loop:** an INVARIANT rail lowers ROLLED with the whole merge inside the intact body — a FRESH
   copy ancilla, a FRESH `|0⟩` out rail, and its own free per activation, so nothing accumulates across
   the back edge and the C-1 in-loop entangled-rail family (bd `7yd0`) has no subject. Rolled ==
   hand-unrolled, **39 = 39 lines** (`e2e-select-bool-loop-twin-identical`).

### 14.4 The decline partition

* `kBareRailCondReason` (`bare i1 register condition`) SURVIVES and stays a discriminator: the VALUE arm
  and the in-place-Ry / state-prep arms (1b-B.2, bd `test_C_libtooling-r9e5`) and the Ry-stem angle
  select (1b-C, bd `test_C_libtooling-l4x4`). It no longer fires for the data select — that fixture is
  `git mv`'d to `control_swap_select_rail_const.ll` and rewritten as the accept its header anticipated.
* `condition measured before the control route` — rung 2 (same-block-before, or reachable side path).
* `condition predates a non-diagonal gate` — rung 3 (a stale sibling or chained theta, or any in-loop
  body theta on the condition rail).
* `control flow` — a condition that is NOT a rail leaf: a `trunc`/`zext`/`sext`, a `phi` (loop-carried,
  bd `test_C_libtooling-boi6`; or a region merge), a template result, a clone `Argument`, a QRAM load.
  `isCondRailLeaf` is `cq_theta_i1`-only on purpose (§13.4), and MEASURED: admitting an i1 `trunc`/`phi`
  reddens SIX fixtures across all four consumers of the shared predicate.
* The emitter's drift guard is now the OPPOSITE assertion and declines `control flow` if a rail root
  reaches step 3 unwrapped — never silently (Rule 1).

### 14.5 Measured (2026-09-10, branch `3qlq-inc1b-b-rail-select`)

* **The owner's program compiles.** `example/grover/grover_oracle_uncompute.c`'s `main()` as of the
  session-3qlq4 close declined `bare i1 register condition` on `main` 87d0699 and now lowers to 15 trace
  lines, stage 2b `1 verified, 0 violation(s), 0 unproven`. Committed verbatim as
  `tests/e2e/slice_control_select_bool.c`.
* Probe family: **29 plain-C programs** (`inc1-records/session-r9e5/probes/`, with a PRE/POST table).
  13 accept shapes move DECLINE → ACCEPT, 5 decline shapes keep or sharpen their string, and the
  orchestrator's `k1`/`k2`/`k4` controls do NOT move. Every ACCEPT is STRICT stage-2b clean.
* `ir-pass-lit`: 1738 → **1757** fixtures (+19 net: 13 accepts and 7 declines, one of the accepts being
  the `git mv`'d discriminator). `lit -s ir-pass/test` → 1757 discovered · 1756 passed · 1 expectedly
  failed · 0 unexpected. **Exactly ONE pre-existing fixture moved** — the `git mv` target — measured by a
  full corpus diff of return code + stdout + stderr over all 1738 pre-existing fixtures:
  **RCDIFF 1 · DIAGDIFF 1 · OUTDIFF 1, the same file all three times.**
* ctest **377 → 385** (`^e2e-` 367 → 375, `^e2e-slice-` 330 → 337, `twin-identical` 27 → 28); goldens
  332 → **339**; **ZERO pre-existing golden churn** (`git status --porcelain tests/` lists only new
  files and `CMakeLists.txt`). `ctest -j6 -R '^e2e-'` **375/375**; `ir-pass-lit` Passed;
  the other 9 entries Passed.
* Injection matrix over the 13 accepts × 11 mutations = **143, 0 MISSED / 0 DIRTY** — after the first run
  read 1 MISSED: on the two-select fixture a BRACKET SLIDE in region 1 slid into region 2 and satisfied a
  seven-entry `ORD` block. Fixed by pinning the full fourteen-entry stream. *An `ORD` block is only as
  strong as the number of regions it covers.*
* `cq-opt` vs stock `opt` full equivalence sweep (required after a diagnostic-surface change):
  **1757 fixtures, 0 mismatches.**
* No new runtime symbol, no ABI change; `runtime/`, `tools/opcode_table.yaml` and `include/` untouched.

### 14.6 Owner questions

1. **`p09`'s reclassification.** The brief scoped `if (b) a = a + 3` on a quantum `a` as 1b-B.2's value
   arm. MEASURED, `-O1` HOISTS the add and folds it to a DATA select with two tainted operands — this
   sub-increment's shape — and its COMPARE twin has accepted through that path since 4.4 shipped. B.2's
   real population is the shapes `-O1` leaves as diamonds with a merge φ; worth re-scoping against
   measured `-O1` output rather than source syntax.
2. **The side-path measure over-declines.** Rung 2 refuses on REACHABILITY, so a program whose classical
   guard is never taken declines anyway. Inherited from §13 (OQ-1b-R2-4), not widened here.
3. **The borrowed-parent freeze.** `Uncomputation::preservesBorrowedParent` refuses `cqrt_cnot` (it fails
   closed), so a chain borrowing the condition register now sees two unrecognized users where a
   compare-conditioned select left none. That is the LEAK direction (Rule 6 safe) and matches §13's
   disposition for a rail under a kickback, but it is a real cost; widening the row to an uncontrolled
   `cqrt_cnot` whose TARGET is not the parent is a Rule-13 change and was NOT made.
4. **`AllowLogicalSelect`** stays off for the data select (`b && q == 5` as a data condition keeps
   declining) — the shipped decline fixture is untouched and widening it is a separate increment.
