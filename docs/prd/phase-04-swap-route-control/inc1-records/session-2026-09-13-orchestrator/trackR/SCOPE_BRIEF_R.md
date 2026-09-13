# SCOPING brief — Track R: F2's collider set EXCLUDES the peel's compare CLONES — bd `rb9x` — and whatever `vd`'s b0-prep F2 decline actually is

Written 2026-09-13 by the orchestrator. Model: opus. **READ-ONLY, measure-first.** No build, no suite; the
per-probe pipeline on the ORACLE only. Protocol: `../PROTOCOL.md` (your row is "scoping"). Record: `SCOPE_R.md`
beside this file; probes under `probes/` with `README.md` + runner. Final message ≤40 lines.

## 0. What is known (MEASURED; do not re-measure, extend)

* bd `rb9x` (read `bd show rb9x` incl. the NOTES correction): a `bool` STATE PREP under an `int` COMPARE condition
  in a FUSED (peeled) diamond declines `state prep seed is proven equal to the condition register under quantum
  control`. The integration review (`../../session-2026-09-11-orchestrator/review_integration.md` §4 I-1) BISECTED
  it to ONE instruction: b6ap's peeled compare CLONE (`MergePhiPeel.cpp:481-493`, `Instruction *Clone =
  S.CondCmp->clone(); … taint.Tainted.insert(Clone)`), not the region's own compare — `HP_f_nopeel.ll` ACCEPTS,
  `HP_g_sel_only.ll` (clone alone, no select) DECLINES; all 3 predicates; plain C `P1` accepts / `P2` (one
  peelable φ) declines; same for seed `true`. Probes: `../../session-2026-09-11-orchestrator/review_integration_probes/{HP_*.ll,P1_*,P2_*,P1t_*,P2t_*}`.
  **The reviewer did NOT finish isolating BY WHICH ROUTE the clone reaches the collider set** — it is defined
  AFTER the branch so the LVI dominance filter excludes it from the backward half; it is reached some other way.
  That isolation is your first job.
* `../probes/vd.c` (N=3 bools) declines `vd.c:10:14: … state prep seed is proven equal to the condition register
  under quantum control` — the `!dbg` is the **b0** theta (line 10). `-O1` hoists region 1's `a`-mux into the
  entry block as `select i1 %1, i32 2, i32 5`, so the diamonds re-shape. WHICH region is being classified when
  this fires, and WHICH value is the collider? Name it with `CQ_CTRL_DBG=1` and by reading
  `f2SeedPinnedByLiveRegister` (`ArmClassify.cpp:1442`; the ONE `CondWire` test at `:1616`; `CondWire` built at
  the caller `:3273` region by calling `railWireClosure(Region.Condition, BackwardOnly, …)` over `condProvenance`).
  Is it rb9x's clone collider, or a NEW F2 collider (a select-folded mux value, a sibling prep's theta, …)?
  This decides whether Track R's increment makes `vd` compile once Track M lands, or whether `vd` needs a second
  F2 narrowing — and the two are DIFFERENT arguments.

## 1. What to measure and write (SCOPE_R.md sections)

**§0 Verdict table, ≥20 probes on the ORACLE**: the four integration-review programs re-run (they are the
baseline); `vd.c`; `vd` with the third region removed (= the owner's file — declines `control flow`, Track M's
wall — confirm); `vd` with `int b0`; `vd` with all-`int`; `vd` with line 99 removed (does the b0-prep F2 decline
survive? this separates the vd collider from the select wall); the rb9x shape with the clone's predicate varied;
a bool prep under an int compare beside TWO peelable φ; the clone's operand being a chained theta; the
un-peeled twin of each (the control); the rival that F2 exists to refuse — `bool c = (b0 == 1); if (c) b1 =
cq_theta(c, .5)` (must STILL decline after any narrowing; record its string today, `condition data use neither
escaped nor measured` per the bd) and its `-O1`-folded form. Every DECLINE row carries the `CQ_CTRL_DBG=1`
anchor (which value LVI/forward-eval pinned, on which edge).

**§1 The route.** Read `f2SeedPinnedByLiveRegister` end to end (`:1442-1640` region) and its caller: the LVI
anchor set, the forward abstract evaluation (`ConstantRange`/`ConstantFold`/`KnownBits`), the candidate
enumeration — and state, with a line number, the exact step at which the peel's clone enters the candidate set
(hypothesis to test first: the FORWARD evaluation seeds from `CondWire` members and walks USERS of the condition's
operands — the clone is a user of `%1`, an `i1` of the seed's type, and folds to a constant on the edge). Then
the same for `vd`'s collider.

**§2 The design.** The bd's fix sketch: exclude from F2's collider set the peel's clones AND any `i1` the
condition-tree grammar derives from `Region.Condition` (the condition VALUE re-spelled) — on the 2026-09-11
argument (every unfolded rival that rotates the condition value under its own control is refused elsewhere: 2c
16 / F1 5 / condition-data-use 5 / l4x4 1 / R4 0, measured in `session-f2-i1`). Two spellings to cost: (i) a
`taint.PeelClones` record written by `peelIndependentMergePhis` at the clone site and consulted at the `:1616`
test — a RECORD, the L1 pattern; (ii) a structural test "a tainted `icmp` whose operands are byte-identical to
`Region.Condition`'s" — a second spelling of "the same compare", which Rule 14 dislikes; say which and why. If
`vd`'s collider is different, a THIRD item with its own argument, or a recommendation to file it separately.
State the RETIREMENT TRIGGER the exclusion inherits from F2's own header (`ArmClassify.cpp:1283`: if
`railWireClosure` as called by F2 diverges from R4's `CondRails` …).

**§3 Hazards.** Over-ACCEPT direction only matters: can excluding the clone admit a program whose UNPEELED twin
declines? (It must not — the clone is by construction the same compare on the same wire; but a clone whose
region is NOT the prep's region — two peels from two diamonds in one function — is a different compare; measure
whether `MergePhiPeel` can produce a clone of a DIFFERENT region's condition that lands in this region's
candidate set.) The `MergePhiPeel.cpp:459-466` comment is FALSE as measured and must be rewritten by the
implementer — draft the corrected paragraph. The F2 audit's 27-rival table (`session-f2-i1/probes`) re-run
against the proposed exclusion by reading (which rivals are caught ONLY by F2 today? if any, the exclusion
cannot go in).

**§4 Decline partition; §5 fixtures (the DECLINE→ACCEPT flip of the rb9x fixture family — find every
`control_peel_*`/`control_inplace_ry_stateprep_*int_cond*` fixture that pins the CURRENT string and list which
flip; the rival pinned as a decline), the e2e slice (`slice_control_cascade_three_bools.c` = `vd.c` — AFTER M
lands; its golden cannot be read off the ORACLE, say what it will be by composition), cost, 1–2 review rounds.**

**§6 The M dependency.** `vd` needs BOTH Track M (the select on the prep φ) and Track R. When Track M's branch
has a binary the ORCHESTRATOR will hand you its path + hash in a follow-up message; measure `vd` on it ONCE and
add the row. Do not build M's branch yourself.

Style models: `../../session-boi6/SCOPE_boi6.md`, `../../session-f2-i1/IMPL_f2.md` §1 (what F2 is), the
integration review §4 I-1. Line numbers dated to 86c0d25.
