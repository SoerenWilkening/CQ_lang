# PRD — Tainted fp-DATA `select` (un-staging §16.4)

> **Status:** revised (2026-07-02) after a pre-implementation adversarial spec
> review (47-agent workflow, 4 dimensions, refute-default verification; 1 blocker
> + 2 majors + minors folded in below — see §9). Supersedes the 2026-07-02
> proposed draft. Extends Phase-4.4 (`SelectClassify` / `SelectMergeEmit`).
> Tracked under the fp-data priority ([[fp-data-priority-iw81-4]]) and the
> 7.x-widenings tracker `8h7d`. **Copy mechanism: Option B** (real
> `cqrt_copy_f<W>_controlled` primitives) — owner decision 2026-07-02.
> **A Rule-13 core change** (the f64 angle/data silent-miscompile family).
> Implementing issue: `test_C_libtooling-kjd1`.

## 1. Motivation

The `openlibm` source-injection census ([`INJECTION-CENSUS.md`](../../../tools/library_coverage/INJECTION-CENSUS.md))
establishes two facts: off-the-shelf libm is blocked by tainted control flow at
scale and by scratch memory (Shadow), and **branchlessness, not integer-ness, is
what keeps functions lowerable** — the fp opcode/template surface itself already
exists (`fadd/fsub/fmul/fdiv/fneg` at `f16/f32/f64/f80` in
`tools/opcode_table.yaml`; "opcodes are not the blocker").

The following is **this PRD's own inference, not a census finding**: branchless
range reduction written as C ternaries reaches the pass as `select` at `-O1`, and
**integer `select` lowers today while fp `select` declines** — so un-staging
fp-DATA `select` removes the select-shaped remainder of the branchless path.
Scope honesty: the census's second blocker (scratch memory / Shadow width
coverage) is untouched here, and the census harness counts a function as
compiling only when **fully inlined** — fp select inside a non-inlined helper
still declines at Phase-6 specialization (`SpecializeReject::InBodyControl`,
`SpecializeReject.cpp:350-355`). This increment is necessary for the branchless
path, not by itself sufficient.

## 2. Why it is safe to un-stage (the safety foundation)

The fp→angle hazard is fenced by a **three-legged** mechanism —
type-agnostically, and (for leg 1) *before* the fp-data question:

- **Leg 1 — GATE 3 (angle fence, `selReachesRotationArg1`)** runs *before*
  GATE 4 (`SelectClassify.cpp:282` vs `:296`). It forward-walks the select
  **result** across value-preserving carriers **only** —
  `fpext`/`fptrunc`/`bitcast`/`freeze`/`phi`/nested-`select`-as-value-operand
  (`SelectClassify.cpp:105-114`) — and any arg-1 reach declines the WHOLE select
  (`rotation angle`, fan-out rule `:97-100`). Value-changing users are
  deliberately not crossed (see leg 3).
- **Leg 2 — the pre-detection escape guards** own the memory/call/opaque routes:
  a stored tainted fp value hits the QRAM verdict or `kMsgStore`; an unknown
  callee hits `kMsgUnknownCallee` (`TaintPropagation.cpp`). No fp value sneaks
  to an angle through memory or an un-analyzed call.
- **Leg 3 — `declineTaintedAngle`** (`RotationLowering.cpp:74-79`, message
  `quantum-derived rotation angle`) is the load-bearing **post-emission
  backstop** for everything GATE 3 does not walk: the select result re-realized
  through fp *arithmetic* (`fadd`/`fmul`/`fneg`), int↔fp domain casts
  (`fptoui`/`uitofp` chains), and the select's **operands** (which GATE 3 never
  walks) separately feeding an arg-1. These routes are **mutate-then-decline**:
  the select is emitted and erased first, then `opt` still exits non-zero,
  loudly (precedent: the 6.5 post-hoist declines). Two code facts keep this
  backstop sighted, and they are **pinned re-review triggers** for this and any
  future select change:
  1. `SelectMergeEmit` inserts the replacement `%out` into `taint.Tainted`
     (`SelectMergeEmit.cpp:130`), so derived users stay tainted;
  2. `scrubTaint` erases **only** the `SelectInst` itself (`:159`), never the
     derived producers — so `taint.Tainted.count(arg-1)` still fires in
     `lowerRotations`.
  (This is the iw81.4.a "pre-rotation RAUW blinds the backstop" landmine
  ([[fp-angle-fence-ordering-invariant]]) — checked here and found NOT to fire,
  *because of* those two facts. Do not weaken either.)

  **Caution:** the parent PRD's §16.2 narrative ("RAUWs the tainted `%sel` to a
  fresh UNTAINTED handle — the angle silently leaks", `PRD.md:1609-1618`) is
  **stale** versus shipped code and must not be reused as a clearance baseline.

So an fp `select` that reaches GATE 4 is not an angle *along any carrier route*
(leg 1), and every non-carrier route to an angle still declines loudly (legs
2–3) — with a **different diagnostic** than GATE 3's (see §5).

- **GATE 5 (coherence, `operandCarriesPhase` + `hasCoherentDownstreamUse`,
  `SelectClassify.cpp:306-310`)** walks lineage/uses, not types. An fp operand
  whose lineage includes an `Rz` (`cq_phi`), or that feeds a downstream
  rotation, still declines. A `cq_theta`-derived fp value (real-amplitude basis
  superposition of fp bit-patterns; `CQ.h` has fp-typed `cq_theta` variants
  incl. conditional f80) is the canonical accept, and the controlled-XOR (CNOT)
  copy of its **bit pattern** is a faithful *basis* copy (bits are bits; handles
  are `i32`, Rule 15).
- **GATE 6 (alias)** — type-agnostic.

**Classical-operand carve-out (state it so reviewers aren't alarmed):** the
accept path's `materializeCopySource` (`SelectMergeEmit.cpp:66-75`) will mint
the codebase's first classical-fp→rail allocation, e.g. `cqrt_alloc_f64(x)` for
the untainted operand. This is the established 4.4 copy-merge carve-out from
the §5.2 "never `cqrt_alloc` a classical operand" prohibition (no `_hl` copy
template exists), now extended to fp; it is legitimate **because** GATE 3 has
already proven the select is data — the materialized rail is a copy *source*,
never an arg-1.

**Parent-spec conformance (§16.4):** the parent PRD staged fp out "until the
§16.2 angle gate is cleared". That condition **is met**: `WI5_SELECT_CLEARANCE.md`
lens 2 (angle-gate airtightness, CLEARED 2026-06-16) plus the iw81.4.a fence-site
locks (2026-06-24, [[fp-angle-fence-ordering-invariant]]) — the WI5 verdict was
rendered over the *integer* accept surface, and §6 below discharges §16.4's
"independently cleared" clause for fp. Note an explicit **scope widening**:
§16.4 staged `{f32,f64}`; this PRD un-stages `{f16,f32,f64,f80}`. The widening
is justified by the existing `cqrt_alloc_f{16,80}` + fp rotation/measure ABI and
the `slice_f80` e2e host precedent (x86_64, real `x86_fp80`), but it is a
widening — not implied parity.

## 3. Scope — NARROW to `select` only

This un-stages fp-DATA **for `select` alone**. The identical "fp under tainted
control = categorically an angle" belief is baked into other sites; they **keep
declining fp**:

- `SwitchClassify` GATE 4, `ArmClassify` br-diamond value arms (`:853`, `:872`),
  `IOSinkLowering`, `AbortParkEmit`, `QramLowering` — **unchanged**; each has
  its own upstream type gate (verified per-consumer, §9).
- **`ClassicalCallArmEmit` (the 6.5 classical-call arm)** — the one consumer
  whose **only** fp fence is `copyControlledFn`'s null return (DD-7,
  `ClassicalCallArmEmit.cpp:102-113`, `ArmClassify.cpp:1184-1185`;
  `classifyClassicalCallArm` has no type/angle/coherence gate of its own).
  **This is why §4.2 keeps the shared minter fenced** (containment by
  construction). fp classical-call results **still decline**; the pinned fixture
  `control_classical_call_arm_reject_fp_result.ll` **must stay green**.
- `widthHasReversibleCopy` (integer-only; **7 call sites in 6 files**:
  `SelectClassify.cpp:297`, `SwitchClassify.cpp:296`, `ArmClassify.cpp:872`,
  `AbortParkEmit.cpp:287`, `IOSinkLowering.cpp:223`, `QramLowering.cpp:671`,
  `QramLowering.cpp:808` — i.e. 6 besides the select gate) — **NOT touched.**
  The select path gets a separate fp-aware predicate (§4.3).

Non-goals this increment: fp **value-arm** (br-diamond method-B) merges; fp
`switch`; fp vectors; the uncontrolled `cqrt_copy_f<W>` (no consumer yet — dead
ABI is forbidden). **Tripwire for that deferred increment:** when uncontrolled
`cqrt_copy_f<W>` is added, re-audit `LoopLowering`'s `wd.copyFn` null-fence and
`ChainWalk.cpp:76-78`'s `isCopyOutSink` prefix test (`starts_with("cqrt_copy_")
&& !contains("_controlled")`) — both start matching the new symbols the moment
they exist.

## 4. Changes

### 4.1 Runtime — Option B frozen ABI (`runtime/cq_runtime.{h,c}`)
Add **`void cqrt_copy_f<W>_controlled(i32 ctrl, i32 src, i32 dst)`** for
`W ∈ {f16, f32, f64, f80}` (controlled only — the select merge's sole consumer;
uncontrolled/`_inv` deferred to the fp value-arm increment to avoid dead ABI —
note the involution point in §7: "deferred `_inv`" refers to the *uncontrolled
copy family's* possible twin, NOT to a `_controlled_inv`, which can never exist).
Trace-only bodies identical in shape to `cqrt_copy_i<W>_controlled` — all three
args are `i32` handles; the fp width tags the symbol name only (Rule 15).

**Doc-surface checklist** — every in-tree statement of "fp merge under tainted
control is categorically an angle / no fp copy twins exist" must be rewritten in
the same commit (the new rationale: angle-fenced by the §2 three-legged
mechanism, so fp-DATA is legitimate for `select`; all other paths still decline):
1. `runtime/cq_runtime.h:9-16` (the header-top "NO cqrt_copy_f16 …" note);
2. `runtime/cq_runtime.h:253-256` (plain-copy block: "no f32/f64 twins exist
   (for the plain copy here nor the `_controlled` merge twin below)" — the
   second half becomes false);
3. `runtime/cq_runtime.h:283-284` (controlled block: "The 5 INTEGER widths only
   — same FP-is-an-angle reasoning", directly above the decls being extended);
4. `ir-pass/include/ControlledSymbols.h:70-73` + the twin comment in
   `ControlledSymbols.cpp:61-67` (adjust to name the new fp entry, §4.2);
5. `ir-pass/src/SelectMergeEmit.cpp:96-98` ("gate 4 already proved a
   scalar-integer ABI width" → "a scalar ABI width with a reversible/controlled
   copy");
6. `runtime/test_trace.c:157-163` (the f16 "has NO cqrt_copy_f16" note; also
   extend the trace test, §8);
7. `ControlledSymbols.cpp:88-89` (`tapeWriteControlledFn`'s "SAME integer-only
   fence as `copyControlledFn`" — reword so the two fences may legitimately
   diverge; tape keeps integer-only).
ROADMAP/CLAUDE.md items are enumerated in §7.

**Freeze:** these are new symbols designated frozen at the Phase-11 gate — §7.

### 4.2 Symbol minter (`ir-pass/src/ControlledSymbols.{h,cpp}`) — REVISED
**Do NOT relax `copyControlledFn`.** Its integer-only null-fence
(`ControlledSymbols.cpp:74-75`) is not mechanical plumbing — for the 6.5
classical-call arm it **is the live classifier** (DD-7): `classifyClassicalCallArm`
defers its fp/i128 RESULT gate to the emitter's null-check
(`ArmClassify.cpp:1184-1185`, `ClassicalCallArmEmit.cpp:102-113`). Un-nulling fp
there was empirically shown (review §9) to flip
`control_classical_call_arm_reject_fp_result.ll` from loud decline to full
silent lowering — including a phase-carrying straight-through operand
CNOT-copied with no `operandCarriesPhase` check anywhere on that path (the WI-3
dephasing family, verify-clean).

Instead add a **separate, select-local entry**:
**`ControlledSymbols::copyControlledFpFn(StringRef abiWidth)`** — mints
`cqrt_copy_f<W>_controlled` iff `abiWidthHasControlledFpCopy(abiWidth)` (§4.3),
null otherwise (f128 / unknown / anything non-fp). Called **only** from
`SelectMergeEmit` (§4.5). `copyControlledFn` keeps its fence verbatim, so no
other consumer's accept surface can move **by construction**.
(`tapeWriteControlledFn` and every other minter: untouched.)

### 4.3 New predicate (`ir-pass/src/OpcodeSupport.{h,cpp}`)
Add **`bool abiWidthHasControlledFpCopy(StringRef)`** returning true for
`{f16,f32,f64,f80}`. Used **only** in SelectClassify GATE 4 and (for the
null-check) SelectMergeEmit / the §4.2 fp minter. `widthHasReversibleCopy` stays
`intBits ∈ [1,64]`, untouched — its 6 other call sites (§3) must not change.

### 4.4 Classifier (`SelectClassify.cpp` GATE 4, lines 285–298)
Relax the fp decline: accept a **scalar** fp result (`isFloatingPointTy`, **not**
`isFPOrFPVectorTy` — fp vectors still decline) that has a controlled fp copy per
§4.3. Preserve the gate ORDER (GATE 3 before GATE 4 — the load-bearing
invariant). Continue to decline: fp vector, f128, pointer/aggregate, and integer
i128 (via the existing check). GATE 5/6 unchanged (they already handle fp
lineage).

### 4.5 Emitter (`SelectMergeEmit.cpp`)
No structural change to the six-step merge — it is width-parametric
(`abiWidthFromType` → `allocFn`/copy/`freeFn`). Select the copy minter by
result type: integer → `csyms.copyControlledFn(Abi)` (unchanged), scalar fp →
`csyms.copyControlledFpFn(Abi)` (§4.2); null → the existing loud decline.
Verify `allocFn(Abi)`/`freeFn()` resolve for fp Abi (they do:
`cqrt_alloc_f{16,32,64,80}` exist, `cqrt_free` is width-less). The rail alloc
`Constant::getNullValue(RailTy)` yields `double 0.0` etc., matching the fp alloc
signatures. The select→`%out` cross-type RAUW (fp select, `i32` handle) follows
the established handle-laundering house pattern (verify-clean; the
`control_swap_select_i8.ll` sub-i32 precedent) and the `%out`
taint/BirthOrder/ControlOwnedRails bookkeeping (`:130-132`) is width-agnostic —
do not alter it (§2 leg-3 invariants). **fcmp conditions:** the flag mint/strip
reuses `lowerCompareToFlag`, which handles FP predicates
(`compareInScope("fcmp", …)`, `ArmClassify.cpp:507-513`; `CompareLowering.cpp`
mints `cq_template_fcmp_<pred>_<W>_hl` and its `_inv`) — no emitter change, but
this is the **first accepted fcmp-minted select merge**; see the §6 fcmp lens.

## 5. Decline matrix (red-green — every one ships a negative fixture)

Diagnostic strings, character-for-character (Rule 12):
- GATE 3: `cq controlled lowering: rotation angle under quantum control`
- GATEs 2b/4/5/6: `cq controlled lowering: control flow under quantum control`
- Leg-3 backstop: `cq rotation lowering: unsupported quantum-derived rotation angle`

Must STILL decline:
1. fp value → rotation arg-1 (angle) through **carriers**
   (`fpext`/`bitcast`/`freeze`/nested select) — GATE 3, `rotation angle`.
2. fp select result → arg-1 through a **value-changing** step — one fixture per
   route, each mirroring the **leg-3 backstop** string (NOT the GATE-3 string),
   and each documented as mutate-then-decline (`opt` non-zero; the select was
   emitted first):
   a. `fadd`/`fmul` between select result and the angle;
   b. an int↔fp domain-cast chain (`fptoui`/`uitofp`);
   c. an ACCEPTED select whose tainted fp **operand** separately feeds
      `cq_phi` arg-1.
3. fp operand carrying an `Rz` (`cq_phi` lineage) — GATE 5, `control flow`.
4. fp operand feeding a downstream rotation (arg-0 wire) — GATE 5,
   `control flow`.
5. fp **vector** select (`<2 x double>`) — GATE 4, `control flow`
   (hand-written `.ll` fixture; `-O1` C rarely produces this shape — fine).
6. `fp128` / unknown width — GATE 4, `control flow` (no copy primitive).
7. aliasing fp operands (two `cq_phi` of one base) — GATE 6, `control flow`.
8. Q+Q select condition (incl. Q+Q **fcmp**) — GATE 2b, `control flow`.
9. **Scope guards** (no leak; each cites the fence that holds it):
   a. fp-data via **switch** (SwitchClassify G4) and **br-diamond value arm**
      (`ArmClassify.cpp:853/:872`);
   b. fp result of a **classical call under quantum control** — the existing
      `control_classical_call_arm_reject_fp_result.ll` **stays green
      unmodified** (fenced by the untouched `copyControlledFn` null, §4.2);
   c. IOSink / AbortPark / Qram fp — existing fences
      (`IOSinkLowering.cpp:223`, `AbortParkEmit.cpp:287`,
      `QramLowering.cpp:671/:808`);
   d. fp select **inside a specialized callee** → `SpecializeReject::InBodyControl`
      decline unchanged; fp select **inside a routed arm** → ArmClassify decline
      unchanged (`ArmClassify.cpp:890`).

Positive: `(q > 0.5) ? <theta-derived fp> : x` — the condition is an **fcmp**,
so the pinned ordered-FileCheck sequence is the full six steps:
`cq_template_fcmp_ogt_f64_hl` (mint) → `cqrt_alloc_f64` (rail) →
`cqrt_copy_f64_controlled` → `cqrt_x` / `cqrt_copy_f64_controlled` / `cqrt_x`
(¬flag bracketed, X encloses ONLY the second copy — §16.3 bracket order) →
`cq_template_fcmp_ogt_f64_hl_inv` (strip) → `cqrt_free`; angle fence intact;
`CHECK-NOT` any `cqrt_copy_i*` symbol.

## 6. Rule-13 clearance plan (a green suite does NOT clear this)

Independent adversarial review (analytic/trace reasoning; no simulation — owner
2026-06-10) on:
- **Angle-fence completeness** — reviewed as the §2 **three-legged** mechanism
  (not GATE 3 alone): carrier coverage, escape-guard coverage, and the leg-3
  backstop's two enabling invariants (`Tainted.insert(Out)`, `scrubTaint`
  scope). Fan-out: fp used as data AND angle at once must decline the whole
  select, never split.
- **Coherence for fp** — theta-basis accept vs `cq_phi`-phase decline; confirm
  the bit-pattern CNOT copy is basis-faithful for a `theta`-derived fp
  superposition and cannot dephase.
- **fcmp flag mint/strip** (new) — the first accepted fcmp-minted merge. The
  WI5 strip-disentanglement argument was phrased over `icmp`/`icmp_inv`
  (`WI5_SELECT_CLEARANCE.md:65-68`); extend it explicitly: strip determinism
  over the untouched fp operands for **unordered predicates** (`uno`/`ord`/`ueq`
  …), NaN and ±0.0 bit-pattern labels, and literal-on-left predicate flips —
  citing the br-diamond fcmp precedent (`control_swap_diamond_derived_f64.ll`),
  not silently extending the icmp-scoped WI5 verdict.
- **Scope containment** — fp does not leak into Switch / br-diamond value arms /
  **ClassicalCallArm (6.5)** / IOSink / AbortPark / Qram / BreakReversePlay;
  verify `copyControlledFn`'s fence is byte-identical pre/post change.
- **Uncompute-spine interaction** (new) — the fp out-rail rides
  `ControlOwnedRails` (DD-4, subtracted in `DagTraversal.cpp:125` /
  `Uncomputation.cpp:314`); the copy-source DAG is marked NotClosed by its
  `_controlled` user (`DagTraversal.cpp:179`), so **the theta-derived source
  lineage is deliberately LEAKED (no `_unc`, no free)** — assert this shape in
  the §8 golden, and verify `ChainWalk.cpp:76-78`'s `isCopyOutSink` name-pattern
  still excludes the new `_controlled` names (it does — by the `_controlled`
  substring; pin it).
- **f80 edge** — 80-bit rail alloc/copy/free trace-consistency (host is x86_64
  with real `x86_fp80`; `slice_f80` precedent).
Adversarial probe family per Rule 10 (not just the positive suite).

## 7. Freeze impact (owner-approved via Option B)

Adds `cqrt_copy_f<W>_controlled` (4 symbols) to the runtime core ABI —
**designated frozen at the Phase-11 gate** (phrasing per the 4.2 precedent:
"re-opens the Phase-9/11 freeze for exactly this one 4-symbol family"; no
executed freeze is being modified). **Adjoint story, recorded now so Phase 8
(`cq_invert` reverse-play) does not re-derive it:** a controlled-CNOT copy is an
involution — its inverse is **re-emission of the same call**, and no
`_controlled_inv` twin will ever exist; `EmitInverse::isInverseEmittable`
currently has **no** branch for `cqrt_copy_*_controlled` (all its branches fail
on it), which is correct-and-loud today but Phase 8 must add the self-inverse
re-emission branch (same class as `cqrt_x`/`cqrt_cswap`,
`EmitInverse.cpp:47`).

Exact statements to revise (not the 7.2–7.4 sentence alone — fp-select is a
4.4-extension under `8h7d`, so that sentence is only obliquely implicated):
- `ROADMAP.md` 4.2 entry (~`:468-473`): "the 5 integer widths only (an FP merge
  φ is an angle, never data) … re-opens the Phase-9/11 freeze for exactly that
  one 5-symbol family" → now a 5+4-symbol family, fp legitimate for select;
- `ROADMAP.md` Phase-7 posture (~`:795`, `:801-804`) and Phase-11 gate list
  (~`:1173-1178`): both "only pre-freeze items that add new frozen symbols"
  lists gain this family;
- `CLAUDE.md`: the "`8h7d` — freeze-orthogonal (7.2–7.4 add no frozen symbols)"
  rider and the freeze-gate sentence — `8h7d` now contains one
  frozen-symbol-adding item (this one);
- the §4.1 doc-surface checklist items (runtime header ×2, ControlledSymbols
  ×2, SelectMergeEmit, test_trace.c);
- parent `PRD.md` §16.4/§17 staging + fixture re-pin sentences (mark un-staged,
  cite this PRD).

Option A (bitcast→`cqrt_copy_i<W>`, zero frozen symbols, no f80) was the
alternative; owner chose B for a clean fp rail and f80 coverage.

## 8. Done-criteria (Rule 12 / 16)

- `ir-pass/test` lit fixtures: the §5 positive ordered-CHECK + the full §5
  negative matrix (each `RUN: not … | FileCheck` mirroring its diagnostic
  char-for-char, including the leg-3 backstop string for matrix item 2), and
  the §5.9 scope-guard set green **unmodified**.
- ≥1 e2e golden smoke (a branchless fp `select` slice through the full
  pipeline), whose golden **asserts the §6 uncompute shape** (out-rail kept,
  source lineage leaked — no `_unc`/free for the copied theta-fp chain).
- Runtime archive rebuilds; `runtime/test_trace.c` extended with the four
  `cqrt_copy_f<W>_controlled` calls (appended after existing handles so h-IDs
  stay stable, per the f16 precedent) and `test_trace.expected.log`
  **deliberately** regenerated (Rule 12: never by reflex).
- §4.1 doc-surface checklist + §7 ROADMAP/CLAUDE.md revisions land in the same
  commit.
- Rule-13 clearance recorded (§6) before commit.

## 9. Review record (2026-07-02)

Pre-implementation adversarial review: 4 ground-truth extractors, 4 attack
dimensions (angle-fence, coherence/emitter, scope-containment,
process/freeze/docs), 2 refute-default verifiers per finding, completeness
critic (47 agents). Outcome: 1 blocker (the §4.2 shared-minter relaxation —
empirically shown to flip the 6.5 fp fixture to silent lowering; fixed here via
the select-local `copyControlledFpFn`), 2 majors (§2 restated as the
three-legged fence with pinned backstop invariants; §7 re-targeted at the
actually-falsified freeze statements), and the minors folded into §§1/3/4.1/5/6/8.
33 attacked claims **held**, including: gate order, the GATE-3 carrier set,
GATE 5/6 type-agnosticism, the fp runtime surface (`alloc f16–f80`, width-less
free), §4.3's isolation decision, §4.4's scalar-only accept, §4.5's
width-parametric emitter + fcmp mintability, per-consumer scope fences for
every path named in §3, and the leg-3 landmine NOT firing. Break-reverse-play
was verified separately fenced (opcode Add/Xor + `isIntegerTy()<=64`,
`LoopLowering.cpp:133-145`) — no fixture needed this increment; see the §3
tripwire for the uncontrolled-copy follow-on.
