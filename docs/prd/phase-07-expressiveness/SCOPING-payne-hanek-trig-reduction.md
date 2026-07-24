# SCOPING — the sinl/cosl/tanl (Payne–Hanek) Shadow-reduction axis

**Date:** 2026-07-24 · **Branch:** `3c6m.14-control-l6` · **Status:** scoping memo of
record (investigation only — no pass change in this increment).
**Tracker context:** bd `20xt` (trio re-bucket 2026-07-18), `3c6m.51` (fp80 Shadow
axis), `iw81.13` (QRAM-in-loop), `8h7d` (loop campaign), `20xt.8` (branchless leaves).

This memo answers the five core scoping questions for the six census cells
**sinl/cosl/tanl.f80 + sin/cos/tan.f64** with measured probes (real openlibm
injection at the `-O1` ship floor, pass @ `3dd30f9`), a Bennett.jl consult, and an
independent adversarial refutation pass. Verification artifacts:
`~/.claude/jobs/7d583c33/tmp/{sinl_f80,cosl_f80,tanl_f80,sin_f64,cos_f64,tan_f64}/pre_cq.ll`
(+ `sinl_f80/fp80dbg.txt` = the post-`promoteFp80Union` module) — reproduce with
`dump_cell.py` in the same directory (a hand replication of `wprobe.probe` at
`CENSUS_OPTLEVEL=O1`).

---

## 1. Measured first blocker — one site, all six cells

Every one of the six cells declines at the **same** site with the **same**
diagnostic (`opt` exit 1, body fully inlined, no surviving calls):

```
f80: ld80/e_rem_pio2l.h:141:9  — cq taint escape: tainted value stored to memory
f64: src/e_rem_pio2.c:174:9    — cq taint escape: tainted value stored to memory
```

That is the `tx[i] = (double)((int32_t)(z))` fill store of the Payne–Hanek
large-argument reduction. The census `OPCODE 3 (cos/sin/tan.f64)` label is
**superseded**: `@llvm.fmuladd` and `@llvm.smax` are in the intrinsic grid; the
f64 trio first-declines at the identical store. sin.f64 is the clean isolation
probe: its blocker set is a strict subset of f80's (no union layer; the
f64 word access is a register `bitcast`, verified 0 × `x86_fp80` in the module).

### What the store actually is (and is not)

- The stored **value** is tainted (theta-derived); the **address** is classical —
  `gep [3 x double] %tx, i64 %i` with `%i` a constant-phi induction (0→1).
  `classifyQramCarve` (QramLowering.cpp:821-823) returns `NotQram` for a
  classical-address value-tainted store **by design** → generic `kMsgStore`.
- The 2-trip fill loop is SCEV-const-provable, but `LoopUnrollPrepass`
  **deliberately fences it out at U2b** (tainted-operand memory access stays with
  the QRAM/Shadow owner — the lf8s Rule-13 review's find).
- **Correction to bd 20xt.8's 2026-07-23 "DECISIVE SIZING":** the kernel's
  working-array *stores* are **NOT tainted-index** (not MUX-EXCH territory). SSA
  tracing shows every `iq[]/f[]/q[]/fq[]/tx[]` store index is data-flow-classical
  (inductions, `jz-1`); only the *values* are tainted. The tainted-**index**
  accesses are the `@ipio2` const-global **reads** (index derived from
  `jv=(e0-3)/24`, e0 = tainted exponent). The trio does not need a quantum-indexed
  *write* strategy; it needs the layer stack below.

---

## 2. The full ordered layer stack (Q1)

Peeling each layer hypothetically, the next decline in firing order (pass order:
`promoteFp80Union` → PredMux → `unrollConstTripLoops` → `declineTaintEscapes` →
control detect → loop lowering → QRAM):

| # | Layer | Site (measured) | Current owner + diagnostic | Capability needed |
|---|-------|-----------------|----------------------------|-------------------|
| L1 | Classical-index **value-tainted scratch stores** — `tx[3]`, then `f/q/fq[20 x double]`, `iq[20 x i32]` (many sites) | `e_rem_pio2l.h:141/:144`, `k_rem_pio2.c:310/:315/:323/:344/:399/:405` | `declineTaintEscapes` → `kMsgStore` (carve `NotQram`, QramLowering.cpp:821) | A classical-index value-Shadow ("quantum register file") — orthogonal to the frozen tainted-index Shadow |
| L2 | Medium-path + dispatch **control**: heterogeneous exponent switch (non-empty default), 3-level precision-refinement cascade with **multi-phi fp merges**, sign-fixup fp selects | `e_rem_pio2l.h:88/:108/:117`; sinl blocks `%39–%104` | PredMux claims **0%** (E2-cycle / E3-side-entry, measured `CQ_PREDMUX_DBG`); ArmClassify fp-merge fence (`ArmClassify.cpp:965`) "…under quantum control" | Multi-phi fp-merge flattening beyond the W5 sole-phi claim; side-entry merges (early returns) |
| L3 | **Data-dependent-trip loops**: `while(tx[nx-1]==zero)nx--` (:146), the `recompute:` goto cycle (`jz+=k`), distill loop (`j>0`, jz tainted), carry loops under `if(ih)`, `for(k;iq[jk-k]==0;k++)`, `while(iq[jz]==0){jz--;q0-=24;}` (:385), compress loops (:412-422) | `e_rem_pio2l.h:146`, `k_rem_pio2.c:319-385` | LoopLowering / d8jl guard → "loop under quantum control"; tryBreak B1 (`decomposeFusedExit` nullopt on a bare tainted fcmp, LoopLowering.cpp:996) and B5 (SCEV witness, :1050) both fail | Bounded **peel + predication** with UB-derived max-trip inference (SCEV measured "Unpredictable" on the exact shape) + loop-carried tainted state |
| L4 | **In-loop, under-control tainted-index QROM**: `f[i]=(j<0)?zero:(double)ipio2[j]` + the recompute gather | `k_rem_pio2.c:310/:373` | QRAM carve → `kMsgQramLoop` / under-control QROM bounds signpost | In-loop windowed QROM gather (frozen ABI forbids in-loop access) |
| L5 | Terminal **`switch(n&3)` fp value dispatch**: 4 homogeneous arms = full inlined `__kernel_sinl/cosl` polynomials (~20-25 fp ops each) merging in one fp80/f64 phi; k_tanl additionally keeps an internal tainted fp diamond with `fdiv` | sinl `pre_cq.ll:1361`, sin_f64 `:1385`, tanl `:1466` | SwitchClassify **G4** (`SwitchClassify.cpp:295`: fp merge + no f80 reversible copy) → decline | N-way fp value-switch method-B (needs an fp copy family beyond the kjd1 select-only `cqrt_copy_f*_controlled`) |

**No opcode-surface gaps anywhere in the stack** (verified): `fdiv f80` QQ,
`shl/lshr/ashr` QQ by a *tainted amount* (`iq[jz-1]>>(24-q0)`), `fmuladd`, `smax`
are all in the grid. `k_sinl`/`k_cosl` are branchless at `-O1`.

### What the existing axes already cover (Q3)

- **`promoteFp80Union` (3c6m.51) fully covers the reduction's union layer**:
  all four `IEEEl2bits` unions (s_sinl `z`, rem_pio2l `u`, `u2`, and the `u1`
  expsign-RMW at :136-139) promote — `CQ_FP80_DBG` shows zero surviving union
  allocas. The first decline moved *past* the unions to the tx store. Layer (a)
  of the expected stack is **built and firing**.
- `foldVolatileConstGlobalLoads` folds the amd64 `volatile double` constants.
- `y[2]`/`ty[2]` out-arrays are SROA-eliminated (pure SSA) — the 20xt.8 note
  "stores the reduced value to a y[2] scratch array" is stale; y is not a blocker.

### Is the reduction "straight-line after SROA"? (Q2) — **No.**

Measured (adversarial pass, `/tmp/scev_while_tx.ll`): with all three tx fill
stores at *constant* indices, SROA still keeps the alloca — the variable-index
`tx[nx-1]` while-header load (and `x[j]` in the kernel) blocks promotion. And the
frozen Shadow-checkpoint ABI does not apply: it models tainted-*index* access;
this is classical-index/tainted-value, `kMsgQramMixed`-adjacent but genuinely a
different shape. The interlock chain closes on itself:

> escape-clear ← array promotion ← constant indices ← loop peel ← **data-dependent-trip capability** (L3).

---

## 3. Bennett.jl parity (Q5)

Consulted at `9c1b77e` (2026-07-21). Findings, with citations:

1. **Memory dispatch** (`src/lowering/memory.jl:148-159`): `idx isa ConstOperand`
   → `:shadow` (any shape); dynamic idx, `N*W≤64` → `:mux_exch_NxW`; dynamic,
   `>64` → `:shadow_checkpoint`; else `:unsupported`. Reversible store =
   3W-CNOT primal/val/tape (`shadow_memory.jl:38-55`); guarded twin promotes each
   CNOT to a Toffoli.
2. **Data-dependent loops**: Bennett unrolls to a **user-supplied static K**
   (`driver.jl:80-82` throws without `max_loop_iterations`), MUX-freezes the
   loop-carried phis per iteration, and emits a **convergence witness wire checked
   at SIMULATE time** (`simulator.jl:208-223`). Nested loops are **rejected**
   (`cfg.jl:111`); `return`-in-body rejected. CQ has no simulator, so Bennett's
   soundness mechanism is structurally unavailable (the known parity asymmetry).
3. **Payne–Hanek**: Bennett **never compiles the loop+array form**. Its
   sin/cos/tan come from SoftFloatLib's hand-written **branchless/unrolled**
   Payne–Hanek (`src/softfloat/fsin.jl:468-566 _rp_paynehanek`): a 19-entry
   constant tuple, a **fixed 192-bit window = exactly 4 statically-clamped
   const-index lookups**, fixed 128-bit pair arithmetic — no `iq[20]`, no
   `while(tx[nx-1])`, no `recompute:`. The dispatcher computes **all** range
   branches unconditionally and `ifelse`-selects.
4. **Fed openlibm's `__kernel_rem_pio2`, Bennett would decline** (nested
   data-dependent loops + goto). CQ's declines on this source are
   **parity-correct**; the parity move for the trio is leaf substitution, which
   CQ already ships (below).
5. **One genuine near-term parity gap** (independent of the trio): Bennett lowers
   a classical/const-index tainted-value store via `:shadow` (3W-CNOT); CQ's
   Shadow is tainted-index-only and declines it `kMsgStore`. Worth its own
   scoped ticket — but note it does **not** compile any of the six cells by
   itself (L2–L5 remain), and payoff on other census cells is per-cell-unknown.

---

## 4. Minimal first increment (Q4) and why we recommend NOT building it now

The adversarial pass tried six shortcut families (SCEV/UB trip bounds, arithmetic
peephole peel, full max-bound unroll, unroll+SROA, range restriction, 799w/y05j
widenings) — **all refuted with measured evidence**; verdict: *no bounded
increment makes any of the six cells compile*. The smallest Rule-17-real advance:

1. ~~gyc9 crash fix~~ — **already done** (`f6d85b9`, CLOSED).
2. Widen U2b to unroll the SCEV-exact 2-trip tx fill when the only tainted
   memops are stores to a non-escaping fixed-size alloca (per-shape Rule-13
   review — this reverses a deliberate lf8s fence decision).
3. Accept a classical-**const**-index tainted-value store to a non-escaping
   alloca as a named-rail write reversed by the Phase-5 LIFO spine. This
   reinterprets the frozen 7.5 Shadow surface (or adds semantics beside it) —
   **owner freeze-gate decision required**.

Measured effect: the first decline moves from `e_rem_pio2*.c:141/174` to the
kernel's f-fill store at `k_rem_pio2.c:310` — same `kMsgStore` layer, one call
deeper. **No cell compiles; the stack does not shorten** (L2–L5 untouched).
~1-2 weeks of Rule-13-heavy core work for census-signature evidence only.
Per the task's own stall-mid-stack warning, we recommend **defer**.

---

## 5. Build/defer recommendation + increment plan

**(A) The real-openlibm trio is NOT a bounded Shadow increment — it is the deep
end of the loop campaign. DEFER behind 8h7d; scope it there.**
The gating capability is L3 (bounded peel + predication + UB-derived max-trip +
loop-carried tainted state), with L2/L4/L5 stacked behind it. Filed as a scoped
child under `8h7d` (see bd), where the same capability already has 8 f32
first-blocker cells waiting (`acosf/acoshf/asinhf/hypotf/powf/fmodf/remainderf/
remquof`) — 11+ census cells of payoff vs 6. This is roadmap-resequencing-scale
work; bring it to a phase decision, not an increment.

**(B) The near-term trio path is the already-approved branchless-leaf category
(Bennett parity).** `branchless/sinl.c` + `cosl.c` are DONE and e2e-verified
(20xt.8); the **one missing leaf is `tanl`** (port `branchless/tan.c` → ld80
`k_tanl.c` coefficients; `fdiv f80` QQ is in the grid; kjd1 handles the selects).
Bounded, recipe-established, no new capability — recommend building it under
20xt.8's recipe carve-out. Honesty rule unchanged: hybrid/authored-leaf category,
census cells stay declined, never quoted with real-openlibm goldens.

**(C) Optional scoped parity ticket (owner-gated):** the classical-const-index
value-Shadow store (§3.5 + §4.2-3) as a standalone Bennett-parity capability —
P3 unless a census cell is found that declines *solely* on it.

**(D) Bookkeeping corrections landed with this memo:** the 20xt trio re-bucket
stands (Shadow-store first blocker confirmed), but the 20xt.8 MUX-EXCH sizing is
corrected (stores are classical-index); the census OPCODE label for
cos/sin/tan.f64 is superseded; `y[2]` is not a blocker (SROA'd); the fp80-union
layer is already covered by 3c6m.51.
