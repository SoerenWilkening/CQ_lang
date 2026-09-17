# bd `test_C_libtooling-zujr` — THE LOOP-CARRIED HANDLE VARIABLE

**Session 2026-09-19.** ORACLE `cq-opt` `07d93784…` (`main` `bda59791`); SUBJECT
built in the worktree `cq-wt-zujr`. Every number below is measured on those two
binaries and re-measured at the close; nothing is copied forward.

## 0. The headline

`example/grover/grover_oracle_uncompute.c` **in its LOOP form compiles as
written** — three-trip cascade, `bool b0[3]`, `int a`, no `cq_*` function added,
no source change:

```
opt exit 0, stderr 0 bytes, 50 trace lines
stage 2b STRICT: 4 rail mint(s) of which 3 left allocated,
                 2 template rail mint(s) of which 1 left dirty,
                 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven
```

K-independent: the lowered module is **75 lines at K=3 and 75 lines at K=1000**
(`probes/k3.c`, `probes/k1000.c`, measured without `-g`).

## 1. What the shape is

After `clang -O1` the second `if` is if-converted into a **4.4 DATA SELECT**, and
`a` is a header φ:

```llvm
%a  = phi i32 [ 5, %entry ], [ %out, %latch ]     ; %out = cqrt_alloc_i32(0), FRESH per trip
```

It is neither of the two kinds the loop layer knew — not **(b)/(b′)** the rail
that crosses the back edge IN PLACE (the latch incoming does not peel back to the
φ), and not **(c)** the ITERATION-LOCAL rail (it manifestly crosses). It is a
**LOOP-CARRIED HANDLE VARIABLE**: a register that crosses the back edge **and** is
re-minted every trip. `ControlDetect.cpp` already said so in words for the value
arm — *"the loop-carried register is a different handle every trip"*.

The runtime needs nothing: a handle is an `i32`, and a loop-carried `i32` whose φ
is selected by CLASSICAL loop control is ordinary classical data (owner ruling,
2026-09-17). The one thing the module was missing is the **trip-1 register**.

## 2. The walls, measured — FOUR, and the ladder was found by peeling, not by reading

An env-gated peel instrument (`ZujrPeel.h`, scratch, not landed) turned each
candidate decline into a skip so ONE binary showed the whole ladder;
`LLVMContext::diagnose` EXITS on the first `DS_Error`, so without it each wall
costs a rebuild.

| # | wall | site |
|---|---|---|
| 1 | R7-loop clause **(c3)**, `iterationLocalTaintEscape` — `a` escapes the loop | `ArmClassify.cpp` (bd `8h7d.11`) |
| 2 | **X1**, round 2 — the latch incoming is a fresh tainted rail | `collapseRailPhisIn` (bd `ej5w`) |
| 3 | `declineUnmarkedRolledIterLocal` **conjunct 2** — the body is unmarked | `LoopLowering.cpp` |
| 4 | `declineClassicalMuxes` — the header φ muxes a literal and a handle | `TaintPropagation.cpp` (bd `832l`) |

⚠ The previous session's brief predicted walls 1, 2 and the §3c clobber; **the
§3c clobber (bd `x5fp`) never fires on this program** and walls 3 and 4 were not
on the list. `$PREV/DECISIONS.md` E5's *"expect a wall 5"* was right in spirit and
wrong in the count: there were two more, not one, and one of them (conjunct 2) is
a POSTCONDITION rather than a precondition, which is why reading the decline
strings could not have found it.

## 3. What landed

**ONE predicate, four call sites (Rule 14).** `loopCarriedHandlePhi`
(`LoopLowering.cpp`, declared in `LoopPlan.h`) with eight conjuncts:

* **(Z1)** reducible, single latch, a real **preheader**;
* **(Z2)** exactly two incomings — the latch and that preheader;
* **(Z3)** the φ is `i32` — the handle ABI. A `short` spelling `report_fatal_error`s
  on a build without this test, MEASURED;
* **(Z4)** the seed is CLASSICAL and not `undef`/`poison`;
* **(Z5)** the latch incoming is tainted, defined in `L`, and is **not** the
  closed self-cycle (asked by CALLING `peelInPlaceBase`, the collapse's own claim
  condition);
* **(Z6)** the latch incoming **is a control-merge rail** — `taint.ControlOwnedRails`
  where that record exists, the emitters' SHAPE where it cannot (two of the four
  slots run at round-1 taint). The shape half is DEFER-ONLY;
* **(Z7)** the trip count is CLASSICAL (`taintedExit`);
* **(Z8)** every out-of-loop reader reads a handle — this is what keeps a
  zero-trip-GUARDED (rotated) loop declining with the LOOP message.

**The promotion.** `promoteLoopCarriedHandleSeeds` runs immediately before
`declineClassicalMuxes` in BOTH entry points, materialises
`cqrt_alloc_<W>(seed)` in the preheader via `materializeCopySource` (Rule 14 — the
same primitive the flat twin's `cqrt_alloc_i32(5)` copy source comes from), and
records the φ in `taint.PromotedCarriedHandlePhis`. **It never declines**: every
refusal is a SKIP, and an unpromoted φ is refused by the very next stage. That is
what makes all four analysis sites decline-SAFE — none is the last owner.

**One un-gated widening**, and it is named because it is not the predicate's:
`railLocalQualifies`' **(L3)** clause now exempts a store that PARKS A RAIL IN A
PROVEN `!cq.railbank` ALLOCA with an UNTAINTED pointer operand. Without it no
banked loop could ever be marked and conjunct 2 could never be satisfied. The
tainted-INDEX half is untouched (`probes/a1_taintedidx.c` still declines
`cq QRAM access: tainted-index memory access inside a loop` on both binaries), and
a parked rail is already FROZEN against adjoint and free by `railStoredToRailBank`.

## 4. Two findings the increment's own probes produced, and both were FIXED before the suite

* **(Z6) was NOT in the first design and its absence cost a DIAGNOSTIC.**
  `probes/a14c_accum_i32.ll` — `lowering_reject_loop_cross_iter.ll`'s accumulator
  at `i32` — went from `cq loop lowering: loop-carried tainted value crosses
  iterations` to `cq taint escape: tainted value muxed by a classical-condition
  phi`. Both declines, safe direction, **wrong label** (CLAUDE.md L6; the defect
  class bd `8h7d.12` is open for). The `double` fixture could not witness it: (Z3)
  refuses that φ before (Z6) is asked.
* **(Z8) likewise**, for the ROTATED loop behind a zero-trip guard
  (`probes/a17_guarded.ll`): the mux guard spoke about the EXIT φ instead of the
  loop. Hoisting the alloc above the guard would make it lower; that is an
  ACCEPT-direction widening with its own Rule-13 round and is **filed, not
  smuggled in**.

## 5. The per-trip unitary argument (Rule 2 — analytic; there is no simulator)

Let `a_0` be the preheader `cqrt_alloc_i32(5)` = |5⟩ and `a_k` the register the φ
names on trip k. Each activation emits, on the ORIGINAL register `a_{k-1}`:

1. `h_cmp = [a_{k-1} > 2]`, a reversible template rail;
2. `b_k = |0⟩`, `Ry(.5)` **controlled on `h_cmp`**;
3. `icmp_..._unc(h_cmp, a_{k-1}, 2)` — the strip's premise holds because nothing
   wrote `a_{k-1}` — then a proven-|0⟩ `cqrt_free(h_cmp)`;
4. `h_op = a_{k-1} − 3`, a fresh rail LEFT ALLOCATED (3qlq Inc-2 PRD §0 E1);
5. `bf = |0⟩`, `cnot(b_k, bf)`; `a_k = |0⟩`; two X-bracketed
   `cqrt_copy_i32_controlled` writing `a_k` once per basis branch; `cnot(b_k, bf)`
   returns `bf` to `x ⊕ x = 0` and it is freed.

So `a_k = b_k ? a_{k-1}−3 : a_{k-1}` on every basis branch, with `a_{k-1}` and
`h_op` left as which-path records — **gate for gate what copy k of the
hand-unrolled program emits**.

**50 lines against the twin's 45, and the five are accounted for one by one** (the
owner's ruling (2): byte-identity is an INSTRUMENT here, not the target):
`+1` the preheader alloc (the twin folds the same register into its trip-1 mux);
`+2` trip 1's compare (`a = 5` ⇒ `a >= 3` folds to TRUE, so the twin emits an
unconditional `Ry`; a control that is |1⟩ deterministically IS no control);
`+2` trip 2's compare (`-O1` folds it to `!b0[0]` and spells it by ADDITIVITY);
`0` **trip 3 is identical gate for gate** — golden lines 27-41 against 32-46.

**LEAK PARITY, measured: SIX undischarged rails in each form** (rolled 3 template
+ 3 alloc; flat 2 + 4, because `-O1` const-folded its first two trips). The rolled
form is therefore not worse than its twin, which is the claim conjunct 2 exists to
protect.

## 6. What moved, measured

* **Corpus A/B over all 2099 `ir-pass/test/*.ll`: 11 movers, ALL accept-direction**
  (10 `DECLINE → ACCEPT`, 1 `DECLINE → DECLINE` with a moved string), **ZERO
  `ACCEPT → DECLINE`**. `probes/sweep.py`.
* All 11 are in the **railbank** family and every one of them carried an L8
  RETIREMENT TRIGGER predicting this. ⚠ **Every trigger named the WRONG next
  wall** — each predicted the decline would MOVE to `kMsgCrossIter`; it is gone
  instead, because X1 was never the last wall either. **A trigger that names the
  next wall is only ever a LOWER BOUND on how many are left.** All 11 re-derived
  in the same change, none deleted, and all 11 validated NON-VACUOUS by running
  them against the ORACLE (every one fails there).
* **5 twin-matrix cells**, all accept-direction: one
  (`m_none_kread_none_none_kflat`) goes `UNROLLED-ONLY → ACCEPT-IDENTICAL`, the
  strongest witness the tree has; four go to `ROLLED-ONLY`, where the UNROLLED
  side declines because `RailBankPromote` is LOOP-SHAPED and an unrolled bank is
  never promoted — a pre-existing asymmetry, not a leak.
* One module that is NOT the increment's: `railbank_promote_uncond_prep.ll` keeps
  declining, at the SELECT, on a bare `trunc`-of-`zext` `_Bool` wire. That is bd
  `r903`; the C spelling of the same program compiles because `-O1` folds the pair.

## 7. Filed, not built

* the **guarded / rotated** loop (a RUNTIME trip bound): hoist the alloc above the
  zero-trip guard and rewrite the exit φ. (Z8) refuses it today.
* the **narrow-width** carried handle: `mutateType(i32)` on the φ at the promotion
  (the `RailBankPromote.cpp` idiom). (Z3) refuses it today.
* the **Rule-8 tripwire** `loop_carried_handle_reject_postloop_rotation.ll`: the
  day bd `r903`/`fg9k` moves the select wall, that program accepts and what it
  accepts is the bd `s82e` dephasing class. Filed against `s82e`, NOT closed here
  (Rule 14).

## 8. The (L3) bank exemption, attacked on its own terms

It is the one widening in this change that is NOT gated on the new predicate, so
it was probed separately, with the condition kind that can actually witness a
missing spine discharge — a DERIVED per-trip condition `(q >> i) & 1`, the only
one that mints `cq_template_*` rails the SPINE (rather than an emitter) must
reverse. `probes/l3a_bank_derived.c` against `probes/l3b_bank_derived_unrolled.c`:

```
ORACLE   l3a (rolled)   DECLINE  control flow inside a loop body
SUBJECT  l3a (rolled)   ACCEPT   36 trace lines
ORACLE   l3b (unrolled) ACCEPT   36 trace lines
SUBJECT  l3b (unrolled) ACCEPT   36 trace lines
diff(l3a.SUBJECT, l3b.SUBJECT) -> EMPTY, BYTE-IDENTICAL
```

and the per-trip stream shows the full discharge —
`and → icmp → x → ry_controlled → x → icmp_unc → and_unc → free → free`. So the
exemption does not merely fail to break anything: **it closes a leak the ORACLE's
decline was hiding**, and the rolled form now emits what the hand-unrolled twin
emits, byte for byte. That is the 19-vs-27 shape (`iterationLocalRollable`'s (c3)
comment) coming out equal.

Other categories attacked, with results:

| probe | what it attacks | ORACLE | SUBJECT |
|---|---|---|---|
| `a1_taintedidx.c` | (L3) must not open the tainted-INDEX half | `cq QRAM access: tainted-index memory access inside a loop` | same |
| `e1_round2.c` | L1 — a seed classical at round 1, tainted at round 2 | decline | same decline |
| `g2_nested.c` | nested loops around the carried handle | `cq rail bank: the cell walk is re-executed by an enclosing loop` | same |
| `a14c_accum_i32.ll` | (Z6) — the accumulator keeps `kMsgCrossIter` | `kMsgCrossIter` | `kMsgCrossIter` |
| `a17_guarded.ll` | (Z8) — the rotated/guarded loop keeps `kMsgCrossIter` | `kMsgCrossIter` | `kMsgCrossIter` |
| `a18_two_carried.ll` | TWO carried handles in one loop | decline | ACCEPT, two independent preheader allocs, 2 verified frees |
| `g1_twofn.c` | bd `1yeu` — TWO FUNCTIONS in one module | decline | ACCEPT, 96 lines, 4 verified frees, 0 violations |
| `d1_postloop_rot.c` | Rule 8 — a non-diagonal gate after the loop | decline | decline (different owner; see `loop_carried_handle_reject_postloop_rotation.ll`) |
