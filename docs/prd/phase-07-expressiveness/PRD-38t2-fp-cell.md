# PRD — 38t2: fp-as-bitpattern memory cell (lift the f64 copy fence for cells)

**Status:** READY (correctness resolved 2026-07-07 — SOUND, no store-value fence; see §3).
**Branch:** `38t2-fp-cell` (off `main`).
**Parent:** iw81.4 (fp-data-vs-angle carve + fp-intrinsic family). **Rule-13 HIGH — frozen ABI.**
**Related memories:** `cqrt-copy-abi-invariant`, `fp-angle-fence-ordering-invariant`,
`7-5-inc2-shadow-store-shapes`, `7-5-inc3-provenance-matrix`, `7-5-qram-design-decisions`,
`7-5-qram-coherent-return-nocloning`, `g5gi-guarded-store-swapped-multi`,
`injection-census-fp-select-net-zero` (kjd1 fp-select precedent), `pointer-boundary-linearity-bennett`.

## 1. What this is

Today a tainted fp **data** memory cell (`double arr[N]; ... = arr[q]` at a tainted index) loud-declines
at `kMsgQramCell`, because the width gate `widthHasReversibleCopy` (OpcodeSupport.cpp:233) is the
integer-only set `{i1,i8,i16,i32,i64}` and `WidthDispatch::copyFn` null-guards on `isIntegerTy` — the
**f64 angle/data fence**. 38t2 lifts that fence **for memory cells** while keeping it intact for rotation
angles. The issue title's `cq_template_copy_f<W>` framing is **stale** (pre-dates the 7.5 as-built Shadow
model, which lowers cells via the hand-written `cqrt_qram_*` family, not a `cq_template_copy`).

## 2. Scope (owner decisions, 2026-07-07)

1. **Full fp cell family.** Lift the fence for BOTH the const-global QROM read path (`lowerQramReads`)
   and the mutable alloca Shadow store/load path (`lowerShadowMemory`). Widths **f16/f32/f64/f80**
   (mirror the kjd1 controlled-fp-copy set; f128 stays declined — no sound c_type on this x86-64 build).
2. **Guarded fp store IN scope.** Also add the fp twin of g5gi's `cqrt_qram_store_<W>_controlled` (+`_unc`).
3. **"Cell commits to basis."** No ported carrier/coherence fence on the store/load *value*; rely solely
   on the existing `declineTaintedAngle` (a cell value used as a rotation arg-1 angle still declines).
   → **This is the load-bearing correctness call.** See §3.

## 3. Correctness — the "cell commits to basis" precondition (GATING)

The settled store semantics (Bennett, `7-5-qram-design-decisions`) is **3W CNOTs**: `save primal→tape;
clear tape→primal; write val→primal`. Step 3 is a **CNOT-per-bit copy of `val`'s basis label** into the
cell (Rule 7: "a CNOT copies a basis label, not a phase"). For integers `val` is always basis-valued data
→ correct. For fp, `val` **can** be a coherent carrier (`double q = cq_theta(..); arr[i]=q;`), and the
store emit (QramLowering.cpp:1053-1054) passes a **tainted `val` straight through** with no carrier check.

**RESOLVED: SOUND — no store-value fence** (adjudication workflow `wh1ihef3b` → `OVER_DECLINE_SOUND` HIGH,
empirically confirmed by running the plugin on shipped integer fixtures; recorded in bd
[`38t2-fp-cell-commits-to-basis-sound`]). An initial soundness pass (`wx05zda84`) returned a HIGH-confidence
**false-positive** UNSOUND; it was mechanistically wrong and is a documented trap. The resolution:

1. **Parity.** The shipped, Rule-13-cleared **integer** Shadow store already stores a raw `cq_theta`
   superposition carrier (`lowering_qram_store_dead_lifo.ll`: `%h3=cqrt_ry` → `cqrt_qram_store_i32(arr,h,h3)`),
   and `cq_phi_si32` exists — so integers DO carry an Rz phase (the "integers can't carry phase" premise is
   false). An fp carrier store is the **physically identical W-bit CNOT-write** (handles are always i32;
   width only selects the symbol name).
2. **Faithful reversible QRAM.** A reversible store *is* a CNOT-based write; the emitted unitary == the gates
   the user wrote → correct-by-construction. A CNOT-copy of a carrier into a `|0⟩` cell **preserves** the
   phase in the joint amplitude (`a|00⟩+b·e^{iφ}|11⟩`); only the value's *local* reduced state goes mixed —
   entanglement, not phase loss. The never-freed entanglement is unobservable at a computational-basis
   measure (`7-5-qram-coherent-return-nocloning`: **measure is immune**).
3. **Frees fire only via `emitCopyOutIfDirectMeasure`** (load's sole user is a *direct* `cq_measure`,
   phase-blind). Any basis-rotation (chained `cq_theta` = in-place Ry, RotationLowering.cpp:207-209) or
   arithmetic between load and measure removes that precondition → no copy-out → the measured cone stays
   coherent. **Empirically:** the sharp discriminator (carrier→store→load-back→chained-Ry→measure) lowers to
   the forward gate stream with **zero frees, zero uncompute**; the dead endpoint runs `store_unc` *before*
   the carrier's `Ry†`/`free` (faithful Bennett order, not method-B).
4. **The one genuine hazard** (compiler dirty-free of an index entangled with a coherently-escaped load) is
   already fenced **width-agnostically** by `kMsgQramCohEscape`, which 38t2 inherits unchanged.

**LOAD-BEARING IMPL INVARIANT:** when lifting the fp width gate, keep the coherent-escape (`kMsgQramCohEscape`)
+ mid-seq (`kMsgQramMidSeq`) + memset-init (`kMsgQramInit`) guards + `declineTaintedAngle` ordered **before**
the fp emit — they currently sit *after* the width-gate early-return, so lifting the gate must NOT relocate
them. `declineTaintedAngle` stays the third-path fence (an fp cell value used as a rotation arg-1 angle still
declines — width-agnostic, already present).

## 4. Frozen ABI surface to add (runtime/cq_runtime.{h,c} + generator where applicable)

Widths `W ∈ {f16,f32,f64,f80}`. All handles i32 (Rule 15); width only selects the symbol name.

- `cqrt_qram_alloc_f<W>(i32 count) -> i32`
- `cqrt_qram_load_f<W>(i32 arr, i32 idx) -> i32`  + `_unc(i32 out, i32 arr, i32 idx) -> void`
- `cqrt_qram_store_f<W>(i32 arr, i32 idx, i32 val) -> void`  + `_unc(same args) -> void`
- `cqrt_qram_store_f<W>_controlled(i32 flag, i32 arr, i32 idx, i32 val) -> void`
  + `_controlled_unc(same args) -> void`  *(decision #2)*
- `cqrt_copy_f<W>(i32 src, i32 dst) -> void`  *(uncontrolled; for `emitCopyOutIfDirectMeasure` + the
  measure copy-out; the `_controlled` fp twins already exist from kjd1)*

These are **hand-written `cqrt_*` core** symbols (like the integer qram family + `cqrt_copy`), NOT the
generated YAML surface — so `gen_templates.py --check` stays clean (opcode_table.yaml untouched). Confirm
count assertions in the runtime/gen tests are updated.

## 5. IR-pass changes (width-gate lift + resolvers)

- **`WidthDispatch`:** `copyFn` — lift the `isIntegerTy` fence for the fp widths that have a `cqrt_copy_f<W>`
  (mirror `abiWidthHasControlledFpCopy`'s `{f16,f32,f64,f80}` set; keep i128/f128/unknown null). The
  qram resolvers (`qramAllocFn`/`qramLoadFn`/`qramLoadUncFn`/`qramStoreFn`/`qramStoreUncFn`/
  `qramStoreControlledFn`/`qramStoreControlledUncFn`) all carry the identical `> 64 / non-integer` fence —
  each must admit the fp cell widths. **Design a shared predicate** (e.g. extend/rename
  `widthHasReversibleCopy` or add `widthHasFpCellCopy`) so carve + emit + all resolvers can never diverge
  (the `matchQramAccess` single-accept discipline, `7-5-inc3-provenance-matrix`).
- **`OpcodeSupport`:** the cell width gate (`widthHasReversibleCopy` at QramLowering.cpp:761,898) must
  admit fp cell widths **without** widening the *integer-only* data-mux/select/switch/loop sites that also
  call `widthHasReversibleCopy` (7 call sites, 6 modules — see OpcodeSupport.h:95). **Do NOT** blanket-widen
  the shared predicate: the fp accept must be cell-local (a new `widthHasFpCellCopy` used ONLY at the two
  QramLowering cell gates), exactly as kjd1 kept `abiWidthHasControlledFpCopy` select-local. Audit every
  `widthHasReversibleCopy` caller for over-widen.
- **`QramLowering`:** the two `kMsgQramCell` gates (:761 QROM read, :898 Shadow) admit fp cells; the
  `emitCopyOutIfDirectMeasure` copy-out (`wd.copyFn(ElemAbi)`) now resolves for fp.

## 6. Spine re-audit (the runtime header §3 tripwires + Rule-13 core files)

- **ChainWalk `isCopyOutSink` (ChainWalk.cpp:77):** `starts_with("cqrt_copy_")` + `arg_size()==2` +
  no `_controlled/_inv/_unc` → **already admits `cqrt_copy_f<W>` for free.** No change; verify the fp
  copy-out is semantically the intended terminal (verdict-dependent).
- **LoopLowering `copyFn` null-fence (LoopLowering.cpp:138,845):** the `> 64` in-place fence is fp-orthogonal
  (`inPlaceValueRailOperand` requires `Add`/`Xor` on an integer; `fadd` is `FAdd` → never reaches). The
  `:845` `!wd.copyFn(RailWidth)` guard: with fp `copyFn` now non-null, confirm the loop rail path does not
  spuriously accept an fp rail (loop rails are integer today — verify fp stays declined at the loop path).
- **EmitInverse:** the dedicated `cqrt_qram_load_/store_[controlled_]unc` branches must mint the fp `_unc`
  decls inline from the forward call's own type (already type-driven, so fp rides for free — verify).
- **DagTraversal / Uncomputation:** fp qram store/load reversal reuses the integer spine (in-place gate +
  enqueue tainted operands); verify no integer-typed assumption on the store value.

## 7. Red-green fixtures (Rule 12 — positive + decline probe, message char-for-char)

- **Positive:** fp cell store/load lowers (`lowering_qram_fp_cell_store.ll` / `_read.ll` — flip the existing
  `lowering_reject_qram_fp_cell.ll`), guarded fp store (`lowering_qram_guarded_store_fp.ll`).
- **Angle-fence probe (MANDATORY):** `cq_phi(u, arr[q])` with an fp cell → **must still decline**
  `quantum-derived rotation angle` (declineTaintedAngle fires on the tainted load handle, despite
  lowerShadowMemory running before lowerRotations — the `fp-angle-fence-ordering-invariant` landmine).
- **Verdict-dependent decline probes:** any coherent-carrier store/load shape the verdict says must decline.
- **e2e golden:** an fp-cell slice (`tests/e2e/slice_qram_fp_cell`), byte-diff trace.

## 8. Done criteria

Fp cell store/load/guarded-store lowers via the fp `cqrt_qram_*`/`cqrt_copy_f<W>` family at f16/f32/f64/f80;
the angle-cell path STILL declines (fence preserved) with the mandatory adversarial probe; `ctest` green;
`gen_templates.py --check` clean; **independent Rule-13 clearance** (frozen ABI + spine/escape audit).

## 9. Rule-13 clearance outcome (2026-07-09 — 16-agent, 6 lenses + adversarial refutation)

**FOUND + FIXED at clearance — the type-pun over-accept** (2 independent lenses, 2 independent
verifiers, live probes): `matchQramAccess` derived `ElemAbi` solely from the ORIGIN array element
and never checked the memop's ACCESSED type, so `store float` through a `[8 x double]` gep
(`*(float*)&arr[q] = x` at `-O1`) **accepted** and emitted `cqrt_qram_store_f64` fed by an f32 rail
— a verify-clean wrong-width gate stream. Pre-38t2 the blanket integer-only width gate incidentally
fenced all fp puns, so the as-drafted diff was a decline→silent-accept flip; the same hole
PRE-EXISTED at integer widths (`store i32` into `[8 x i64]`). **Fix: the pun fence** — the accessed
type must BE the cell type (`matchQramAccess`, right after `matchAddressGep`) — closing both
families with one check; the un-matched tainted memop loud-declines at the pass-wide escape guards
(single-accept discipline: `matchAddressGep` has exactly one caller, so QROM/shadow/guarded/carve
are all fenced). Red-green fixtures: `lowering_reject_qram_pun_store_fp.ll`,
`lowering_reject_qram_pun_load_fp.ll`, `lowering_reject_qram_pun_store_int.ll`; a mixed
legit+punned same-array probe declines whole-module (no partial lowering).

**Test-gaps closed at clearance:** the §3 load-bearing guard-order invariant is now PINNED at fp
width (`lowering_reject_qram_init_fp64.ll`, `_mid_seq_fp64.ll`, `_coherent_return_fp64.ll` — the
fp coh-escape probe must launder through `fptosi`→`ret i32`, a naked `ret double` declines earlier
at the non-i32-width escape guard); the Shadow-path width gate got its own probe
(`lowering_reject_qram_fp128_shadow_cell.ll`); and the fp reversal + guarded families are now
LINK-proven by two new e2e goldens byte-parallel to the integer twins
(`slice_qram_local_uncompute_fp`: `cqrt_copy_f64` + `load_f64_unc` + `store_f64_unc` in Bennett
LIFO order; `slice_qram_guarded_store_fp`: `store_f64_controlled(+_unc)` with the
store-reverse-BEFORE-strip pred-lifetime invariant). `runtime/test_trace.c`'s stale "NO
UNCONTROLLED cqrt_copy_f16" comment refreshed. **Residual (ticketed, `3c6m.15`):** the f16/f32/f80
family members are lit-pinned but not yet link-pinned per width. Two review findings were REFUTED
(angle-probe path coverage; deleted-fixture supersession) — both verified as already-covered.
