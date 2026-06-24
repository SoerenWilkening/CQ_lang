# PRD — fp-data carve + fp-intrinsic / math.h family (test_C_libtooling-iw81.4)

**Status:** **DRAFT / design-of-record** (Rule 16, written at phase start
2026-06-24). Owner-scoped current cut: the fp-data carve precondition + the fp
`@llvm.*` intrinsic family, **with `wd2p` (fma/fmuladd ternary) and `8rvn` (the
missing fcmp predicates) PULLED IN** (owner decision 2026-06-24). The remaining
fp follow-ups — `nyww` (direct-libm matcher), `spe5` (i128↔fp casts), `38t2`
(fp-as-bitpattern cell), `g387` (by-ref math) — stay **deferred** as tracked
children of iw81.4.

**Grounded in real clang 19.1.7 `-O1` codegen** + the live pass (every IR/ABI
claim below was extracted this session via `/usr/local/opt/llvm@19/bin/{clang,opt}`
+ `build/ir-pass/libCQPass.so`, or read from source with a `file:line` anchor).
No statevector simulation (owner decision 2026-06-10); correctness is established
by golden e2e trace diff + analytic/trace reasoning + Rule-13 adversarial review.

> Parent epic: `iw81` (Bennett.jl capability parity). This is the
> `bennett-parity` cross-cutting #2 item — "build the fp-data carve once and a
> whole family rides it." Sibling reuse target: Phase 7.1-E (curated reversible
> `@llvm.*` *integer* idiom intrinsics), DONE + Rule-13 cleared.

---

## 1. The problem in one sentence

A tainted (quantum) value cannot flow into a `math.h` function today — every
`sin(q)`/`exp(q)`/`a*b+c` lowers `clang -O1` to a `@llvm.*` intrinsic (or a libm
call) that hits `declineTaintEscapes` → `kMsgUnknownCallee` and loud-declines —
even though these are **pure total functions, hence reversibilizable** by the
exact recompute-from-live-source `_unc` model Phase 5 / 7.1-E already ship.

---

## 2. Ground truth (verified this session)

### 2.1 The fp-DATA path ALREADY exists and is safe

Tainted fp **arithmetic** already lowers. `double q = cq_theta_f64(x,0.5); r =
(q+q)*q; cq_measure_f64(r)` at `-O1 -ffp-contract=off`:

```llvm
%h     = call i32 @cqrt_alloc_f64(double %0)
         call void @cqrt_ry_f64(i32 %h, double 5.000000e-01)
%h_op  = call i32 @cq_template_fadd_f64(i32 %h, i32 %h)
%h_op1 = call i32 @cq_template_fmul_f64(i32 %h, i32 %h_op)
%m     = call double @cqrt_measure_f64(i32 %h_op1)
```

`opt` exit 0. The fp arith templates are frozen in `tools/opcode_table.yaml`
(fadd/fsub/fmul/fdiv/frem at f16/f32/f64); the data path is `ArithLowering::
rewriteBinary` (`ArithLowering.cpp:67-73`, `WantsFp = Stem.starts_with("f")`).

**Consequence:** "the carve" is **NOT** new f64 data-path machinery. It is
**additive recognition** layered onto a proven-safe path. The hazard is keeping
a rotation *angle* out of these templates — and that fence is already load-
bearing and intact (§3).

### 2.2 The angle fence is POSITIONAL, not a decline-all-fp rule

A tainted fp value derives transitively from `cq_theta` (sole source, Rule 3). It
is an *angle* in exactly one structural position: the **arg-1 operand-use** of
`cq_phi`/`cq_theta` (or a control-flow merge feeding an arg-1). Taint propagation
skips that edge **per-operand-use** (`TaintPropagation.cpp:303-309`):

```cpp
if (Callee && (ThetaFns.contains(Callee) || PhiFns.contains(Callee)) &&
    CI->arg_size() >= 2 && CI->getArgOperand(1) == V &&
    CI->getArgOperand(0) != V)
  continue;  // V used here ONLY as the classical angle; skip edge.
```

So **"a tainted fp value is DATA" is a sound discriminator** (it cannot be a live
quantum angle — a *tainted* value reaching an arg-1 is the data-controlled-
rotation DECLINE, not an accept). Five fence sites enforce this; all are
preserved verbatim (§3).

### 2.3 The `-O1` math.h surface is a MIXED partition (verified)

| Form at `-O1` | Functions (verified `@llvm.*` / `@call` / fold) |
|---|---|
| `@llvm.<fn>.f<W>` **intrinsic** (current scope) | `sin cos tan asin acos atan sinh cosh tanh exp exp2 log log2 log10 sqrt floor ceil trunc round rint nearbyint fabs` (unary); `pow minnum(=fmin) maxnum(=fmax) copysign` (binary); `fma fmuladd` (ternary) |
| **fp→int** intrinsic (edge, see §6.5) | `lround → @llvm.lround.i64.f64` (fp arg, i64 result) |
| **direct libm `@call`** (→ deferred `nyww`) | `cbrt expm1 log1p` (verified `declare`); + `atan2 hypot remainder` (prior run) |
| **folds away** (no call) | `pow(q,2.0)→fmul`; `pow(q,-1.0)→fdiv`; `pow(q,0.5)→@llvm.sqrt`; `fmod(q,p)→frem` (already DONE) |

**FMA contraction (the reason `wd2p` is core, not optional):** at default `-O1`,
ordinary `a*b+c` contracts to `@llvm.fmuladd.f64` (verified) — which declines
today. Without `wd2p`, plain tainted fp expressions silently fail at the validated
`-O1` floor.

### 2.4 The single fp gate

`isCuratedReversibleIntrinsic` (`IntrinsicLowering.cpp:112-133`) is the membership
gate; the fp-blocking line is `widthInTableSet` (`:91-96`), which returns false
for **every** fp/vector width today (`base = i8|i16|i32|i64`). The carve-out at
`TaintPropagation.cpp:537` (`if (isCuratedReversibleIntrinsic(CI)) continue;`)
**auto-covers** new fp intrinsics the instant the predicate widens — no edit
there.

---

## 3. The carve precondition (build FIRST — iw81.4.a)

A tainted fp value MAY flow into an fp-data template / fp-intrinsic recognizer
**iff all** hold (any failure → loud decline, lower nothing):

1. It is **not** in the arg-1 (angle) operand-use of `cq_phi`/`cq_theta`
   (positional, per-use). The **five fence sites stay first-checked, verbatim**:
   - `TaintPropagation.cpp:303-309` — per-use arg-1 taint skip (root).
   - `RotationLowering.cpp:74-79` `declineTaintedAngle` (theta `:141`, phi `:195`)
     — `"quantum-derived rotation angle"`.
   - `ArmClassify.cpp:361-383` `taintedAngleGate` (call `:747`) — `"rotation angle"`.
   - `SelectClassify.cpp:86-118` `selReachesRotationArg1` (call `:282`) — the
     value-preserving-carrier walk (fpext/fptrunc/bitcast/freeze/phi/select) into a
     rotation arg-1; **any** reach declines the whole construct.
   - `SwitchClassify.cpp` G3 `mergeReachesRotationArg1` — the all-const data-mux
     backstop.
2. It does not transitively carry into any rotation arg-1 (the
   `selReachesRotationArg1` fan-out rule — once `sin` etc. is recognized, a
   `cq_phi(u, sin(q))` puts the tainted `sin` result in arg-1 and MUST still
   decline; **this is the headline new probe**, §7 D1/G1).
3. **Intrinsic:** callee is an EXACT `Intrinsic::ID` member of the curated fp
   table (NEVER `starts_with("llvm.")`), with a generated frozen
   `cq_template_<fn>_f<W>` (+ `_unc`) at an in-table fp width (f16/f32/f64).
   **(Direct-libm is `nyww`, deferred.)**
4. **Source-liveness (Rule 8):** lowered as a Class-2 additive producer; the
   `_unc` recomputes `f(live sources)` and XORs the out rail to `|0⟩` — it never
   recovers the input. Fan-out (>1 forward consumer, non-terminal) leaves the rail
   allocated and **skips** the free.

**The fp control-merge fence** (the deepest f64 trap) uses
`isFPOrFPVectorTy()` — verified at `ArmClassify.cpp:852`, `SelectClassify.cpp:296`,
`SwitchClassify.cpp:295` — never scalar-only `isFloatingPointTy()` and never
`abiWidthFromType` non-empty. **Do not touch these.**

iw81.4.a ships **no new templates** — it formalizes the predicate and locks the
fence with a decline-probe family (§7). It is the precondition the issue mandates.

---

## 4. Recognizer extension

### 4.1 IntrinsicLowering.cpp edits (the four switch functions + a new kind)

- `intrinsicStem` (`:31-51`) — add EXACT-ID cases: the 22 unary fp →
  `"sin"`/…/`"fabs"`; `pow`,`minnum→"fmin"`,`maxnum→"fmax"`,`copysign`;
  `fma`,`fmuladd→"fma"` (both stems `"fma"` — the trace does not distinguish the
  `fmuladd` "may-fuse" rounding from `fma` "must-fuse"; a Phase-9 backend concern).
- `intrinsicKind` (`:53-68`) — unary fp → `Unary`; `pow/minnum/maxnum/copysign` →
  `Binary`; **`fma/fmuladd` → new `IntrinKind::Ternary`** (§4.3).
- `intrinsicCommutative` (`:72-84`) — `minnum/maxnum` → true (qq+hl);
  `pow/copysign` → false (qq+hl+lh).
- `widthInTableSet` (`:91-96`) — admit `f16/f32/f64` **only** for the carve-
  approved fp IDs (a per-ID allow, NOT a blanket fp open — keep the f64 fence on
  every non-curated fp path).
- `rewriteIntrinsic` (`:135-242`) — the Unary/Binary arms already emit via
  `wd.dataTemplateFn(Stem, W, Shape)`; add the Ternary arm (§4.3).

### 4.2 intrinsic_table.yaml rows (the sibling table)

Add the fp widths to the table's `widths:` block (currently int-only;
`abi_codegen.py:48-50` already has the `_Float16`/`float`/`double` ctypes):

```yaml
f16: { bits: 16, c_type: "_Float16", domain: "fp" }
f32: { bits: 32, c_type: "float",    domain: "fp" }
f64: { bits: 64, c_type: "double",   domain: "fp" }
```

Rows (all **class 2**, `pure_noninjective` — none is an involution, so all reverse
via recompute-from-live-source `_unc`; even injective `sqrt` uses class 2 uniformly):

```yaml
# unary fp transcendental / round family / fabs (×22), fwd+unc:
- { op: sin, llvm_id: sin, class: 2, reversibility: pure_noninjective, arity: unary, widths: [f16,f32,f64], variants: [fwd, unc] }
#   cos tan asin acos atan sinh cosh tanh exp exp2 log log2 log10 sqrt
#   floor ceil trunc round rint nearbyint fabs  — identical rows
# binary commutative fp (fmin/fmax), qq+hl:
- { op: fmin, llvm_id: minnum, class: 2, reversibility: pure_noninjective, arity: binary, commutative: true,  widths: [f16,f32,f64], variants: [fwd_qq, fwd_hl, unc_qq, unc_hl] }
- { op: fmax, llvm_id: maxnum, class: 2, reversibility: pure_noninjective, arity: binary, commutative: true,  widths: [f16,f32,f64], variants: [fwd_qq, fwd_hl, unc_qq, unc_hl] }
# binary non-commutative fp (pow/copysign), qq+hl+lh:
- { op: pow,      llvm_id: pow,      class: 2, reversibility: pure_noninjective, arity: binary, commutative: false, widths: [f16,f32,f64], variants: [fwd_qq, fwd_hl, fwd_lh, unc_qq, unc_hl, unc_lh] }
- { op: copysign, llvm_id: copysign, class: 2, reversibility: pure_noninjective, arity: binary, commutative: false, widths: [f16,f32,f64], variants: [fwd_qq, fwd_hl, fwd_lh, unc_qq, unc_hl, unc_lh] }
# ternary fp (fma/fmuladd), §4.3:
- { op: fma, llvm_id: fma, class: 2, reversibility: pure_noninjective, arity: ternary, widths: [f16,f32,f64], variants: [fwd_qqq, fwd_qql, fwd_qlq, fwd_qll, unc_qqq, unc_qql, unc_qlq, unc_qll] }
```

The header comment's "intrinsics use INT only" + the EXCLUDED "fp transcendentals
(Phase-6 Path-1 libm)" note must be revised. Regenerate with
`tools/gen_templates.py`; the SHA-256 drift check (`--check`) gates it (Rule 15).
Verify f16 transcendental emission at implementation — clang may promote `_Float16`
transcendentals to f32 (decline-safe if the f16 form never arises).

### 4.3 The ternary (fma) shape — the one new ABI shape (wd2p)

fma(a,b,c) = `a*b + c`. The product pair `(a,b)` is **commutative**; the addend
`c` is **positional**. Canonicalize the pair (handle-before-literal, then by
`BirthOrder`) → **4 shapes** keyed by `(pair pattern) × (addend pattern)`; the
all-literal pair cannot occur (it folds to a constant, no fma):

| Shape | Forward signature | `_unc` twin |
|---|---|---|
| `qqq` | `i32 fma_f64(i32 a,i32 b,i32 c)` | `void fma_f64_unc(i32 out,i32 a,i32 b,i32 c)` |
| `qql` | `i32 fma_f64(i32 a,i32 b,double c)` | `void …_unc(i32 out,i32 a,i32 b,double c)` |
| `qlq` | `i32 fma_f64(i32 a,double b,i32 c)` | `void …_unc(i32 out,i32 a,double b,i32 c)` |
| `qll` | `i32 fma_f64(i32 a,double b,double c)` | `void …_unc(i32 out,i32 a,double b,double c)` |

`abi_codegen.py` edits (the **only** generator change in this PRD): add the four
fwd ternary signatures/stub-bodies to `signature`/`stub_body` and the four `unc`
twins to `_unc_signature`/`_unc_body` (`tools/abi_codegen.py:62-175`), plus the
new shape names to `VARIANT_INFO`/`UNC_SHAPES` in `gen_templates.py`. The whole-DAG
uncompute spine recognizes them by the `cq_template_` prefix with **zero** new
pass code (`DagTraversal::isTemplateProducer`, `EmitInverse` `_unc` branch). Partial
staging (e.g. `qqq` first) is decline-safe — an unmatched pattern declines, never
miscompiles.

### 4.4 fcmp predicates (8rvn)

Extend **both** mirror lists to the missing predicates (no new ABI shape — reuses
the existing fcmp variant grid):
- `tools/opcode_table.yaml:113` `predicates.fcmp` (currently `[oeq,une,olt,ogt,ole,oge]`).
- `OpcodeSupport.cpp:146-151` `compareInScope` fcmp set (must mirror exactly).

Missing set: the ordered/unordered comparison family `one ord uno ueq ugt uge ult
ule` (the unordered twins + `one`/`ord`/`uno`; `true`/`false` stay out — trivial,
no comparison). fp-DATA only; the compare result is an `i1` flag, never an angle.
**Never mint a phantom symbol for an out-of-set predicate** (the ziov4 hazard) —
keep a residual negative fixture for at least one excluded predicate. Flip
`lowering_fcmp_one_negative.ll` from decline to accept.

---

## 5. Increment breakdown

Order: **a → b → c → 8rvn → wd2p** (8rvn is the cheapest/lowest-risk; wd2p is the
one generator change, sequenced last). Each ships red-green fixtures (positive
`CHECK` + negative `RUN: not … | FileCheck` mirroring the diagnostic char-for-char,
Rule 12) and clears Rule-13 (independent adversarial review).

| Inc | Content | Accept-predicate | Red-green | Rule-13 | Freeze |
|---|---|---|---|---|---|
| **iw81.4.a** | Carve precondition: formalize "tainted fp = data", lock the 5 fence sites, add decline probes. NO templates. | §3 | GREEN: fp arith still lowers. NEW negatives D1 (`lowering_reject_math_result_as_angle.ll`), D11 (`…_math_double_realize.ll`); confirm D2 fp-merge declines stay green. | MED | none |
| **iw81.4.b** | Unary fp intrinsics (22) + binary `pow/fmin/fmax/copysign`. YAML rows + 4 switch edits + `widthInTableSet` fp admit. | §3 + EXACT fp `Intrinsic::ID` at f16/f32/f64; Class-2 additive producer + `_unc`. | RED→GREEN: flip `lowering_reject_intrinsic_transcendental_sqrt.ll`. NEW positives `lowering_intrinsic_sin_f64.ll`, `…_pow_f64_hl.ll`, `…_fmin_f64_qq.ll`; NEW negative `…_fp_vector.ll`. ≥1 e2e golden. | **HIGH** (first fp into the recognizer; the f64 family). | YES |
| **iw81.4-8rvn** | 7+ missing fcmp predicates. | §4.4 (fp-data, i1 result, in curated set). | FLIP `lowering_fcmp_one_negative.ll`; NEW positive per pred; residual negative for an excluded pred (no phantom symbol). | LOW | YES |
| **iw81.4-wd2p** | fma/fmuladd ternary + the one `abi_codegen` shape. | §4.3; product pair canonicalized, addend positional. | NEW positive `lowering_intrinsic_fma_f64_qqq.ll` + the mixed shapes attempted; e2e golden for `a*b+c` (contracted fmuladd). NEW negative non-curated ternary. | **MED-HIGH** (3-operand order; first ternary template). | YES |

**Done-criteria (Rule 16):** both lit fixtures **and** ≥1 e2e golden smoke per
increment; full `ctest` green; `gen_templates.py --check` clean; each core change
(b, wd2p) independently Rule-13 cleared.

---

## 6. Decline matrix (preserve / mint)

| # | Shape | Diagnostic (mirror char-for-char) | Fixture |
|---|---|---|---|
| D1 | Tainted fp → **arg-1 ANGLE** incl. `cq_phi(u, sin(q))` | `"quantum-derived rotation angle"` / `"rotation angle"` | EXISTING angle fixtures + NEW `lowering_reject_math_result_as_angle.ll` |
| D2 | fp **control-merge φ** of tainted value | `"… under quantum control"` / `"rotation angle"` (`isFPOrFPVectorTy()`) | EXISTING `control_swap_reject_*fp*` |
| D3 | **by-ref** math (`modf/frexp/sincos/remquo`) | `kMsgUnknownCallee` (→ `g387`) | NEW `lowering_reject_math_byref_frexp.ll` |
| D4 | `*.with.overflow` aggregate | `kMsgUnknownCallee`, `CHECK-NOT: cq_template_` | EXISTING `lowering_reject_intrinsic_overflow_uadd.ll` |
| D5 | **i128↔fp** cast | `"no template for opcode 'sitofp …'"` (→ `spe5`) | EXISTING `lowering_reject_i128_sitofp.ll` |
| D6 | **fp↔int reinterpret** `bitcast` | `"no template for opcode 'bitcast …'"` | NEW `lowering_reject_fp_int_bitcast.ll` |
| D7 | **errno-modeled** libm (`-fmath-errno`, `memory(write)`) | `kMsgUnknownCallee` (over-decline-safe) | NEW `lowering_reject_math_errno_write.ll` |
| D8 | **Non-curated `@llvm.*`** (incl. `@llvm.fmuladd` **until wd2p**, vector fp) | `kMsgUnknownCallee` | EXISTING `lowering_reject_intrinsic_funnel_fshl_general.ll` |
| D9 | **Out-of-set fcmp predicate** (after 8rvn) | `"no template for opcode 'fcmp …'"` (no phantom symbol) | residual `lowering_fcmp_*_negative.ll` |
| D10 | **Fan-out** on a math producer | rail left allocated, free SKIPPED (Rule 8) | EXISTING precedent `lowering_intrinsic_smin_fanout_skip.ll` |
| D11 | Math result feeds BOTH data AND a rotation arg-1 | decline whole construct | NEW `lowering_reject_math_double_realize.ll` |

### 6.5 fp→int edge: `lround`/`llround`/`lrint`/`llrint`

`lround(q) → @llvm.lround.i64.f64` — fp arg, **i64 result** (cross-domain). Not
fp→fp unary; result width is int (in table) but the operand is fp. **Out of this
PRD's core set** — handle with the cast family or its own row (note in `nyww`/
`spe5` neighborhood); declines safely via `widthInTableSet`/unmatched-shape until
then.

---

## 7. Silent-miscompile hazards

1. **The f64 angle/data family (THE hazard).** A rotation ANGLE reaching a soft-
   float DATA template reopens the family. Mitigations: keep the 5 fence sites
   first-checked (§3), the `isFPOrFPVectorTy()` merge triad, and gate fp behind a
   **per-ID** `widthInTableSet` admit (never blanket fp). G1 probe: a curated math
   result reaching an arg-1 MUST still decline (verify empirically — this is the
   one report-flagged unproven claim).
2. **Non-injective `_unc` dropping the live source.** Class-2 recompute needs the
   source live until its own `_unc`; fan-out must SKIP the free (Rule 8, D10).
3. **errno impurity.** Under `-fmath-errno` libm calls gain `memory(write)` — not
   pure; require `memory(none)`, let the errno form ride the loud decline (D7).
4. **2-arg / 3-arg taint-on-wrong-operand.** `pow(q,2)` HL vs `pow(2,q)` LH vs
   `pow(q,p)` QQ — operand order is semantic for non-commutative pow/copysign; the
   commutativity table must be exact. fma's product pair commutes, addend does not.
5. **No phantom fcmp symbol** for an out-of-set predicate (ziov4) — `compareInScope`
   must mirror `opcode_table.yaml` exactly.
6. **fp↔int reinterpret** (`bitcast double↔i64`) would launder an angle bitpattern
   into the int domain where the fence is absent — must decline (D6, reuse iw81.1).

---

## 8. Frozen-ABI impact

Per Rule 15, every new `cq_template_<op>_f<W>` symbol is **frozen ABI ⇒ pre-freeze
YAML edit**. iw81.4.a = pure recognizer (no ABI). iw81.4.b/8rvn = new generated
symbols, no new generator *shape*. wd2p = new symbols **and** the first ternary
generator shape (`abi_codegen` edit). All land before the Phase-11 freeze.

**Deferred (tracked children, NOT this PRD):** `nyww` direct-libm matcher,
`spe5` i128↔fp, `38t2` fp-as-bitpattern cell (lifts the deliberate `copyFn`
`isIntegerTy` fence — riskiest single change, gated on 7.5), `g387` by-ref math
(stays declined until 7.5 Shadow multi-result routing).

---

## 9. Open questions

**Resolved (owner, 2026-06-24):** include `wd2p`+`8rvn` now; domain-restricted fns
(`log`/`sqrt`/`asin`) curated at recognition now (trace computes no NaN; matches the
shipped `abs`-on-INT_MIN precedent), |0⟩-rail domain proof deferred to the Phase-9
backend; errno-form libm over-declines; fp-as-bitpattern cell deferred.

**Remaining (confirm at implementation):**
- f16 transcendental emission — does clang emit `@llvm.sin.f16` or promote to f32?
  (Decline-safe either way; affects whether f16 rows are exercised.)
- `lround` family fp→int routing (§6.5) — fold into a cast follow-up or its own row.
- fma mixed-shape coverage — ship all 4 canonical shapes, or stage `qqq` first and
  let mixed forms decline initially (both safe).
