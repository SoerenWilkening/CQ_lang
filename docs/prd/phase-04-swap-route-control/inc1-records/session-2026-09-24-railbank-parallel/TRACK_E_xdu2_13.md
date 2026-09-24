# Track E — bd `xdu2.13`: a CLASSICAL leaf of a mixed `and`/`or` node in a 4.4 data select

Session 2026-09-24, rail-bank parallel session, Track E. The worktree branch is
`worktree-agent-a2b9793f123da59f8`, based on `aad63450`. The oracle is `cq-opt`
`63e2f0bbd3708c92` (the `aad63450` build). The final subject is `cq-opt`
`64a6d313cc8b27c3`. Probes and the mutation harness are in `trackE_probes/`.

## 1. Headline: read this before flipping anything

**The capability landed. Row 13 does NOT accept. It moved to a THIRD wall, and
that wall is pre-existing.**

- The hybrid 4.4 data select now lowers. `clang -O1` turns `if (q && m == n)`
  into `select (and (icmp eq m,n), (icmp ne q,0))`. The pass now emits
  `h_cmp = icmp_ne_hl(h,0)`, then `gl = cq_template_and_i1_hl(h_cmp, %c)`, the
  two controlled copies on `gl` (with the `cqrt_x` bracket), then
  `cq_template_and_i1_hl_unc(gl, h_cmp, %c)` with the same SSA literal,
  `cqrt_free(gl)`, the compare strip, and `cqrt_free(h_cmp)`. `or` works the same
  way through `cq_template_or_i1_hl`. No new frozen symbol is added: both
  templates already ship. No classical-guard path is added, clang's IR is not
  rewritten, and the classical operand is never allocated a qubit.
- **Row 13** (`railbank_dynamic_matrix.c` CASE 13, and its fixed-table twin) now
  declines with `cq loop lowering: round-1 iteration-local marking falsified by
  round-2 taint`. This is the loop layer's bd `tu9q` re-ask
  (`declineRound2FalsifiedRailGrants`). `-O1` LICM-hoists `%17 = and i1 %16, %15`
  into the preheader. At round 1, `lowerLoops` records it as an invariant
  register ROOT of the loop's iteration-local grant. The 4.4 emitter then
  consumes and ERASES that tree node. The re-ask treats a NULLED root as a
  refusal. This was measured with a temporary env-gated print, since reverted:
  roots were `{%16 phi, %18 select, %8 and}`, and the output said `nulled root`.
  **Pre-existing and not literal-specific.** A pure-quantum `(q > 1) & (r < 5)`
  select in the same rolled loop declines with the same string on the oracle
  (probe `p19`/`p20` in `gen.sh`). The function's own comment says a nulled-root
  over-decline is "to FILE, not a fence to relax in place". I did not relax it.
  **Owner/orchestrator question:** file a bead for "a compound 4.4 condition tree
  in a rolled loop: the round-1 grant names a tree node the select emitter
  erases". It blocks row 13, `q && i < m` with a loop-invariant `q`, and every
  Q∧Q `&`-tree in a loop.
- Updated deliberately (L8): `predmux_guarded_vla_reject_row13_hybrid_select.ll`
  keeps its name and now pins the new wall. Its `CHECK-NOT: CQ_CTRL_DBG: decline`
  witnesses that no control-layer decline fires any more. Its retirement trigger
  is re-armed. The diagnostic in shared row 13 and in
  `railbank_guarded_vla_matrix` row 6 moved to the loop string. **Neither was
  flipped to accept.** The stale comments in `railbank_dynamic_matrix.c` CASE 13,
  `railbank_guarded_vla_matrix.c`, `slice_predmux_guarded_vla.c`,
  `ArmClassify.cpp` (the kickback's hybrid comment), `PredMuxFlatten.cpp` (the
  rule-(B) residue paragraph) and `SelectClassify.cpp` (the q2wk "LOAD-BEARING"
  block) are corrected at the source (L7).

## 2. Mechanism

- `collectCondTree` has a new optional `IsLiteral` callback. When it is passed,
  an `and`/`or` child for which the callback is true is recorded in
  `CondTree::LiteralLeaves`/`LiteralNodes` and is NOT walked. It never applies to
  an `xor`, never to the root, and never to both children. Every other caller
  passes null and behaves exactly as before.
- The classifier (`classifySelectRegion`) passes `condLiteralAdmissible`. That
  predicate requires a non-`Constant` `i1` `Instruction`/`Argument`. The value
  must be untainted at classifier taint. No `!cq.predmux.predicted` mark may sit
  in its i1 cone, and the function must carry no overflow mark. The classifier
  then refuses a literal whose tainted sibling is a bare rail (a `_Bool` register
  or a merge φ). It refuses any literal on an ANGLE select, which keeps the
  pre-change string. It commits the literals to `ControlRegion::CondLiterals`
  (`WeakTrackingVH`).
- The emitter (`SelectMergeEmit`) re-derives the tree by MEMBERSHIP of
  `CondLiterals` and re-asks untaintedness. It refuses a size mismatch.
  `emitCondNetwork` mints the mixed node through `emitCondLiteralNode` on a flag
  the network minted. A rail flag or two literals is `Malformed`.
  `stripCondNetwork` (moved verbatim to `CondTreeStrip.cpp` to keep
  `CondTreeEmit.cpp` under its 400-line budget) strips it with `emitInverseCall`,
  which produces the `_unc` with the same operands, then `cqrt_free`.
- **L1 / round 2.** Each forward literal gate is recorded in
  `taint.CondLiteralGates`. `declineQuantumCondLiterals` runs after the round-2
  fixpoint in BOTH entry points, next to `reverifyCmpCondReads`. It declines
  loudly with `…classical condition literal became quantum-derived under quantum
  control`. This is reached from plain C (matrix CASE 14). A literal compares a
  6.5 classical-call merge; at round 1 the merge is classical, and the emitter
  turns it into `%out`.
- Dominance needs no conjunct. The literal is a non-φ SSA operand of a tree node,
  the node dominates the select, and the mint, the copies and the strip are all
  emitted immediately before the select.
- `undef`/`poison`: a `Constant` child is never a literal. It keeps its decline
  (`…reject_undef_literal.ll`).

## 3. bd q2wk rule (B): re-derived, and made a record anyway

E6 rule (B) now records every branch condition it admits
(`PredMuxRegion::PredictedConds`). At the claim, and again at every `literal()`
built from such a condition, the whole i1 cone is marked with
`!cq.predmux.predicted`. Metadata survives the PredMux fixpoints' `taint =
propagate(...)` rebuilds and the unroll pre-pass's clones. `condLiteralAdmissible`
refuses any marked cone. The marks are stripped right after the round-2 re-ask,
so the lowered module is byte-identical to one that never carried them. They are
not recorded in clone mode.

**The re-derivation found no residue to fence.** Every construction I tried kept
the prediction exact:
- An edge literal that folds to a constant needs a constant branch.
  `foldConstantConeAndBranches` folds those at the top of every
  `flattenPredMuxRegions` call, before E6. My first decline fixture was built
  this way. It landed on `E6-classicalbr`, which pins nothing, so I deleted it.
- A `cq_measure` sink between the φ and the condition is refused at
  `E4-dataflow` (`trackE_probes/rb1.ll`).
- The ENTRY φ and the all-equal φ are q2wk's own fences.

So the refusal direction is defence in depth with no constructed subject. Rule 12
cannot pin an unreachable shape (the bd `e1gr` precedent). The retirement trigger
is written at the E6 site. What IS pinned is that marks neither refuse an
unrelated genuine literal nor leak: `…accept_predmux_ruleb.ll`. There, a rule-(B)
condition coexists with a genuine literal, and PredMux's De Morgan clone of that
literal reaches `cq_template_or_i1_hl`.

## 4. Owned tests (subject `64a6d313`)

```
$ cd build && lit ir-pass/test --filter 'condtree_classical_leaf|row13_hybrid|predmux_guarded_vla|cond_tree|condtree'
Total Discovered Tests: 2245
  Excluded: 2201 (98.04%)
  Passed  :   44 (1.96%)
$ ctest --test-dir build -R '^e2e-condtree-classical-leaf-matrix$|^e2e-slice-condtree-classical-leaf$|^e2e-railbank-dynamic-admission-matrix$|^e2e-railbank-guarded-vla-matrix$'
100% tests passed, 0 tests failed out of 4
condtree_classical_leaf_matrix: 18 case(s): 11 accept, 7 decline; 3 twin(s); 0 failure(s)
```

**Red on the oracle.** I swapped the oracle `cq-opt` into `build/` for one lit
run and then restored it; the hash was checked afterwards. The 7 new accepts, the
round-2 decline and the row-13 fixture FAIL on the oracle. The 5 other declines
(xor, undef, rail sibling, angle select, phase) PASS on the oracle by design:
they pin that each verdict and string is unchanged. Mutation kills them instead
(§5).

All 11 matrix accept rows contain a forward `…_i1_hl(` and its `_unc`, and each
passes STRICT stage 2b with `N verified, 0 violation(s), 0 unproven`
(`rowcheck.sh`). The slice's 60-line golden pins both literal values: `argc ==
argc` gives literal 1, and `argc != argc+1` gives literal 0.

**Twins.** CASE 12↔13 (the literal `i < m` varies per trip: 1, 1, 0) and CASE
17↔18 (an `or` node, with `m == n` both true and false) are byte-identical.
CASE 10/11 (a loop-carried `int` accumulator) are both accepts but are NOT a
byte-identical pair. The rolled form promotes the classical seed before trip 1
(bd `zujr`), while the unrolled twin's trip-1 select has classical arms. This is
a pre-existing first-trip spelling difference; the later trips agree up to handle
numbering (measured diff). A quantum seed instead hits `loop-carried tainted
value crosses iterations`.

## 5. Mutation matrix (source injection, owned tests only)

`trackE_probes/mutate.py`: one mutant per run. Each run does an exact-text
substitution (the anchor must match exactly once), rebuilds CQPass + cq-opt, runs
the 44 lit fixtures and the 4 ctest entries, restores the file, and asserts the
restore. The **NULL mutant ran first, twice, with 0 movers** (denominators 44
lit + 4 ctest, 0 non-PASS at baseline).

**Denominator: 30 real mutants. 14 KILLED, 16 MISSED.** The 16 MISSED fall
into four groups, each with its reason in the table below:
- 6 are halves of a same-string pair, and each pair is KILLED together.
- 7 have no constructed subject.
- 2 are unreachable: M7, and M26 (clone mode).
- 1 is output hygiene: M20.

| mutant | conjunct | verdict | killed by / reason |
|---|---|---|---|
| M1 | drop the `Constant` refusal | MISSED | shadowed by M5's Instruction/Argument refusal (they are mutually redundant) |
| M5 | drop the Instruction/Argument refusal | MISSED | shadowed by M1 |
| M1M5 | both | KILLED | `reject_undef_literal` |
| M2 | tainted child admitted | KILLED | 15 movers |
| M3 | rule-(B) mark ignored | MISSED | no constructed subject (§3) |
| M4 | overflow mark ignored | MISSED | no subject (cones are ≤ a handful of nodes) |
| M6, M6b | xor admits a literal (classifier) | MISSED | shadowed by `emitCondLiteralNode`'s opcode refusal (same `control flow` string) |
| M6x | classifier + emitter xor refusals | KILLED | `reject_xor`, matrix |
| M7 | two-literal node admitted | MISSED | unreachable: a tainted node has at least one tainted child |
| M8 | rail sibling (classifier) | MISSED | shadowed by the emitter's `isRailFlag` refusal |
| M13 | rail sibling (emitter) | MISSED | shadowed by M8 |
| M8x | both | KILLED | `reject_rail_sibling`, matrix |
| M9 | angle-select guard | KILLED | `reject_angle_select` |
| M10 | literal commit to region | KILLED | 14 movers: the emitter then mints a compare flag FROM THE CLASSICAL LEAF, which is the §5.2 violation this guards |
| M11 | emitter taint re-check | MISSED | no subject: a literal RAUW'd between classify and emit is caught by the WeakTrackingVH/size check or by the round-2 re-ask |
| M12 | emitter size-mismatch refusal | MISSED | no constructed subject |
| M14 | and↔or template swapped | KILLED | 8 movers |
| M15 | mixed-node strip dropped | KILLED | 8 movers |
| M16 | mixed-node free dropped | KILLED | 8 movers |
| M17 | mixed-node `_unc` dropped (dirty free) | KILLED | 8 movers |
| M18 | round-2 re-ask never fires | KILLED | `reject_round2_literal`, matrix CASE 14 |
| M19 | round-2 record dropped | KILLED | same |
| M20 | marks never stripped | MISSED | no accept keeps a marked instruction alive to output (each one is tainted and lowered away) |
| M21, M22, M23 | E6 record / claim mark / edge-literal mark dropped | MISSED | no constructed subject (§3) |
| M24 | emitter walks into literals | KILLED | 9 movers |
| M25 | classifier walks into literals | KILLED | 13 movers |
| M26 | record also in clone mode | MISSED | the clone body never runs the data-select classifier |

Three pairs (M1/M5, M6/emitter, M8/M13) are defence in depth with the same
string. Each pair is killed together.

## 6. Scope decisions (Rule 17: stated, not hidden)

- **Branch phase** (`if (q && m == n) cq_phi(θ)`): the same tree reaches
  `ArmClassify::classifyPhaseKickback`. It **keeps declining** `control flow`,
  pinned by `…reject_phase.ll` with a retirement trigger naming the stream. The
  source comment there is updated.
- **Value-arm `br` diamond** (the arm holds a table load, so clang does not
  if-convert and PredMux leaves at W-witness): it **keeps declining**. See matrix
  CASE 16.
- **Rail sibling** (`_Bool b && m == n`): it **keeps declining** at the
  classifier. The `_hl` template would read the user's register in a handle slot
  that no rail-ladder rung was asked about.
- **xor** with a classical child: it **keeps declining**.
- **Round-2-tainted literal**: this is a LOUD over-decline. Once the classifier
  has admitted a leaf it cannot re-classify it as a quantum leaf. The program is
  valid (it is a Q∧Q tree after the fixpoint). I suggest filing it as a residual.

## 6b. Rule-13 round 1 on `fc7e6b8e`: CLEAR-WITH-ITEMS, 0 P1

- **P2-1, fixed.** `control_swap_reject_select_classical_leaf.ll` (3c6m.12 L4,
  `or(q>5, k>7)`) now ACCEPTS. My filtered lit could not see it. It is converted
  in place, keeping its name (L8), to an accept that pins the stream:
  `gl = or_i1_hl(h_cmp, %c2)`, copies controlled on `gl`, `_unc` with the same
  literal, then the frees. Its header's "hybrid conjunction out of scope" is
  rewritten as [HISTORY] (L7). **Exit-code sweep** against the frozen pre-change
  binary (`cq-opt.preE`, `63e2f0bb`): every `ir-pass/test/*.ll` whose name
  matches `*select*|*condtree*|*cond_tree*|*classical*|*leaf*|*hybrid*|*predmux*|*kickback*`
  was run, **728 fixtures**. The null control was 0 of 20. There are 8 movers:
  the 7 new `condtree_classical_leaf_accept_*` fixtures plus this one, and **no
  other**. This agrees with the reviewer's all-2245 measurement
  (`trackE_probes/sweep.py`).
- **P3-1, recorded, no code.** The `i1` literal is passed with no `zeroext`. With
  the hand-IR `trunc i32 (argc+254) to i1`, the runtime prints 255 at both the
  forward and the `_unc`. They still PAIR, because both read the same register
  bits, so Rule 6 is intact. The mis-extension was already there on the data
  path (the bd `ix2v` class, shared with the boolean-algebra path's
  `and_i1_hl`). **This change adds customers to it.** ⚠ This item said the
  defect "cannot be reached from C at `-O1`", and **that was FALSE**. Round 2 F-2
  reached it from C (`q90_togglephi.c`, a `_Bool` toggled in a rolled loop,
  printed literals 2/254/253), and it is fixed for THIS emission site (§6c).
- **P3-3, pinned.** The reviewer's `p36_measself` measures `q` and then reads it
  in a mixed tree. Its decline string moves from `control flow` to `condition
  measured before the control route`: the literal is now admitted, so the select
  reaches the measured-before rung that used to sit behind the taint gate. The
  verdict is unchanged. `condtree_classical_leaf_reject_measured_self.ll` pins the
  new string; on the pre-change binary it declines with `control flow`, measured.

## 6c. Rule-13 round 2 on `bc42274e`: CLEAR-WITH-ITEMS for the mechanism

- **F-1, fenced — SUPERSEDED by §6d (conjunct (d) removed, fixed at the taint layer).** A quantum register RETURNED by a defined `noinline` function
  is untainted in the caller, because taint does not cross a call return. That
  pre-existing P1 is now filed as bd `test_C_libtooling-3jru`. The literal slot
  gave it a new accept route: `r = g(m); if ((q>1) & (r==n))` emitted
  `and_i1_hl(h_cmp, icmp eq <handle id>, n)`.
  - `condLiteralAdmissible` now has a conjunct **(d)**. It walks the literal's
    whole operand cone and refuses a call to a DEFINED function whose return-value
    cone carries a tainted value. The check recurses through nested defined
    callees, is depth-bounded, and refuses on budget exhaustion. It also refuses
    any INDIRECT call.
  - The PRECISE form was possible because the taint set is module-wide, verified:
    `propagate` seeds every defined function.
  - Declarations answer "no" (the cross-TU case is 3jru's). Call ARGUMENTS are not
    walked: a tainted argument taints the call itself, and a `cq_measure` result
    must stay a legal literal.
  - Fixtures: `…reject_callee_quantum_return{,_nested}.ll` (red on `bc42274e`,
    which accepted), `…accept_callee_classical_return.ll` (q93) and
    `…accept_callee_classical_helper.ll` (a defined `iabs` + `llvm.smax`).
  - Whole-corpus exit-code sweep against the `bc42274e` binary: 2251 fixtures,
    null control 0 of 20, **2 movers, the two new declines**
    (`trackE_probes/sweep_all.py`).
- **F-2, fixed at this emission site.** `emitCondLiteralNode` adds `zeroext` to
  the literal slot of the forward, and `stripCondLiteralNode` adds it to the
  `_unc`. The runtime prototype is `bool b_classical`, which Clang passes
  `zeroext`. q90 now prints 1/0/1 and 0/1/0, where it printed 2/254/253.
  `…accept_zeroext_toggle.ll` pins both attributes. 8 existing accept fixtures
  had their literal-slot CHECK lines updated to `i1 zeroext`; that is a stream
  change, made deliberately. **The DATA path (bd ix2v, reviewer q91) is NOT
  fixed and is left to ix2v.** The slice golden is unchanged, since the trace
  already printed 0/1 there.
- **F-3, recorded, not implemented.** `markPredictedTaintCone` marks the WHOLE i1
  cone, including genuinely classical leaves. The reviewer's `q50_ruleb_mixed.ll`
  and `q58_ruleb_or.ll` therefore decline, while their hand-flattened unmarked
  twin `q52` accepts. This is a safe over-decline. Narrowing it is not a small
  change:
  - The negation clones built in `literal()` would need a correspondence back to
    the predicted leaf, or a taint-free re-derivation of
    `valueWillTaintAfterFlatten`, which is mid-flatten and has no `TaintSet`
    available.
  - So it is left for the coordinator to file.

- **Mutation delta (round 2).** The null control ran first, twice, with 0
  movers (denominators 50 then 51 lit, and 4 ctest). **7 new mutants, 7
  KILLED:**
  - M27 (fence dropped), M28 (callee return cone never asked), M29
    (defined-callee check dropped) and M30 (tainted-member test dropped): each
    is killed by both `reject_callee_quantum_return*` fixtures.
  - M31 (call arguments walked, the over-decline direction): first MISSED,
    because no accept put a `cq_measure` result in a literal. It is KILLED by
    the new `…accept_measured_literal.ll`.
  - M32 and M33 (`zeroext` dropped on the forward, or on the `_unc`): each is
    killed by 10 accept fixtures.
  - Running total: **37 real mutants, 21 KILLED, 16 MISSED**. The 16 MISSED are
    unchanged from §5.

## 6d. Rule-13 round 3 on `5bc6ee64`: BLOCK. bd 3jru is fixed at the TAINT layer; conjunct (d) is removed

**Why round 2's fence failed.** Round 3 defeated conjunct (d) five ways; each
probe compiled at exit 0 and passed stage 2b on `5bc6ee64`, while the oracle
declined:
- `abs(g())`: `@llvm.abs` is a declaration, and (d) did not walk its arguments.
- `smax(g())`: the same, through `@llvm.smax`.
- `tw(g())`: the returned register reaches the literal only as an argument of a
  classical helper.
- an out-param: `*o = h(k)` stored an untainted value.
- a `_Bool` argument computed from the register in `main`.
- `cq_measure(g()) == n`: the measure was deleted, leaving a handle id.

A further P3: `returnsQuantum` was exponential. This is L5: a syntactic walk
answering a semantic question. Per the orchestrator's DECISION, the fix moved to
the taint layer.

**The fix (bd test_C_libtooling-3jru).**
1. **`propagate` iterates a cross-function fixpoint.** Every direct call site of a
   DEFINED function whose `ret` operand is tainted joins `Tainted` and propagates
   forward, through chains and recursion. Every rebuild of the taint set by the
   PredMux fixpoints inherits this.
2. **`declineQuantumReturnCalls` refuses loudly.** Any USE of such a function —
   a direct call, or the address taken (a function pointer) — fails with
   `cq taint escape: quantum value returned across a function boundary`
   (DS_Error, source-located). A function with no use in the module keeps the
   existing Escaped-`ret` contract.
3. **Slot: once per entry point, after the round-2 fixpoint.** This reads FINAL
   taint, which answers the L1 question: `repropagateControlMerges` can taint a
   callee's `ret`. It runs before `lowerRotations` and `lowerMeasures`.
   ⚠ **CORRECTED IN §6e.** This item went on to claim that "every stage above the
   slot already sees the call result TAINTED". **That was FALSE for round-2
   growth.** The closure lived only in `propagate`, and `propagateFromSeeds` and
   the round-2 reseed did not apply it. Rule-13 round 4 F-R4-1 exhibited the
   miscompile with j01. Its "keep their strings" half was also over-broad: it
   holds only for owners ABOVE the slot. See §6e.
   - An EARLY slot was tried first. It preempted two pre-existing owners:
     `spec_reject_cq_primitive.ll` (the specializer's `callee contains a quantum
     primitive`) and `lowering_reject_inloop_rail_record_offchain_ret.ll`, whose
     `main` reads `inner()`'s returned register — a 3jru exhibit sitting inside a
     loop fixture.
   - The late slot keeps both of their strings. Every stage above the slot
     already sees the call result TAINTED, so none of them treats it as
     classical in the meantime.
4. **What the 6.5 path owns is untouched.**
   - The late slot comes after `detectSpecializations`, so the specializer's own
     declines speak first. r04 now declines with its
     `floating-point quantum argument or return has no reversible copy`, a
     misleading string for an `i1` that is pinned as the owner that speaks.
   - Every `control_classical_call_arm_*` fixture is byte-identical to the
     aad63450 oracle in exit code, stdout and diagnostic string.
5. **Out-params (r12).** With `h(k)` tainted inside `g2`, the existing
   store-escape guard fires first (`tainted value stored to memory`), as the
   orchestrator predicted.

**Conjunct (d) is REMOVED (Rule 14).** Conjunct (b), "untainted", is again the
one owner of "is this literal classical". The (d) decline fixtures are kept and
now pin the 3jru string. The (d)-era accept fixtures keep their shapes, with
rewritten rationale.

**Fixtures.** All are red on aad63450 (12 of 12 measured, plus `chain_store`):
- `taint_reject_quantum_return_{measure,branch}`: the main-branch P1 itself. On
  the oracle, q06 deleted `cq_measure(g(x))` at exit 0, and q07 branched on the
  handle id.
- `taint_reject_quantum_return_{abs,smax,boolarg,measured_literal,helper_arg,fnptr,outparam}`:
  the round-3 probes r01, r03, r04, r05, r06, r10 and r12.
- `…_chain_store`: pins the ITERATED fixpoint. `g` is defined before `h`, and
  `main` stores `g()`; only the second pass lets the store guard speak.
- `taint_accept_classical_decl_literals`: r13, the green side.

**Probes on this binary.** r01–r06, r10, r11, r12, q04–q07 all decline. q93,
r13, r14 (the blow-up, now 0.08 s) and r15 all accept.

**Sweeps.**
- **ir-pass fixtures** (by hand, vs aad63450, comparing exit code, stdout sha and
  the first error line): null control 0 of 40 first, then **2252 fixtures, 17
  movers**. Every mover is one of this change's own fixtures: the 12
  accept-direction flips and 5 decline-string moves, each intended and pinned.
  **No pre-existing fixture moved.**
- **e2e C sources** (`tests/e2e/*.c`, default CASE, exit code and diagnostic):
  432 of 450 compiled standalone (18 need -D flags or other TUs and were NOT
  swept). **2 movers**, both this change's own (`condtree_classical_leaf_matrix.c`
  and `slice_condtree_classical_leaf.c`).
- `example/grover/main.c` is not in this worktree (untracked, bd 5zwz). The
  single-function programs are covered by the sweeps above.

**Mutation delta** (null control first, 0 movers; denominators 107, then 108 lit,
and 4 ctest):

| mutant | removes | result |
|---|---|---|
| M34 | tainting call sites in the fixpoint | KILLED (boolarg, outparam: their owners change) |
| M35 | the refusal slot, both entry points | KILLED (9 fixtures) |
| M36 | the address-taken branch of the refusal | KILLED (fnptr) |
| M37 | the fixpoint iteration (one pass only) | first MISSED: the late refusal reads final taint, so the verdict held; KILLED by the new `chain_store` fixture |
| M38 | `functionReturnsTainted` (always false) | KILLED (11 fixtures) |

M27–M31, the conjunct-(d) mutants, are retired with their code.

**Not tested.**
- A module where round-2 growth alone makes a callee's `ret` tainted. The late
  slot reads that growth by construction, but I have not built a fixture for it.
- Cross-TU returns (a declaration answers no; this is the Escaped contract).
- `invoke` call sites: `CallBase` covers them, untested.
- The 18 e2e sources that need -D flags or other translation units.
- The full ctest and an unfiltered lit.

## 6e. Rule-13 round 4 on `d393b4bb`: CLEAR-WITH-ITEMS (0 P1, 1 P2, 3 P3)

- **F-R4-1 (P2, L2), fixed.**
  - **The defect.** The call-return closure lived only in `propagate`. The round-2
    reseed (`repropagateControlMerges` → `propagateWorklist`) and
    `propagateFromSeeds` (`MergePhiPeel`, `adjudicateTaintDelta`) never applied
    it. So j01 (`g` returns a 6.5 classical-call arm merge, whose `ret` is
    tainted only in round 2) left `g(m)`'s call site CLASSICAL at final taint.
    `declineQuantumCondLiterals` then passed a literal carrying the handle id.
    E3 accepted this silently; E4 declined it only at the later slot.
  - **The fix (Rule 14: one owner).** The closure now lives INSIDE
    `propagateWorklist`, which is the one drain every taint grower goes through.
    When a `ReturnInst` is newly tainted, every DIRECT call site of its function
    whose result is USED joins the worklist. Chains and recursion close through
    the worklist itself. The separate loop in `propagate` is gone.
  - **Growers enumerated:**
    - `propagate` and all of its rebuilds;
    - `repropagateControlMerges` (the reseed and its onward-control fixpoint);
    - `propagateFromSeeds` (`MergePhiPeel` via `adjudicateTaintDelta`);
    - `collectAndSeed`'s bank-load seeds, which drain through the same worklist.

    Emitters that insert `%out` directly (`SelectMergeEmit`) replace a value
    that was already tainted, so no `ret` newly becomes quantum there. The
    6.5/4.5 `%out` rails are exactly the round-2 reseed's seeds.
  - **j01 now declines at 696**, `declineQuantumCondLiterals`, with `classical
    condition literal became quantum-derived`. That is the first owner after the
    fixpoint, because the literal is now tainted at final taint
    (`taint_reject_quantum_return_round2_literal.ll`, red on d393b4bb).
  - **q61 (volatile flag)** declines with the 3jru string. `slice`'s `ret` is a
    quantum-condition mux of the volatile `flag`, and `main` reads it. The oracle
    declined earlier with `control flow`
    (`taint_reject_quantum_return_volatile_flag.ll`).
  - The false §6d sentence is corrected at the source (`CQLoweringPass.cpp` slot
    comment, `TaintPropagation.h`, `propagateWorklist`) and in §6d above (L7).
- **P3-a (over-decline), fixed.** A direct call whose result is UNUSED is no
  longer tainted and no longer refused. a12 (`g(m, 0);`) accepts with the rail
  left allocated, as on aad63450 (`taint_accept_quantum_return_unused.ll`, red on
  d393b4bb). Address-taken uses are still refused, including a function that is
  only address-taken and never called. Proving that no indirect call reads the
  result is a points-to question; the comment at `declineQuantumReturnCalls` says
  so.
- **P3-b (wording), corrected.** "Keeps earlier owners' strings" holds only for
  owners ABOVE the slot: the specializer, the loop layer and
  `declineQuantumCondLiterals`. Owners BELOW it (`declineClassicalMuxes` onward)
  are PRE-EMPTED in a multi-function module whose callee returns a register. The
  reviewer's a08, g03 and g05 now print the 3jru string where the oracle printed
  `tainted value muxed by a classical-condition phi`. Both are declines; only the
  owner moved. Corrected in the source comment and the header.
- **P3-c (record only).** r04's specializer string, `floating-point quantum
  argument or return has no reversible copy`, is fired for an `i1` (`_Bool`)
  argument. It is pinned as-is, since it is not this change's owner. **Suggested
  bead:** the specializer's arg/return width gate names fp for a non-fp width;
  re-derive the string from the actual type.
- **Round-4 probe set (reviewE_r4, ~110 C probes, both binaries).** Every
  exit-code mover was checked:
  - a01–a06, a13, b02, c02–c04, c06, c08, c10, c12, c14–c17, d01–d03, d05, g01,
    g02, g04, g06 and i01 now decline where aad63450 exited 0. **Every one of
    them reads a register returned by a defined function** — exactly the 3jru
    miscompile class.
  - c05, c07 and c13 decline at earlier owners (QRAM, rail bank, ctlz), because
    the returned value is now tainted.
  - The accepts that stayed accepts: a07 (a returned measure is classical),
    a12, b01, b03, b04, e05, q42, q62, q91.
- **Sweeps.** ir-pass fixtures vs aad63450 (exit code, stdout sha and first error
  line), null control 0 of 40 first: **2266 fixtures, 30 movers, every one this
  change's own**. That is 11 condtree accepts, the converted classical-leaf
  fixture, 5 intended string moves, and 13 new taint fixtures.
- **Mutation delta.** Null control first, 0 movers; denominators 111 lit and 4
  ctest.

  | mutant | removes | result |
  |---|---|---|
  | M39 | the closure hook in `propagateWorklist` | KILLED (boolarg, chain_store, outparam, round2_literal) |
  | M41 | the unused-result skip in the refusal | KILLED (unused accept) |
  | M35 | the refusal slot | KILLED (10) |
  | M36 | the address-taken branch | KILLED (1) |
  | M38 | `functionReturnsTainted` | KILLED (10) |
  | M40 | the unused-result skip in the TAINT step | **MISSED**, no subject: an unused call has no users, so tainting it is unobservable, and the refusal skips it anyway |

  M34 and M37, round 3's loop-shaped mutants, are retired with that loop.

## 7. What I did NOT test

- I did not run the full ctest, an unfiltered lit, cq-opt-equivalence or the
  corpus A/B, as the brief required. The change touches `collectCondTree` (every
  caller: behaviour is identical when `IsLiteral` is null, by construction),
  `SelectMergeEmit` (identical when `CondLiterals` is empty) and the
  `stripCondNetwork` move (verbatim plus one branch). **The orchestrator's full
  suite is what witnesses byte-identity for the existing select/kickback
  fixtures.**
- No Rule-13 round has been run on this change.
- I did not construct a W-witness value region whose untainted data φ is read by
  a mixed select classified in the same round. In that case the value region's
  RAUW puts the `i32` `%out` into the `i1` literal slot before the re-ask
  declines it. I argue that the re-ask fires first, but I have not measured it.
  The hand-IR probe `cd1.ll` was flattened by PredMux instead, and it is
  byte-identical to the oracle.
- Clone mode, multi-function modules, and `+Asserts`: none were tested.
- `ix2v`'s class on the DATA path. The literal emission site now passes
  `zeroext` (§6c), but the data path's `_hl` mints (`lowerOps`, including the
  boolean-algebra path's `and_i1_hl`, reviewer probe q91) are unchanged and
  still pass `i1` without it.
