# Rule-13 review r2A — bd `test_C_libtooling-rhk5`, round 2, surface A (the kyy1 fix)

- **Subject:** commit `c7dad811` (on round 1 `c89afa59`), worktree
  `.claude/worktrees/agent-a7712272d6ca568e9`, `build/ir-pass/cq-opt` sha-256
  `aa0dff29ea088cde195e222c…` (measured). `cq-opt-debugalloc` `2da6e185c4e223b6…`.
- **Oracle:** `scratchpad/frozen/cq-opt.main_9a230646` (`3f6db37f5cf937b4…`).
- **Diff read:** `c89afa59..c7dad811` (source: `Uncomputation.cpp`, `ChainWalk.{h,cpp}`,
  `DagTraversal.{h,cpp}`, `RotationLowering.{h,cpp}`); `9a230646..c7dad811` re-read for
  every non-comment change (all gated on `AdmitCloneCalls`, see §2).
- **Time:** 00:30–01:10 (≈40 min), load 90–125.
- **What I ran, literally:** `probes/pair.sh` / `probes/pair3.sh` (r1B's harness, copied:
  stage 1 two-TU `llvm-link`, stage 2 `cq-opt`, stage 2b `free_pairing_check.py` STRICT,
  stage 3 link, stage 4 run, `tools/trace_twin_equiv.py` subject-vs-twin) on 24 C probes;
  `probes/determinism.sh` (2× `cq-opt`, `CQ_OPT_DEBUG_ALLOC=lifo`, `=nofree`) over 72 modules;
  one timing probe (`sc40`); ONE private build — a **composed** binary
  (rhk5 r2 `c7dad811` + z0re r2 `9a68064f` + nlfd/ev3m `bae50351`; conflicts only in
  `CODE_MAP.md` and `tests/e2e/CMakeLists.txt`, resolved by union; target `cq-opt` only;
  sha-256 `ab9f5450d3a3b3452d0757fe…`, kept at `scratchpad/frozen/cq-opt.r2A_composed_rhk5r2_z0rer2_nlfd`;
  worktree removed).
- **What I did NOT run:** lit, ctest, corpus A/B, the implementer's mutation matrix (read,
  not re-run). **No mutants of my own** — my one private build went to the composition.
  cepm (`7f0be42f`) was not composed.

## Verdict: `CLEAR-WITH-ITEMS`

0 P1. 1 P2 (disclosed by the implementer, re-attacked, not closed). 3 P3.

---

## §1 The argument, restated — and the step that is asserted

The kyy1 fix makes two claims.

1. **Per component.** An ON component holding (b′) rails is ALSO planned as its pre-rhk5
   pieces, and the whole plan is kept only if it discharges a superset of the pieces' rails.
2. **Per function.** ON (with step 1) and OFF (the pre-rhk5 planner verbatim) both run, and
   ON is used only if its final discharged set is a superset of OFF's.

I re-derived why this is sound. Each step below was checked against the code, not the comment.

- **(a) OFF is pre-rhk5 verbatim.** Every non-comment change in `9a230646..c7dad811` to
  `isInteriorConsumer`, `isInteriorTerminalHandle`, `preservesBorrowedParent`,
  `planInteriorComponent`, the `recoverDataDag` closure and `collectInteriorPlans*` is
  `AdmitCloneCalls && …` or a pure refactor (`buildComponents` with `Allowed = Anchorable`).
- **(b) Pieces are exactly OFF's components inside the ON component.** `Cand_ON ⊇ Cand_OFF`,
  because (b′) only admits. `Anchorable` is a per-rail user test and does not depend on the
  mode. The link rules are one lambda. So every OFF link lies inside one ON component, and
  `PreRhk5 = Comp ∩ Cand_OFF`.
- **(c) A piece planned ON equals its OFF plan whenever OFF succeeds.** Clause (3) only
  deletes `return false`s. `IP.AdmitCloneCalls` is inert for a piece, because a piece's owned
  rails passed `isInteriorTerminalHandle(…, false)` and so have no clone consumer. The
  convergence loop, `At`, `D` and `Borrowed` do not read the mode.
- **(d) Result of (a)–(c).** Before the cross-plan ordering check, ON's discharged set is a
  superset of OFF's in every component. Only the ordering check can break that.
- **(e) When the ordering check can drop a plan.** It drops `Outer` only when some
  `Inner.Borrowed ∩ Outer.D.Rails ≠ ∅`. Within one multiplicity, a rail that one plan owns
  and another reads is `link()`ed into the same component. So a drop needs a `sameMultiplicity`
  split, which means a marked iteration-local body. Layer (2) exists for that case.
- **(f) Is "superset of rail SETS" the right metric?** It is, given per-plan soundness.
  Moving a discharge from the piece's `At` to the whole plan's later `At` is the identity on
  the state, for three reasons:
  - Let V be the isometry `|x⟩|0⟩_u → |x⟩|f(x)⟩_u` that computes an owned rail from its
    borrowed parents' labels. V commutes with every gate clause (d) admits inside the window:
    diagonal Rz, controlled Rz, forward template producers, and clone calls proven read-only.
  - V also commutes with every gate that touches neither a borrowed parent nor an owned rail.
  - The owned rails' own users all precede `At`, by the convergence loop.

  `FrozenRails` cannot occur in an interior plan, because §4 requires
  `preservesBasisUnderRecord` of every gate. So `addDischargedRails` is `D.Rails` there.
  A double discharge is impossible: the code keeps either the whole plan or the pieces, never
  both; components are disjoint; and (I2) excludes terminals. **`f3` is a measured instance of
  the move**: `u` is discharged after both clone calls instead of after the strip. It is
  `EQUIV` to its twin and clean under 2b.

**The asserted step is (e)'s reachability**, and it is F-r2A-1 below. **The other asserted
step is the comment's end-to-end claim.** "Never worse than pre-rhk5" is checked on the module
`uncompute` sees. It is not checked on the module the oracle would have produced, because the
M-C late round consumes the ON/OFF choice one stage earlier (F-r2A-4).

---

## §2 Findings

### F-r2A-1 — P2 — INTRODUCED (disclosed in TRACK §R2.5/§R2.6) — layer (2) is unpinned, and I could not reach it from C either

**Claim tested.** The implementer says layer (2) is needed when clause (3) enables an inner
piece plan that then drops an outer plan through the ordering check. Their mutant R9 (layer
removed) moved 0 of 3,384 modules.

**Attempts.** 13 C programs, `probes/src/l2a.c` … `l2m.c`:
- a hoisted (b′) rail `p = 3q`;
- per-trip interior rails in a rolled body that BORROW `p`;
- a dead sibling in `p`'s component;
- a loop exit the body's discharge point does not dominate: runtime trip, or a classical
  `break` ahead of the kickback.

**Results.** Every spelling that makes the ordering check fire declines on BOTH binaries,
before the planner runs:
- `condition predates a non-diagonal gate under quantum control`: the P4 cross-block gap, for
  any guard or break between `p`'s definition and the body's condition (`l2a`, `l2b`, `l2f`,
  `l2k`, `l2l`, `l2m`).
- `rolled body leaks a rail entangled with a rotated register`: (ii-d) refuses a hoisted rail
  that has any out-of-loop user, so a dead sibling of `p` is impossible (`l2c`–`l2h`, `l2j`).
  The twins decline the same way.

The one spelling that lowers is `l2i`, with a constant trip count and the clone inside the
body. There the body dominates the exit, so `provablyBefore` holds and nothing is dropped.

**Conclusion.** Layer (2) currently has no reachable customer from C: argued in §1(e), with 13
measured attempts behind it. It fails safe, because it can only choose OFF, which is the
oracle's plan. It is an `e1gr`-shaped backstop. Its trigger is the day P4 or (ii-d) admits a
guarded loop or a hoisted rail with an out-of-loop user. Its first customer would then be the
tu9q P0 shape plus a clone consumer. Notes appended to bd `kyy1`.

**Repro.** `cd …/review_r2A_rhk5/probes && ./pair.sh l2k "5 3"; ./pair.sh l2j 5`

### F-r2A-2 — P3 — INTRODUCED — a D→A mover outside every swept population, correct but unpinned

**Probe.** `probes/src/l2i.c`, 2-TU, argument `5`:

    q = cq_theta(m,.5); r = cq_theta(m,.3); p = q*3;
    for (i<3) { if ((p>>i)&1) cq_phi(.2); r = cq_theta(r,.1); t += cq_measure(h(m+i,p)); }
    q = cq_theta(q,.9);

| binary | result |
|---|---|
| ORACLE | declines `cq loop lowering: hoisted invariant rail admitted for in-loop discharge was not discharged` — bd tu9q's ex-post postcondition: (ii-d) granted, the clone consumer then kept `p` out of the interior partition |
| SUBJECT | accepts: warn 0; 2b strict `dirty=0 viol=0 unpr=0`; `mul_i32_hl_unc(h2,h0,3); free(h2)` at the loop exit, before `cqrt_ry(h0, .9)` |

**Is the accept right?**
- Rolled vs the hand-unrolled twin with the clone kept (`l2iV.c`): `trace_twin_equiv` EQUIV.
- Rolled vs the hand-unrolled, hand-inlined twin (`l2iU.c`): DIFF only because Bennett
  contraction found 3 blocks against 0. That twin also discharges `h2` before the Ry, on both
  binaries.
- On `l2iV`, the ORACLE leaks `h2` (warned, dirty 1); the subject does not.
- The rolled hand-inlined twin (`l2i_T.c`) declines on both binaries. That is a pre-existing
  over-decline of measured per-trip rails, not rhk5's.

**Why it is an item.** This is (b′) retiring a POSTCONDITION decline, the fence that verifies
the (ii-d) grant ex post. The postcondition is now *satisfied*, not bypassed; I checked that.
But the record's "0 A→D, 0 D→A" is scoped to the corpus, and the class has no fixture.
- **Owed:** an accept fixture of `l2i`'s shape (Rule 12). A negative prefix must pin that
  `mul_i32_hl_unc(h_op…)` sits after the loop and before the trailing `cqrt_ry`.
- **The record should say** that rhk5 moves a tu9q postcondition decline to an accept.

**Repro.** `./pair.sh l2i 5; ./pair.sh l2iV 5; ./pair.sh l2iU 5`

### F-r2A-3 — P3 — (design limit, not a regression) — layer (1) tries only "all (b′) rails" or "none"

**Probe.** `probes/src/f2.c`: `p = q&3; w = q*5; u = p^w; if (u==10) cq_phi(PI);
s1 = h(m,p); q2 = cq_theta(q,.7); s2 = h(m+1,w)`.

**What exists.** A plan `{p, u}` with `w` borrowed, discharged before the Ry, satisfies
clause (d): `w`'s only in-window user is `u`'s `xor`, and its clone lies after `At`.

**What happens.** Neither binary finds it. The whole plan `{p,w,u}` fails, the pieces are
`{u}`, and `p` stays live across the Ry (warned, dirty 2). The subject and the oracle are
byte-identical, so the subject is never worse — a missed rhk5 win. It belongs with kyy1's
granularity half; noted on bd `kyy1`.

**Repro.** `./pair.sh f2 5`

### F-r2A-4 — P3 — INTRODUCED (comment scope, L7-shaped) — "never worse than pre-rhk5, CHECKED" holds for the module `uncompute` sees, not end to end

`collectInteriorPlans` is also what `planInteriorDischarges` calls in the M-C late round
(`ArithLowering.cpp`, arm (d2)). That is Rule-14-correct: one wrapper. It also means M-C
converts a reassignment in place on the ON/OFF choice made on the PRE-conversion module. The
OFF run inside `uncompute` then plans on a module the oracle would not have produced.

**Why this is safe.** I argued it and did not construct it:
- M-C converts only when every prior reader is discharged by the chosen plan provably before
  `bo`.
- A later flip to OFF leaves that record live. It stays a function of the mutated register:
  a leak with the same entanglement as the out-of-place spelling, never a dirty free.
- Every plan re-runs clause (d) against the new in-place gate, so no `_unc` reads a
  relabelled register (the pre-existing (d2) argument).

My two attempts to reach the M-C late round (`mc1`, `mc2`) never converted: `q -= 3` stays
out-of-place on all three binaries.

**Owed.** One sentence at `collectInteriorPlans` scoping the claim, and stating that the M-C
late round asks the same comparison one stage earlier.

---

## §3 Attacked and not broken

| # | attack | result |
|---|---|---|
| 1 | Set comparison hides a worse circuit (a later discharge, a double discharge, LIFO) | §1(f). `f3` moves `u`'s discharge later: EQUIV to twin, 2b clean. Frozen impossible in interior plans. Two plans with the same `At` where one borrows the other's rail: `dominates(I,I)` is false, so the outer plan is dropped |
| 2 | Clause (3) in a piece plan × the ordering check | Pieces are OFF components (§1(b)–(c)). An extra inner plan needs a multiplicity split (§1(e)), which is F-r2A-1 |
| 3 | Layer (2) distinguishing input | F-r2A-1. Two components sharing a borrowed parent cannot drop each other: the check is owned ∩ borrowed, not borrowed ∩ borrowed |
| 4 | Determinism / allocator | `probes/determinism.txt`: **72 modules**, 2× `cq-opt` + `lifo` + `nofree`, **0 differ**. My first run printed `checked 1 files`: zsh does not word-split `$files`. Re-run under bash; the vacuity was caught by the count, not by luck |
| 4′ | Cost | `sc40.c` (40 (b′) components in one function): user **0.20 s** subject vs **0.19 s** oracle; 125 vs 84 `_unc` lines; **0 vs 40 warnings** |
| 5 | L1: does the ON run mutate what OFF reads? | No `insert`/`erase`/`Create*`/RAUW/`eraseFromParent` in `Uncomputation.cpp` lines 1000–2100 (grep). `RepeatOracle` is per mode. `Plans` vectors are fresh per mode. `cloneCallPreservesArg`'s memo is per query |
| 6 | Family members not built by the implementer | `f1` (one (b′) rail, clones on both sides of the Ry): S==O. `f2`: S==O (F-r2A-3). `f3` (two (b′) rails, both clones before the Ry): subject EQUIV to twin, oracle warned/dirty 2. `l2i` (clone in a loop body): F-r2A-2. Spot-check of the implementer's claims: r1B `b2n`, `b2`: S==O byte-identical ✓ |
| 7 | Rule 12 hygiene of the 10 new fixtures | Accepts carry SILENT + a LOWER chain whose negatives come after positives in the same prefix, with no `CHECK-COUNT`. Leaks pin the WARN string and `LEAK-NOT` the adjoints. No vacuity seen |

## §4 Standing-lesson questions

- **L1.** The planner runs only in `uncompute` and in the M-C late round, both after both
  control rounds. It is pure analysis (row 5) and records nothing. The M-C interplay is F-r2A-4.
- **L2.** The widened set is the interior candidate set in ON. The component partition and its
  anchor were computed over it, which was kyy1's cause; they are now compared per component
  and per function. `planInteriorDischarges`' `GateAt` consumes the same wrapper, so it is
  consistent. `TermGates` is untouched.
- **L3.** `preservesBorrowedParent` clause (3) and (b′) are gated by the same flag, which
  `IP.AdmitCloneCalls` carries into the closure scan, so the two agree by construction.
  `isInPlaceGateOn` and the moved-anchor scan are unchanged; round 1's reasoning still stands.
- **L4.** Both superset tests enumerate a full set. No return-first walker.
- **L5.** n/a.
- **L7.** F-r2A-4. `ChainWalk.h`'s "OFF reproduces the pre-rhk5 candidate set EXACTLY" is
  **true** (§1(a)).
- **Rule 14.** One `buildComponents` and one `isInteriorTerminalHandle` for `PreRhk5`. ✓
- **Rule 12.** Layer (1) is pinned by one fixture (R7). Layer (2) is pinned by none (R9,
  F-r2A-1). `l2i`'s loop form has no fixture (F-r2A-2).

## §5 Composition

**Named program:** `probes/src/z_k3C.c` (r1B's `k3C`, runtime-seed prep). It needs z0re to
lower at all and rhk5 to lower clean. Results on the composed binary `ab9f5450…`:

| probe | z0re alone (`8441d60d…`) | nlfd alone (`93c65d0d…`) | rhk5 r2 alone | **composed** |
|---|---|---|---|---|
| `z_k3C` (13 6) | A, warned, dirty 2, DIFF vs twin | decline | decline | **A, warn 0, dirty 0, EQUIV to `k3T`** |
| `n_ev9` (5) | decline (taint escape) | A, warned, dirty 2 | decline | **A, warn 0, dirty 0, EQUIV** |
| `n_ev7` (5) | abort 134 | A, warned, dirty 2 | abort 134 | **A, warn 0, dirty 0, EQUIV** |
| `n_mtl` (5) | abort 134 | A, warned, dirty 1 | abort 134 | **A, warn 0, dirty 0, EQUIV** |

**The musttail programs `ev9`/`ev7`/`mtl` become clean with rhk5 round 2**, and `k3C` becomes
twin-equivalent, as the brief asked.

The composition does not move rhk5's own results:
- all 19 `spec_*` fixtures of `9a230646..c7dad811` produce byte-identical output under
  composed vs subject;
- `b2n`, `b2`, `f1`–`f3`, `l2i` and `mc2` produce identical traces.

The `abort 134` rows are ORACLE-shared (the oracle aborts on `ev7`/`mtl` too). They are nlfd's
subject, not this review's. **cepm was not composed.**

## §6 Beads

- `--append-notes` on bd `test_C_libtooling-kyy1`: F-r2A-1's reachability argument and its 13
  attempts; F-r2A-3's missed `{p,u}` plan.
- `--append-notes` on bd `test_C_libtooling-rhk5`: F-r2A-2's `l2i` D→A mover (a fixture is
  owed); the composition table.
- Nothing created, nothing closed.
