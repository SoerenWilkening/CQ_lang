# Phase 7.1 Increment D — Rule-13 Clearance Record (FROZEN ABI)

> Mandatory pre-commit clearance for the freeze-gating wide-width increment
> (PRD §4 done-criterion #5, plan §6 CLEAR step). Recorded 2026-06-20.

## Scope as shipped: **f16 only** (i128 deferred)

Increment D adds the **f16 (IEEE `half`)** fp width as a frozen, permanent ABI.
The sibling **i128 is DEFERRED** (owner decision 2026-06-20): empirical verification
disproved the plan §6 i128 mechanism — clang's C ABI shreds a `__int128`
parameter/return into `{i64,i64}` aggregates on x86_64 (darwin **and** linux), so
`abiWidthFromType`/`declMatchesPrototype` can never recognize the source, a tainted
`add i128` is split into low-i128 + high-i64 ops, and `-O1` eliminates i128
intermediates. i128 is tracked as a pre-freeze follow-up (`test_C_libtooling-n0ui`,
memory `7-1-D-i128-abi-shred`). f16 is clean end-to-end (`half` everywhere).

## Verdict: **CLEAR** (0 blockers)

Six independent adversarial lenses (frozen-ABI lockstep · f16-angle/no-cloning
fence · cast-source-width core fix · symbol-count/cast-matrix/i128-hygiene ·
runtime-trace/e2e · completeness critic). 5 CLEAR, 1 clear-with-fixes; **0
blockers**. All findings resolved before commit:

- **MAJOR — f16-internal specialization expansion.** Adding f16 to `fpBits` flips
  `SpecializeReject::unsupportedWidth(half)` false, so a classical helper with an
  f16 intermediate (called under quantum control) now specializes (was rejected).
  **Resolution: verified correct, accepted, covered.** Empirically the clone
  forward-computes the f16 intermediates, copies out only the **i32** result
  (`cqrt_copy_i32` — f16 carriers are never copied, the angle fence holds), then
  LIFO-reverses every f16 op via its `_unc` twin and frees each rail; verify-clean.
  This is the natural composition of the (already-cleared) f16 templates + the
  (already-cleared) `__cq_q` clone/uncompute spine — not a hazard. Pinned by
  `spec_accept_f16_body.ll`.
- **MINOR — thin cast-fix / f16 coverage.** Added `lowering_sext_i8_to_i32_theta.ll`
  (cast-fix INT theta-source branch), `lowering_fptosi_f16_to_i32.ll` (f16 fp→int
  cast), `lowering_fadd_qc_f16.ll` (f16 Q+C/HL).
- **MINOR — stale doc counts.** Updated `opcode_table.yaml` header (1562→1732,
  68→90 cast pairs, 7→8 widths, per-kind breakdown) and `gen_templates.py`.
- **NITs.** `CQ.h` "14 widths"→"15"; OpcodeLowering cast-fix ordering invariant
  made explicit; second f16 control decline `lowering_reject_f16_classical_mux_phi.ll`.
  The controlled-rz f16 twins are dead frozen ABI **by design** — they match the
  documented pre-existing controlled reserve for all widths (no action).

## The central hazard — f16-angle / no-cloning fence — HOLDS

There is **no `cqrt_copy_f16`**: `WidthDispatch::copyFn` null-guards on
`isIntegerTy` (a `half` is not an integer), and the control path tests
`isFPOrFPVectorTy`. An f16 carrier is an angle, never data (the f64 miscompile
family at a new width). Verified: a tainted-condition f16 data select **declines**
(`control flow under quantum control`) where the shape-identical i8 select
**accepts**; an f16 classical-condition phi mux declines; a tainted f16 return
declines; bfloat (16-bit, non-half) is rejected by `isHalfTy` specificity.

## Frozen f16 symbol surface (PERMANENT at Phase 11)

**Hand-written core ABI** (`runtime/cq_runtime.{h,c}`) — 6 symbols:
`cqrt_alloc_f16`, `cqrt_measure_f16`, `cqrt_ry_f16`, `cqrt_rz_f16`,
`cqrt_rz_f16_controlled`, `cqrt_rz_f16_controlled_inv`.
**Deliberately ABSENT**: `cqrt_copy_f16` (the angle fence — load-bearing).

**Generated template ABI** (`runtime/cq_templates.{h,c}`, from the YAML) —
**+170** symbols (total 1562 → 1732):
- fp binary (fadd/fsub/fmul/fdiv/frem) × f16 across {fwd,inv,controlled,unc}×{qq,hl,(lh)} = +65
- `fneg_f16` × {fwd,inv,unc} = +3
- `fcmp_<pred>_f16` × 6 preds × {fwd_qq,fwd_hl,inv_qq,inv_hl,unc_qq,unc_hl} = +36
- 22 cast pairs touching f16 (fpext f16→{f32,f64}; fptrunc {f32,f64}→f16;
  sitofp {i8,i16,i32,i64}→f16; uitofp {i1,i8,i16,i32,i64}→f16;
  fptosi f16→{i8,i16,i32,i64}; fptoui f16→{i1,i8,i16,i32,i64}) × {fwd,inv,unc} = +66

**Frozen frontend** (`include/CQ.h`) — `cq_theta_f16`, `cq_phi_f16`,
`cq_measure_f16` + the `_Float16` `_Generic` arm in all three blocks. NO
`default:` arm (non-ABI `_BitInt(N)` stays a compile-error decline).

## Non-frozen change shipped alongside (no ABI impact)

`OpcodeLowering.cpp` cast-source-width fix: a cast directly off a tainted theta
handle recovers its logical source width from `HandleWidth` (Increment A's
side-table) instead of the laundered i32. Fixes a pre-existing latent gap (every
non-i32-source cast off a theta — `fpext f16→f32`, `sext i8→i32`, … — previously
declined). Pure pass logic; makes existing frozen symbols reachable; verified to
not regress the measured-compare zext bridge.

## Gates (all green)

29/29 ctest · 14 f16 lit fixtures · 7 frontend (smoke rows + `_BitInt` reject) ·
`gen_templates.py --check` drift 0 · `gen_templates_test.py` (count 1732) ·
`runtime_header_compile` (`-Wpedantic -Werror`, `_Float16` clean) · e2e
`slice_f16` links + golden-matches (forward + whole-DAG `_unc`).
