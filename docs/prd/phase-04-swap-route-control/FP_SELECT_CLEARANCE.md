# FP_SELECT_CLEARANCE — Rule-13 record for the fp-DATA select un-staging (kjd1)

**Scope:** the implementation of
[`fp-data-select-PRD.md`](fp-data-select-PRD.md) (issue
`test_C_libtooling-kjd1`, 2026-07-02): GATE-4 scalar-fp accept, the
select-local `copyControlledFpFn` minter, `abiWidthHasControlledFpCopy`, the 4
frozen-designate `cqrt_copy_f{16,32,64,80}_controlled` runtime symbols, and
the §5 fixture matrix + e2e `slice_control_select_fp`.

**Method.** Independent adversarial multi-agent workflow over the uncommitted
working tree (28 agents, ~1.7M tokens): the six §6 lenses (angle-fence
three-legged · fp coherence · fcmp mint/strip · scope containment ·
uncompute-spine · f80 edge), each writing and running concrete `.ll`/C probes
against the built plugin — analytic/trace reasoning only, no simulation (owner
2026-06-10). The refute-default verifier stage and the completeness critic
were interrupted by a session-capacity limit; **every actionable finding was
instead independently re-derived first-hand** (each probe re-run and confirmed
before any fix; each fix then red-greened per Rule 12, so a false-positive
finding would have produced a fixture that passed *without* its fix — none
did). A post-fix refute-default verification round ran after the capacity
window (see the addendum at the end of this file).

## Lens verdicts

| Lens | Verdict | Outcome |
|---|---|---|
| angle-fence (three-legged) | DEFECTS → fixed | fence itself HELD under 12 probes (memory, ptr, vector, fan-out, per-use edge, QROM carve, curated-intrinsic, cross-function); 1 major: call-blind coherence walk (D3 below) |
| fp coherence | DEFECTS → fixed | basis bit-pattern copy claim HELD (NaN/±0.0/f80 labels; no wrong unitary); 1 blocker: SSA-anchored GATE 5 (D2) |
| fcmp mint/strip | DEFECTS → fixed | flips/unordered preds/width-independence/mint-strip symmetry HELD; 1 blocker: no stale-condition guard (D1); 2 minors (M1, M2) |
| scope containment | CLEAR | `copyControlledFn` code-byte-identical; `copyControlledFpFn` single caller; all 7 `widthHasReversibleCopy` sites untouched; 6.5 fp fixture green; 2 pin fixtures added (§5.9d) |
| uncompute-spine | CLEAR | out-rail rides `ControlOwnedRails`; source lineage leaked (NotClosed); `isCopyOutSink` excludes `_controlled` names; 1 coverage minor (M3) + 2 notes (N2, N3) |
| f80 edge | CLEAR | ABI/type/trace/print all consistent end-to-end incl. a linked f80 run; 1 coverage minor (M4) |

## Confirmed defects (all pre-existing on the integer 4.4 path; all newly
## fp-reachable through the GATE-4 un-staging; all FIXED both-families)

**D1 — [blocker] Stale condition: no non-diagonal wire guard between compare
and select.** `SelectMergeEmit` mints the flag AT the select; a chained
`cq_theta` (in-place Ry) between the source compare and the select made the
flag encode the post-Ry predicate while the SSA condition denoted the pre-Ry
record — verify-clean wrong unitary (probe p11 `.ll`, p12 integer twin, p13
plain C through `-O1`; pre-fix all exit 0 with `ry; ry; mint` streams). Both
sibling classifiers already carried the guard
(`ArmClassify::nonDiagonalGateBeforeBranch`, `SwitchClassify`); 4.4 shipped
the select without it. **Fix:** GATE 2c in `SelectClassify` — the select
mirror of the ArmClassify guard (Rule 14: `condProvenance` + the shared
`WireWalk::findNonDiagonalWireGate` position-free walk, the cross-block
conservative decline, and the positional compare→select tainted-theta scan);
same house string `condition predates a non-diagonal gate under quantum
control`. Fixtures: `control_swap_reject_select_stalecond_chained_theta.ll`
(+ `_i32`).

**D2 — [blocker] GATE 5 was SSA-anchored, not wire-anchored.** A chained
`cq_theta` rebases a wire onto a new SSA name; a `cq_phi` (or later `cq_theta`)
hanging off the OLD alias was in neither GATE-5 walk, so the merge CNOT-copied
a PHASED wire — the exact circuit the phase-operand fixture declines,
differing only in SSA spelling (probes: rebase + phi, integer twin, post-select
interference variant; pre-fix exit 0 with `rz; …; copy` on one handle — the
WI-3 dephasing family). **Fix:** wire-anchoring of both walks —
`operandCarriesPhase` gains forward wire edges (a rotation-call user with
matching arg-0 continues the physical wire; a sibling `cq_phi` anywhere on it
declines), and `hasCoherentDownstreamUse` is seeded from the operand's whole
backward tainted lineage with a `rotationAncestry` exemption (the operand's
own producer chain is walked through, never flagged — the sanctioned
chained-prep accept survives; any OFF-ancestry rotation on any lineage wire
declines). Fixtures: `control_swap_reject_select_fp_phase_sibling_alias.ll`
(+ `_i32`), `control_swap_reject_select_fp_theta_fork.ll`.

**D3 — [major] Coherence walk was blind to call-shaped producers.**
`hasCoherentDownstreamUse` `continue`d on every non-sink, non-rotation
`CallInst` user without walking its result (a rationale stale since the
7.1/libm curated carves), so an operand feeding `cbrt(%q)` whose result took a
downstream Rz silently accepted while the `fmul` twin declined (probe p9 /
p9b). Natural in the PRD's own motivating branchless-libm workload. **Fix:** a
surviving call's result is pushed into the walk (what survives the escape
guard is a curated producer whose result continues the coherence lineage).
Fixture: `control_swap_reject_select_fp_coherent_call_derived.ll`.

**Fix-safety argument (why the fixes need no accept-side re-clearance):** all
three are strictly decline-monotone — GATE 2c and the call-crossing only add
decline paths, and the `rotationAncestry` exemption applies only to nodes
that were UNREACHABLE in the pre-fix walk (the pre-fix walk started at the
operand and only moved forward; ancestry rotations are backward), so no
pre-existing decline was weakened. The full suite (607 lit + e2e + runtime)
green post-fix proves no shipped accept regressed.

## Recorded minors / notes (no code change or pinned-only)

- **M1** (fcmp): unsupported fcmp CONDITION width (fp128 cond + f64 data)
  declines loud + pre-mutation but branded `no template …` (data dialect).
  Pinned as-is: `control_swap_reject_select_fp128_cond.ll`; sharper
  detection-time branding filed as a follow-on.
- **M2** (fcmp): `fcmp ogt %q, undef` accepts with two independently-
  materializable `undef` uses across mint/strip — UB-adjacent C only,
  pre-existing on the icmp path; recorded, not changed.
- **M3** (uncompute): the initial leak pins were trivially green (no dead
  terminal → the closure scan never ran). Fixed with
  `control_swap_select_fp_dead_sibling_leak.ll` (a dead sibling terminal
  forces DAG recovery; the `_controlled` user marks it NotClosed; the leak is
  asserted non-vacuously).
- **M4** (f80 lens): no f32 positive existed. Fixed:
  `control_swap_select_f32.ll`.
- **N1** (angle-fence): the 1b reserved-prefix escape carve admits a
  hand-authored `declare @cqrt_*` angle route — unreachable from the CQ.h C
  surface; pre-existing posture, recorded only.
- **N2** (uncompute): union terminal-group over-suppression — a dead fp
  sibling makes an unrelated closed integer chain in the same function leak
  instead of uncompute. Safe direction (Rule 6/8), pre-existing mechanism.
- **N3** (uncompute): in-loop tainted select is newly fp-reachable (no select
  analog of the d8jl `regionEntryInLoop` guard); per-iteration stream is
  faithful and matches pre-existing integer behavior. Owner decision filed as
  a follow-on (accept-with-per-iteration-semantics vs decline).
- Scope §5.9d pins added: `control_swap_reject_select_fp_in_routed_arm.ll`,
  `control_swap_reject_select_fp_in_specialized_callee.ll`.

## What HELD under attack (33+ spec claims, now probe-backed)

The §2 three-legged angle fence (all 12 angle-route probes declined: memory
store/load, inttoptr, vector insert/extract, fan-out, `cq_phi(%sel,%sel)`,
QROM carve, curated `llvm.fabs`, nested select, cross-function); the leg-3
backstop's two enabling invariants (`Tainted.insert(%out)`, `scrubTaint`
erases only the select) — confirmed in code and empirically; the basis
bit-pattern copy claim for theta-derived fp (NaN payloads / ±0.0 / f80
pseudo-denormals are labels, never a wrong unitary); fcmp mint/strip symmetry
incl. literal-on-left flips and unordered predicates; `copyControlledFn`
byte-identity + the 6.5 classical-call fp fixture green unmodified; the
`widthHasReversibleCopy` 7-site freeze; `isCopyOutSink`'s `_controlled`
exclusion against the new names; the f80 ABI end-to-end.

## Addendum — post-fix refute-default verification round (2026-07-03)

Second workflow (4 agents, ~630k tokens): three refute-default skeptics
attacking the D1–D3 fixes on the fixed tree (30+ probes, preserved under
`scratchpad/postfix-{skeptic,fable}/`) + the completeness critic that the
capacity limit killed in round 1.

**Held:** D2 (wire-anchored GATE 5) and D3 (call-crossing) survived every
evasion attempted — router-hidden Rz forward/backward, two-hop curated-call
coherence, call-wrapped theta (closed by the specialization guard),
deeper alias chains, cousin-wire forks. No over-decline: the diagonal
`cq_phi`-between-compare-and-select accepts, the chained-prep
`select(c, theta(theta(q)), x)` accepts (hand-IR and via `-O1`), and all
shipped select fixtures + e2e slices stayed green throughout.

**Broke through and FIXED (round 2):**

- **E1 — [blocker] GATE 2c router evasion.** A chained theta whose arg-0
  reaches the condition wire only through a one-register value-routing phi
  (the sanctioned lift shape; plain-C reachable at `-O1`), positioned BEFORE
  the compare, evaded all three prongs: prong (a) walked with
  `CrossValueRouting=false` (routers not crossed), prong (c)'s window starts
  at the compare, and the pass-wide stale-record guard excludes
  select-condition compares. Verify-clean stale mint reproduced in three
  spellings (hand-IR, sanctioned-lift `phi[%q, cq_phi(%q,·)]`, plain C).
  **Fix:** prong (a) now walks with `CrossValueRouting=true` — a router
  forwards the same physical handle. All three spellings decline; full suite
  green (no lift-shape over-decline). Fixture:
  `control_swap_reject_select_stalecond_phi_routed.ll`.
- **E2 — [major] fp `FreezeInst` mutate-then-CRASH.** A tainted fp freeze as
  select operand or in the condition provenance passed every gate; the theta
  RAUW-to-handle then left `freeze double %h` ill-typed and `opt` SIGABRT'd
  (134, broken module) instead of declining — a crash on valid input, newly
  fp-reachable through the gate-4 accept (fp freezes survive the 7.1-Inc-B
  escape-guard skip and, unlike integer freezes, are never folded). **Fix:**
  detection-time freeze fences — `taintedLineageHasFreeze` on each tainted
  operand and a `FreezeInst` scan of the condition's provenance set — decline
  `control flow` before any mutation. Fixtures:
  `control_swap_reject_select_fp_freeze_{operand,cond}.ll`.

**Confirmed adjacent, FILED (pre-existing, outside this change's blast
radius):**

- **E4 — [major → bd `tayx`, P1]** the identical router evasion in the
  sibling guard `ArmClassify::nonDiagonalGateBeforeBranch`
  (`CrossValueRouting=false` at ArmClassify.cpp:421): a routed phase-arm
  diamond emits over a stale flag (probe p11, exit 0). Pre-existing on the
  4.1 path; the kjd1 select mirror is fixed, the diamond fix needs its own
  Rule-13 clearance (also audit the same-flag callers in SwitchClassify /
  SwitchArmProve).
- **E5 — [RESOLVED, bd `4i7r`, 2026-07-03]** the fp-freeze wire-hop outside the
  select path (the dead-theta freeze-carrier spelling SIGABRT'd instead of
  declining). FIXED by `RotationLowering::declineFrozenWire`: a pre-RAUW module
  scan at the top of `lowerRotations` that loud-declines EVERY tainted non-i32
  `FreezeInst` ("cq rotation lowering: unsupported frozen quantum wire") before
  the cross-type RAUW-to-i32-handle can break it. The invariant is width, not
  fp: the runtime handle is ALWAYS i32 (Rule 15), so any tainted freeze at a
  non-i32 result type is un-launderable (integer non-i32 freezes already decline
  upstream at `declineTaintEscapes`; the four select/angle fp-freeze fixtures
  decline earlier at detection, so their brands are untouched — the guard runs
  strictly after `detectControlRegions`). Rule-13-cleared (6-lens adversarial
  workflow, ~860k tokens, 0 freeze-guard holes; before/after pass builds proved
  zero accept→decline regressions and the intended 134→decline flip). The round
  ALSO surfaced an ORTHOGONAL, pre-existing over-accept of the SAME class (a
  taint-gated guard missing an UNTAINTED non-i32 quantum-controlled value RAUW'd
  to an i32 handle) but via `ret`, not `freeze`: the Phase-6.5 classical-call arm
  accepts an i64 untainted merge phi (`int64_t y=5; if(q>3) y=f(a); return y;`)
  and SIGABRTs on `ret i64` — filed as bd `8mld` (P2, needs its own clearance;
  audit `SelectMergeEmit` / value-arm merges for the same ret-escape blind spot).

**Completeness critic:** §5 decline matrix 100% pinned with exact strings
(after adding the one gap it found — the §5.9c AbortPark fp leg, now
`control_swap_reject_abort_fp_cond.ll`); §4.1 doc-surface checklist and §7
ROADMAP/CLAUDE.md revisions all landed; §8 done-criteria met. Two recorded
notes: BreakReversePlay's scope coverage rests on the PRD §9 pre-review
verdict (opcode Add/Xor + `isIntegerTy()<=64` fence, LoopLowering.cpp:133-145
— no fixture this increment, per the PRD's own §3 tripwire for the
uncontrolled-copy follow-on), and §5-row-1's bitcast/freeze/nested-select
carriers stay pinned by the integer-era GATE-3 fixtures (the new fp fixture
exercises the fpext carrier + the fan-out rule).

## Postscript — the follow-ons landed (2026-07-03, bd tayx + 9ymx)

A third adversarial round (3 refute-default skeptics, ~470k tokens, 30+
probes) cleared the follow-up change set:

- **bd `tayx` FIXED**: `CrossValueRouting=true` at all four detection-time
  WireWalk sites (both ArmClassify sites, SwitchClassify G10, SwitchArmProve;
  the select was already true). The router-hidden pre-compare theta now
  declines on the phase-diamond and phase-switch paths (fixtures
  `control_swap_reject_stalecond_router_diamond.ll`,
  `control_swap_reject_switch_stalecond_router.ll`); the two value paths were
  already owned by the pre-detect `declineStaleRecordOps` backstop (pinned by
  the two `*_router_base_backstop.ll` fixtures). The round then found the
  claim-boundary hole: the **depth-2 nested phase path had NO stale-condition
  guard at all** (bypasses `classifyArms`; direct AND routed spellings
  verify-clean, plain-C-reachable — probe p16 family). Fixed with the
  per-level guard in `RegionTreeDetect` (flat-path mirror; fixtures
  `control_swap_reject_nested_stalecond_{direct,router}.ll`). Intended
  over-declines recorded: phi-mediated post-region theta spellings now align
  with their already-declining direct twins.
- **bd `9ymx` RESOLVED (owner: option (a), conditionals in loops allowed)**:
  GATE 2c's cross-block blanket decline removed (prong (a) — position-free,
  router-crossing — owns condition-wire staleness with no window; the dropped
  positional conservatism only ever covered other-wire thetas, which cannot
  move the condition basis). The N3 note above is thereby resolved: the
  in-loop select accept is documented as intended
  (`control_swap_select_inloop{,_hoisted_cond}.ll`, e2e
  `slice_control_select_loop` pinning the per-iteration contract). Skeptic
  verdicts: the relaxation and the in-loop physics CLEAR (per-iteration
  mint/strip valid, exactly one flag free per iteration, q never freed,
  dead out-rails leaked never freed dirty); one safe-direction asymmetry note
  (same-block other-wire thetas still over-decline via retained prong (c)).

**Final tallies:** 3 rounds, 35 agents, ~2.8M tokens, 90+ probes. 7 defects
found and fixed across the family (kjd1: D1–D3, E1–E2; tayx: the four-site
router flip + the guard-less nested path), `4i7r` (fp-freeze crash outside
select) and `52oi` (condition-width branding) filed and open, `9ymx` resolved
by owner decision. Every stale/phase fix is decline-monotone; the one
deliberate accept-widening (the 9ymx cross-block relaxation) was cleared by a
dedicated refute-default round. The full suite (623 lit + 60 ctest incl. e2e
goldens) is green post-fix. The un-staged fp accept surface itself survived
every attack on its own terms (angle fence, basis-copy physics, fcmp
mint/strip, scope containment, uncompute shape, f80 ABI).
