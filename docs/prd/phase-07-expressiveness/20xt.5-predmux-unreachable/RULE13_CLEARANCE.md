# Rule-13 clearance — bd 20xt.5 (d): PredMux tolerates `unreachable` switch-defaults

Independent adversarial review of increment (d) (the merge-recompute-ignoring-
unreachable + E3 unreachable-tolerance change in `PredMuxFlatten.cpp`), per
Rule 13 (a green suite alone does NOT clear a core-lowering change).

## Method

5 independent opus adversarial lenses (no statevector simulation — owner
decision; analytic/trace reasoning + read-only probing of the EXISTING built
`.so` on hand-crafted `.ll`, agents FORBIDDEN from rebuilding the shared plugin),
then an independent adjudicator that re-verified every reported defect against the
actual code. Lenses:

1. **merge-helper** — `mergeIgnoringUnreachable` returning a wrong-but-E3-passing
   merge; the popcount-argmax chain assumption; multi-ret / all-succ-unreachable
   dead-ends; BitVector fixpoint convergence; irreducible CFG.
2. **ub-soundness** — is "drop unreachable = UB, obligation-free" airtight under
   quantum superposition; does the select-chain fallback absorb a would-be-
   unreachable basis state into a wrong-but-defined value.
3. **flatten-mechanics** — side-effecting/pure body in an unreachable block being
   hoisted; phis in unreachable blocks; shared-sink teardown; topoOrder; the
   switch default `∧ ne` predicate.
4. **blast-radius** — verify ZERO effect on any function whose standard-PDT ipdom
   is a real block (the entire existing accept + decline set).
5. **atan2l-trace** — independent re-derivation of the e2e golden's per-basis-
   state correctness + Rule 6/8 bookkeeping.

## Independent author probes (pre-review, analytic + read-only `.so`)

- Non-exhaustive switch with a REAL default (cases `{0,7}`, default a reconverging
  body) — handled by the STANDARD PDT path (helper not even triggered); flattens
  correctly. Confirms (d) is narrowly scoped to genuine `unreachable`.
- Non-contiguous cases `{3,8,20}` + `unreachable` default, nested — flattens +
  `opt -verify` clean; "impossible" scrutinee values get the chain fallback
  (legal: source-asserted UB, the SAME principle as the shipped Inc-3 QROM
  NeedsMask mask, PRD 3c6m.14 §4.5).
- The `(e)` residues (`and i1 false`, `or i32 0`) are cq-lowering-minted, NOT in
  the source IR (0 occurrences pre-lowering) — confirming `(e)` is a separate
  flatten/promotion residue-fold increment, exposed (not caused) by (d).

## Verdict

**SAFE TO COMMIT — `safe_to_commit: true`, ZERO confirmed defects.** All 5 lenses
returned `clean: true`; the adjudicator re-verified all 11 reported observations
against the code (crafting failing `.ll` and running the existing `.so`
read-only) and adjudicated **every one REFUTED** — each was a doc-precision or
test-coverage NOTE, none a correctness defect. Highlights:

- **UB-soundness** (2 lenses): "drop `unreachable` = obligation-free UB" IS the
  LLVM LangRef contract for `unreachable`, which the pass is entitled to trust in
  valid input IR (Rule 11 trust-valid-input). clang emits `default:unreachable`
  only from exhaustiveness proofs over ALL bit patterns (atan2l's `and i32 %q,3`
  → exhaustive for every i32 → every basis state) or from source
  `__builtin_unreachable`/`assume` (a UB contract binding the WHOLE superposition
  support). A would-be-unreachable basis-state component is either zero-amplitude
  or source-UB, so the select-chain fallback absorbing it is a **sound total
  refinement of the source's partial unitary**, never a miscompile of a defined
  program. Verified the ancilla uncompute (toffoli then inverse-toffoli) restores
  every rail to |0⟩ on every basis state — no dirty free / cross-basis collapse.
  The quantum-specific sharp edge (user `__builtin_unreachable` under
  superposition) is documented in bd memory, not a blocker.
- **Merge-helper** (2 REFUTED): the max-popcount = ipdom argument is correct
  (post-dominators form a strict chain, so `PostDom(D1)` is strictly largest);
  the BitVector post-dom fixpoint is monotone over a finite lattice ⇒ terminates
  even on cyclic Node sets; the broader trigger surface (infinite loops /
  multi-ret virtual roots) is fully contained by E2 (cycle) + nullptr-on-no-
  reconvergence + E3, empirically confirmed on disjoint-exit probes.
- **Flatten-mechanics / doc** (REFUTED): `moveBody` DOES hoist a non-empty pure
  dead body, then `sweepDead` erases it (a successorless block dominates nothing
  outside itself ⇒ use_empty); an impure body leaves at E4. Empirically inert
  (0x424242 → 0 occurrences, verify-clean). **Comment/PRD reworded** + new
  hardening fixture `control_predmux_accept_unreachable_dead_body.ll` added.
- **Blast-radius** (REFUTED, strengthened): a standard-ipdom region can NEVER
  contain a reachable `unreachable` block, so both edits are dead code on the
  standard path — every existing accept + real-ipdom decline is byte-identical.
  Containment claim reworded for precision (the virtual-root decline subset is
  exactly where the intended flip happens).

## Post-review hardening applied (all NOTE-level, none a blocker)

1. Reworded the E3 comment + PRD §1 "no moved body" → precise "no SURVIVING moved
   body" (pure dead-swept / impure E4-left).
2. Reworded the containment claim (comment + PRD §2) to exclude the virtual-root
   decline subset.
3. Added `control_predmux_accept_unreachable_dead_body.ll` (non-empty pure
   dead body in the `unreachable` block, CHECK-NOT the swept constant).
4. bd memory records the quantum-specific UB sharp-edge.

Process: the shared `.so` was NOT rebuilt by any review agent (forbidden in the
lens prompts); author clean-rebuilt + re-verified the full ctest after.
Workflow: `rule13-predmux-unreachable-d` (5 opus lenses + opus adjudicator,
749k subagent tokens, 101 tool calls).
