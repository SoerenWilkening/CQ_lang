# SCOPE_T2 — bd `test_C_libtooling-tu9q`'s HOISTED-TEMPLATE HALF

Group-1 scoping agent, session 2026-09-18. MAIN checkout, ORACLE `cq-opt`
`9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` (verified at open and
before every measurement; never rebuilt). **I edited no source, no fixture, no test, and ran
no build and no suite.** Every line below is a MEASUREMENT with its command in `GATES.md`, or
a SOURCE reading with `file:line`. Probes under `probes/`.

> ⚠ **Read §0.1 first.** Three load-bearing claims in `$PREV/trackT/IMPL_T2.md` §6 — the
> document this increment is scoped from — do not survive measurement. The increment is still
> a GO and the "one increment or none" conclusion still stands, but for a **different
> mechanism**, and the file surface §6 names is **wrong in one file**.

---

## §0 — VERDICT: **GO**, one increment, FOUR pieces in a strict dependency chain

**Rule 17 sentence.** This is a lowering we set out to build, and it is the correctness
boundary for the full Grover iteration. A decline is not the escape here and is not proposed
anywhere below: every fence this scope adds is a BACKSTOP behind a real placement, never a
substitute for one. The one program I recommend leaving declined
(`preheader_volatile_imm`, §3.4) is declined by a **different predicate with a different
owner**, measured in source, and it is filed as a defect rather than absorbed.

**And the increment is more urgent than the brief says: it closes a live over-accept, not
only a divergence.** `probes/a1_apost.c` — bd `1m5p`'s own "reachable consequence", which
nobody had built — compiles at **exit 0** today with the hoisted `sqrt` rail left allocated
and entangled, a **non-diagonal `cqrt_ry_i32` on the register it copies**, and then a
measurement of that register. Its hand-unrolled twin discharges the rail. Rolled and flat are
**different unitaries** (Rule 8's last sentence) and the only instrument that sees it is a
**WARNING** (`non-diagonal gate over a live derived record`, rolled; silent on the twin).
`declineDephasingUnmarkedLoopRails` does **not** refuse it, and §2.6 gives the source reason:
its conjunct (3) quantifies over `L`'s **OWN** blocks and this rail is minted in the
**PREHEADER**. That is CLAUDE.md §5's Q-R1-1 *second half* — "the ACCEPT was the defect" —
reproduced, at exit 0, on the session ORACLE.

**The four pieces and why the chain matters** (each prefix is safe to land on its own; no
prefix is safe to SKIP):

| # | piece | file | what it buys | what breaks without it |
|---|---|---|---|---|
| **P1** | the real MULTIPLICITY test (`markedHeaderOf(G) == markedHeaderOf(At)`) | `Uncomputation.cpp` | a BACKSTOP that refuses a gate/discharge pairing whose endpoints repeat different numbers of times | P2 can place an `At` outside a marked body while a recovered gate is inside it — **one adjoint for K forward executions**, a wrong unitary |
| **P2** | the loop-EXIT anchor for a rail minted outside the loop its consumer sits in | `Uncomputation.cpp` | closes bd `1m5p` (6 quarantined class-A cells) **and the `a1_apost` over-accept** | the rail is DROPPED by the per-activation anchor test and leaks forever (measured, §2.3) |
| **P0** | partition interior COMPONENTS by enclosing-marked-body of the MINT block | `Uncomputation.cpp` | lets a component that spans the loop boundary discharge its body half per trip and its preheader half once | with P3 but without P0 the mixed component refuses at P1 and the invariant rail leaks — see P3 |
| **P3** | clause **(ii-d)**: admit a hoisted out-of-place TEMPLATE rail as a Root | `LoopLowering.cpp` | closes `s2_live_derived_region`, `hoisted_template`, `short_sext`, the bd `s82e` divergent hoisted-template half | **P3 ALONE IS A NEW OVER-ACCEPT** — see §0.1(b) |

**Recommended landing shape: ONE branch, one Rule-13 budget, four commits in the order
P1 → P2 → P0 → P3.** If the orchestrator wants to de-risk, **P1+P2 is a complete, closed,
independently valuable capability** (bd `1m5p` + the `a1_apost` class) that touches ONE file
and marks NO new body — so it cannot silence Track S′'s fence — and P0+P3 can follow as a
second commit on the same branch under the same review. I do **not** recommend two separate
sessions: P0/P3's Rule-13 argument is about the same placement logic P1/P2 introduce, and
splitting the review is how a composition ships uncleared (CLAUDE.md, three sessions running).

### §0.1 — three IMPL_T2 §6 claims that do not survive measurement

**(a) THE K-ADJOINTS-AGAINST-ONE-FORWARD HAZARD §6 DESCRIBES IS UNREACHABLE, and §6
contradicts itself about it.** §6 says admitting the root without piece 2 gives *"K adjoints
against ONE forward `cq_template_mul_i32_hl`"*; four paragraphs later the same section says
the rolled form *"would emit 23 trace lines against its twin's 25 … because `%p` itself would
leak"*. Those are different outcomes and only the second is reachable. Source: the interior
partition's convergence loop (`Uncomputation.cpp:879-898`) runs **before** §4, and it asks
`provablyBeforePerActivation(U, At, /*Barrier=*/R, DT)` where `R` is the rail's own MINT. For
a PREHEADER-minted rail with an IN-BODY consumer and an IN-BODY `At`, every path `At ⇝ U`
goes round the back edge and **never re-executes the preheader**, so
`reachesWithoutBarrier` succeeds, the helper returns false
(`WireWalk.cpp:885-920`) and the rail is **DROPPED from `Owned`** — it leaks. The other
partition refuses the same pairing by the explicit re-confirmation at
`Uncomputation.cpp:442-448` (an iteration-local group whose DAG contains a gate outside
`IterationLocalBlocks` returns outright). **The consequence for the plan is not "relax":
P1 is still required**, because P2 *creates* the mirror pairing (a body gate with an
exit `At`) that nothing today refuses — see §2.1.

**(b) "ONE INCREMENT OR NONE" IS TRUE, BY A DIFFERENT MECHANISM, AND THE MECHANISM IS WORSE
THAN A LEAK.** P3 alone marks the body of `s2`. `declineDephasingUnmarkedLoopRails`'
**conjunct (1) is "the body must be UNMARKED"** (`LoopLowering.cpp:4435` `bodyBlocksMarked`,
consumed at the fence; `$PREV/trackT/IMPL_T2.md` §5 states the same in the opposite
direction). So P3 alone converts `s2` from a **LOUD DECLINE** to an **ACCEPT at 23 lines
against the twin's 25** with the hoisted `mul` rail left allocated and entangled across the
trailing `cqrt_ry_i32(h0, 0.9)` and `cqrt_measure_i32(h0)`. That is exactly the class the
fence exists to refuse, arriving through the door P3 opens — the F-1 shape of 2026-09-15
repeating. **P3 must not land without P0, and the implementer must be told this in those
words.**

**(c) THE FILE SURFACE IN §6 IS WRONG IN ONE FILE.** §6 says piece 2 is *"new placement logic
in `FreePoint` / `DagTraversal`"*. Measured: every customer's rail is owned by the **M-B
INTERIOR partition**, which never calls `computeFreePoint` (`Uncomputation.cpp:1397-1398`
says so in its own words: *"there is no free point to compute"*) and computes its `At` with
`dagInsertPoint`, which is defined in **`Uncomputation.cpp:182`**, not in `DagTraversal.cpp`.
Evidence: `s2`'s twin lowers to ONE insertion point emitting `and_unc/free, and_unc/free,
mul_unc/free` in one block (`GATES.md` row 3), which is `reverseInteriorGroup`'s shape; and
`h1`/`h2` both have template-producer users, so `isTerminalHandle` is false and
`isInteriorTerminalHandle` (I1)/(I3) is true (`ChainWalk.cpp:920-966`). **`FreePoint.cpp` and
`DagTraversal.cpp` are NOT touched** (§1, with the residual filed).

---

## §1 — THE FILE SURFACE (this decides the session's gate topology)

| file | touched? | functions / line ranges | note |
|---|---|---|---|
| `ir-pass/src/Uncomputation.cpp` | **YES** — the main edit | `planInteriorComponent` (`:855-1285`): the §4 per-gate scan at `:965-981` and the §2.9 final-`At` fence at `:1025-1027` get **P1**; the anchor loop at `:867-874` (the `Anchors.push_back` at `:872`) gets **P2**. `collectInteriorPlans` (`:1307-1560`): the union-find `link` at `:1519-1532` gets **P0**, and the post-plan cross-group ordering check is new code after `:1552`. `reverseTerminalGroup` (`:376-576`): P1 mirrored at `:442-448` and `:561-563` as defence in depth. `uncompute` (`:1608-1690`): the new loud (ii-d) POSTCONDITION at its tail (§2.5). | ~60 code + ~190 comment |
| `ir-pass/src/LoopLowering.cpp` | **YES** — narrowly | NEW clause **(ii-d)** inside `invariantRegisterRootsImpl`, between (ii-c) at `:3486-3502` and the `dyn_cast<CallInst>(Root)` at `:3503-3505`. `railLocalQualifies` at `:3707-3712` — **COMMENT ONLY** (`onRail(Op)` becomes true automatically once the root is in `Roots`; its 12-line retirement trigger is now FIRED and must be re-derived IN THE SOURCE, L7-with-a-twist). `measureOwnedInvariantRail`'s header at `:3320-3356` and clause (ii)'s "hoisted TEMPLATE rail … is UNAFFECTED and still refused" paragraph at `:3540-3543` — comment corrections. | ~15 code + ~120 comment |
| `ir-pass/src/FreePoint.cpp` | **NO** | Its three `IterationLocalBlocks` reads (`:169-178`, `:304-310`, `:342-352`) serve the DEAD-TERMINAL driver only. No customer of this increment is a dead terminal (§0.1(c)). ⚠ FILE the symmetric residual: a dead-terminal group whose DAG reaches a preheader gate is refused at `Uncomputation.cpp:442-448` and leaks; that is an over-decline with **no measured customer**, and inventing one is out of scope. | — |
| `ir-pass/src/DagTraversal.cpp` | **NO** | `recoverDataDag`'s output does not change; only where its adjoint is placed. | — |
| `ir-pass/src/ChainWalk.cpp` | **NO** | `isInteriorTerminalHandle` (I1) already admits a `cq_template_*` rail — that is *why* the multiplicity argument that licenses a root mint does not carry, and the fix is placement, not admission. `!cq.branchphase` membership untouched. | — |
| `ir-pass/src/TaintPropagation.cpp` · `ir-pass/include/TaintPropagation.h` | **NO** | **P1 needs NO new `TaintSet` field.** `markedHeaderOf(BB)` is derivable in `Uncomputation` from the `LoopInfo` it already builds plus `taint.IterationLocalBlocks` (§2.1). Avoiding a field is not cosmetic: a new member in the MIDDLE of `TaintSet` is the ODR/layout divergence that segfaulted `cq-opt` while `libCQPass.so` lowered correctly (`IMPL_T2` §13). | — |
| `ir-pass/src/CQLoweringPass.cpp` | **NO** | No new stage. The (ii-d) postcondition lives at the tail of `uncompute` (which already has `Module`, `TaintSet`, `WidthDispatch`) rather than as an 11th entry in the two `run` chains. ⚠ If the implementer instead adds a stage, it must go in **BOTH** entry points (`:500`/`:1212` neighbourhoods) and the brief should say so. | — |
| `ir-pass/include/*.h` | **ONE, optionally** | `LoopPlan.h` — iff the implementer exports the single "does this loop have a usable exit discharge point?" predicate so clause (ii-d) and the P2 anchor rule CALL one spelling instead of two (Rule 14; the drbq Inc-3 (b′) defect). **Recommended.** Nothing else. | ~8 lines |

**The E5.2 seams, by line range, measured today — and one of the brief's four line numbers is
STALE.**

| seam (brief) | where it actually is at `cff8f7ac` | edited by this increment? |
|---|---|---|
| `iterationLocalTaintEscape` "`4143-4158`" | **`LoopLowering.cpp:4933-4958`** — the brief's number predates the 2026-09-15 landings. Its two callers are `ArmClassify.cpp:4174` and `LoopLowering.cpp:5279` | **NO** |
| the marking re-verify region "`~4380-4560`" | `bodyBlocksMarked` `:4435-4515`, `declineRound2FalsifiedRailGrants` `:4549-4672` | **NO.** The re-ask calls `invariantRegisterRoots` (`:4658`), so it picks up clause (ii-d) automatically — that is the Rule-14 property, not an edit |
| `kMsgCrossIter` `:2143` | `LoopLowering.cpp:2143` — correct | **NO** |
| `kMsgCrossIter` `:2595` | `LoopLowering.cpp:2595` — correct | **NO** |

**Explicitly NOT touched, so Group 2 does not collide:** `ir-pass/src/ArmClassify.cpp`,
`ir-pass/src/RegionTreeDetect.cpp`, `ir-pass/src/WireWalk.{h,cpp}`. This increment is a
**CALLER** of `WireWalk`'s `provablyBeforePerActivation` and `everyPathReExecutes` and edits
neither. **⇒ Group 1 and Group 2 (bd `x5fp`, bd `drbq.12`) are DISJOINT BY FILE and may run
in parallel.** ⚠ Two caveats the orchestrator should carry: (i) `iterationLocalTaintEscape`
*lives* in `LoopLowering.cpp` and is *called* from `ArmClassify.cpp`, so if Track X or D
finds it must widen that body, the two groups MERGE — tell both tracks to report it rather
than edit it; (ii) bd `8h7d.12`'s (c3) diagnostic is in `LoopLowering.cpp` and is therefore
Group 1's file, exactly as the session prompt says.

**Explicitly NOT edited by Group 1:** `tools/loop_twin_matrix.py`, `…expected.txt`,
`…quarantine.txt`. Track V owns them and lands FIRST. Group 1's twin witness goes through
committed e2e goldens + ctest entries, as Track T's did. ⚠ **Group 1 WILL move six
quarantined cells** (§3.2) — those rows go to the **merge-and-gate agent** as a table with
per-trip arguments (§3.2), never written by the implementer. **This is a hard sequencing
constraint: Track V must land before Group 1's merge gate, or the quarantine selftest and
`e2e-loop-twin-matrix` go red for two unrelated reasons at once.**

---

## §2 — THE DESIGN

### §2.1 — P1, the multiplicity predicate

```cpp
// Uncomputation.cpp, file-local, beside RepeatOracle (:159-176).
// NULLABLE KEY. `nullptr` == "runs at most once per function activation".
const BasicBlock *markedHeaderOf(const BasicBlock *BB, LoopInfo &LI,
                                 const TaintSet &taint) {
  if (!taint.IterationLocalBlocks.count(BB)) return nullptr;
  const Loop *L = LI.getLoopFor(BB);          // INNERMOST, deliberately
  return L ? L->getHeader() : nullptr;
}
bool multiplicityAgrees(const Instruction *G, const Instruction *At,
                        LoopInfo &LI, const TaintSet &taint) {
  return markedHeaderOf(G->getParent(), LI, taint) ==
         markedHeaderOf(At->getParent(), LI, taint);
}
```

**Which side refuses which pairing.** Asked at exactly the two places that already ask each
endpoint alone, and **only after** they have answered:

* `planInteriorComponent` §4, immediately after the existing
  `if (canRepeat(G->getParent()) && !taint.IterationLocalBlocks.count(G->getParent()))
  return false;` (`:978-979`) — add `if (!multiplicityAgrees(G, At, LI, taint)) return false;`.
  This refuses **preheader-`G` / body-`At`** (null vs header) and **body-`G` / exit-`At`**
  (header vs null). The second is the one **P2 creates**; the first is unreachable today for
  the reason in §0.1(a) and is the `8h7d.10` backstop.
* `planInteriorComponent` §2.9, at `:1025-1027`, the same test against the final `At`.
* Mirrored in `reverseTerminalGroup` at `:442-448` and `:561-563` as defence in depth, with a
  comment saying it is expected never to fire there (the `IterLocal` re-confirmation at
  `:444-448` already refuses the same pairing) — the same trade the file already makes at
  `:1362-1381` for the four ownership sets.

**`canRepeat`, not `LoopInfo` — and this predicate does not break that (bd `4p7j`).** The
repeat ORACLE stays `RepeatOracle`/`blockCanRepeat` exactly as today; `LoopInfo` is used here
only to build a **key**, and only for blocks that are already in `IterationLocalBlocks`.
**An irreducible cycle is never marked** (both writers are `LoopInfo`-gated —
`LoopLowering.cpp:2486` and `:3762`, and `bodyBlocksMarked`'s enumeration at `:4401-4425`
proves there are exactly two), so `markedHeaderOf` returns `nullptr` for every irreducible
block, and the *existing* `canRepeat` test has already refused it before this one is asked.
Write that argument at the definition, with the retirement trigger **"a third
`IterationLocalBlocks.insert` site, or a marker that is not `LoopInfo`-gated, invalidates the
null-key reading"** — the same trigger `bodyBlocksMarked` already carries, which is why the
two must be re-derived together.

⚠ **THE NULL×NULL CELL IS THE ONE TO ATTACK** (§6 lens 1): two *unmarked* blocks in two
*different* loops both key to `nullptr` and compare EQUAL. That is sound only because the
pre-existing per-endpoint `canRepeat` tests have already refused any repeating unmarked
block, so null×null can only mean "both run once". **If either of those tests is ever
narrowed, this predicate becomes an over-accept.** State it at the definition; do not rely on
the reader reconstructing it.

### §2.2 — P2, the loop-exit recovery point

In `planInteriorComponent`'s anchor loop (`:867-874`, the push at `:872`), replace
`Anchors.push_back(cast<Instruction>(U)->getNextNode());` with: if `U` sits in a loop that does
**not** contain `R` (the rail's own mint), walk **outward** to the OUTERMOST such loop `LOut`
and anchor at `LOut`'s exit instead.

```cpp
// The rail is minted outside the cycle its consumer runs in, so the consumer's own
// `getNextNode()` is a point that repeats while the forward gate does not. Anchor at the
// point where the consumer is finished for good: the loop's single exit.
const Loop *LOut = nullptr;
for (const Loop *L = LI.getLoopFor(U->getParent()); L; L = L->getParentLoop())
  if (!L->contains(R->getParent())) LOut = L;          // outermost non-containing
Instruction *A = U->getNextNode();
if (LOut) {
  BasicBlock *Exit = LOut->getUniqueExitBlock();       // nullptr ⇒ multi-exit
  if (!Exit || Exit->getFirstInsertionPt() == Exit->end())
    return false;                                      // no usable point — LEAK (Rule 6)
  A = &*Exit->getFirstInsertionPt();
}
Anchors.push_back(A);
```

**Nothing downstream is relaxed; the placement simply gets a better candidate, and every
existing proof is re-run at it.** That is the whole safety argument and it is why this is
small:

| Track T's named soundness condition | how it is CHECKED, not assumed |
|---|---|
| "`%p` is dead at the exit" | the existing convergence test, now at the new `At`: `provablyBeforePerActivation(U, At, R, DT)` (`:889`). With `At` at the exit the PLAIN leg succeeds (`DT.dominates(U, exit)` and `!isPotentiallyReachable(exit, U)`) and no barrier walk is needed — which is exactly why the rail stops being dropped |
| "its borrowed parent `y` is ungated inside `L`" | clause (d) at `:1244-1280`, unchanged. A mutation `M` of the parent **inside** `L` satisfies neither `everyPathReExecutes(M, At, First)` nor `routeGroupFullyInside`, so the component **LEAKS** (`return false`). I traced this by hand for `a = cq_theta(a,.5)` in the body: `First` is the preheader `sitofp`, the path `M → latch → exit` re-executes nothing, refused ✓ |
| "the body's rails have already been returned to \|0⟩" | ⚠ **This one is NOT checked by anything today and is P0's obligation, not P2's** — see §2.4. For a component whose rails are ALL minted outside the loop (bd `1m5p`, `a1_apost`) there are no body rails and the condition is vacuous, which is why P1+P2 alone is a safe prefix |
| every gate ran before, and `At` post-dominates it | §4's existing `DT.dominates(G, At)` (`:1003`) and `PDT.dominates(At->getParent(), G->getParent())` (`:1013`), unchanged |
| `At` itself runs once | §2.9's `blockCanRepeat(At->getParent())` (`:1025`), unchanged — a loop exit block that is itself inside an outer loop still refuses |

**Multiple exits / `break`.** `getUniqueExitBlock()` returns null, the candidate is dropped
and the rail leaks — **today's behaviour exactly**. So `tu9q.1`'s `r1_break_loop` and
`loop_pairing_accept_break_latch_folded.ll` are **unmoved by construction**, and the
implementer owes a decline fixture that pins it (§5). This is the safe direction and is NOT
an over-decline to remove now: a multi-exit discharge point is a separate capability with its
own post-dominance argument (`FIX.md` §6 already refuses to invent one).

**Nested loops (bd `emkg`'s class — checked, not assumed).** The walk takes the **OUTERMOST**
non-containing loop, so a rail minted outside a nest and read in its innermost body is
discharged after the WHOLE nest. That is required: anchoring at the inner exit would place a
once-only discharge on a point that repeats once per outer trip, and §2.9's
`blockCanRepeat(At->getParent())` would then refuse it — correct, but as a leak rather than
as the right placement. ⚠ `emkg`'s actual defect was **conjunct (1) reading `L->blocks()`
where conjunct (3) reads own blocks**; this walk uses `L->contains(...)` (which DOES include
subloops, and that is the right reading here: "is the mint inside this cycle at all"), and
`markedHeaderOf` uses `LI.getLoopFor` (INNERMOST, which is the right reading there: "how often
does this block run"). **Two different questions, two different quantifiers, stated at both
sites** — that is precisely the L2 discipline `emkg` was filed for.

### §2.3 — why the drop happens today (the measurement P2 is built on)

`m_none_oder_none_none_none` rolled, ORACLE, `probes/…none.trace`: the chain
`sitofp → fadd → sqrt` is LICM-hoisted to the preheader; `h2`/`h3` are `_unc`'d and freed **in
the preheader at trace lines 8-11**, and `h4` (the `sqrt` rail, read by the body's condition)
is never discharged. That is `planInteriorComponent`'s convergence loop dropping `h4` (its
consumer is in the body, its barrier is the preheader `sqrt`) and then re-converging on
`{h2,h3}` with `At` in the preheader. **`h3` is freed while `h4`, derived from it, is live**,
which is why `h4` can never be discharged afterwards — the LIFO inversion bd `1m5p` records.
With P2 the whole component anchors at the exit and all three discharge LIFO, matching the
twin's multiset exactly.

### §2.4 — P0, the component partition (the piece IMPL_T2 §6 does not name)

`collectInteriorPlans`' union-find (`:1519-1532`) merges a rail with every **producer
operand** that is anchorable. For `s2` that puts the preheader `mul` rail and the body `and`
rail in **ONE component with ONE `At`** — and there is no single point that is right for both
(the `mul` ran once, the `and` ran K times). P1 therefore refuses the component and it leaks:
23 lines vs 25. **P3 without P0 is §0.1(b)'s over-accept.**

**The fix, and it must argue with a written invariant.** `Uncomputation.cpp:1490-1493` says
*"NEVER FINER THAN A COMPONENT … splitting them would let one be freed while the other's
adjoint still reads it (Rule 8's shared prefix)"*. The partition proposed here is finer, so
the invariant's own hazard must be **discharged, not waived**:

* **Partition rule**: `link()` merges two rails only when
  `markedHeaderOf(A->getParent()) == markedHeaderOf(B->getParent())` (the same key P1 uses —
  ONE spelling, two customers, Rule 14). For `s2`: `{h2}` keyed on the body header, `{h1}`
  keyed null. `h1` then becomes a BORROWED parent of `{h2}` (§3's frontier at `:913-931`
  inserts any tainted non-owned operand) and an OWNED rail of its own component.
* **The hazard is discharged by ORDER, and the order is CHECKED.** `{h2}`'s in-body adjoint
  `and_unc(h2, h1, 2)` READS `h1`; `{h1}`'s `cqrt_free(h1)` must follow every execution of it.
  Add, after the `Plans` vector is built and before any emission: for every pair of plans
  where one's owned rail appears in the other's `Borrowed` set, require
  `DT.dominates(At_inner, At_outer) && !isPotentiallyReachable(At_outer, At_inner)` — i.e.
  plain `provablyBefore` — and **drop the OUTER plan** (leak, Rule 6) if it fails. ~12 lines.
  ⚠ Do **not** express this as "the exit post-dominates the body"; that is true and it is not
  the property (a zero-trip guarded loop's body does not dominate its exit, and then the inner
  adjoints never run while the outer one does — which is *fine*, because the body rails were
  never minted either, but the code must say which property it is relying on).
* **"PLAN ALL, THEN EMIT ALL" (`:1495-1500`) is what makes this legal** and must not be
  reordered: at plan time `{h2}`'s clause-(d) scan over `h1` sees only the forward `and`, not
  `{h1}`'s not-yet-emitted `mul_unc`/`free`. ⚠ I considered and **rejected** a two-pass
  "plan, emit, then re-plan the dropped rails" spelling for exactly this reason — the second
  pass would see the first's `_unc`s as users of `h1`. Record the rejection so the next agent
  does not re-derive it as an optimisation.

### §2.5 — P3, clause (ii-d), and the postcondition that makes it total

Insert between (ii-c) (`:3486-3502`) and the `dyn_cast<CallInst>(Root)` at `:3503-3505`:

```cpp
// (ii-d) OR A HOISTED OUT-OF-PLACE TEMPLATE RAIL — the half bd `tu9q` left.
//        Unlike (ii)/(ii-b)/(ii-c) this rail IS exactly what
//        `ChainWalk::isInteriorTerminalHandle` (I1) admits, so the multiplicity
//        argument that licenses the other three DOES NOT CARRY. It is licensed
//        instead by PLACEMENT: `Uncomputation`'s loop-exit anchor discharges it
//        ONCE after the loop, and P1's multiplicity test refuses every other
//        pairing. Both halves are required; see the postcondition below.
if (auto *VI = dyn_cast<Instruction>(V))
  if (!L->contains(VI->getParent()) &&
      mintsOutOfPlaceTemplateRail(VI, taint) &&   // Rule 14: CALL Track S′'s
      loopHasExitDischargePoint(L)) {             // the ONE spelling P2 also calls
    RootsOut.insert(Root);
    continue;
  }
```

Four things about that, each measured or read in source:

1. **The vocabulary is PRE-lowering, and that is why it must be `mintsOutOfPlaceTemplateRail`.**
   `lowerLoops` runs at `CQLoweringPass.cpp:500` and `collapseFlattenedLoopRails` at `:600`,
   both **before** `lowerRotations` (`:826`) and `lowerOps`. So `p = y * 3` is still an LLVM
   `mul i32` — a `BinaryOperator`, not a `cq_template_mul_i32_hl` call — which is why clause
   (ii)'s `dyn_cast<CallInst>(Root)` refuses it today. `mintsOutOfPlaceTemplateRail`
   (`LoopLowering.cpp:4329-4374`) is the tree's ONE predicate for *"will `lowerOps` mint an
   out-of-place rail here?"* and it handles `BinaryOperator`/`CmpInst`/`CastInst`/`FNeg`.
   ⚠ **L3-MIRROR OBLIGATION, and it is the one this increment is most likely to get wrong.**
   That predicate's own retirement trigger says *"this is a SUPPRESSION at both call sites — a
   `true` here silences a decline. Any third caller must state which direction it reads the
   answer in BEFORE it is added."* This caller reads it in the **GRANTING** direction (`true`
   ⇒ admit a root ⇒ mark a body ⇒ more discharge AND a silenced fence). **Write that sentence
   at the new call site and re-derive the predicate's stale-marking CEDE branch
   (`:4342-4360`) for the granting direction, in the same change.** That exact omission —
   adding a granting caller to a predicate whose "not exploitable" argument was written for
   its existing callers — cost a P1 on 2026-09-14 (bd `a3z7` / `0njv`).
2. **Which loop-marking call site this reaches.** All three hoisted-template customers have
   in-loop tainted control, so `lowerLoops`' round-1 escape (`:5471-5474`) refuses them at the
   (L2) tainted-branch clause and the marking comes from **`collapseFlattenedLoopRails`
   (`:3891-3907`)**, after the region is emitted and flattened. ⚠ **That path does NOT call
   `recordRound1RailGrant`** (grep: exactly one call site, `:5474`) and it runs at `:600`,
   **before** `repropagateControlMerges` at `:616` — so its grant is inside the round-2 taint
   window with **no L1 re-ask at all**. That is PRE-EXISTING (the reviewer filed
   `markIfIterationLocal`'s round-1 grant as the same gap, `review_r13_loop` §I-5) and **this
   increment adds customers to it**. §6 lens 4 and §7 carry it.
3. **`preheader_volatile_imm` is deliberately NOT admitted** — see §3.4.
4. **THE POSTCONDITION (new, and it is what makes P3 total).** Clause (ii-d) grants a
   MARKING on a prediction about a placement that a *different file* makes several stages
   later, over facts (`ControlOwnedRails`, borrowed-parent mutations, convergence) that are
   not final at marking time. If `Uncomputation` then refuses, the invariant rail leaks **and
   Track S′'s fence has already been silenced by the marking** — §0.1(b) with no diagnostic.
   So at the **tail of `uncompute`**, for every (ii-d)-granted root recorded in a small
   `TaintSet`-free side vector, verify the module now contains a `cq_template_*_unc` naming
   it; if not, **DECLINE LOUDLY**. Suggested string:
   `cq loop lowering: hoisted invariant rail admitted for in-loop discharge was not discharged`.
   This is the `declineSurvivingIntrinsicCalls` pattern (Rule 1: make the postcondition a
   checked, LOUD property rather than a comment) and it is the ONLY total answer — a fence in
   `LoopLowering` cannot see the outcome. ~20 lines.

### §2.6 — two implementation facts the implementer will hit in the first hour

* **`mintsOutOfPlaceTemplateRail` is defined at `LoopLowering.cpp:4329`, inside the anonymous
  namespace block `:4179-4543`, while `invariantRegisterRootsImpl` is at `:3370` inside the
  block `:2525-3792`.** All unnamed-namespace blocks in one TU name the SAME namespace, so a
  forward declaration inside the earlier block is legal and sufficient. **Declare it forward;
  do NOT move the definition** — Track S′ owns that function and moving it manufactures a merge
  conflict in the one file two sessions have already fought over.
* **`declineDephasingUnmarkedLoopRails`' conjunct (3) reads `L`'s OWN blocks, so it is blind to
  a PREHEADER-minted rail** (§3.6). That is why P3's safety cannot be delegated to it and why
  §2.5(4)'s postcondition exists. Do not write "the fence would catch it" anywhere.

**`railLocalQualifies` needs NO code change.** Once the root is in `Roots`, `onRail(Op)` at
`:3712` is true and the "accumulating loop-invariant tainted input" clause stops firing.
⚠ **But that clause carries a 12-line retirement trigger** (`:3713-3725`) ending *"Widening it
— even 'just' to admit a hoisted loop-invariant temp — makes it reachable, and no shipped test
would go red. Re-derive the multiplicity there first."* **That trigger has now FIRED. The
re-derivation must LAND IN THE SOURCE in the same change** (L7-with-a-twist: a record
correction not applied at the site is not a correction — measured three times on one sentence,
bd `z9t1`).

**L2 — what OTHER set was computed over the same closure?** `railLocalQualifies`' `onRail`
lambda and `invariantRegisterRootsImpl`'s `RootsOut` are keyed on
`peelInPlaceBase(V, …, AsLowered=true)`, and clause (ii-d) must insert **`Root`, not `V`**, for
the same reason (ii-c)'s comment gives at `:3493-3498`. For a template rail the two coincide
(there is nothing to peel through), but writing `V` would make the two sets disagree the day a
peelable spelling arrives.

**L3 — what OTHER predicate names the same gate?** Three, and all three must be re-read
against (ii-d): `railIsInterior` (`:4223`, S′'s helper — the retirement trigger at
`measureOwnedInvariantRail`'s definition says to re-derive if it grows a measure-independent
clause; (ii-d) is that clause arriving from the other side); `mintsOutOfPlaceTemplateRail`
(item 1 above); and `Uncomputation::preservesBorrowedParent` (`:596+`), which must keep
answering for the `and`-reads-`h1` case — it is asked about MUTATION, and a template producer
that merely reads its operand is not one.

---

## §3 — THE TARGET STREAM, READ OFF THE ORACLE (per customer)

### §3.1 — `s2_live_derived_region` — target **25 == 25**, multiset-identical, ORDER-divergent

Twin, measured (`probes/s2_un.trace`, 25 lines): one function-scope discharge point, LIFO —
`…icmp_unc(h5,h4,0)`, `and_unc(h4,h1,4)`, `free(h4)`, `and_unc(h2,h1,2)`, `free(h2)`,
`mul_unc(h1,h0,3)`, `free(h1)`, `free(h5)`, `ry(h0,0.9)`, `measure(h0)`.

The ROLLED target, derived from the twin plus the measured per-trip ORDER of the
`s3_live_rootmint_region` positive control (`GATES.md` row 4 — the interior `At` lands PAST
the recorded flag strip, so the rail `_unc` follows the `icmp_unc`):

```
preheader:  alloc_i32(5)->h0 ; ry_i32(h0,0.5) ; mul_i32_hl(h0,3)->h1          [3]
per trip:   and_i32_hl(h1,1<<k)->hA ; icmp_eq_i32_hl(hA,0)->hF ; x(hF) ;
            rz_i1(hF,0.3) ; x(hF) ; icmp_eq_i32_hl_unc(hF,hA,0) ;
            and_i32_hl_unc(hA,h1,1<<k) ; free(hA) ; free(hF)                  [9 x 2]
exit:       mul_i32_hl_unc(h1,h0,3) ; free(h1) ; ry_i32(h0,0.9) ; measure(h0) [4]
                                                                       total = 25
```

**The claim is COUNT + MULTISET + a per-trip commutation argument, and it is written that way
deliberately** (owner ruling S3; and `CLAUDE.md` §5 records a shipped fixture family that read
a stability measurement as a correctness one). The two streams differ in ORDER: the twin defers
both `and_unc`s to the end, the rolled form does each at the end of its own trip. They are the
same unitary because everything between trip-1's `and_unc(h2,h1,2)` and the twin's position for
it only READS `h1` and writes `h4`/`h5` — a support disjoint from `h2` — and reads commute with
reads while disjoint writes commute. **Witness: two committed goldens + the argument, NOT a
`compare_files` twin gate** (which would be red).

### §3.2 — bd `1m5p`, the 6 quarantined class-A cells — target **27 == 27**

Measured on the ORACLE for `m_none_oder_none_none_none` (`probes/…none.trace` /
`…none_un.trace`): rolled **25**, `sqrt_f64_unc` **0**; twin **27**, `sqrt_f64_unc` **1**.
After P1+P2 the rolled form gains `sqrt_f64_unc(h4,h3)` + `free(h4)` and moves the whole
chain's discharge from the preheader to the exit → **27 == 27, multiset-identical**, order
still divergent (the twin interleaves `free(h6)` after the chain).

⇒ **The 6 class-A rows stay QUARANTINED with NEW signatures and a NEW argument.** Hand to the
merge-and-gate agent:

| cell | today | after | what the new argument says |
|---|---|---|---|
| `m_none_oder_none_none_none` | `digest 23e11d73657198da`, rolled `fadd_f64_hl_unc(h3,h2,…)` vs unrolled `fcmp_ugt_f64_hl(h4,…)->h5` | re-measure | ROLLED IS NO LONGER DEFICIENT; the divergence is POSITIONAL only (rolled discharges the hoisted chain at the loop EXIT, the twin at function scope after the second region), multiset equal |
| `m_none_oder_none_none_addpost` | `7552cd99e0393129` | re-measure | same |
| `m_none_oder_none_none_rypost` | — | re-measure | same; measured today at rolled 27 / twin 29, `sqrt_f64_unc` 0 vs 1 |
| `m_none_oder_none_none_rypre` | — | re-measure | same |
| `m_none_oder_none_none_rzpost` | — | re-measure | same |
| `m_none_oder_none_rpostmark_none` | — | re-measure | same |

⚠ **The `m_none_oder_add_*` SIX are CLASS B (bd `a3z7`), not class A**, and their digests pin
the class-B divergence, which is found FIRST. If class A is fixed underneath them their
digests may still move. **Re-measure all twelve `oder` cells, not six.**

### §3.3 — `control_phase_kickback_mixed_hoisted_template_leak_control.ll` — target **40 == 40**

Twin measured (`probes/ht_un.trace`, 40 lines): 3 `and_i32_hl` mints / 3 `_unc`, matching the
fixture header's `3/3`, with `mul_i32_hl_unc(h2,h0,3)`+`free(h2)` at the end. The rolled target
is the same count with the three `and_unc`/`free` pairs moved in-body per trip and the
`mul_unc`/`free` at the exit: preheader 5 + per-trip 10 × 3 + exit 5 = **40**.
`control_phase_kickback_mixed_short_sext_leak_control.ll` is the identical shape with a
`cq_template_sext_i16_to_i32` rail in place of the `mul` (`mintsOutOfPlaceTemplateRail`'s
`CastInst` arm, `:4367-4370`), so it moves with it.

**Both fixtures' L8 retirement triggers are character-for-character correct** (*"when `tu9q`
lands this becomes an ACCEPT again, and the stream to re-derive is the HAND-UNROLLED twin's —
`3/3`, not the `3/0` this file used to pin"*). Follow them; do not restore the pre-conversion
CHECK prefixes.

### §3.4 — `control_phase_kickback_mixed_preheader_volatile_imm_leak_control.ll` — ⚠ **NOT A CUSTOMER. Its L8 trigger names the wrong owner.**

Its base is `q = q + off` with a **volatile** `off` — an M-C IN-PLACE op, not a hoisted
template rail. It leaks because `commitOutOfLoopInPlaceOps` refuses to commit it at
**`LoopLowering.cpp:3162-3165`**, `if (!isa<Constant>(Imm)) return;` — the F-C1B-1 (1a) fence,
whose whole argument is that a `Constant` can never become tainted between `lowerLoops` and
`lowerOps`. With no commitment, `peelInPlaceBase(…, AsLowered=true)` stops at the `add`, `Root`
is a `BinaryOperator`, and clause (ii)'s `dyn_cast<CallInst>` refuses. Clause (ii-d) does **not**
admit it either: `mintsOutOfPlaceTemplateRail` returns **false** for an op that lowers IN PLACE
(`:4332-4344`) — which is the right answer, because the rail is the register, not a new one.
Its own header says so: *"the register the body reads IS the root mint's rail and the discharge
would be SOUND; it is simply no longer PROVEN at the point the proof is needed."*

**Disposition: it STAYS DECLINING, its header's L8 trigger is CORRECTED IN PLACE to name the
(1a) fence instead of `tu9q`, and the over-decline is FILED as its own bead.** It is a real
over-decline under the owner's 2026-09-11 ruling, and it is plausibly cheap now that
`declineRound2FalsifiedRailGrants` exists to re-ask a round-1 prediction — but that is a
different predicate with a different argument, and folding it in would be the drbq Inc-3 (b′)
defect. ⚠ **Rule 17 check**: this is not a punt. The work we set out to build is the hoisted
TEMPLATE rail; this program has no hoisted template rail.

### §3.5 — CLAUDE.md §5's Q-R1-1 second half — **the over-accept, and it is LIVE**

`probes/a1_apost.c` (bd `1m5p`'s own "reachable consequence", constructed here because nobody
had): `for(i<2){ if (sqrt(a+3.) <= off) r = cq_theta(r,.9); } a = cq_theta(a,0.7);
return cq_measure(a) + cq_measure(r);`

| | rolled | hand-unrolled twin |
|---|---|---|
| `opt` exit | **0** | 0 |
| trace lines | **26** | 28 |
| `cq_template_sqrt_f64_unc` | **0** | 1 |
| stderr | **WARNING** `cq rotation lowering: non-diagonal gate over a live derived record` | **EMPTY** |

The leaked `h4 = sqrt((double)a + 3.0)` is an injective function of `a`'s basis label — a
perfect which-path record — standing at a **non-diagonal `cqrt_ry_i32(h0, 0.7)`** on `a`,
which is then measured. Rolled and flat are different unitaries (Rule 8's last sentence).
**`declineDephasingUnmarkedLoopRails` does not refuse it, and §2.6 is the reason.** P2 closes
it. ⚠ Note what this says about the fence: the WARN-ASYMMETRY is the only instrument that saw
it, it is a **warning** by owner ruling bd `lyyf`, and bd `bbu0`'s (D) reorder is what would
let the fence consult the warning's record set — so this probe is also **evidence for bbu0**
and should go to the owner with it.

### §3.6 — the fence's blind spot, in one sentence (source, not inference)

`declineDephasingUnmarkedLoopRails`' conjunct (3) quantifies over `L`'s **OWN** blocks
(`bodyBlocksMarked`'s own-blocks reading, `:4435-4515`, and `FIX.md` §2). A rail LICM-hoisted
into the **preheader** is in none of them, so the fence that exists for bd `s82e`'s divergent
class **cannot see the hoisted-template instance of that class at all** — it catches `s2`
(whose leaked rail is the per-trip body `and`) and misses `a1_apost` (whose leaked rail is the
preheader `sqrt`). ⚠ **This is a NEW finding and it is not in any record I read.** File it
against bd `s82e`; it is the reason §0 calls the increment an over-accept closure.

---

## §4 — POSITIVE CONTROLS THAT MUST NOT MOVE, with the source reason each

| control | cited verdict | why unaffected, by source |
|---|---|---|
| `s1_live_shift` **14 == 14** | `$THIS/GATES.md` 11:05 | Its invariant read is a ROOT MINT admitted by clause (ii); its leaked-then-fixed rails are minted **in the body**, so P2's condition (*the consumer's loop does not contain the rail's mint*) is FALSE and the anchor is unchanged. P0's key is the same for all its rails ⇒ one component, as today. P3 is not reached (clause (ii) already accepts) |
| `s3_live_rootmint_region` **22 == 22** | `$THIS/GATES.md` 11:05 | Same: body-minted rails, root-mint invariant base, `cqrt_alloc`-producer excluded from the interior partition by (I1) (`ChainWalk.cpp:928-941`) so it is BORROWED, never anchored |
| `w2k_noregion_invread` **20 == 20** (and `w2h` 38, `w2h3` 48) | `$THIS/GATES.md` 11:05/11:08 | Their hoisted `y & 1` rail is **measure-owned**: every user is a `cq_measure`, so `isInteriorTerminalHandle` (I3) refuses it outright (`ChainWalk.cpp:948-956`) and it is never a candidate — P2 cannot reach it. Clause (ii-c) already admits it as a Root, so P3 is not reached either |
| `b7b_w2k_interfered` **24 == 24**, `b7c_w2h_interfered` **42 == 42** | `$THIS/GATES.md` 11:08 | Same (ii-c) route; the post-loop interference changes the fence's conjunct (2), not the placement |
| `b10_inplace_volatile` 7 == 7, `b11_cmp_rail_data` 14 == 14 | `$THIS/GATES.md` 11:08 | `b10`'s stream is in-place `cqrt_xorc` with no template rail (no candidate at all); `b11`'s rail is body-minted |
| **n1 / n2 / n3 nested — must KEEP DECLINING** | `$THIS/GATES.md` 11:05 | **Checked, not assumed.** None has a hoisted template rail: `(y>>i)&1` and `(y>>(j+8))&1` are computed IN the body and `y` is a root mint. Their outer loops are refused by the **SUBLOOP clause** (`markIfIterationLocal:2447-2458`, `railLocalQualifies:3676-3684`), which clause (ii-d) does not touch, so `bodyBlocksMarked(outer)` stays false and `declineDephasingUnmarkedLoopRails` still fires. ⚠ The implementer must MEASURE this, not cite me: the three are the F-1 regression fixtures and they are the cheapest early warning that (ii-d) over-widened |
| `lowering_uncompute_interior_loop_consumer_and_after.ll` (ACCEPT) | shipped fixture | **The most load-bearing control for P2.** A rail minted in `entry`, read K times INSIDE a loop and once AFTER it. P2 rewrites the in-loop consumer's anchor to the loop exit — and `dagInsertPoint`'s `Latest` in the common block is still the POST-loop consumer's next node, which comes later, so `At` is **unchanged**. If this fixture moves, P2's anchor rule is wrong |
| `lowering_uncompute_interior_leak_irreducible_{mint,gate}.ll` | shipped leak probes | An irreducible cycle is never marked (both markers are `LoopInfo`-gated) and `getUniqueExitBlock()` is meaningless for it; `RepeatOracle`/`blockCanRepeat` is untouched. Must stay leaking |
| `loop_pairing_accept_break_latch_folded.ll` / `r1_break_loop` (bd `tu9q.1`) | shipped | `getUniqueExitBlock()` null ⇒ today's behaviour. Unmoved by construction; owed a fixture |
| the four `e2e-slice-loop-pairing-*` entries + `e2e-loop-pairing-rootmint-twin-identical` | shipped | All are root-mint / measure-owned (rows 1-4 above) |
| `slice_control_inplace_ry_loop_leak{,_unrolled}` | shipped | ⚠ **Not argued — MEASURE.** It is one of the 5-of-366 warn-firing slices and the closest shipped e2e shape to `a1_apost`. If P2 moves it, that is the capability working, and the golden must be regenerated **deliberately** with the twin comparison in the record |

---

## §5 — RULE-12 PLAN

**Red-green order matters here**: P1's fixture cannot be written before P2 exists (bd
`8h7d.10`'s recorded gap — *"a fence with no reachable customer and no failing fixture is a
prediction, not a test"*). So: write P2's accept fixture first, watch it fail; land P2 with P1
in the same commit; then write P1's **decline** fixture against the P1-less binary by binary
mutation (the `FIX.md` §3 method — all four nested fixtures were validated that way).

| # | fixture | verdict | pins |
|---|---|---|---|
| F1 | `loop_pairing_accept_hoisted_chain_exit_discharge.ll` (bd `1m5p` class-A, one region) | ACCEPT | P2: the hoisted chain's `_unc`+free land in the **exit block**; counted in its own whole-file prefix, negatives pure (Rule 12 hygiene (a)) |
| F2 | `loop_pairing_reject_hoisted_chain_multi_exit.ll` (a `break` in the loop) | ACCEPT-and-LEAK | P2's `getUniqueExitBlock()` null path — a `LEAK` prefix with `CHECK-NOT` on `sqrt…_unc`, in its own prefix |
| F3 | `loop_pairing_reject_hoisted_chain_parent_gated_inside.ll` (`a = cq_theta(a,.5)` in the body) | ACCEPT-and-LEAK | clause (d) refusing the exit placement — the rail must NOT be discharged |
| F4 | `loop_pairing_reject_multiplicity_body_gate_exit_at.ll` | ACCEPT-and-LEAK | **P1's own red-green.** A component whose gate is in a marked body and whose `At` P2 would put at the exit. Validate by **binary mutation** (constant-`true` `multiplicityAgrees` ⇒ the fixture must go red), and record the MISSED count — the file already documents one premise (`intervalAlternates`) that is green under a constant-`true` mutant and calls that a **Rule-12 GAP**; do not add a second |
| F5 | `loop_pairing_accept_hoisted_template_split.ll` (`s2`'s module) | ACCEPT | **P0+P3.** Two insertion points: the per-trip `and_unc`+free IN-BODY and the `mul_unc`+free at the EXIT. The single strongest structural check in the batch |
| F6 | `loop_pairing_reject_hoisted_template_no_unique_exit.ll` | DECLINE or LEAK | clause (ii-d)'s `loopHasExitDischargePoint` conjunct, isolated |
| F7 | `loop_pairing_reject_hoisted_inplace_volatile.ll` | ACCEPT-and-LEAK | (ii-d) does NOT admit an op that lowers in place (§3.4). The isolating control for `preheader_volatile_imm` |
| F8 | `loop_pairing_reject_postcondition_undischarged.ll` | **DECLINE**, new string | §2.5(4)'s postcondition. ⚠ If no module can be built that grants (ii-d) and then fails to discharge, say so and file it as an unreachable fence rather than shipping a prediction — that is `8h7d.10`'s lesson applied to the new code |
| C1–C5 | conversions: `loop_leak_dephase_reject_region_derivedbase_live.ll` (incl. its `CQ_BBU0_DEFER_DEPHASE_FENCE=1` **DEFER** RUN line at `:109-110` — **both** move), `loop_pairing_reject_root_hoisted_template_data.ll` (its `LEAK` prefix becomes positive counts), `control_phase_kickback_mixed_hoisted_template_leak_control.ll`, `…short_sext…`, and the header-only correction to `…preheader_volatile_imm…` | | convert **in place, never `git mv`** (bd `gahu`, L8 — a renamed fixture can be resurrected by a merge), historical headers kept verbatim under a banner |

**Decline strings.** The interim `cq loop lowering: rolled body leaks a rail entangled with a
rotated register` is pinned by **10** fixtures (`grep -rln`, listed in
`MEASURED_FIXTURES.md`). It **RETIRES** for `region_derivedbase_live`, `hoisted_template` and
`short_sext`; it **STAYS** for the four `nested_*` and for `preheader_volatile_imm`; and
`cmp_rail_data` / `inloop_rotation` already carry it only in historical header text (their RUN
lines are ACCEPTs). **Write the L8 retirement trigger into the four `nested_*` headers naming
what would retire them (a nested-loop discharge point, bd `emkg`'s class) so the next agent
does not read their survival as an oversight.**

**Injection matrix.** Reuse `$PREV/trackT/probes/inject_T.py` **verbatim** with `CQ_T_BUILD`
repointed (Rule 14; it runs each fixture's OWN RUN lines, which is the defect that once
produced "45 MISSED against fixtures that catch everything"). Self-attack it first: **no
fixture argument must exit 2**. Report MISSED **and** N/A; an `n/a` is a HOLE, not a pass.
Run it over F1, F5, and the converted C1/C2 accepts at minimum.

**e2e.** Two new slice PAIRS (`slice_loop_pairing_hoisted_chain{,_unrolled}` for §3.2,
`slice_loop_pairing_hoisted_template{,_unrolled}` for §3.1), four goldens. ⚠ **Do NOT add
`*-twin-identical` `compare_files` gates for these** — both pairs are multiset-equal and
order-divergent (§3.1, §3.2) and such a gate would be red. Commit both goldens and put the
commutation argument in the record; the twin claim is the **multiset + commutation**, written
in those words (`FIX.md` §1a's `c2` precedent). `tests/e2e/CMakeLists.txt` has ONE tail anchor
above the mandatory-last `get_property` sweep — expect a conflict per slice-adding branch and
run the three post-union checks.

**K-independence.** Measure the lowered IR line count at K=3 and K=1000 for both new slices,
without `-g`, and report both numbers. A K-dependent count means P2 unrolled something.

### §5.1 — `taint.IterationLocalBlocks`, the raw-`BasicBlock *` exposure

`IMPL_T2` §10 item 3 / `FIX.md` §8: it is a raw `BasicBlock *` set that **nothing scrubs**,
read in the ACCEPT direction by `FreePoint.cpp:176/309/348` and `Uncomputation.cpp:446/562/
979/1026/1343/1453/1656` **after** `lowerBreakReversePlay` creates blocks. **This increment
adds customers to it twice over**: (ii-d) marks more bodies, and `markedHeaderOf` makes the
set decide a NEW question (multiplicity) rather than only a suppression.

**A scrub is NOT in scope** and the reason is measured, not preference: the set is written in
`LoopLowering.cpp` and read in three other TUs, and scrubbing it at the erase sites is the same
cross-TU change the `InPlaceRailOps` scrub was declined for (`IMPL_S2` §3 — *"`scrubTaint` is a
per-TU mirror at eight TUs … it would drag five more files into this GROUP"*). Under PROTOCOL
S1 it merges Group 1 with everything.

**The fence that keeps the added population safe**, and it must be written down rather than
assumed: a **stale** `BasicBlock *` can only make `IterationLocalBlocks.count(BB)` return TRUE
for a recycled address. At every existing read that is the GRANTING direction (a leak becomes a
discharge) — which is why the exposure is filed as P2-with-a-shape-precondition rather than
closed. For `markedHeaderOf` the extra exposure is different and worth one sentence in the
source: a stale-true would give a block a NON-null key, and a non-null key can only make
`multiplicityAgrees` return **false** where the other endpoint keys null — i.e. the added
population's failure mode at the NEW site is a **REFUSAL (a leak), not a grant.** That
asymmetry is the whole reason the increment can proceed without the scrub, and it is the kind
of sentence that must be at the definition, not in a record. **File the scrub** (§7).

---

## §6 — RULE-13 ATTACK PLAN, ≥3 rounds, in the order I would attack it

Budget **three rounds up front plus one independent reviewer** (the 2026-09-15 loop round found
a P1 on round 1 of a *smaller* change; `3qlq` Inc 1 found 8 instances over 6 rounds on one
function, two of them introduced by a fix).

**Round 1 — the pairing itself.**
1. **K-adjoints-against-one-forward, both directions.** Construct a module for each: (a)
   preheader `G` with body `At` (§0.1(a) says the convergence loop refuses it — **verify that
   by mutation**, not by my reading: force `provablyBeforePerActivation` to `true` and check
   P1 is what refuses); (b) body `G` with exit `At` (P2 creates this — F4).
2. **The null×null cell of `markedHeaderOf`** (§2.1): two unmarked repeating blocks in two
   different loops. Prove the pre-existing `canRepeat` tests refuse first, and construct the
   module where they would not.
3. **The `_unc` ORDER across the split** (P0): does trip-K's in-body `and_unc(h2,h1,…)` ever
   run AFTER `free(h1)`? Attack with a guarded (possibly-zero-trip) loop and with a loop whose
   exit block is itself inside an outer loop.

**Round 2 — the loop shapes.**
4. **Multi-exit / `break`** (bd `tu9q.1`): `r1_break_loop` plus a `break` whose latch `-O1` does
   NOT fold; confirm `getUniqueExitBlock()` null ⇒ unmoved, and that no *partial* discharge
   escapes.
5. **Nested loops, the `emkg` class**: the OUTERMOST-non-containing walk against a 3-deep nest
   (`r1_triple_nest_mid_rail` is the seed), and against `n1`/`n2`/`n3`. Attack the
   `L->contains` (includes subloops) vs `LI.getLoopFor` (innermost) asymmetry of §2.2
   **deliberately** — one of the two is wrong in exactly one of the two sites.
6. **A hoisted rail whose borrowed parent IS gated inside `L`** (F3): confirm clause (d) leaks,
   and that it leaks the COMPONENT and not the function.
7. **A hoisted rail that is ALSO re-rotated after the loop** (`a1_apost`, the Rule-8 customer):
   confirm the warning goes SILENT because the record is discharged, not because the warn stage
   stopped looking.

**Round 3 — the windows and the compositions.**
8. **The L1 window with NO record** (§2.5 item 2): `collapseFlattenedLoopRails`' marking at
   `:3891-3907` runs at `CQLoweringPass.cpp:600`, before `repropagateControlMerges` at `:616`,
   and calls **no** `recordRound1RailGrant`. Build a module whose (ii-d) root becomes tainted
   only at round 2, or whose round-2 taint growth falsifies `railLocalQualifies`. If it is
   reachable, the cure is the pattern (RECORD at the site, RE-ASK after the fixpoint, in BOTH
   entry points) — `recordRound1RailGrant` already exists and takes the same arguments.
9. **The composition with Track S′'s `declineDephasingUnmarkedLoopRails` (R7).** `IMPL_T2` §5
   argued structurally that every `tu9q` customer exits at conjunct (1); **this increment makes
   that argument load-bearing in the dangerous direction** — P3 SILENCES the fence, so the
   postcondition of §2.5(4) is the only thing standing behind it. Attack the postcondition, not
   the fence. ⚠ And carry §3.6: the fence is blind to preheader-minted rails, so "the fence
   would have caught it" is **false** for this whole class.
10. **The composition with Track V** (the nested-loop matrix axis) and with Group 2's binaries:
    a mover no single-track binary reproduces is the F×P finding repeating. *A composition is
    not cleared by clearing its parts* — three consecutive sessions have paid for that sentence.
11. **`mintsOutOfPlaceTemplateRail`'s third caller in the GRANTING direction** (§2.5 item 1),
    including its stale-marking CEDE branch at `:4342-4360`.

**What a round must NOT count as clearance:** a green `ir-pass-lit`; STRICT stage 2b (it counts
`cqrt_alloc` SITES and **every rail in this increment is TEMPLATE-minted**, so it reported
`0 violation(s)` on the leaking form too — `IMPL_T2` §2(a) says so in its own words); and
`free_pairing_check.py` generally.

---

## §7 — OPEN ITEMS AND COST

**The `InPlaceRailOps` scrub of `IMPL_S2` §3/§8 is NOT filed under a bd id.** `bd list` (228
issues) has no bead matching `scrub` / `InPlaceRail` / `nothing scrubs` other than `gy1w`,
which is a *different* scrub (`taint.MeasureCalls`, `ArmClassify.cpp`). **File it.** It lives
in `LoopLowering.cpp`'s neighbourhood (`markInPlaceRailOp` `:199`, `inPlaceValueRailOperand`
`:151`) — Group 1's file — but the CHANGE is a cross-TU scrub at the erase sites in eight TUs,
so it is **NOT in scope**: doing it here merges Group 1 with five more files under PROTOCOL S1.
Its shape precondition is unchanged by this increment (this increment adds no writer of
`InPlaceRailOps`; clause (ii-d) admits only ops that `mintsOutOfPlaceTemplateRail` says mint
OUT of place, i.e. exactly the ops `commitOutOfLoopInPlaceOps` does not commit).

**Other items to file:**

* the **preheader blind spot** of `declineDephasingUnmarkedLoopRails` conjunct (3) (§3.6) —
  against bd `s82e`, with `probes/a1_apost.c` as the reproducer;
* the **over-decline** of `preheader_volatile_imm` (§3.4), with the (1a) fence named;
* the **L1 window with no record** at `collapseFlattenedLoopRails:3891-3907` (§2.5 item 2) —
  pre-existing, population widened here;
* the **`IterationLocalBlocks` scrub** (§5.1) — pre-existing, population widened here;
* the **symmetric dead-terminal residual** in `FreePoint`/`reverseTerminalGroup` (§1) — an
  over-decline with no measured customer;
* `probes/a1_apost.c` as **evidence for bd `bbu0`** (the warn-vs-fence reorder).

**COST, calibrated against `534ea73a` (`IMPL_T2`'s own landing: 444 lines in
`LoopLowering.cpp` + 45 in `TaintPropagation.h` + 20 in `LoopPlan.h` + 14 in
`CQLoweringPass.cpp` ≈ **523 pass-source lines**, 6 fixtures new/converted, 4 e2e
slices + goldens, 2 self-run Rule-13 rounds + 1 independent review that found a P1):**

| item | this increment | vs `534ea73a` |
|---|---|---|
| `Uncomputation.cpp` | ~60 code + ~190 comment = **250** | new ground (T touched 0 lines there) |
| `LoopLowering.cpp` | ~15 code + ~120 comment = **135** | 0.3× |
| `include/LoopPlan.h` | ~8 | 0.4× |
| **pass source total** | **~390 lines, ~70% comment** | **0.75×** |
| fixtures | **8 new + 5 converted/corrected = 13** | 2.2× (the multiplicity backstop needs its own isolating pair, and P0/P1/P2/P3 are four independent doors) |
| e2e | 4 slices + 4 goldens, **no** `twin-identical` gate | 1.0× |
| Rule-13 | **3 self-run rounds + 1 independent reviewer**, 11 named lenses | 1.3× |
| quarantine rows handed to the merge agent | **12** (`oder` ×12, not 6) | new |

**Sequencing constraints for the orchestrator, in one place:** Track V lands BEFORE Group 1's
merge gate (12 quarantine rows move). Group 1 and Group 2 are disjoint by file and may run in
parallel. Group 1 owns `LoopLowering.cpp`, so bd `8h7d.12` belongs to Group 1's implementer or
to nobody this session.
