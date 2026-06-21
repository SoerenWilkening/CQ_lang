# Design — i128 wide-integer support (test_C_libtooling-n0ui)

**Status:** design pass, 2026-06-21. Awaiting owner scope decision before
implementation. Supersedes the IMPLEMENTATION-PLAN-7.1 §6 i128 mechanism (which
**guessed** `__int128 → i128 @cq_theta_si128(i128, double)` and was empirically
disproved — see memory `7-1-D-i128-abi-shred`).

This doc is grounded in **real clang 19.1.7 `-O1` codegen** and a 4-axis parallel
investigation (frozen-surface map · `-O1` hazard probe · decline-site inventory ·
Tier-2 frontend-representation survey), each verified against the live pass.

---

## 1. The problem in one sentence

`__int128` is freeze-gating (it would add frozen ABI), but the C ABI **shreds** a
`__int128` function parameter/return into a `{i64,i64}` aggregate on x86-64, so the
plan's "i128 is just another width like f16" mechanism is false — i128 needs a real
design, split by *where the 128-bit value lives*.

---

## 2. Ground truth — two scenarios, very different difficulty

### Scenario A — i128 as SOURCE/SINK (`__int128` `cq_theta`/`cq_measure`) — HARD
The C ABI decomposes `__int128` at the function boundary. Real `-O1`:
```llvm
%5  = call { i64, i64 } @cq_theta_si128(i64, i64, double)  ; theta returns an AGGREGATE
%6  = extractvalue { i64, i64 } %5, 0                       ; low half
%7  = extractvalue { i64, i64 } %5, 1                       ; high half
; ... zext/shl/or reassemble to a logical i128 ...
%16 = add i128 %15, %14                                     ; low + carry, in i128
%18 = lshr i128 %16, 64                                     ; extract carry-out
%20 = add i64  %13, %19                                     ; high half, in i64
%21 = call { i64, i64 } @cq_measure_si128(i64 %low, i64 %high)  ; 2-arg sink
```
A *single* logical i128 add is split across an `add i128` **and** a separate
`add i64`, carry threaded by `lshr`/`trunc`. Requires **aggregate-taint seeding**
through `extractvalue`, **split-op coalescing**, and a **2-arg measure ABI** — none
of which exists.

### Scenario B — i128 as INTERMEDIATE (born i64, widened mid-computation) — CLEAN
Source/sink stay at a standard width; i128 appears only as single clean ops. Real
`-O1` for `(unsigned __int128)a * (unsigned __int128)a >> 64` (a 128-bit "mulhi"):
```llvm
%2 = call i64 @cq_theta_ull(i64, double)   ; clean i64 ABI source
%3 = zext i64 %2 to i128
%4 = mul nuw i128 %3, %3                    ; SINGLE clean i128 op
%5 = lshr i128 %4, 64
%6 = trunc nuw i128 %5 to i64
%7 = call i64 @cq_measure_ull(i64 %6)       ; clean i64 ABI sink
```
Directly analogous to the f16 / `_BitInt` **intermediate** cases that already work.
Verified: i128 `udiv`/`urem`/`mul` survive as **single clean IR ops** at `-O1` (the
`__udivti3`/`__multi3` libcall expansion is **backend-only**, not in the Stage-1 IR
the pass sees), so they do **not** taint-escape. (Caveat: a *full* 128×128→128 `mul`
also synthesizes `@llvm.fshl.i128`, an i128 intrinsic that is **not** in the curated
set → would decline; `mulhi` via `zext` does not hit this.)

---

## 3. Tier-1 design — i128 as a template width (Scenario B)

### 3.1 Frozen surface — **+206 `cq_template_*` symbols, ZERO new `cqrt_*` core**
Confirmed by regenerating the table and compiling under the exact
`runtime_header_compile` gate (`-std=c11 -Wall -Wextra -Wpedantic -Werror`, exit 0):

- `tools/opcode_table.yaml`: add `i128: {bits:128, c_type:"__int128", domain:"int"}`
  to the widths map; append `i128` to the **13 int binary rows**
  (add/sub/mul/sdiv/udiv/srem/urem/and/or/xor/shl/lshr/ashr) and **12 cast pairs**
  (zext/sext from i8/i16/i32/i64→i128; trunc i128→i8/i16/i32/i64).
- `tools/abi_codegen.py`: `WIDTH_INFO['i128'] = {ctype:'__int128', fmt via (long long)}`
  (the i128 `_hl` literal carries cleanly as an `__int128 b_classical` param — clang
  emits genuine 128-bit literals that overflow i64, e.g.
  `add nuw nsw i128 %2, -44291611843981158765213436369005982225`).
- IR pass — **3 one-liners**: `intBits` (`+128`), `abiWidthFromType` (`case 128`),
  `typeForAbiWidth` (`getInt128Ty`). `castInScope` already works via `intBits`. **No**
  `kRows`/`allSuffixes`/`frontEndIntrinsicNames` edits (i128 is never a theta/phi/
  measure suffix — that is Scenario A).
- `tools/gen_templates_test.py`: 1732 → 1938.
- **No** `cqrt_alloc_i128`/`measure_i128`/`ry_i128`/`rz_i128` (source/sink stay i64),
  **no** `cqrt_copy_i128`, **no** CQ.h change. The whole-DAG uncompute ships the i128
  `_unc` twins for free (`EmitInverse.cpp:128` rebuilds the `_unc` FunctionType from the
  forward call's own param types — it never calls `cqrt_copy`).

Both tiers are pure ABI **additions** (new symbols, never changes to existing ones),
so Tier-1 is **not technically freeze-gating** — it can land pre- *or* post-freeze.
The freeze "gate" is the owner's *scope* decision (is i128 in v1?), not a lock-in.

### 3.2 The MANDATORY safety fences (the load-bearing work — Rule-13 core change)
Extending the central `abiWidthFromType` to return `"i128"` is consumed in ~9 sites
that currently **decline via the `abiWidthFromType(i128).empty()` arm**. Without
these fences, the widening silently flips those declines to dangerous accepts:

1. **`copyFn` fence (WidthDispatch.cpp:132).** Today `if (!Ty || !Ty->isIntegerTy())`
   — i128 *is* an integer, so a non-empty width would make `copyFn(i128)` mint a
   `cqrt_copy_i128` that does not exist. Tighten to
   `!Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64`, so tainted i128
   `select`/`switch`/value-merge **still decline** (no `cqrt_copy_i128` ever minted),
   now via `copyFn`-null rather than `abiWidthFromType`-empty. **Re-anchor** the three
   `control_swap_reject_*_i128.ll` fixtures (their `CHECK` strings depend on the old
   arm).
2. **`dataTemplateFn` phantom-mint guard (WidthDispatch.cpp:200).** `ArithLowering`
   gates a binary op on `abiWidthFromType().empty()` **alone** and `dataTemplateFn`
   mints via `getOrInsertFunction` with **no** width guard — so the moment i128 enters
   the recognizers, any tainted i128 op the YAML does *not* cover mints a **phantom
   unresolved** `cq_template_*_i128` (verify-clean, exit 0, **link-fails**). Reproduced
   on `spec_reject_intermediate_width.ll`. Add a defensive `typeForAbiWidth`/YAML-set
   guard so an uncovered width is a **loud null-callee decline**, not a phantom mint.
3. **`SpecializeReject::unsupportedWidth` (SpecializeReject.cpp:93).** Flips so an i128
   intermediate **inside a specialized clone** is accepted — a *behavior change* needing
   a `spec_accept_i128_body.ll` (mirroring `spec_accept_f16_body.ll`) **and** confirming
   the BennettWrap/EmitInverse void-uncompute synthesizes the i128 `_unc` twins. The
   per-opcode in-scope check must distinguish *opcode*, not just *width* (so an i128
   `udiv` inside a clone declines if div is excluded).
4. **Re-point `spec_reject_intermediate_width.ll`** to a genuinely-still-unsupported
   width (i256 / x86_fp80), since i128 now accepts.

**Stays correctly declined (width-independent guards — verified did NOT flip):**
`spec_overaccept_probe_i128_return.ll` (return-ABI gate is `RetW != "i32"`); the i128
`select`/`switch`/value-merge control fixtures (the `copyFn` fence above).

This is a **Rule-13 core change** (`abiWidthFromType` is consumed in ~20 files). It
needs independent adversarial clearance with an explicit probe family proving tainted
i128 `select`/`switch`/merge/value-arm and i128-in-specialized-body **still decline**
loudly post-widening.

### 3.3 Open scope sub-questions (owner)
- **`icmp i128` IN or OUT.** OUT keeps the delta at **+206** and loud-declines a
  straight-line i128 compare-to-data (clang *does* emit `icmp ugt i128`); IN adds +60
  (→ +266) for compare parity but enlarges the permanent surface and needs the i128
  compare-uncompute Rule-13 over-accept clearance (the WI-7 i64 lesson). **Recommend OUT**
  for the minimal first surface.
- **`div`/`rem` i128 IN or OUT.** Single clean IR ops at `-O1`, so template-able; but
  including them means the SpecializeReject body scan must gate per-opcode. Recommend
  IN for grid consistency, with the per-opcode audit.

---

## 4. Tier-2 analysis — i128 SOURCE/SINK — DEFER post-freeze

**No frontend declaration keeps `__int128` whole within the SSA-only taint model**
(tested all four against real `-O1`):
- by-value `__int128`, two-i64 scalars, `struct{i64,i64}` → all shred to `{i64,i64}`
  (aggregate theta return + 2-arg measure + split add).
- `<2 x i64>` vector → SSA-clean boundary, but real i128 arith reassembles via
  `extractelement`/`zext`/`shl`/`or` and the add re-splits.
- by-pointer / sret → the **only** form that keeps `add i128` whole, but it is a
  load/store **memory** program (theta is `void(ptr out, ptr in, double)`, no seedable
  SSA result) = exactly the **Phase-7.5 QRAM Shadow** model, blocked today by the
  tainted-store decline.

The three viable register strategies imply **mutually incompatible** frozen surfaces
(aggregate `{i64,i64}` return + 2-arg measure vs a `void(ptr,...)` memory ABI), so
**do NOT reserve frozen slots now** — reserving the wrong shape is a permanent
mistake. Tier-2 is a clean post-freeze **addition** (or may fall out of Phase 7.5 for
free via the by-pointer form).

### 4.1 The ONE mandatory pre-freeze safety item (independent of the Tier-1 decision)
Today a user writing `cq_theta_si128(__int128, double)` gets a **silent classical
no-op** (the `{i64,i64}` aggregate prototype is unrecognized → zero lowering, exit 0)
— a latent silent miscompile. **Make an unrecognized but `cq_`-named aggregate
theta/measure prototype a LOUD decline** (a prototype-shape reject in
`declMatchesPrototype`/the prototype guard), so Tier-2 can never silently miscompile,
whether or not Tier-2 ever ships.

---

## 5. Recommendation

1. **Do now, regardless (small, mandatory safety):** the §4.1 aggregate-prototype
   loud-decline fence. Closes a latent silent miscompile. ~1 guard + 1 decline fixture.
2. **Owner scope decision — Tier-1 (Scenario B intermediate i128):**
   - **Ship it** if i128-intermediate expressiveness is wanted in v1 (the roadmap's
     2026-06-19 "wide integers IN for v1" intent). Bounded: **+206** frozen symbols,
     zero core ABI, but a **real Rule-13 core change** to `abiWidthFromType` with the
     §3.2 mandatory fences + independent clearance.
   - **Defer it** post-freeze if the +206 permanent surface + core-change risk is not
     justified by demand yet. i128 then becomes a clean additive extension; v1
     loud-declines i128, nothing miscompiles.
3. **Tier-2 (i128 source/sink): DEFER post-freeze** either way. No reservable slots.
   Revisit with Phase 7.5 (the by-pointer form may come for free).

**Author's lean:** do (1) now; ship **Tier-1 with `icmp` OUT, div/rem IN**, treating
the §3.2 fences as the load-bearing deliverable (not the templates); defer Tier-2.
This matches the f16 precedent (a bounded frozen width add + a load-bearing no-clone
fence + Rule-13 clearance) and delivers the common wide-intermediate case.

---

## 6. If Tier-1 is approved — work breakdown (red→green→clear, Rule 16)
1. YAML widths + rows + cast pairs; `abi_codegen` WIDTH_INFO; regen; SHA recheck;
   `gen_templates_test` 1732→1938.
2. The 3 recognizer one-liners + the §3.2 fences (copyFn >64, dataTemplateFn guard).
3. Re-anchor the 3 control i128 fixtures + re-point `spec_reject_intermediate_width`.
4. Positive: `lowering_i128_intermediate_mulhi.ll` (+ its `_unc` shape) and
   `spec_accept_i128_body.ll`; e2e golden round-trip (`slice_i128_mulhi.c`).
5. Adversarial probe family: tainted i128 `select`/`switch`/value-merge/source/sink/
   `udiv`(if excluded)/specialized-body all **still decline** loudly.
6. Independent Rule-13 clearance (core change to `abiWidthFromType`).

See memory `7-1-D-i128-abi-shred` (the shred) and `bitint-already-lowers-clang-rounds-and-masks`
(the sibling _BitInt finding — clang lowers wide-C semantics into stock ABI-width ops).
