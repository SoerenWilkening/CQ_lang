# PRD — g387: by-ref math out-params (frexp / modf / remquo)

**Status:** in progress (branch `g387-byref-math`, 2026-07-01).
**Scope (owner decision 2026-07-01):** all three families, in one increment,
including the new `cross_binary` ABI shape for remquo's quotient.
**Tracker:** `test_C_libtooling-g387`. Design memory: `bd memories g387-byref-math-design`.

---

## 1. Goal

Lower a **tainted** call to a by-ref libm math function that returns one value
and writes a second through a pointer out-param:

| fn | signature | primary result | secondary (out-cell) |
|---|---|---|---|
| `frexp` | `T frexp(T x, int* e)` | mantissa (fp) | exponent → `int` cell |
| `modf`  | `T modf(T x, T* ip)` | fraction (fp) | integer part → `T` cell |
| `remquo`| `T remquo(T x, T y, int* q)` | remainder (fp) | quotient bits → `int` cell |

× widths `{f32, f64, f80}` = **9 functions**. Unblocks the 9 `math.h`
`cannot-yet` rows (coverage 90% → ~95%).

Non-goal (tracked separately, `g7ip`): by-ref out-params on **visible user
functions** — those have a body and go through clone-on-taint + Shadow, not
curation. Opaque libc has no body, so curation is the only path (the same wall
Bennett hits: a bare `declare` has no instructions to reverse).

## 2. The core hazard (why this is a core change, not "add table rows")

CQ taint is a pure SSA use-def property (`TaintPropagation.cpp:287-313`); it
**never crosses memory**. The out-param cell has a **classical address** (an
`alloca` scalar, no tainted index — unlike QRAM, whose load is tainted via the
tainted *index* flowing through the gep as a real SSA edge). So:

```llvm
%2 = alloca i32                              ; classical address
%3 = call double @cq_theta_f64(...)          ; TAINTED source
%4 = call double @frexp(double %3, ptr %2)   ; %4 TAINTED (call reads %3)
%7 = load i32, ptr %2                          ; %7 CLASSICAL — taint didn't cross memory
```

The primary `%4` rides the normal libm path. The secondary `%7` and its
downstream (`modf`: `load → fptosi → measure`) are **not tainted**. Injecting a
tainted producer for the load naively (RAUW the raw load) would corrupt the
`fptosi` up-front width capture (`OpcodeLowering.cpp:236-267`) and leave
untainted downstream un-lowered. **Miss-safety is structural**: a load we don't
account for stays classical → silent miscompile (Prime Directive). The accept
shape must prove the cell's *complete* read/write set or decline.

## 3. Architecture — canonicalize to markers + double-propagate

Reuse the entire existing curated-libm path by making the by-ref result look
like an **ordinary tainted curated libm call**:

1. `propagate()` — learn which by-ref calls are quantum (fp arg tainted).
2. **`lowerByRefMath`** (new module, runs right after the first propagate,
   before `detectSpecializations`; mirrored in both twin entry points): for each
   quantum by-ref call with a **valid cell shape**, rewrite
   - primary result → `call <T> @cq_byref_<fn>_<W>(<fp args>)`
   - each out-cell `load` → `call <cellT> @cq_byref_<fn><slot>_<W>(<fp args>)`
   then erase the original call + loads + alloca + lifetime/dbg markers.
   Off-pattern cell → loud `kMsgMathByRef`; the by-ref name is carved in
   `declineTaintEscapes` so the generic `kMsgUnknownCallee` never double-fires.
3. `propagate()` **again** — the markers are plain SSA calls reading the tainted
   source, so taint flows to the whole downstream via the normal mechanism.

The markers are recognized by `isLibmCall` (kLibmTable rows, by exact name) and
lowered by `rewriteLibmCall` to `cq_template_*` producers. Widths are read from
the marker `FunctionType` (phase-safe — `paramW`/`retW`, never operand values).

`propagate`, `declineTaintEscapes` (except a 1-line by-ref name carve),
`lowerRotations`, `lowerOps`, `uncompute` are **unchanged**.

### 3.1 Markers ARE synthetic libm calls

A marker `call double @cq_byref_frexp_f64(double %x)` is well-typed pre-rotation;
`lowerRotations` RAUWs `%x` → i32 handle (transient mismatch, laundered on
rewrite — identical to how a real `@cbrt` call is handled); `lowerOps` rewrites
the marker to `cq_template_frexp_f64(%handle)`. The `modf` `fptosi` keeps its
`double` operand through lowerOps Phase-1 (the marker is not yet rewritten), so
`getSrcTy()` reads `f64` correctly — no HandleWidth trick needed.

## 4. Producers (two independent Class-2 producers per fn)

| fn | primary template | secondary template | kinds |
|---|---|---|---|
| frexp | `cq_template_frexp_<W>` | `cq_template_frexpexp_<W>_to_i32` | same_unary + cross_unary |
| modf  | `cq_template_modf_<W>`  | `cq_template_modfint_<W>` | same_unary + same_unary |
| remquo| `cq_template_remquo_<W>` (qq/hl/lh) | `cq_template_remquoquo_<W>_to_i32` (qq/hl/lh) | same_binary + **cross_binary (NEW)** |

Each output is a deterministic function of the input(s) — `frexp` is a bijection
`x ↔ (m, e)` — so two Class-2 producers over the **shared live source** is sound
(fan-out, handled by the whole-DAG uncompute spine, WI-4). No cloning: rails are
zeroed by recompute-from-live-source, never by freeing a dirty rail.

### 4.1 `cross_binary` ABI shape (remquo quotient)

`(fp, fp) → int`, qq/hl/lh + `_unc`. Signatures are **byte-identical** to
`same_binary` (all handles are i32; result i32); only the NAME differs
(`<stem>_<from>_to_<to>[_shape]`, `classical_w = from`). So it needs **only** an
`enumerate_libm` branch in `gen_templates.py` — no new `abi_codegen` shape,
no new `TemplateName` grammar beyond an inline name build in `rewriteLibmCall`
(mirroring `mixed_binary`). Additive rows in the libm sibling YAML; does **not**
re-open the freeze.

## 5. Accept shape (tight; miss-safety is structural)

The ptr out-param cell must be:
- a **direct scalar `alloca`** (single element, not an array; static);
- cell scalar type == expected (frexp/remquo: `i32`; modf: same fp as input);
- users == **only** {the one by-ref call as the ptr arg, `load`s, lifetime/dbg
  intrinsics} — no other call, no store, no ptrtoint/gep, not itself stored;
- **single writer** = the by-ref call;
- **every load dominated by the call** (DominatorTree); no pre-call load;
- **not under tainted control** (`instUnderTaintedControl`), **not in a loop**.

Anything off-pattern → `kMsgMathByRef` (loud, source-located). Also decline: fp
arg classical (leave as a normal libc call — passthrough); `f128`/vector cell;
`sincos` (two out-ptrs — out of scope this increment).

## 6. Files

- `tools/libm_table.yaml` — 6 new rows (frexp/frexpexp/modf/modfint/remquo/remquoquo).
- `tools/gen_templates.py` — `cross_binary` branch in `enumerate_libm`.
- regenerate `runtime/cq_libm_templates.{h,c}`; `gen_templates.py --check` clean.
- `ir-pass/src/LibmLowering.cpp` — `CrossBinary` kind; kLibmTable `cq_byref_*`
  rows; `isLibmCall`/`rewriteLibmCall` cross-binary + by-ref marker handling.
- `ir-pass/src/ByRefMath.cpp` + `ir-pass/include/ByRefMath.h` — `lowerByRefMath`
  + `kMsgMathByRef`.
- `ir-pass/src/CQLoweringPass.cpp` — call `lowerByRefMath` + second propagate in
  both entry points; by-ref name carve in `declineTaintEscapes`.
- `ir-pass/CMakeLists.txt` — add `ByRefMath.cpp`.

## 7. Tests (Rule 12 red-green + Rule 13)

- ir-pass lit: one positive `.ll` per fn (frexp/modf/remquo) at f64 showing the
  two producers + erased alloca/load; f32/f80 smoke; `cross_binary` remquo qq/hl/lh.
- decline probes (`RUN: not … | FileCheck`, message char-for-char): non-scalar
  cell (array), extra store to cell, cell address escapes to a 2nd call, load not
  dominated, cell in a loop / under tainted control, `sincos`.
- e2e goldens: `slice_byref_frexp.c`, `slice_byref_modf.c`, `slice_byref_remquo.c`
  (the link-proof layer — every emitted symbol resolves + signature-matches).
- library coverage probe: frexp/modf/remquo flip 🟡 → ✅; bless goldens.
- **Rule 13**: independent adversarial review of the two-producer fan-out
  uncompute + the accept-shape miss-safety + the cross_binary shape, before commit.
