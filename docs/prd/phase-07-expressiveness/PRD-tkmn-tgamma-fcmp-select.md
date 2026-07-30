# bd `tkmn` Increment 1 — the fcmp-conditioned fp select in a specialized clone

**Status:** Inc 1 SHIPPED. Moves **zero census cells** (by design — the target cell has
further layers) and **advances exactly the 2 target cells**. The lever as a whole is
**BLOCKED pending an owner decision**; see §5.

**Branch:** `3c6m.14-control-l6` · **Date:** 2026-07-30 · **Epic:** bd `tkmn`
(discovered from the now-CLOSED bd `20xt`).

---

## 1. Scope

ONE hunk in `ir-pass/src/SpecializeReject.cpp::isLiftableFpSelect` — the Phase-6
SPECIALIZATION shape gate deciding whether a `select` inside a classical callee body may
be lifted into a quantum clone. It required an `ICmpInst` condition; it now also admits an
`fcmp`.

No emitter changed. No frozen symbol added (the fcmp template grid — 14 predicates ×
{f16,f32,f64,f80} × {fwd,inv,unc} × {hl,qq} — was already shipped and frozen; this
increment only lets the existing grid be reached from this gate).

**Explicitly NOT in scope** (owner instruction): the loop at `b_tgamma.c:200` and the
self-recursion at `b_tgamma.c:309/311`. Neither was touched, and — see §4 — neither turns
out to be the next blocker anyway.

## 2. The blocker, PINNED (not inferred)

The census cells `tgamma.f64` + `tgammaf.f32` are ONE lever: `tgammaf` is literally
`(float)tgamma(x)`, and both decline with the same diagnostic naming the same function
(`in function tgamma double (double)`), proving the shared body.

First blocker at the O1 census floor:

```
error: /private/tmp/openlibm/bsdsrc/b_exp.c:171:14: in function tgamma double (double):
       cq specialization: callee contains tainted control flow under quantum lift
```

Source: `return( isfinite(x) ? scalbn(1.0,5000) : x );`. At `-O1` clang **if-converts**
this to a straight-line `select` — so there was no control-flow work here at all:

```llvm
%.inv.i        = fcmp one double %273, 0x7FF0000000000000
%spec.select.i = select i1 %.inv.i, double 0x7FF0000000000000, double %273
```

`double` result (already in the width whitelist) and const/value arms (already admitted by
the bd `20xt.3` materialize-classical-arm widening) — the **fcmp condition was the sole
failing clause**.

**HOW IT WAS PINNED.** By instrumentation, not by reading the message: both
`SpecReject::InBodyControl` origins and all three `diagnoseReject` call sites were tagged
with distinguishing suffixes and the plugin rebuilt in a throwaway worktree. Result:

```
[origin=B-select@511(nonICmpCond=FCMP) caller=SpecializeDetect]
```

then corroborated INDEPENDENTLY of that global by locating `!dbg !775` (line 171, col 14)
in the inlined IR and reading the instruction directly. **The inherited ticket was wrong
about the emitting site** — it named `Specialization.cpp:532 or :877`; the actual caller is
`SpecializeDetect.cpp:130`. This is the third consecutive increment in which the ticket was
wrong about its own root cause; budget for it.

## 3. Why this is safe

* **Angle safety.** A clone body is provably **rotation-free** — `scanBody` rejects every
  `cq_theta`/`cq_phi` as `QuantumPrimitive`, and `buildClone` never lowers rotations — so
  there is no rotation arg-1 angle slot for a compared fp value to reach, and kjd1's
  top-level gate-2c stale-condition wire guard is **vacuous** here rather than merely
  unlikely. RE-VERIFIED at this increment against the source, not inherited from a comment.
* **The emitter was already fcmp-capable.** `mintCondNetwork`'s leaves are generic
  `CmpInst`s lowered by `lowerCompareToFlag`, whose family stem is literally
  `IsFp ? "fcmp" : "icmp"`.
* **The added fences are DEFENSE IN DEPTH, and the PRD says so rather than overclaiming.**
  Measured: an `fcmp olt fp128` condition declines `(unsupported width)` and an `fcmp true`
  condition declines `(unsupported compare predicate)` — **both at `scanBody`'s data-op
  whitelist**, which reaches the condition compare as an instruction in the body before the
  select gate is consulted. The clauses are kept so `isLiftableFpSelect` is self-contained
  rather than silently coupled to another gate's reachability.
* **Bennett parity** (standing owner instruction): the emitted stream is `fcmp` compare
  templates plus `ifelse`-style predicated copies. Bennett.jl (rev `e15ea23`, full 433-file
  clone) ships `soft_fcmp_*` and uses `ifelse` predication as its own branch mechanism. No
  parity inversion.

## 4. Result — MEASURED on three surfaces

| surface | result |
|---|---|
| (a) full census, both plugins, 123 cells | **0 status changes**, injection-covered **97 → 97**; exactly **2 diagnostics moved** (the 2 target cells) |
| (b) all 934 ir-pass fixtures, both plugins, exit code AND emitted IR | **1 exit-code diff** (the deliberately converted pin), **0 IR diffs** |
| (c) e2e goldens (full `ctest`) | see the tracker comment for the run of record |

Both target cells **advance**:

```
tgamma.f64 / tgammaf.f32
  before: tgamma double (double): … tainted control flow …      @ b_exp.c:171:14
  after :    sin double (double): … non-reversibilizable construct (unsupported instruction)
```

## 5. THE STRATEGIC FINDING — the lever's layer order was wrong, and layer 2 is expensive

The ticket predicted the layers behind the fcmp select were (i) the `b_tgamma.c:200`
statically-bounded fp-induction loop and (ii) the depth-1 self-recursion. **Neither is the
next blocker.** Measured (instrumented `scanBody`):

```
CQ_SPECREJ_DBG: unsupported instr in @sin : %2 = alloca [20 x i32], align 16
```

That is `iq[20]` from `__kernel_rem_pio2` — the **Payne–Hanek** scratch — inlined into
`sin`. It is reached because `neg_gam` (the `x < 0` reflection branch) calls
`sin`/`cos` at `b_tgamma.c:290/292`.

The ticket's claim that this path is **mathematically dead is CORRECT**: `z = ceil(x) - x`
then folded to `z ∈ [0, 0.5]`, and `sin` is called only under `z < .25`, so the argument
lies in `[0, π/4)` — far below the threshold at which `__ieee754_rem_pio2` enters
`__kernel_rem_pio2`. But **`scanBody` scans the whole body regardless of reachability**, so
the compiler cannot use that fact. The ticket listed dead-path pruning as one of four
co-equal sub-levers; it is in fact the **immediate** next blocker, ahead of both the loop
and the recursion.

**Consequence — and this is the owner decision.** Flipping `tgamma.f64`/`tgammaf.f32`
requires ONE of:

1. **fp-range dead-path pruning** — prove `M_PI*z < π/4` through `ceil`/`fsub`/`fmul` and
   DCE the Payne–Hanek path. A genuinely new capability (fp interval analysis), reusable,
   cost unknown and probably not small.
2. **Lowering the Payne–Hanek body** — this is the *source form* the 9 `sin`/`cos`/`tan`
   cells are **decided-decline** for (owner ruling 2026-07-27/28). Out of scope by that
   ruling.
3. **Authored branchless substitution** — does not count for the census by the campaign
   honesty rule (bd `libm-coverage-source-injection-rule`).

The loop and the recursion layers remain **UNMEASURED** — they sit behind `sin` and were
never reached. Do not quote them as known-remaining blockers.

## 6. Rule-12 fixtures

* `spec_accept_fp_select_fcmp.ll` — CONVERTED from `spec_reject_fp_select_fcmp.ll`. Mirrors
  the real `b_exp.c:171` shape; pins the full stream including the Bennett reverse, with
  copy SOURCES named explicitly (a wildcarded source would let a mutant that copies the
  live qubit pass) and `--implicit-check-not=cqrt_cswap`.
* `spec_reject_fp_select_fcmp_fp128.ll` — off-grid compare operand width.
* `spec_reject_fp_select_fcmp_degenerate_pred.ll` — `fcmp true` (no template; must never
  mint a phantom symbol).

Both decline fixtures record **which gate actually fires**, which is not the gate a reader
would assume from the change.
