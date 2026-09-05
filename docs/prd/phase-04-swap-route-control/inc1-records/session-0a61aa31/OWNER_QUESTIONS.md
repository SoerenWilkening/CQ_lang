# Owner questions raised this session (3qlq), in order found

## OQ-1 (Inc 0, agent inc0, 2026-09-05) — the linear rule is enforced for tainted PURE ops only
Measured on the pre-3qlq oracle (52d7764), straight-line, no loop, no region:
`int q = cq_theta(seed,.3); int mark = q; cq_ry(q,.4);` then
- `int s = mark*7;`  → exit 1 `cq opcode lowering: operand predates a non-diagonal gate`
- `cq_measure(mark);` → exit 0, emits alloc; ry(h,.3); ry(h,.4); measure(h)  (mark read POST-gate)
- `cq_measure(q); return mark;` → exit 0, `ret h`
`declineStaleRecordOps` covers pure ops; `staleRailRecordRead` is loop-scoped; R6 is region-scoped.
0/1582 fixtures pin the flat measure/ret read. Same class as bd test_C_libtooling-5sva (which was
in loops). PRE-EXISTING, not touched by this epic. PRD D5 frames the three sites as THE rule's
enforcement; frontend.md §3.2 (Inc 0) now records the gap instead. Reproducers:
$SP/progress/inc0-work/{pureop,measure_only_mark,retstale}.c. Proposed: file a bd issue
(over-accept of an ill-formed program at a measure/ret sink; fix = extend declineStaleRecordOps'
question to sink reads) — owner to rule whether it is a 3qlq blocker (I say no: it is arm-class
independent and predates the epic).

## From prep b (agent prep_b, 2026-09-05) — seven coverage consequences of D1/D2, full text in
## $SP/wt/prep-b/docs/prd/phase-04-swap-route-control/inc1-records/PRE_DISPOSITIONS.md §5.
## Orchestrator dispositions taken so the session can proceed; each is one revert if the owner rules otherwise.

- **OQ-2 (prep-b OQ-1) keep-alive, 15 slices.** The old register `cq_phi` was the only opaque READER
  keeping a derived chain alive past -O1 DCE (bswap/ctlz/ctpop/fma/fpmath/fshl/f16/f80/bitint/
  fp80-union/uncompute_dead_{dag,shapes}/loop_iter_local/compare_qq). Nothing in CQ.h reads without
  being a sink or a non-diagonal gate. DISPOSITION: option (iv), not in prep-b's list — the honest CQ
  consumer is a KICKBACK UNDER A DERIVED CONDITION (`if (y == k) cq_phi(θ)`), which exercises the
  forward chain, the mint, the strip AND the chain's `_unc` (the derived-condition chain is uncomputed
  after the strip), i.e. keeps exactly the `_unc` coverage those slices exist for. Goldens for those
  15 are REWRITTEN PROGRAMS (recorded per slice, NOT audit substitutions). Where the derived compare
  is not lowerable at that width, fall back to `cq_measure` of the terminal and record the coverage
  loss. Owner may prefer (i) delete or (ii) a test-only register extern — (ii) contradicts D3's spirit.
- **OQ-3 (prep-b OQ-2) 8 inplace-Ry loop slices + 4 cmp gates.** The Rz was the loop-VARIANT maker for
  the condition register; register-free, the compare LICM-hoists and drbq.12's P4 declines. Their
  pre-3qlq goldens were the identity on q anyway. DISPOSITION: re-base the variant-maker on
  `q = cq_theta(q, 0.05)` at the end of the body (the Inc-3 Grover customer shape); goldens regenerate
  as rewritten programs; the four cmp twin gates stay. NOTE for the owner: `for (i<K) if (q==5) cq_phi(θ)`
  with q loop-INVARIANT is a legitimate program (phase K·θ) that DECLINES — drbq.12 territory, not
  widened in Inc 1.
- **OQ-4 (prep-b OQ-3) P5 switch-phase has no plain-C customer:** `-O1` tables arms that differ only by
  a double into `@switch.table` + one `cq_phi(load)`; the tainted-index load makes the angle tainted →
  loud decline. DISPOSITION: Inc 1b implements P5 on the IR `switch` (hand-IR fixtures) + an e2e slice
  whose arms differ STRUCTURALLY (N-gate arms), pins the table fold as a loud decline. A table-fold
  recognizer (per-entry eq-flags from a const table) is a FOLLOW-ON needing an owner ruling.
- **OQ-5 (prep-b OQ-4) two unspellable slices:** `slice_loop_break_qq_phase` becomes byte-identical to
  `slice_loop_break_qq` → DELETE (recorded). `slice_select_rail_alias_cond`: 3 of 5 alias cases fold to
  constants (their property — a RENAMING diagonal gate — no longer exists in the language) → keep the
  two surviving cases, retire three with the reason in the header.
- **OQ-6 (prep-b OQ-5) N>1 cq_phi per arm:** DECIDED — emit N `cqrt_rz_i1` on the same flag (exact, no
  arithmetic, the angle-select precedent); PRD §6.3's rounding rationale is a Ry-stem reason and 4
  shipped accepts would regress. Sent to impl_inc1a. bd 3qlq.7 becomes "closed by Inc 1" if the owner
  agrees; one-line revert to decline otherwise.
- **OQ-7 (prep-b OQ-6) `slice_control_phase_nest_deep` is a MIXED nest** (Ry in the outer arm, phase in
  the inner): §6.3 mixed decline WINS over P4 (homogeneous). DISPOSITION: pin as a lit decline; the .c
  leaves CMake. The homogeneous genuine nest customer is the migrated `slice_control_nested_phase.c`.
- **OQ-8 (prep-b OQ-7) angle select spelled as a `phi double`:** sent to impl_inc1a as part of P2
  (accept when arms are empty and the phi's sole user is the merge-block `cq_phi`).

## From prep a (agent prep_a, 2026-09-05) — corpus consequences, full text in
## $SP/wt/prep-a/docs/prd/phase-04-swap-route-control/inc1-records/MIGRATION_REPORT.md
- **OQ-9 (prep-a F1) the DERIVED-BASE idiom dissolves — 28 fixtures.** `%qd = cq_phi(%q,.9)` feeding a
  condition was the corpus's way to build a derived base that stays on the SAME rail (the
  "diagonal alias" family: `diagonalAliasHit`, `phaseSpineBase`, `walkPhaseSpine`). Under D2 `%qd` IS
  `%q`, so each becomes the plain-base fixture beside it, and the diagonal-alias pass logic becomes
  vacuous. DISPOSITION: in the re-derive pass, keep ONE representative per pinned property (converted
  to the plain base if that property is not already pinned), retire the rest with the reason in the
  migration report; the vacuous pass helpers are left in place with a comment (PRD P6 "vacuous, not
  deleted") and listed for the owner as dead-code candidates at the freeze.
- **OQ-10 (prep-a F3) "phase-class value" retired — 8 decline gates lose their only spelling**, incl.
  `control_swap_reject_switch_value_clobber.ll`, the ONLY G7 (§3c clobber) fixture. DISPOSITION: the
  re-derive agent RE-SPELLS each of the 8 with a value op (`add`/`xor`) where the property is about the
  VALUE path (G7 clobber is), and retires the ones whose property was the diagonal gate itself, each
  recorded. G7 must not lose its fixture.
- (prep-a F2 = OQ-6, decided: N gates.)  (prep-a F4: 55 oracle-green migrated fixtures are NOT
  evidence — queued for re-derivation with the 181 reds; no owner action.)

## From Inc 2 (agent impl_inc2, 2026-09-05, branch 3qlq-inc2, 7 commits) — full text in $SP/progress/impl_inc2.md
- **OQ-11 Q+Q condition for VALUE arms** is one 4-line `if` away; PRD §9 says deferred → fenced (explicit decline). Owner may lift.
- **OQ-12 run-time classical shift amount ≥ W** passes through to the gate on BOTH binaries (pre-existing, mechanism-independent) → filed, not fenced.
- **OQ-13 the `value-arm swap-route` decline string** names a retired mechanism (6 sites, 28 fixtures) → rename deferred to the Inc-2 clearance/fix round.
- **REVIEW FLAG (load-bearing):** `emitSelectRegion` is now reachable with DERIVED bases (coherent Rz-lineage operands) that `classifySelectRegion` would refuse; `slice_control_value_derived` ships without a twin gate because its select twin declines on both binaries. NOTE: after Inc 1 there is NO Rz lineage any more (cq_phi is register-free), so this class must be re-asked post-rebase — the Inc-2 review lens item 8 covers it.
- Inc 2's speculation-totality fence (`isSafeToSpeculativelyExecute`) is a NARROWING of a shipped accept (`p/n`, run-time classical n) — safe direction; recorded.
- Step-0 measured: `-O1` erases the `if` vs `?:` distinction (SimplifyCFG's threshold decides) — the honest twin is the PRE-HOISTED select `int t = R(p); p = c ? t : p;`. bd memory `o1-erases-if-vs-ternary-spelling`.

## From prep d (agent prep_d, 2026-09-05, branch 3qlq-inc1-matrix, 8 commits) — full text in $SP/progress/prep_d.md
- **OQ-14 `inplace_twin_matrix.py`'s I2 invariant premise is FALSE since drbq Inc 2b** (a by-difference angle `-0.5 = 0.4-0.9` trips "negated controlled rotation"); reproduces on both surfaces on the oracle. Pre-existing instrument defect, untouched. Owner: fix I2 or retire it.
- **OQ-15 no byte-identity twin exists for the Rz angle select under `void`**: `if (q==5) cq_phi(A); if (q!=5) cq_phi(B);` is byte-identical at -O1 to the if/else. The audit's substitution (d) is the ONLY witness for P2 (Rz stem); the matrix records `RZ-VOID-NO-TWIN-*` and prints the rz_i1 lines for eye-check. Reviewers (L4) must argue P2's unitary analytically.
- POST run TODO (after Inc 1 lands): re-run the three instruments on the Inc-1 binary with `--phi-surface void` (angle_select with `--oracle <pre-3qlq cq-opt>`), commit `*_post1.txt`; the inplace `--stateprep` pool was NOT measured under void.

## Round-1 lens L7 (2026-09-05) — $SP/progress/review_r1_L7.md
- **F-L7-1 CONFIRMED MISCOMPILE (Inc 1a, fixed in round 1):** ShareCondFlag path — the whole-DAG spine adjoints the
  kickback `rz_i1(f,θ)` with `rz_i1(f,−θ)`, cancelling the phase exactly; oracle keeps the gate. 5-for-5 on "the first
  adversarial round finds a confirmed silent miscompile". Fix: record kickback gates; spine opaque by membership.
- **F-L7-2 REGRESSION (Inc 1a P6, fixed in round 1 or declined):** rolled in-loop kickback with a DERIVED condition leaks
  the derived chain every iteration (orch-measured: 4 mints / 0 unc on the subject; oracle 4/4; flat 2/2). D4's per-bit
  idiom is exactly this shape, and the diffusion after it is dephased with only a WARNING. OWNER: the composition
  question stands even after the fix — a warning is the wrong severity for a live which-path record at a non-diagonal
  gate (it is a dephasing, not a leak). Consider promoting `non-diagonal gate over a live derived record` to a decline.
- **PRD §9 per-bit row** ("2 _unc → 2 free") is true of the flat/fixed form; the doc is corrected in the notes.

## Round-1 lens L3 (2026-09-05) — $SP/progress/review_r1_L3.md
- **F-L3-1 CONFIRMED MISCOMPILE (Inc 1a P7, fixed in round 1):** `deleteGlobalPhases` ran before the onward-control
  second round (`repropagateControlMerges`), so a `cq_phi` under an ONWARD tainted branch was deleted as a global phase;
  the orphaned angle select then lowered as fp DATA. Two plain-C reproducers through the shipped two-TU harness.
  Fix: reorder in both entry points. F-L3-2 (over-decline of the shipped onward slice) shares the root.
- F-L3-3 latent recognizer gap (spec candidates read the empty PhiCalls) — fixed. F-L3-4 address-taken `cq_phi` survives
  to link — made a loud decline. F-L3-5: the "opt exit 0 on verifier failure" note was FALSE (exit 134) — comments corrected;
  no harness weakness. F-L3-6/7 docs/strings.
- NOTE for the owner: `cq-opt` exits at the FIRST DS_Error (one decline line per module) — a pre-existing property, now recorded.

## Round-1 lens L1 (2026-09-05) — $SP/progress/review_r1_L1.md
- F-L1-1 = F-L7-1 independently confirmed; reproducer is the SHIPPED `slice_control_cond_datause` on the new surface;
  the defect is polarity-dependent (negated arm survives by the accident of its cqrt_x bracket). Polarity itself CLEAR
  over 33 spellings / 51 traces.
- **OQ-16 (F-L1-4) if/else with ≥2 cq_phi per arm DECLINES** (`-O1` emits two angle selects on one compare, or a diamond
  with two merge-tail phis); N-per-arm is a property of the DIAMOND spelling only. Loud and safe; widening = accept
  multiple selects/tail phis on one flag (same mechanism). Owner: widen in Inc 1 fix round or file as follow-on?
  Orchestrator disposition: NOT widened this round (keeps the review surface bounded); filed.
- F-L1-2/3 coverage + doc truth (if/else unreachable from C; "one bracket pair per arm" false for the tail spelling) — fixed.

## Round-1 lens L2 (2026-09-05) — $SP/progress/review_r1_L2.md
- F-L2-1 = F-L7-1 (third independent confirmation, 5 reproducers). Operand relabelling between mint and strip: CLEAR (11 items).
- **F-L2-2 REFINES F-L7-2: the rolled per-bit leak is PRE-EXISTING and arm-class-independent** — a loop body with NO rail
  gate on the condition register leaks its derived `and` rail per iteration on the ORACLE too (Ry arm). D4's idiom is
  exactly that shape. Disposition: fix in the in-loop discharge if reachable this round, else DECLINE the rolled D4 idiom
  loudly + quarantine class + OWNER QUESTION. Not blessed.
- **OQ-17 (F-L2-4)** a kickback on an ALREADY-MEASURED condition register accepts (harmless analytically; inconsistent
  with the FreePoint post-measure-gate reject). Disposition: decline for consistency unless a reason appears.

## Round-1 lens L5 (2026-09-05) — $SP/progress/review_r1_L5.md
- **F-L5-1 = F-L7-2/F-L2-2 with the ROOT CAUSE** (Uncomputation.cpp:1320 silent skip; markIfRailLocal returns on a
  loop-invariant tainted operand with no rail — the kickback body gates nothing, so D4's idiom is the NORMAL case now).
  OWNER: if the fix agent cannot ship the iteration-local widening safely, the rolled D4 idiom DECLINES (hand-unrolled
  works) — that contradicts D4's "measured: lowers ROLLED at K=4/32" claim, which was measured on the register surface
  where the arm gate made q loop-carried. Needs a ruling either way.
- **OQ-18 (F-L5-2) 14 new non-quarantined rolled≠unrolled cells in the VOID loop twin matrix** on the subject (0 on the
  oracle — it DECLINED all 14 `control flow`); all first-differ on the M-C in-place decision = the filed a3z7/1m5p class.
  New POPULATION on a known defect. Disposition: quarantine with pinned signatures + bd issue (prep-d2), not blessed.
- **OQ-19 (F-L5-4) P2 (angle select) inside a rolled loop declines** `condition predates a non-diagonal gate` although
  PRD P6 lists P1–P3 in-loop; the fix agent checks whether the drbq Inc-3 per-activation reading applies; else pinned +
  filed.
- **OQ-20 (F-L5-6) the three PHASE-CARRIER fences** (break B3 / ret / abort "lineage carries a phase") are VACUOUS IN THE
  WIDENING DIRECTION: a kickback-phased register has no cq_phi in its lineage. Fix: record phased registers at
  emission and consult. Reachability at HEAD unconfirmed (held shut by other fences) — latent.
- F-L5-3 in-loop accept fixture unreachable from C + drbq.12 at the phase stem (`for(){ if(q==k) cq_phi(θ); }` with
  q invariant DECLINES; workaround = opaque threshold). F-L5-5 = F-L3-7. F-L5-7 harness: `e2e-loop-twin-matrix`
  HARNESS-ERRORs under the new header (needs `--phi-surface void` + new tables) and the void guard is a whitespace-
  sensitive literal — prep-d2.
- CLEAN: nine rolled/unrolled pairs byte-identical (mixed kickback+cRy, K=1, N gates, two regs, sequential, derived+gated).

## Round-1 lens L6 (2026-09-05) — $SP/progress/review_r1_L6.md
- **F-L6-1 CONFIRMED third path (fixed in round 1):** a stale-header `if (q==5) q = cq_phi(q,PI)` const-folds arg-0,
  the retired call is still CLAIMED as an arm gate (prefix test) but never lowered → opt exit 0, gate dropped, link error.
  Fix: any declared `@cq_phi_<sfx>` declines (reserved name) + end-of-pass survivor assert.
- **OQ-21 (F-L6-6)** a module that DEFINES `void cq_phi(double)` with a body is silently captured by P7 (calls deleted);
  a classical `int` argument is silently a 7-rad angle (the type system no longer separates register from angle).
  Disposition: defined `@cq_phi` → reserved-name decline if consistent with the other 33 names; the int-angle is a doc note.
- F-L6-5: docs still describe the two-argument surface in backend.md, quantum-classical-handling.md, example.md,
  CLAUDE.md Rule 3 (Inc 0 rewrote frontend.md §3.3 only) → a docs pass after the merge, before the commit.
- F-L6-2/3/4/7 fixture/doc truth (count slip 155→129; smoke test windowed; f16/f80 missing from NOROUTE; phiFn dead).
- CLEAR: old spelling is a hard compile error (63/63 slices); 129 green retired-family fixtures measurably not false-green.

## Round-1 lens L8 (2026-09-05) — $SP/progress/review_r1_L8.md
- CLEAR on integrity: 64/64 injections caught across the 11 accepts (harness controlled clean + known-bad + two
  broken-fixture self-checks); every count in impl_inc1a.md re-measured exactly. Four fixture/prose items (f16/f80
  widths; cqrt_x negative missing in 3; the Rule-1 assert string has no fixture; a superseded string listed as shipped) →
  fix_r1. No owner question.

## Round-1 lens L4 (2026-09-05) — $SP/progress/review_r1_L4.md
- CLEAR on the unitary (x;rz(B);x;rz(A) exact per basis branch up to a global phase; bracket closed before the strip
  in 42/42 traces; polarity has no case; corpus sweep: exactly the 10 intended new accepts). Q3 (run-time arms for
  the phase stem) measured sound.
- F-L4-1 undef/poison arm passes through for the phase stem (hand-IR only) → fixed; nan/inf/ConstantExpr pass-through
  pinned as DELIBERATE (matches the uncontrolled cq_theta baseline on both binaries). F-L4-2 = f16/f80 gap. F-L4-3
  eight unpinned P2 decline shapes → fixtures. No owner question.

## ROUND 1 COMPLETE (8 lenses): 3 confirmed miscompile classes (F-L7-1 ×3 lenses, F-L3-1, F-L6-1), 1 in-loop
## discharge gap on D4's idiom (F-L5-1), 14 new matrix divergences (F-L5-2), ~20 fixture/doc items. All with fix_r1.

## From impl_inc1b (Inc 1 part B — P3/P4/P5, 2026-09-05). Full text + reproducers in
## $SP/progress/impl_inc1b.md under `## OWNER QUESTIONS`.

- **OQ-11 — P5 (phase switch) has NO plain-C `-O1` customer, and OQ-4's proposed remedy is
  MEASURED not to work.** OQ-4 said "Inc 1b implements P5 on the IR switch + an e2e slice
  whose arms differ STRUCTURALLY (N-gate arms)". Seven spellings measured
  (`$SP/progress/inc1b_probes/`): a phase arm's only content is
  `call void @cq_phi(double)`, so every arm's suffix is identical modulo one operand and
  SimplifyCFG's common-code sinking ALWAYS applies — dense case values become a
  `@switch.table` of angles (or of pointers) with ONE shared call, sparse ones a cascade
  joined by `phi double`. N-gate arms sink too (measured at 1/2/3 and 4/3/2 gates). So NO
  P5 e2e slice exists in this increment. SHIPPED instead: P5 lowers on the IR `switch`
  (3 accept + 7 decline fixtures, stage 2b STRICT PASS) and BOTH `-O1` outcomes are pinned
  as loud declines, incl. `control_phase_switch_reject_table_fold.ll` carrying the verbatim
  `-O1` module. **Owner:** (a) accept P5 as hand-IR-only (the footing the if/else kickback
  arm has had since part A), or (b) commission the TABLE-FOLD RECOGNIZER as its own
  increment — the table is `private unnamed_addr constant` with `ConstantFP` entries, so
  the N angles are statically known and the lowering is P5 with the case values read from
  the table. (b) is what gives P5 a real customer.
- **OQ-12 — the 4.4 DATA select still declines the logical-select condition.**
  `collectCondTree` gained `AllowLogicalSelect`, ON for the branch phase and OFF for the
  data select / clone lift, so `control_swap_reject_select_i1sel_combinator.ll` is
  unchanged and the lift measured ZERO change across 1602 fixture outputs. Consequence:
  `if (q==5 && r==3) cq_phi(θ)` lowers while `int x = (q==5 && r==3) ? a : b;` declines —
  one grammar, two verdicts, decided by a flag. Safe direction, recorded rather than left
  implicit (the bd 3c6m.67 / big5 "absence of a decision" shape). Proposed: widen in a
  follow-on with its own probe family; the emitter already handles it.
- **OQ-13 — `Specialization::mintCondNetwork` is a THIRD copy of the condition network**
  (forward-only, `cqq.g` ancilla name, its own NodeMints/NodeRails capture, no strip).
  Not folded into `CondTreeEmit` because it would move the specialization goldens; a
  cross-reference comment says so. Proposed: a "keep flags live + capture" mode in a
  follow-on.

## Inc 2 round-1 lens V1 (2026-09-05) — $SP/progress/review_inc2_V1.md — CLEAR of miscompile (59 programs)
- **OQ-22 (F-V1-1) UNREVIEWED WIDENING:** routing the value diamond through emitSelectRegion sets
  `taint.HandleWidth[Out]`, so a downstream CAST or Q+Q COMPARE on the merged register now accepts (5 plain-C
  programs, incl. the flagship i32 `int e = (p == r)` after a value arm) where the oracle declined. Streams correct,
  2b clean = capability gain, but shipped invisibly with zero fixtures. Disposition needed: keep (pin with accept
  fixtures + note) or fence to the oracle's disposition. Orchestrator recommendation: KEEP + pin (the 4.4 select
  merge already owns that width table for `?:`; the diamond is the same mechanism).
- **F-V1-4 PRD §3/§7.1 truth:** the chain-final rail R(p) is NOT `_unc`'d/freed — left allocated AND ENTANGLED
  with out (the oracle's leaks were `_unc`-zeroed). Physically sound while p is retained; the PRD sentence
  "t uncomputed by _unc … freed clean" is false and must be corrected in the Inc-2 notes + PRD errata.
- F-V1-2 mutate-then-decline (flatten before emitSelectRegion can fail on compareFlagMintable) — unreachable today
  (needs an i128 condition, F-V1-9 pre-existing), 3-line pre-fence. F-V1-3 fp row rationale false (fp merge is
  lifted to a select before detection; the value path's fp backstop is unreached). F-V1-5 §3c/M-C clear but the
  "two distinct copy sources" property now rests on ArithLowering's G6/G7 "weak tripwire" — pin + comment.
  F-V1-6 totality clear; rationale sentence corrected. F-V1-7 add the negated-polarity twin pair as a slice+gate.
- **F-V1-9 PRE-EXISTING:** a tainted `icmp i128` branch condition is neither claimed nor declined by the control
  layer on either binary (only a later template error). File as a bd issue.

## Round-1 FIX (agent fix_r1, branch 3qlq-inc1-fix-r1 tip bb78020, 9 commits) — notes in RETIRE_SWAP_ROUTE_INC1_NOTES.md §1
- Fixed: F-L7-1 (spine adjoint) via per-instruction metadata `!cq.branchphase` refused by isInPlaceGateOn /
  preservesBasisUnderRecord / isInverseEmittable (deviation from the TaintSet-image plan; reasons in the notes —
  round 2 must probe metadata survival); F-L3-1 (deleteGlobalPhases after the round-2 fixpoint, both entry points);
  F-L5-1 (invariantRegisterRoots → markIfRailLocal, root mints only — rolled == unrolled on D4's idiom); F-L6-1
  (reserved-name decline + declineSurvivingIntrinsicCalls postcondition); F-L4-1; F-L5-6 (phase-carrier record);
  fixture/doc items. 34 new lit reds, all in the retired-family migration set.
- **Q-R1-1** the HOISTED-template-rail case of the in-loop discharge still leaks (only root mints are marked).
- **Q-R1-2** = OQ-19 (P2 in a loop declines vs PRD P6). **Q-R1-3** = OQ-21a (defined @cq_phi captured).
  **Q-R1-4** = OQ-21b (classical int → radians). **Q-R1-5** = OQ-16 (N per arm: construct vs diamond spelling).
- The brief's "goldens differ by exactly one rz_i1 line" witness was WRONG: on the ShareCondFlag path adding the
  kickback also removes the strip+free (as the oracle does); the correct witness is recorded in the notes.

## Inc 2 round-1 lens V2 (2026-09-05) — $SP/progress/review_inc2_V2.md — CLEAR on the mechanism
- 0 miscompiles / 0 over-accepts / 0 pre-existing fixtures moved (1586 × 2 sweep); 950 fuzzed switch-value programs
  0 mismatch, 0 dirty free; three cmp gates non-circular (oracle reproduces the twins byte-for-byte).
- **OQ-23:** V2 wrote a BASIS-STATE evaluator over the emitted gate list as an independent witness for VALUE regions
  (pure permutations ⇒ classical evaluation on basis inputs is a complete check of the permutation AND of
  "freed at |0>", which the golden byte-diff cannot see). It is not a statevector simulation. Owner: admit it as a
  `tools/` instrument (like the twin matrices) or keep it out under the 2026-06-10 no-simulation decision?
- F-V2-1/2/4 doc truth; **F-V2-5/6 fixture truth (CHECK-NEXT contiguity dropped in 7/8 accepts; a dropped flag
  strip = hidden measurement is invisible to one fixture)** → fix_inc2_r1. F-V2-3 = F-V1-4 (dirty chain finals; 3qlq.5
  unsound by default under this leak class).
- V3 (switch value) has NO byte-identity twin of any kind (the uncontrolled preload is not expressible in C) — its
  floor is a self-regenerated golden + analytic argument + V2's basis-state check. Recorded.

## Round-2 lens R1 (2026-09-05) — $SP/progress/review_r2_R1.md
- **F-R1-1 CONFIRMED rolled≠unrolled (fixed in round 2):** in-loop kickback over an ONWARD (6.5 out-rail) register
  leaks one entangled which-path rail per activation — `collapseFlattenedLoopRails` runs ONCE before the round-2
  onward-control claim (stage-order gap, F-L3-1's shape one level up). Population created by the round-1 fixes.
- **F-R1-2 OVER-DECLINE (fixed in round 2):** the phase-carrier fences asked REACHABILITY not control-dependence,
  so an uncontrolled global phase after an abort park declined. Notes' "latent at HEAD" was false for abort.
- F-R1-3/4/5 doc truth (five emission sites not three; a `cqrt_rz_` name test in preservesBorrowedParent clause (1)
  soundly ADMITS the kickback gate — must not be narrowed for symmetry; metadata reason (3) unreachable).
- **OQ-24 (F-R1-6, pre-existing):** a D2 global phase inside a specialization candidate is REFUSED (detectSpecializations
  runs before deleteGlobalPhases) instead of deleted; same as the oracle on the old spelling. Owner-scale.
- CORE CLAIM HELD: 633 accepted fixtures, `#rz_i1 == #!cq.branchphase`, zero negative-angle kickbacks, no non-i1 Rz.

## Round-2 lens R2 (2026-09-05) — $SP/progress/review_r2_R2.md — 0 miscompiles, 0 over-accepts
- Emitted Rz set = `cqrt_rz_i1` ONLY over 1661 fixtures (35 emit it, 0 any other width); `#rz_i1 == #!cq.branchphase`;
  postcondition holds (0 surviving intrinsic calls); the fixes changed 0 lowered outputs outside the F-L6-1 decline set.
- **F-R2-1 systemic fixture truth:** round-1 fixture repairs were not propagated to part B's 15 accepts (+3 others):
  18 blind to f16/f80, 21 to an unpaired cqrt_x, 20 to an extra free, 3 to a dropped strip → fix_r2 applies to all 37.
- F-R2-2..11 doc/fixture truth (six mark sites not three; two headers still carry the false "exit 0" claim; docs cite
  e2e witnesses living on the slices branch; a non-discriminating switch decline fixture; P2 record pinned by one file).
- Stage 2b runs on NO kickback e2e program on this branch until prep-b2 merges (63/66 cq_phi slices fail stage 1 on
  the branch's header) — ir-pass-lit is the branch's only gate until then. Known; the merge closes it.

## Inc 2 round-1 FIX (agent fix_inc2_r1, branch 3qlq-inc2, +8 commits) — notes RETIRE_SWAP_ROUTE_INC2_NOTES.md §1
- All V1/V2 items closed; OQ-22 widening KEPT + PINNED (5 fixtures + 1 slice, red on the oracle); F-V1-2 fence found
  REACHABLE on the value path (i128 condition) and pinned — closes the VALUE half of F-V1-9; the PHASE half is
  **bd test_C_libtooling-3qlq.8** (pre-existing unclaimed i128 compare condition). 3qlq.5 recorded UNSOUND BY
  DEFAULT under the dirty chain-final leak class. Lit 1593/1; e2e 330/330; 4 twin gates; injection matrix 0 missed.
- Left for Inc 2: rebase onto landed Inc 1; ONE round-2 lens on the "emitSelectRegion reachable with a coherent
  Rz-lineage operand" flag (NOTE: after Inc 1 there is no Rz lineage — re-ask post-rebase); clearance.

## prep a2 (2026-09-05, branch 3qlq-inc1-migration, 10 more commits; lit 1655 with 12 reds = the 12 FLIPS)
- Gate passed (0 reds outside the population). 104 re-derived / 143 re-spelled (26 clause-moved) / 16 theta-swapped /
  6 retired (reasons in MIGRATION_REPORT §17). Integrity: first harness was worthless (injected inside the CHECK-NEXT
  chain) — fixed; 4/104 were blind to an injected `cqrt_rz_i32_controlled` → narrow twin negative added; final 104/104.
- **12 DECLINE→ACCEPT FLIPS left RED for review** (§14) → lens `review_flips` launched. Two groups likely legitimate
  (2b rounding/runtime angle: no subtraction under kickback; eqfold wrong-edge: no arg-0 to re-anchor); the
  "impure phase arm"/"nested" ones must be argued.
- 3 fixtures LOST THEIR SUBJECT (built on `cq_phi(i32 CLASSICAL, θ)`) — an ill-formed CQ program is a well-formed LLVM
  module, so no oracle check could see it (§12.1). `diagonalAliasHit`/`walkPhaseSpine` now unreachable (§13.3) —
  freeze-time dead-code candidates (= OQ-9's pass-side half).

## prep b2 (2026-09-05, branch 3qlq-inc1-slices tip dc45595, 7 commits) — GOLDEN_REGEN.md (476 lines)
- 71/71 slices full STRICT pipeline; audit: 33 substitution-only + 2 ambiguous + 10 new + 26 FINDING = exactly the 26
  rewritten programs, 0 unexplained; tree-wide goldens: 0 negative-angle rz_i1, 0 `_controlled` Rz, 0 non-i1 Rz;
  the audit's (b)-NEST MODEL matched the real trace line for line; e2e 325/327 (the 2 reds are prep-a's
  fixture-guard-liveness (retired-family fixtures, closes at the migration merge) and prep-d2's twin matrix).
- **F-B2-2 → fix_r2:** Q+Q kickback condition declined by the OPCODE layer, not the control layer (Rule 1).
- **F-B2-3 → prep_b2 resumed:** 4 slices whose subject was the uncontrolled Rz now test nothing (audit-clean class (c),
  which is exactly why a green suite cannot see it) — one-line remedies applied.
- **OQ-25 coverage loss, recorded:** the aliased-operand COMPARE has no spelling left in CQ at any width (4 templates +
  4 `_unc` twins leave the corpus); only the arithmetic alias survives. Owner: accept, or find a spelling.
- Removed: slice_loop_break_qq_phase (dup), slice_control_phase_nest_deep (mixed nest = decline),
  e2e-slice-control-switch-phase (no plain-C P5 customer, OQ-4/OQ-11 — .c kept unregistered),
  e2e-angle-select-rz-twin-identical (no twin under void, OQ-15). CLAUDE.md count "five loop-break --allow-unproven" → four.
- prep b2 REMEDIES (tip f38ef48): 4 slices rewritten (two of the one-line proposals were measured WRONG — a rotation is
  not a phase; a hoisted compare makes a second merge phi); +1 twin (`slice_loop_phase_accum_unrolled`, byte-identical,
  closing a prose claim standing since 7.3); audit 30 FINDING = exactly the 30 rewritten programs; e2e 327/329.
- TOOL NOTE (prep-c): `golden_multiset_audit.py` raises FileNotFoundError on a DELETED golden in its default set —
  run with an explicit list until fixed (orchestrator: fix before commit or file).

## Lens review_flips (2026-09-05) — $SP/progress/review_flips.md — 0 OVER-ACCEPTS among the 12
- 8 LEGITIMATE-ACCEPT (#11 contingent on §12 Q3), 4 RETIRE (property unrepresentable without a register cq_phi).
  Executed by prep_a2 (resumed). 4 extra-discharge rows SOUND (the increment removed a freeze whose object no
  longer exists: no controlled-Rz minter remains).
- **OQ-26 (lens F1):** `tryEqFoldArm` D1–D8 + the §5 const-fold re-anchor (`straightThroughConstFoldHandle`,
  EqFoldArm.cpp) are UNREACHABLE at HEAD (the cq_theta(i32 k,θ) spelling is intercepted by drbq Inc-4's F1 on both
  binaries); 4 eqfold accept fixtures were FALSE-GREEN with headers claiming a fold that no longer happens → headers
  rewritten; the code is a freeze-time dead-code candidate (with diagonalAliasHit/walkPhaseSpine/phiFn/emitRz).
- Lens F2: SwitchClassify's arm-content clause lost its only pin → re-spelled fixture. §13.3 wording corrected:
  diagonalAliasHit/operandsAlias are DECLINE tests whose vacuity WIDENS them; safe only because the population
  cannot exist.
- Audit tool: DELETED goldens now reported instead of crashing (orchestrator patch on 3qlq-inc1-audit).

## prep d2 (2026-09-05, branch 3qlq-inc1-matrix tip 7f4776f, 5 commits)
- Void surface = the shipped `e2e-loop-twin-matrix` gate (--phi-surface void; whitespace-insensitive header classifier in
  all three instruments); register tables kept as `.register.txt`; POST tables committed; loop-twin 4/4 green (695 s);
  quarantine 15 → 29 cells (8 a3z7 class B verbatim, 4 same M-C decision on the xor PREFIX, 2 fit neither — below);
  quarantine self-test was RED at ffa95cc (prep_d's signature change) → fixed, 12 → 27 cases under both surfaces.
- **OQ-27 (OQ-D2-1)** `m_xor_range_{none,rz}`: rolled emits `xorc(h0,9)`, flat `xor_hl(h0,8)` — `-O1` drops the mask's
  low bit on the flat side ([6,20) is closed under a bit-0 flip): the two SPELLINGS are different programs = a
  GENERATOR question (make the immediate opaque), not a compiler defect. Pinned as class C, not blessed.
- **OQ-28 (OQ-D2-2)** the boundary control `q_armoncond` DIVERGES under void with 1m5p class A's signature (a branch
  phase writes nothing, so the control now satisfies the precondition it bounded). Kept + pinned; the class story is
  bounded by `q_noregion` alone.
- F-L5-2's 14 cells: none moved on the fixed binary (they are the M-C decision class, unrelated to the fix).
- DOCS: CLAUDE.md/ROADMAP.md describe the quarantine as 15 register-surface cells — now 29 void cells, three classes.

## Round-2 FIX (agent fix_r2, 4 commits, tip 6a3a125) + MERGE (be4e2ea)
- F-R1-1 fixed in two halves (clause (ii-b) control-owned merge out-rails as invariant roots + a second
  collapseFlattenedLoopRails pass over the round-2 delta), mutation-validated one half at a time; the population was
  wider than R1 said (4.4 select-merge and 4.5 data-mux out-rails leaked at ROUND 1 too). Q-R1-1 hoisted-template
  residual still refused, byte-identical to main.
- F-R1-2 fixed by post-dominance over RETURNING paths (the park's `unreachable` arm is its own post-dom root, so the
  brief's two suggested tests both failed — measured). Q+Q kickback condition now declines in the CONTROL layer
  (`kQQCondReason`, per leaf, P1+P4; P5 structurally exempt).
- **Q-R2-1** round-1 iteration-local MARKING is never re-verified under round-2 taint (marking only grants).
  **Q-R2-3** `lowerControlledIOSinks` and `lowerLoops` are not re-run at round 2 — both MEASURED to over-decline an
  onward shape whose round-1 twin accepts. Both filed in notes §2 with the once-only-stage table.
- **OQ-29 (decl-only retired family):** `lowering_legacy_phi_decl_prototype_family.ll` records that a DECLARE-ONLY
  unused `@cq_phi_<sfx>` is SWEPT (accept), not declined — reasons: inert; "a decl-only decline would redden ~490
  fixtures mid-migration". The second reason is MOOT after the migration (6 references remain, all fixtures about
  this). Also lost vs the oracle: prototype validation of an uncalled wrong-typed retired decl. Owner/clearance:
  tighten to the reserved-name rule now that the corpus is migrated? (one clause; ~5 fixtures to re-point).
