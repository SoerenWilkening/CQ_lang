# TRACK D — bd `test_C_libtooling-xdu2.9`: the constant-dead bank cell

Session 2026-09-24, parallel rail-bank follow-ups. Worktree branch
`worktree-agent-a26c9862184ee134a`, based on `d0720cb1`. Rule-13 core
(`RailBankPromote.cpp`). Non-normative record; rules live in `CLAUDE.md`.

## 1. The bead, and where the constant becomes a FACT

`int c[3] = {0}; for (i<3) { int t = cq_theta(c[i], .25); if (c[i] != 0) c[i] = t; }
… cq_measure(c[i])` is well-defined C whose store can never fire. It declined at the
literal-cell postcondition (`railbank_dynamic_matrix.c` rows 20/21).

Measured in the IR (stage 1 → promoter output, `CQ_RAILBANK_DBG`): the arm is the
EMPTIED ARM (theta before the branch, store alone in the arm) that `planBank` case (1)
admits. Inside ONE call of `applyBank`:

* PASS B forwards the in-header cell load to the zero seed;
* PASS F constant-folds its user `icmp eq i32 0, 0` → `i1 true` (the `-O1` polarity
  puts the arm on the FALSE edge);
* PASS H then read that constant condition and minted `select i1 true, i32 0, i32 %t`.

So the constant is a FACT inside the promoter, at PASS H, in the same stage that made
it — no later stage and no round-2 window is involved, and the L1 record/re-ask
machinery is not needed for it. What happened next depended on the function:

* `c[]` alone: the carve marked the bank (the select is tainted), the select reached
  `declineClassicalMuxes` → `cq taint escape: tainted value muxed by a
  classical-condition select`;
* beside a PredMux-claimed Grover `b[]` (rows 20/21): `simplifyFlattenResiduesInFunction`
  folded the select to the literal → `store i32 0` into a MARKED bank → the xdu2.4
  postcondition declined (pre-xdu2.4 HEAD accepted it and measured a freed `h0`).

## 2. The fix (one conjunct)

PASS H: if the branch condition is a `ConstantInt`, each merge φ is RAUW'd to the
value the TAKEN edge carries (`ConstCond->isOne() == ArmOnTrue ? VArm : VSkip`)
instead of becoming a `select` — SimplifyCFG's own fold, value-preserving for every φ
by definition of the constant. Only `ConstantInt` (not `undef`/`poison`/`ConstantExpr`).

* Skip edge taken (dead store): the φ becomes the seed literal, the relocated store is
  classical, the carve answers `NotBank` (`a classical store is never a rail bank`),
  `!cq.railbank` is never minted, the measure loop reads classical memory (a
  never-quantum `cq_measure` lowers to its operand, no trace line). The dead
  `cq_theta` still runs per trip.
* Arm edge taken (`if (c[i] == 0)`): the φ becomes `t`, the store is unconditional,
  and the object is the ordinary unconditional-prep bank (marked, measured).
* The runtime D1 (uninitialised VLA) case keeps the relocated `store i32 0`: it is
  NOT a no-op there, it is what makes the measure read the 0 that D1 says the cell holds.

`declineNonHandleBankStores` is untouched. Since no MATRIX ROW of this change reached it
any more (⚠ corrected in §13: a C program still does — q45, now matrix row 24), a new
IR pin was built: `railbank_deadcell_reject_backstop_literal.ll` (the row-21 module
with the `c[]` body hand-rewritten to store `select i1 true, i32 0, i32 %theta` — a
constant-condition select the promoter does not own: no in-loop load, so B8 leaves it
alone). The carve marks it, the PredMux residue fold makes it literal, the
postcondition declines. Deleting the postcondition turns exactly that fixture red (M6).

## 3. What the dead `t` emits — matched to the right twin, and why not the flat one

Flat twin (`c0,c1,c2` scalars, matrix CASE 2): `alloc/ry` ×3, then the whole-DAG
spine's `ry(−θ)+free` ×3 **LIFO at function end**. Rolled fixed program: the same
gates, uncomputed **per trip** (`alloc, ry θ, ry −θ, free` ×3). Same gate multiset on
DISJOINT fresh rails, so the reorder commutes; it is the spine's schedule for any
rolled dead preparation and is bank-independent — the ARRAY-FREE rolled twin (CASE 16)
diverges from the flat twin by the identical diff **on the pre-fix oracle too**
(measured, oracle `c6f61f80a5d524c6`). The twin of record is therefore the
array-free ROLLED twin, and the bank program is BYTE-IDENTICAL to it:

| rolled (bank source) | twin (no array) | trace |
|---|---|---|
| 1 fixed dead | 16 | IDENTICAL, 12 lines |
| 3 runtime dead (n=3) | 17 | IDENTICAL, 12 lines |
| 5 fixed constant-TAKEN | 6 (flat) | IDENTICAL, 9 lines |
| 7 copy of row 21 (+Grover `b[]`) | 18 | IDENTICAL, 100 lines |
| 9 copy of row 20 (+Grover `b[n]`) | 19 | IDENTICAL, 94 lines |
| 14 `_Bool` dead | 20 | IDENTICAL, 12 lines |

Every accept row: stage 2b STRICT, 0 violations.

## 4. Matrix `tests/e2e/railbank_deadcell_matrix.c` (+ `.c.cases.json`), ctest `e2e-railbank-deadcell-matrix`

23 cases, 18 accept / 5 decline, 6 twins. Pre-fix (oracle `c6f61f80a5d524c6`) vs fixed
(`e36d9df4bb18ce1b`):

| case | shape | pre-fix | fixed |
|---|---|---|---|
| 1 / 3 | dead cell, fixed / runtime | D `classical-condition select` | **A**, not a bank |
| 5 | constant-taken arm | D `classical-condition select` | **A**, a bank |
| 7 / 9 | copies of rows 21 / 20 | D `a cell parks a value that is not a rail handle` | **A**, `c` not a bank, `b` a bank |
| 14 | `_Bool` dead cell | D `classical-condition select` | **A** |
| 2, 4, 6, 8, 10, 15, 16–20, 23 | twins | A | A |
| 11 | one nonzero seed (`{0,1,0}`) — NOT dead | D `array escapes to an unsupported user` | D (same) |
| 12 | store gated by a classical runtime value — NOT dead | D `classical-condition select` | D (same) |
| 13 | partly dead (`c[i] != 0 \|\| i == 1`) | D `classical-condition select` | D (same) |
| 21 / 22 | IN-ARM dead prep (`if (c[i]!=0) c[i]=cq_theta(c[i],…)`), fixed / runtime | D `classical-condition phi` / `stored to memory` | D (same) |

The "no literal handle is ever parked" property is asserted on EVERY accept row by the
runner (§6), including the two rows that carry a real Grover bank beside the dead cell.

## 5. Shared rows to flip at merge (not edited here, per brief)

`tests/e2e/railbank_dynamic_matrix.c.cases.json` rows **20 and 21 → `accept: true`,
`diagnostic: null`** (keep the default `require_railbank`: the Grover `b[]` is still a
bank). Measured on the fixed binary with the shared source: both exit 0, `!cq.railbank`
present (on `b` only), 2b STRICT `4 verified, 0 violation(s), 0 unproven`, scoped
literal-in-bank hits `[]`. ⚠ They pass ONLY together with the §6 runner change: under
the old substring check each carries `store i32 0, ptr %cq.bank.addr` — the CLASSICAL
store into the non-bank `c[]` — and would fail. The source comments above CASE 20/21 in
`railbank_dynamic_matrix.c` ("Now the bank-store postcondition declines it", "so this is
an OVER-DECLINE filed as bd xdu2.9") become stale and should be updated in the same flip.

## 6. Shared harness change: `run_railbank_dynamic_matrix.py`

The literal-0 check was `"store i32 0, ptr %cq.bank.addr" in lowered_text` — keyed on
the PROMOTER'S NAME, which is minted before the carve decides whether the object is a
bank. It is now `literal_zero_bank_stores()`: every `store i32 0, ptr %P` whose `%P`
resolves through `getelementptr` hops to an alloca carrying `!cq.railbank`, per
function. Controls (run before relying on it, L10): 7 null controls (lowered accept
rows) → 0 hits each; 3 positive controls (a bank store rewritten to `store i32 0`,
fixed and runtime; and one under a renamed gep the OLD check could not see) → 1 hit
each. It is strictly more precise on banks and no longer flags a classical store into a
non-bank. Not covered: a literal reaching a bank through a `bitcast`/`addrspacecast`
hop or a direct store to the alloca (the check resolves `getelementptr` only);
`declineNonHandleBankStores` is the real gate for those.

## 7. Red-green and mutation (owned tests only; NULL control first; denominator printed)

Owned tests: `lit ir-pass/test --filter 'railbank_deadcell|railbank_literal|railbank_promote'`
(29 fixtures) + ctest `^e2e-slice-railbank-bool-|^e2e-railbank-(flat|uninit-zeroinit)-twin-identical$|^e2e-railbank-deadcell-matrix$` (6 entries).

| mutant | lit red | ctest | verdict |
|---|---|---|---|
| M0 null (`(void)0;`) | 0 / 29 | 6/6 green | survived (as required) |
| ORACLE (HEAD source) | 5: literal_cell, accept_{fixed,runtime,bool,taken_arm} | matrix red (6 rows D, twins unlinkable) | RED — the red half of red-green |
| M1 fold disabled | same 5 | matrix red | killed |
| M2 polarity flipped | 5 | matrix red (5 not a bank; all 6 twins differ) | killed |
| M3 fold on ANY condition (drop the `ConstantInt` conjunct) | reject_classical_cond, reject_partly_dead | rows 12, 13 accept | killed |
| M4 always the skip value | accept_taken_arm | row 5 not a bank, twin 5/6 differs | killed |
| M5 always the arm value | 4 | 5 twins differ | killed |
| M6 postcondition disabled | reject_backstop_literal | green (no C row reaches it any more) | killed (lit only) |

**Denominator: 8 run (1 null, 1 oracle, 6 mutants); 6/6 real mutants killed; MISSED 0.**
The comment-only rebuild after the mutation run produced a bit-identical `cq-opt`
(`e36d9df4bb18ce1b`), an unplanned build null control.

⚠ Instrument incident (L10 family): a sibling track wrote its own `mutate.py` /
`mutate.log` into the SHARED session scratchpad mid-run and truncated my log; the
first run's rows for ORACLE–M4 were lost. The whole matrix was rerun from scratch in a
track-private directory; the table above is that rerun only.

## 8. Fixtures

New: `railbank_deadcell_accept_{fixed,runtime,taken_arm,bool}.ll`,
`railbank_deadcell_reject_{classical_cond,partly_dead,backstop_literal}.ll`. Each accept
pins the promoter's output (`CQ_RAILBANK_DBG`: no `select`, no `mark bank`) and the
lowered IR (no `!cq.railbank`, no `cqrt_measure`; the per-trip dead prep).
Changed: `lowering_reject_railbank_literal_cell.ll` is now an ACCEPT, deliberately NOT
renamed (L8 / bd `gahu`); its header records the history and names the new backstop pin.

## 9. Residuals, not done here (proposed filings)

* **IN-ARM dead prep** (`if (c[i] != 0) c[i] = cq_theta(c[i], …)`): the arm does not
  empty, PASS H never runs, and the constant `br` the promoter leaves declines at
  `classical-condition phi` (fixed) / `stored to memory` (runtime); the flat twin
  compiles with no gate. Same over-decline class, different shape; matrix rows 21/22
  carry a retirement trigger. Fix direction: fold a constant-condition diamond whose
  dead arm holds the prep, before detection.
* **Partly-dead** (row 13) and **one nonzero seed** (row 11): not constant-dead; the flat
  twins compile. Needs per-trip classical specialisation / a nonzero-initialiser
  promoter; not a constant fold.
* Stale comment corrected in the same change (L7): `promoteRailBankCells` said "the
  rewrite changes NO edge"; false since xdu2.4's PASS H (it erases the arm block). The
  per-call rebuild is what makes the analyses safe.

## 10. What was NOT run

Full `ctest`, the full `ir-pass-lit`, `cq-opt-equivalence`, the corpus A/B, the loop
twin matrix and `e2e-railbank-dynamic-admission-matrix` (not owned; its rows 20/21 WILL
fail until flipped as in §5). No `+Asserts` build.

## 11. Independent Rule-13 round (one round, in-track) — `CLEAR-WITH-ITEMS`, 0 P1, 0 P2, 3 P3

A separate agent reviewed commit `8a69986e` read-only on the built binary (probes under
the session scratchpad `trackD_xdu29/review/`, not committed). It attacked the seed
(irreducible re-walk, escaped pointer, nonzero memset, partial runtime memset,
nonzero initializer, partly-dead): every one declines before PASS H. Accepted probes
checked by hand: dead fixed/runtime/`_Bool` (twins identical), rows 20/21 copies
beside PredMux, a `_Bool` TAKEN arm (PASS G narrowing then the fold), a runtime taken
arm, an `unsigned` `icmp ugt` fold, the dead prep's `t` measured directly, two banks in
one dead arm, a taken arm beside the Grover arm vs its flat twin, and a hand-edited
NON-bank merge φ in the fold block on both polarities (classical answers correct).

* **P3-1** — the scoped runner check missed `store volatile` / `store atomic`, a store
  with no `, align`, and quoted function names. **Fixed in the follow-up commit**:
  loosened regexes, a loud failure on an unparsed `define`, and 5 more positive
  controls (all 1 hit) beside the 8 null/positive controls of §6 (16/16 PASS). Still
  NOT resolved by the harness (by design): a store through a φ/select of addresses —
  `declineNonHandleBankStores` is the compiler's gate.
* **P3-2** — pre-existing: a dead cell and a real bank in ONE loop declines
  `cq uncompute: tainted handle live range crosses a loop backedge`; the array-free twin
  declines identically, so it is the uncompute spine's limit, not this change's.
* **P3-3** — the non-bank-φ branch of the fold has no demonstrated C customer (`-O1`
  sinks classical ops into the arm, so it never empties); exercised only by hand IR.

Not attacked by the round: multi-function modules (bd `1yeu`), and
`getUnderlyingObject` through a φ/select of pointers in the postcondition.
⚠ One in-track round is NOT the Rule-13 budget CLAUDE.md asks for on a core change;
the merge gate owes its own.

## 12. Orchestrator Rule-13 round 1 on `665cb4a7` — `CLEAR-WITH-ITEMS`, 0 P1/P2

**P3 (fixed in the follow-up commit): the scoped runner check was still too narrow.**
It flagged only `store i32 0`; a NON-ZERO integer literal, `undef` or `poison` stored
into a marked bank, and any bank alloca / gep / function name containing `-` or `$`,
were invisible. `literal_zero_bank_stores` is replaced by `literal_bank_stores`: it
flags ANY non-SSA stored value (any integer literal at any width, `true`/`false`,
`undef`, `poison`, a constant expression — ⚠ a comma-containing one only since §13's
fix) whose address resolves through
`getelementptr` hops to a `!cq.railbank` alloca. Local names use LLVM's full unquoted
class `[-\w.$]+` or a quoted name; function names likewise; an unparsed `define` is a
loud failure. Controls (pure Python, run by hand): **50 controls, 0 failures** —
28 NULL modules (every lowered ACCEPT of both matrices in this worktree: 18 deadcell +
10 dynamic, all non-empty, 16 carrying a real `!cq.railbank`) → 0 hits each; 22
positive/boundary controls → literal 0 (fixed and runtime), 5, −1, `undef`, `poison`, a
constant expression, volatile, atomic, no-align, renamed gep, gep names with `-`/`$`/
quotes, bank allocas named with `-`/`$`/quotes, quoted and `-` function names, a direct
store to the alloca → 1 hit each; an SSA handle and the dead `c[]` classical 0 into a
non-bank → 0. Still NOT resolved (by design): a store through a φ/select of addresses.
Only two rail-bank matrices exist in this worktree (dynamic, deadcell); the third
track's matrix is not on this branch and was not run.

**Recorded, no code (reviewer probe `p13_taken_outer_rail.c`).** An ALWAYS-TAKEN arm
(`if (c[i] == 0) c[i] = r;`) that parks a rail `r` minted OUTSIDE the loop into every
cell now compiles: after PASS H resolves the constant condition the store is
unconditional, so the same handle is parked in all three cells and measured three
times (`h0` measured 3×). It matches the UNCONDITIONAL twin (`c[i] = r;` in the loop),
which the pre-fix oracle already accepts — so the defect class is PRE-EXISTING (bd
xdu2.1's class: one rail aliased into several cells), not introduced here. ⚠ But
"pre-existing" is true of the defect and FALSE of its population: this change adds a
ROUTE into it (a conditional store whose condition folds to constant-true). Whatever
fence closes xdu2.1's class for the unconditional spelling closes this route too,
because after PASS H the two are the same IR; the xdu2.1 fix should carry this probe
as a customer.

## 13. Orchestrator Rule-13 round 2 on `1ca78174` — `CLEAR-WITH-ITEMS`, 0 P1/P2

**P3-3 (fixed): §12's "flags a constant expression" was FALSE for any constant
expression containing a comma** (`getelementptr (…, …)`, `add (…, …)`): the operand
regex `[^,]*` stopped at the first comma, the line no longer matched, and the store
was silently skipped. The operand is now split from the address by anchoring on the
LAST `, ptr %<name>` of the store line (a constant can never name a `%` local, so the
last such anchor is the address). Controls: **54, 0 failures** (28 null modules
unchanged, plus 3 comma-ConstantExpr positives — `ptrtoint(getelementptr(…,…))`,
`add(…,…)`, and an atomic `add(…,…)` into a quoted gep named `%"q, r"` — and an
SSA-with-`!tbaa`-tail negative). RED CHECK: the same 54 controls against the
`1ca78174` runner fail exactly the 3 comma positives (3 failures), so the controls
witness the fix.

**P3-4 (fixed, comment only): the PASS H "a FACT, not a prediction" claim is now
stated as CONDITIONAL ON THE SEED.** For a zero-initialised bank the zero is what C
says; for an UNINITIALISED bank (fixed without initializer, or any VLA) it is owner
ruling D1, and the comment now cites D1 and says the conjunct falls with it for
uninitialised banks. The `undef`-condition refusal is reconciled in one sentence (D1
chose the seed once, by ruling; an `undef` condition would be a second, unruled
choice). Rebuilt `cq-opt` is bit-identical (`e36d9df4bb18ce1b`) — a comment-only null
control.

**Matrix row 24 (reviewer probe q45) — the BACKSTOP REACHED FROM C.** My §2 sentence
"no C row reaches it any more" was true only of THIS change's matrix rows. q45 compares
the cell with a `volatile const` local: not a constant when the promoter runs (PASS H
keeps the select, the carve MARKS the bank), then a later stage folds the volatile
const to 0 and the PredMux residue fold (the Grover `b[]` in the same function) makes
the select a literal — `declineNonHandleBankStores` declines `cq rail bank: a cell
parks a value that is not a rail handle`. Pinned as a decline row; it is an
over-decline of well-defined C (asking the constant question after the late fold would
remove it), left deliberately and noted in the row's comment.

**Round-2 residuals, recorded (no code; the orchestrator files beads):**
* **q74/q75** — the `store (select (icmp c[i]==0), 0, t)` spelling: PASS F folds the
  compare but deliberately refuses to fold a non-constant-operand select, so the
  module declines `classical-condition select`; the flat twin compiles. Pre-existing.
* **q45** — above; row 24.
* **q43/q44** — the `switch` spelling of the dead cell still declines
  `classical-condition phi` (PASS H only folds the emptied if-without-else diamond).
