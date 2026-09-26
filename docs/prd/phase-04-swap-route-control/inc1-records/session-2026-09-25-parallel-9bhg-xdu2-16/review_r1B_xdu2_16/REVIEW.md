# Rule-13 review r1B — bd `xdu2.16` (commit `ee2ad6d1`), the EMITTED CIRCUIT

Reviewer: independent agent, round 1B. Round 1A (a separate reviewer) had the fence logic. This
round covered the circuit the change emits. Session 2026-09-25. The owner paused the session partway
through. Every measurement that was in flight at the pause was re-run afterwards (the `g13x` family,
the `bool` sweep cells). The results below come from those re-runs only.

- SUBJECT `cq-opt` `b1603d237fc3a739` (worktree `build/`, hash checked before and after the pause).
- ORACLE `cq-opt` `438c77bf45c02e3e` (main `983f9361`, frozen).
- INSTRUMENTED: a private worktree `scratchpad/rev1B_xdu2_16_wt` at `ee2ad6d1`. It logs every
  `return false` of `invariantRegisterRootsImpl`, each (ii-d) root/obligation, and each entry to the
  xdu2.16 nulled block, under `CQ_R1B_DBG`. Null control with the variable unset: **0 divergent of
  115** modules (stdout + stderr + rc against SUBJECT).
- Harness: `probes/h.py` runs stage 1 at `-O1`, then stage 2 on BOTH binaries, then 2b STRICT and
  its CENSUS line, then link (templates before runtime) and run. It refuses an empty stage-1 module.
  Checked against three committed goldens before use: 3/3 byte-match.

## Verdict: **CLEAR-WITH-ITEMS** — 0 P1, 0 P2, 4 P3

I found no wrong unitary, no over-accept and no crash in the accept surface xdu2.16 opens.
Every new accept I built is covered by one of the following:
- byte identity with a twin, or
- identity after an explained normalisation, or
- a differential witness to a twin-identical sibling, or
- a hand argument that is written out below.

The §7 cell is now **witnessed**, not only argued (F-B1-1).

| id | sev | finding |
|---|---|---|
| F-B1-1 | P3 | The §7 ROLLED-ONLY cell DOES have a constructible flat twin, at the IR level. Its rolled stream is byte-identical to it on 15/15 cells, and the ORACLE also accepts the twin with the same stream. |
| F-B1-2 | P3 | "One ROLLED-ONLY cell" understates the population. There are **3 more flat-decline causes**, and 50 rolled-only cell-forms in my sweep. All of them are argued or witnessed correct. |
| F-B1-3 | P3 | Converges with r1A's F-A1-1 (bd `xdu2.21`). 87 of 510 sweep cell-forms move from the xdu2.16 wall to the (ii-d) postcondition. The fresh derivation records NEW exit obligations, and the source comment does not mention them. Plus two new data points. |
| F-B1-4 | P3 | The (iii-b) MergeOutRail void-user clause is REACHED from plain C through the xdu2.16 path. That falsifies its comment ("a shape no emitter builds") and the record's M2 note ("no constructible subject"). It is an over-decline. |

## What was attacked, and what it showed

### 1. The §7 data-rotated cell: first argued, now witnessed

**Differential.** On every accepted `rot` cell (26 of 26: and/or/xor/nest/lit/litor/lvar ×
i8/i16/i32/i64/`_Bool` × for/do-while), the rolled `rot` stream equals the rolled `meas` stream with
one extra line per trip: `cqrt_ry_i32(out, 0.7)` inserted immediately before `cqrt_measure(out)`. A
second check confirms the rotated handle each time: it is the select's fresh `%out`, allocated
`|0⟩`, whose only earlier uses are the two controlled copies INTO it. The `meas` streams are
byte-twin-identical to their C-level unrolled twins.

**IR-level twin (F-B1-1).** The recipe is in `probes/unrl/twin_ir.sh`:
1. Make the trip count constant (3).
2. Lower the rolled stage-1 IR to a flat form with `opt -passes='loop-unroll<O3>'`, after rewriting
   `llvm.loop.unroll.disable` to `llvm.loop.unroll.full`. No other re-canonicalisation runs.
3. Lower both forms.

Result: **15/15 `rot` cells are byte-identical rolled vs flat**. The ORACLE lowers the same flat
modules to the same stream: **15/15**.

The C-level twin declines only because C-level `-O1` CSEs the three trees into the entry block,
where prong (c) fires. The IR twin has no CSE. So the claims "no twin until xdu2.19" and "argued, not
witnessed" in the fixture header and in record §7 are out of date.

A single-compare version of the same asymmetry already exists on the ORACLE, pre-existing (`st/single_rot_*`: rolled accepts, flat
declines on both binaries). So xdu2.16 adds customers to a known asymmetry. It does not create it.

### 2. G-13: REACHED, for the first time on this surface

A trailing non-diagonal gate on a register that the **condition** reads stays unreachable. I tried:
- `for` and do-while (do-while removes the zero-trip path that makes the exit undominated),
- i8/i32/i64/`_Bool`,
- derived reads (`q^m`, `q*m`, `sext`),
- a rotation inside the body and after the loop,
- a nest with the outer body rotating `q`,
- a carried accumulator,
- a rail-bank alias (`cq rail bank: unsupported reader`),
- a cross-function rotation (`cq specialization: callee contains a quantum primitive`).

Every one of these declines at an earlier wall, identically on both binaries:
- prong (a) `condition predates…`,
- `operand predates…`,
- `control flow` (gate 5 on a data operand's wire),
- `rolled body leaks a rail entangled with a rotated register`.

**What IS reached:** a trailing `cq_theta` on a register `r` that the per-trip **in-body data rails**
read, where `r` is not in the condition. The loop is a do-while (`g13d/{and,lit}_{i32,i8}_r_dw`,
`g13x/xdata_r_dw`). All 5 cells are new accepts, STRICT 2b clean, census `0 left dirty`. In each of
them:
- Every per-trip rail built from `r` (`add_hl(h1,i)`, `xor_hl(h1,i)`, their compares) is `_unc`'d
  and freed **in the body**.
- The hoisted `sext`/`sub` rails (clause (ii-d) roots, recorded by the fresh derivation) are
  discharged **once at the loop exit, LIFO, before `cqrt_ry_i8(h1,…)`** (trace lines 66–70 of
  `lit_i8_r_dw`). That answers attack item 3.
- The only records of `r` still alive at the rotation are the zext copies, and those have already been
  measured, as the program says.

Twins:
- `xdata_r_dw` is byte-twin-identical at the C level. Its IR twin is IDENTICAL too.
- The other four are EQUAL after eliding the trip-0 `add_hl(h,0)`.
- Or they differ only by the flat spine's function-end LIFO placement of the per-trip compare
  `_unc`s. Those commute: they act on disjoint rails and are uncomputed from the unchanged
  `h4`. In both forms they land before the exit discharge and before the Ry.

### 3. Twin sweep: 510 cell-forms

The sweep crosses: conditions {and, or, xor, nested, literal `&`, literal `|`, loop-variant leaf,
derived `q^m`, `_Bool` leaf, `_Bool |`, `_Bool`&literal} × bodies {measured select, rotated select,
two selects on one tree, in-body data compare, value from `q`, value from `q` then rotated, hoisted
data chain, select-of-select, phase, rotated `r` value} × widths i8/i16/i32/i64/`_Bool` × {for,
do-while, hand-unrolled K=3}. Denominators are printed, and `sw_all.log` is analysed by an inline
script.

Transitions:
- **181** go WALL→ACCEPT.
- **87** go WALL→POSTCOND (F-B1-3).
- **0** go A→D.
- **0** other string moves.

All rolled accepts pass 2b STRICT, with 0 violations and 0 unproven.

IR-level twin over the **88** `for`-form accepts:

| result | count | explanation |
|---|---|---|
| byte-identical | 45 | — |
| EQUAL after identity-op elision | 63 total (includes the 45) | — |
| DIFF: `sel2` family | 15 | `loop-unroll`'s instsimplify folds the loop-variant literal per trip: `or(x,0)`→`x`, `or(x,1)`→const. The rolled stream carries the literal (0, 0, 1). Checked by hand. |
| IR twin declines | 10 | 7 `valqrot`, 2 i64 `rotr2`, 1 pre-existing `lvar_rotr2` (see F-B1-2) |

The normaliser `probes/unrl/norm.py` passed a null control (a file against itself: EQUAL) and a
positive control (`meas` against `dcmp`: DIFFERENT) before any real run.

**K-independence:** 7 new accepts across widths and shapes were lowered at `i<3` and `i<1000`. The
lowered modules are identical except for the ModuleID and the trip constant.

**Other accepts checked by twin or by hand:**
- `st/`: sibling loops on one tree, pre- and post-loop selects on the same tree, `break`,
  per-trip-measured carried accumulator, in-place `xorc`/`addc` derived leaf (`ipx_dead*`, the
  in-place op lands in the preheader and the body reads the mutated rail, which is correct because
  `q` is dead after it), earlier-select `%out` as a leaf.
- `inbody/`: an in-body data-compare `_unc` placed before an Ry on the select output.
- `mix/`: a kickback, an in-place Ry arm and a 6.5 call beside the compound select.
- `multi/`: two functions in one module. The joint trace equals the concatenation of the separate
  traces.

### 4. Row 13, argued (xdu2.8 CASE_SPEC_GUARDED_BOUND)

I read the full golden (`m≠n`, literal 0) and an `m==n` variant (`row13/row13_meqn.c`, literal 1,
`p=[3,4]`, trace `add_hl(h2,3)`, `sub_hl(h1,3)`, then `add_hl(h7,4)`, `sub_hl(h10,4)`).

Per trip:
- `a' = c ? a+p[i] : a` and `z' = c ? z-p[i] : z`, with `c = (q≠0) ∧ lit`.
- Two independent `icmp_ne_hl`→`and_i1_hl(·, lit)` networks. Each is X-bracketed into a fresh
  `%out`, then `_unc`'d with the same SSA literal and freed.
- `h0` is only ever a template operand.

The E4 guarded read, `load(select(freeze i <u freeze m, &p[i], zero))`, only matters when `c` can be
true, which needs `m == n`, so `i < n = m` and the read is in bounds. When `m ≠ n`, the copied arm is
`a` regardless, so the zero cell is harmless.

Left in place (census `6 template rail mints, 2 left dirty`, plus 5 allocated):
- the per-trip `h_op` chain rails,
- the old carried rails.

This is bd `zujr`'s design (3qlq Inc 2 E1). Every such rail is a function of `q` and the literal,
which stay live, so the garbage is an isometry on live state. A trailing non-diagonal gate on
`q`/`a`/`z` declines at earlier walls in every spelling I tried.

## Findings

### F-B1-1 (P3) — the §7 twin exists at the IR level

Evidence: `probes/unrl/twin_ir.sh` and `irtwin.log`. The ORACLE-on-twin check is scripted in this
review's command log. Rolled vs IR-unrolled: 15/15 byte-identical. ORACLE on the IR twin vs SUBJECT
rolled: 15/15.

Recommendations:
- Use this recipe as the twin witness for `…_accept_hoisted_data_rotated.ll`.
- Use it as a mechanism for bd `xdu2.20`. It removes the C-level `-O1` CSE/fold confound that makes
  sel2/dcmp/valq cells unmatchable at the C level.
- Update the fixture header and record §7. The retirement trigger "when the flat twin accepts" is
  already met by the IR twin.

### F-B1-2 (P3) — the rolled-only population is at least four causes, not one

Beyond prong (c) (bd `xdu2.19`, the `rot` family) and r1A's kickback (bd `xdu2.22`):

**(a) Value routing after the trip-0 fold.** Seen in `valqrot`:
`t = C ? (q+i) : 55; t = cq_theta(t,.7)`. The flat form folds `q+0`→`q`, so copy 1 is
`select(C, q, 55)`, and the value-routing walk treats `Ry(t)` as a gate on `q`'s wire. That gives
`operand predates a non-diagonal gate`, and the IR twin declines the same way.
Witness: `valqrot == valq + Ry on the fresh %out before its measure` on **14/14** accepted cells, and
the `valq` IR twins are EQUAL.

**(b) i64 trunc/select order.** Seen in i64 `rotr2`: `t = C ? r : i; t = cq_theta(t,.7)`. Rolled
`-O1` emits `select` then `trunc`, so the Ry lands on a fresh `trunc` rail. Flat `-O1` emits `trunc`
then `select`, so the Ry is value-routed back to `trunc r`, and the result is a `control flow`
decline. The rolled stream reads correctly by hand: controlled copy of `h1` or `i` into `%out`, strip,
`trunc`→`h7`, `Ry(h7)`, measure.

**(c) Pre-existing rolled-only on the ORACLE.** `lvar_rotr2` and single-compare `single_rot`.

All of these are flat over-declines, in the safe direction. Filed as bd `xdu2.23` (below).

### F-B1-3 (P3) — WALL → POSTCOND family (converges with r1A F-A1-1 / bd `xdu2.21`)

Instrumented on `derq` (`((q^m) > 1) & (r < 5)`):
`R1B nulled grant` → `R1B (ii-d) root+obligation: %7 = xor i32 %3, %1` → postcondition.

The fresh derivation **records NEW (ii-d) exit obligations at the post-fixpoint slot**. The source
comment's "round-1 residue" list mentions only the round-1 obligation of the erased node. It does not
mention these new ones. The postcondition, not the re-derivation, is what stops them. That is safe,
but the comment should say so (L7).

Population in the sweep: 87/510. It includes:
- derived leaves at every width,
- every i8/i16/i64 `valq`/`dcmp`/`chain`/`rotr2` cell, where a hoisted `sext` becomes an (ii-d) root.

Two data points to add to `xdu2.21`:
1. When the hoisted derived rail is read by **lowerOps templates** in the body (derived DATA, the
   `chain` and `dcmp` bodies), the exit discharge IS placed in the **do-while** form. See
   `sw_full/i32_lit_chain_dw` (`mul_unc` at exit), `g13d/lit_i8_r_dw`, and `g13w/and_wi_none_dw`.
   The **for** form (zero-trip guard) still declines.
2. When the rail's only in-loop readers are the **4.4 emitter's flag mint and `_unc` strip** (a
   derived LEAF), the discharge is never placed. It declines in both forms.

### F-B1-4 (P3) — (iii-b) is reachable, and its comment is false

This plain C declines on BOTH binaries (`outleaf/ol_none.c`):

```c
int u = (q > 1) ? k1 : k2;                         // 4.4 select → %out rail, k1,k2 runtime
for (i < n) { int t = ((u > 3) & (r < 5)) ? i : 55; s += cq_measure(t); }
```

On SUBJECT it reaches the xdu2.16 nulled block, and the fresh derivation returns false at
`invariantRegisterRootsImpl`'s **(iii-b)** clause (instrumented site 9, `LoopLowering.cpp` ~4400).
The void in-L user is the 4.4 emitter's compare strip, `cq_template_icmp_sgt_i32_hl_unc(flag, %out_u,
3)`. It **reads** the merge out-rail as a borrowed operand. It is not arg 0, and it is not a write.
The clause tests `isVoidTy()` on any in-L user, so it cannot tell a borrow from a write.

This falsifies two statements:
- the clause's comment: "None of those is producible inside `L` for a rail allocated outside it …
  this refuses a shape no emitter builds",
- TRACK_XDU2_16.md §6, mutant M2: "(iii-b) … have no constructible subject".

It is an over-decline: the single-leaf sibling `(u > 3) ? i : 55` accepts on both binaries
(`ol_single.c`).

I did NOT build M2, so I did not check whether this subject separates M2. My reading is that it does
not: `railLocalQualifies`' invariant-input clause refuses the uncovered `%out_u` anyway. Filed as bd
`xdu2.24`.

## What I did NOT attack

- **The fence logic itself** (monotonicity, dangling `IterationLocalBlocks` pointers, record
  hygiene). That was r1A's surface.
- **Mutants M2/M3/M6.** I built none.
- **A `+Asserts` build.**
- **A round-2-only nulled root.** I could not construct one. A round-2-tainted leaf is a classical
  literal at round 1, and it either:
  - accepts with no round-1 grant (`r2/ca_lit`, identical on both binaries, so the nulled block is
    never entered), or
  - declines at xdu2.13's `classical condition literal became quantum-derived` (`r2/callarm`).

  The 4.5 switch value shapes decline flat (`value-arm swap-route`).
- **Other nulling emitters** (switch data-mux, AngleSelect, PredMux sweeps).
- **Loop and tree shapes:** multi-latch or irreducible loops, a nulled grant on an OUTER loop of a
  nest, trees with more than three leaves, several nulled roots in one grant, `xor i1` with a
  literal leaf.
- **A C-level twin for row 13, and an IR twin for it.** At constant trip `-O1` changes the shape to a
  branch, which declines as `control flow` on both binaries. Row 13 is argued (§4), not witnessed.
- **Measuring a condition register inside the loop** (the bd `yiid` class).

## Beads filed / annotated

- NEW bd `xdu2.23` (P3 bug): F-B1-2's value-routing and i64 trunc-order ROLLED-ONLY families.
- NEW bd `xdu2.24` (P3 bug): F-B1-4, (iii-b) reachable by a read-only `_unc` borrow. False comment and
  over-decline.
- Comments added to bd `xdu2.20` (F-B1-1 recipe) and bd `xdu2.21` (F-B1-3 data points).
