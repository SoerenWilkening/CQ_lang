# Lifted clones on main's stage list (bd p3kd.7.8): spike measurements

Status: historical spike followed by the reviewed implementation, 2026-10-07. Owner direction:
bd memory `owner-direction-clone-one-pipeline-2026-10-07`. Non-normative where
it disagrees with `NORTHSTAR.md`.

## What the spike wired

Branch `spike-p3kd78` (local, commit `f57a1757`, not for merge), on top of
`4c323c3c`. Inside `lowerCloneControl`, after the existing clone-mode PredMux
fixpoint and under the clone's own `cloneTaint`, it runs main's stages in main's
order: `unrollConstTripLoops` and `recognizeCtlzIdiomLoops` (each followed by the
PredMux fixpoint), `lowerLoops`, `unifyTaintedReturns` + `peelIndependentMergePhis`,
`detectControlRegions` + `lowerControlRegions`, `collapseFlattenedLoopRails`,
`repropagateControlMerges`. Re-propagation is the clone's param-rooted reseed
(`reseedCloneTaintFromParams`), the equivalent of main's `propagate(M, wd)`.
Two diagnostics were added: a loud decline when the Bennett wrap's capture
misses a `cqrt_*`/`cq_template_*` call (a gate it would not reverse), and env
knobs for the variants below.

Probe set: the 45 census probes whose first blocker on main is a clone-control
decline (44 `callee contains tainted control flow under quantum lift`, plus cbrtl
Q `bitcast i80`). Each probe is the census `source()` compiled by `tools/cqc
--emit-ll`; the spike's `cq-opt` lowers `probe.combined.ll`.

## Measurements

| variant | compile | reach the wrap | main control-chain decline | loop decline |
|---|---:|---:|---:|---:|
| A: stages off (= main today) | 0 | 0 | 0 (44 clone backstop, 1 `bitcast i80`) | 0 |
| B: stages on | 0 | 3 | 40 | 2 |
| C: B + deferred fp retype | 0 | 7 | 36 | 2 |
| D: C + main's PredMux mode (claimAll=false) in the clone | 0 | 7 | 36 | 2 |

Variant A reproduces main's first blockers probe for probe (the no-op control).
"Reach the wrap" means every stage accepted and the spike's capture check found
gates the flat-stream wrap does not reverse (`cqrt_alloc_i1` flags first).

Parity: the probe's direct libm callee inlined into `probe` (its own callees,
including the `alwaysinline` keep-set shims, kept as calls, as `cqc` does), lowered
by main's `cq-opt` at HEAD. Main compiles 7 of the 45 that way: cbrtl, ilogb,
ilogbf and nextafter/nextafterl/nexttoward/nexttowardf QQ. Six of them are among
the 7 that reach the wrap in variant C; the seventh there, nexttowardl QQ, fails
parity only through its nested nextafterl clone.

Of the 38 probes variant C still declines, 34 fail in main's control chain on
both sides: 24 with the same message, 5 with `nested control flow` on one side
and `control flow` on the other, 5 through a nested clone (scalbn/scalbnf/scalbnl,
nextafterl) whose own probe fails main's control chain. 3 have no direct callee
to inline (pow, powf, tanhl). One, nextafter QQ, compiles in main but not in the
clone: the clone's PredMux leaves at `E6-condtree` on the logical or
`select i1 %55, i1 true, i1 %56` that main's PredMux flattens (not explained yet;
bd p3kd.7.5's shape). A plain-C reproducer of the main decline is bd `dm7f.16`.

## Findings

1. **Main's stages run on a clone without a new mechanism.** The clone-only
   backstop declines become main's own control-chain declines. 34 of the 38 that
   remain also fail main's control chain with the body in the caller: they are
   main gaps (`dm7f.16`, loops under `8h7d`), not clone gaps.
2. **The flat-stream wrap cannot reverse what main's emitters produce.** When
   CondTreeEmit/SelectMergeEmit fire inside a clone they mint condition flags
   (`cqrt_alloc_i1`, `cqrt_toffoli`), controlled copies into an `%out` rail and
   their own inline strip and frees. The wrap captures only template producers,
   clone calls, QRAM loads and the clone-select sets, so it would drop these
   from the reversal. The premise "after main's stages the body is one block
   again, so the wrap keeps working" is false whenever an emitter fires. Reversal
   by main's `uncompute()` (copy-out before `ret`, params borrowed, `out`
   escapes) is the first commit that can gain a cell, not an optional second one.
3. **Q2 is load-bearing.** `cloneFor` retypes a tainted fp param to an i32 handle
   before any stage runs, which leaves ill-typed instructions in the body that
   main's stages read: `fadd i32 %0, %1`, `fcmp oeq i32 %0, %1`,
   `bitcast i32 %0 to i64`. PredMux then leaves at `E6-condtree` on the compare
   and at `E3` on every enclosing region. With a well-typed placeholder per
   retyped param during the stages (`call double @__cq_spike_fparg_f64(i32 %p)`,
   restored before the existing clone lowering continues), 4 more probes pass
   every stage (variant C).
4. **Q1 does not move a count today.** claimAll=true vs false in the clone changes
   no probe's class (C vs D). But main's own PredMux leaves classical control
   nested in a tainted region (`E6-classicalbr`), which the clone mode speculates
   since p3kd.7.2, so a clone accepts shapes main declines (`dm7f.16`).
5. **The clone's inner-call loop must skip runtime calls.** Main's emitters put
   `cqrt_*`/`cq_template_*` calls with tainted arguments into the body before the
   nested-lift loop runs; the spike crashed in `diagnoseReject` on such a
   declaration until the loop skipped them.

## Stages keyed on a `cq_theta` root

All 22 `ThetaCalls` uses in the stages' files are vacuous for a clone whose
`ThetaCalls` is empty: each is an early-out, a gate-call set used only on a
rotation path, or the theta functions collected to skip an angle operand while
spreading taint. The hazards are helpers that walk a value back and expect the
walk to end at a `cq_theta` call; for a clone the walk ends at a parameter.
None is a silent miscompile; each makes a param-rooted shape decline or skip a
lowering that main applies to a theta-rooted one.

| # | site | effect for a param root |
|---|---|---|
| H1 | `tryCaseA` (LoopLowering.cpp:3209) | a param-rooted loop-carried rail is never claimed as Case A |
| H2 | `railChainRootMint` / `railPhiRootMint` (LoopLowering.cpp:377-427) | null for a param, so `collapseRailPhisIn` leaves the header phi uncollapsed |
| H3 | `invariantRegisterRootsImpl` (LoopLowering.cpp:4744) | a loop that reads a tainted param directly returns `false` ("unclassifiable") |
| H4 | `isCondRailLeaf` (SelectClassify.cpp:635) | a tainted `i1` param is not a condition rail (only `cq_theta_i1` is) |
| H5 | `classifyConeNode` (PredMuxFlatten.cpp:639) | an Argument leaf needs `noundef`; `cloneFor` drops param attributes on a retyped param |
| H6 | `collectTaintedCalleeCone` (LoopUnrollPrepass.cpp:75) | the clone is not in the tainted-callee set, so its untainted constant-trip loops are not unrolled |
| H7 | the driver's re-propagation | `propagate(M, wd)` seeds only from `cq_*` calls; a clone must re-seed from its params |

H1-H3 decide the two loop probes (logbl, ilogbl) once their control-chain
decline is gone. H5 is one more reason to defer the retype (Q2).

## Questions for the owner

- **Q1. Classical control in a clone.** Recommendation: keep the p3kd.7.2
  speculation for clones now (it moves nothing either way, measured), and decide
  `dm7f.15`/`dm7f.16` for main as "speculation + rail select", the same
  mechanism. Then main and clones share one PredMux mode and the clone flag can
  be retired.
- **Q2. fp params.** Recommendation: defer the retype. The clone keeps fp params
  while main's stages run; the i32 handle replaces them only where main itself
  turns a value into a handle (before `lowerOps`). Teaching `CastLowering` or
  PredMux the `bitcast i32 to i<W>` and `fadd i32` shapes would make every stage
  read ill-typed IR.
- **Order.** Commit 1 = driver + deferred retype + reversal by `uncompute()` +
  the loud capture check, as one reviewed core change, because the driver alone
  gains no cell (variants B-D) and would ship the wrap's silent-drop hazard to
  every clone where an emitter fires. Or: commit the driver with the loud capture
  check first (zero cells, closes the hazard), then the reversal.

## Owner ruling (2026-10-07)

Defer the retype (Q2). Keep the p3kd.7.2 speculation for clones; decide
`dm7f.15`/`dm7f.16` for main as the same mechanism (Q1). Land the driver, the
deferred retype, the reversal by `uncompute()` and the loud capture check as one
reviewed core change. bd memory `owner-ruling-clone-pipeline-q1q2-2026-10-07`.

## Superseding reversal ruling and reviewed implementation

The owner subsequently required a mechanical Bennett mirror, superseding the
`uncompute()` recommendation above: main's uncompute spine does not reverse
ControlOwned merge rails. See bd memory
`owner-ruling-clone-reversal-mechanical-2026-10-07`. The single-block requirement
therefore remains a compiler gap under p3kd.7.9.

`StageList` now owns the loop prepasses and control-chain order used by both pass
entry points and `lowerCloneControl`. Clone speculation remains `claimAll=true`
under the Q1 ruling. The clone stays well typed while those stages run;
`retypeCloneSignature` then replaces masked FP arguments and re-keys the taint,
width, cache and mask records before data lowering. Clone-only condition-network
and select emitters were removed; p3kd.7.2's classical rail selects remain.

The wrapper elides owners' inline strips, captures the complete forward gate
stream, copies the result out, and emits each inverse in reverse order. Surviving
forward frees, adjoints or unrecognized runtime calls fail loudly. For a basis
label, each accepted gate is a phase-free permutation: retaining scratch changes
no result read before its owner's strip. After its last read, an omitted strip
writes only the scratch being retained. The argument also relies on owners
forbidding later reads after a scratch free; it is an optimization over these
emitters, not a general dead-call rule. The full mirror clears scratch before
free, preserves borrowed parameters and leaves the escaping result allocated.

The H1--H7 spike table describes risks, not grants to parameter roots. Review
confirmed conservative H1--H4 behavior, preservation of attributes through the
stages (H5), and parameter-rooted reseeding before emission (H7). H6's scope needs
a narrower statement: static unrolling can act on the reachable callee cone,
including an original nested callee, under its existing U1--U8 safety checks.
Prediction metadata cleanup is module-wide. These exceptions are now documented
in StageList rather than described as blanket clone-only mutation.

Deferred retyping also fixes the P0 width miscompile p3kd.7.10: the earlier
clone-select route used i32 controlled copies for some FP64/FP80 inputs. A
verify-clean IR and the coshl golden had concealed the truncated copies. The
reviewed golden changes use the logical FP width. Inverse literal slots retain
effective `zeroext`/`signext` through the shared inverse emitter.

Validation on the implementation branch: 39/39 live changed/new lit fixtures;
51/51 distinct scoped e2e slices (12 regenerated goldens plus 48 multi-TU slices,
nine overlapping). One mistaken lit filter selected zero tests before correction.
Mutation validation ran one passing no-op and three killed mutants: strip
elision removed, FP retype moved early, and the clone control chain skipped.
MISSED: 0/3. No behavioral source change followed green.

[Four independent adversarial rounds](clone-one-pipeline-review/README.md) each
accepted, with 6, 6, 6 and 2 fresh lowering executions. They cover H1--H7, aliased
borrowed parameters, late data reads of conditions, nested mirrors, FP signature
replacement and attributes, `inBennettClone`, and newly created/grown-mask round-2
clones. Invalid or blocked probes are identified in their reports and earn no
coverage credit.

## Full user-driver census after merge

Measured once at main `92e9f0ec` with
`python3 tools/library_coverage/runtime_census.py --output tools/library_coverage/runtime_census.json --jobs 6 --evidence-dir /tmp/p3kd78-census-evidence`:

| Provider | Before | After |
| --- | ---: | ---: |
| Source-injected | 24/120 | 28/120 |
| Intrinsic | 48/48 | 48/48 |
| Macro | 10/12 | 10/12 |
| Scalar total | 82/180 | 86/180 |
| Classical-only constructors (outside scalar total) | 3/3 | 3/3 |

Of 483 runtime-mixture probes, 362 accept and 121 decline; all accepted probes
pass the structural free check. Ten mixtures changed from decline to accept,
with no acceptance regressions. The newly complete cells are ilogb, ilogbf,
cbrtl and nextafter. nextafterl and nexttoward/nexttowardf/nexttowardl also gain
QQ acceptance, while their CQ mixtures still fail shared control lowering.
The FMA CCQ mixtures from `4c323c3c` accept at all three published widths.

Remaining first blockers: 43 body-construct/memory, 33 shared control (13 nested),
18 undef/poison returns, 14 argument/return ABI, nine frem source-lowering gaps,
two shared loop/control, and two macro unknown-callee failures. ilogbl/logbl
remain the two loop/control probes under p3kd.7.4 and 8h7d. The shared control
carriers in p3kd.7.3 and p3kd.7.5 are re-attributed to dm7f.15/dm7f.16; unresolved
i80/speculation and i1 rail-select conditions stay open behind those first
blockers. cbrtl's p3kd.7.6 and the P0 width bug p3kd.7.10 are fixed.

A read-only audit of the saved census IR, using the original library signatures,
checks 318 direct FP-parameter copies in 247 clone bodies/twins across 73
FP-bearing accepted probes: zero wrong widths. None of 29,943 clone frees names
a parameter. [Audit and validation evidence](clone-one-pipeline-review/validation/README.md)
records the exact scope. SelectMergeEmit's omitted const-zero-arm optimization
is filed as p3kd.7.11; its redundant copy accounts for some clone gate-count growth.
