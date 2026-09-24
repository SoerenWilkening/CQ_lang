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
- `ix2v`'s class: the `i1` literal is passed without `zeroext`. The slice trace
  prints clean 0/1. It is pre-existing, and it is shared with the BoolAlg path's
  `and_i1_hl`.
