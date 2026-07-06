# Issue kmdc — FP select in a lifted clone (5po2 fp widening) — design + Rule-13 record

`test_C_libtooling-kmdc` (discovered-from `5po2`) · branch
`dugh-repropagate-control-merge`. Extends 5po2 (integer select in a Bennett-wrapped
specialization clone) to the **fabs-shape FP two-arm select**, so user `int→int`
helpers whose fp is purely internal scratch lift. Canonical target:

```c
int mhelper(int n) { double x=(double)n; double a=(x<0.0)?-x:x; return ilogb(a); }
```

which `clang -O1` gives as `select(icmp slt n,0, fneg x, x)` feeding the libm
producer `ilogb` (i32 return).

## Why it is SAFE — no angle fence needed inside a clone

The top-level fp-DATA select (kjd1) needs a **three-legged angle fence** because a
top-level fp value can flow into a rotation *angle* (arg-1 of `cq_phi`/`cq_theta` —
the f64/angle silent-miscompile family). **Inside a specialization clone that
hazard is structurally absent**, on two independently-verified pillars:

- **Rotation-free body** — a clone is a copy of a callee that passed `scanBody`,
  which rejects every `cq_theta`/`cq_phi` as `QuantumPrimitive`
  (`SpecializeReject.cpp`); and `buildClone` never calls `lowerRotations`. So a
  clone body contains **zero** rotation instructions → **zero** rotation arg-1
  angle slots for an fp value to reach. All three fence legs are **vacuous** here.
- **No fp boundary crossing** — the clone return is gated to i32
  (`RetW == "i32"`; an fp-returning clone declines `FpAbi`, verified live), so no
  fp value crosses the clone boundary toward a caller angle; even the returned i32,
  if steered toward a caller rotation angle, is caught by the pre-existing
  `taintedAngleGate`.

fp-select-in-clone is therefore **strictly safer** than the top-level fp select
kjd1 already ships. **Load-bearing preconditions (re-review triggers):**
**R1** the `RetW=="i32"` return gate must stay in force (it confines fp to
clone-internal scratch); **R2** `scanBody` must keep rejecting rotations. Relaxing
either re-arms the f64/angle miscompile family with no clone-local guard present.

## The mechanism

Scoped tight (Prime Directive; first slice): **`isLiftableFpSelect`**
(`SpecializeReject.cpp`) — scalar fp result in an **explicit `{f32,f64}` whitelist**
(NOT `abiWidthHasControlledFpCopy`, which also admits f16/f80 with no coverage;
f128/vector fall out via `isFloatingPointTy`), an **integer `icmp`** condition (the
fabs sign test folds to `icmp slt i32`; `fcmp` clamps deferred), and **both arms
non-constant** (the fabs `fneg x` / `x`). Shape gate only.

**`lowerCloneSelect`** fp branch (`Specialization.cpp`) — re-proves the condition
AND **both** arms tainted (all-classical → left for the backend; **mixed → loud
decline** `"mixed classical/quantum fp select under quantum lift"`), then emits the
full 4.4 stream with the flag kept **live** for the Bennett reverse:

```
flag = cq_template_icmp_slt_i32_hl(n, 0)     ; kept live
sel  = cqrt_alloc_f<W>(0.0)                   ; fp |0> rail
cqrt_copy_f<W>_controlled(flag, arm_T, sel)   ; copy_T  (out ^= flag ? T : 0)
cqrt_x(flag) ; cqrt_copy_f<W>_controlled(flag, arm_F, sel) ; cqrt_x(flag)  ; copy_F on ¬flag
```

fp copy via `copyControlledFpFn` (selected by `isFloatingPointTy`; the integer
`copyControlledFn` null-fence is **untouched**). Tainted arms are threaded **as-is**
(fp-typed) and become well-typed i32 handles when the later `lowerOps` RAUWs their
`sitofp`/`fneg` producers — the deferred-RAUW the top-level 4.4 emitter also relies
on. `EmitInverse` needs **no change** — its `cqrt_copy_<W>_controlled` involution
is width-agnostic and `cqrt_x` is self-inverse.

### The CONFIRMED hazard + its mitigation (red-green proven)

The two `¬flag cqrt_x` brackets are **not** `cq_template_*` calls, so
`isForwardTemplate` does not capture them. Without a dedicated capture they are
**dropped from the Bennett reverse**, which then replays `[copy_F, copy_T]` at the
wrong polarity → `out = arm_T ^ arm_F ≠ 0` → `cqrt_free(sel)` frees a **dirty fp
rail** (a Rule-6 hidden measurement), **verify-clean**. Mitigation: a new
**`SelectXBrackets`** capture set → ForwardStream-only. Proven by red-green: with
the capture disabled the clone shows only **2** `cqrt_x` (reverse pair missing) and
`spec_accept_fp_select_body.ll` fails; with it, **4** (palindrome) and it passes.

## Verified

- **e2e golden** `e2e-slice-specialize-fp-select` — the fabs helper, source-injected,
  links + byte-diffs the palindromic trace (both `cqrt_x` brackets present in
  forward AND reverse; all five scratch rails freed on |0>). First golden to
  exercise fp-select-merge + a libm producer together.
- **Lit** accepts `spec_accept_fp_select_body.ll` (f64, ordered forward+reverse
  palindrome + `CNT-COUNT-4 cqrt_x`) and `spec_accept_fp_select_f32_body.ll`;
  declines `spec_reject_fp_select_{return,fcmp,f80,mixed,const_arm}.ll`.
- Adds **no new frozen symbol** — reuses the kjd1-frozen
  `cqrt_copy_f{16,32,64,80}_controlled` family. No freeze-gate impact.

## Rule-13 clearance

Perspective-diverse adversarial verification workflow (reversibility/dirty-free,
over-accept boundary, fp-semantics/emitter lenses + a synthesis judge that
independently re-derived and executed the clone).

**Verdict: CLEAN — no verify-clean silent miscompile in the accepted shape.**
All three lenses found zero holes; the judge dismissed seven probed hazards each
with a file:line reason and confirmed by execution (all fixtures + full ctest
71/71 + own Q+Q / broader-cbrt / nested-fan-out probes).

| Lens / probe | Result |
|---|---|
| Dropped-bracket → dirty free / **hidden measurement** | **safe** — the two `¬flag cqrt_x` are captured into `SelectXBrackets` → ForwardStream (`buildClone`); `emitInverseChain` reverses op-by-op in exact reverse program order, re-emitting `cqrt_x` / `cqrt_copy_f<W>_controlled` as width-agnostic self-inverses → an exact palindrome that zeroes the fp rail (and every scratch rail) before its free. Red-green proven + the accept fixture's `CNT-COUNT-4` pin + broader (4×) and nested (8×) probes. |
| Angle reaches a rotation arg-1 (f64/angle family) | **safe** — the clone is provably rotation-free (R2), and R1 (i32 return) blocks fp from escaping toward a caller angle; the kjd1 three-legged fence is genuinely vacuous here. |
| Dephasing a superposed input (Rule 7) | **safe** — a rotation-free clone is a pure reversible permutation oracle; the XOR merge creates no phase, dephases nothing, frees no dirty/entangled rail; only the basis-valued result escapes, correctly entangled with the borrowed input. |
| Fan-out / nested-select double-uncompute (Rule 8/10) | **safe** — the Bennett wrap reverses OPS not VALUES, each op once, freeing scratch only after the complete reverse; a fanned-out source is uncomputed once and outlives every consumer's inverse (nested probe: perfect LIFO, verify-clean). |
| Q+Q icmp condition | **safe** — `lowerCompareToFlag(qqWidth={})` Q+Q bail diagnoses + returns null BEFORE any mutation; `lowerCloneSelect` continues before the Out alloc → zero partial emit (probe: loud exit 1). |
| Shared-condition two selects (nested-merge UAF class) | **safe** — the compare is erased only under `use_empty()`; the program-order snapshot keeps a shared compare alive until its last select-user is gone. |
| Deferred-RAUW mistyped fp copy operand | **safe** — a residual fp operand is a LOUD `opt -verify` type error, never verify-clean; and `scanBody`'s accept set ⊆ `lowerOps`' lowered set, so every tainted fp arm producer is RAUW'd to an i32 handle. |

**Residual preconditions (re-review triggers):** R1 the `RetW=="i32"` return-ABI
gate; R2 `scanBody` rejecting `cq_theta`/`cq_phi`; R3 the `{f32,f64}` width
whitelist is deliberately tighter than `copyControlledFpFn`'s `{f16,f32,f64,f80}`
(the sole width fence — widen only with matching runtime + e2e coverage); R4 the
accept-set ⊆ lowered-set invariant the deferred-RAUW depends on.
