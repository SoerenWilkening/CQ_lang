# bd 3c6m.13 — empirical evidence artifact (for owner ratification)

Preserved per the design-review framing lens (the re-scope rests on measured facts that
**contradict the ticket's literal description**; the owner was away at the decision point).
Reproduce with the census harness `tools/library_coverage/full_surface/` (corpus at
`/tmp/openlibm` + `/tmp/bc`, built per `full_surface/README.md`) and
`full_surface/batch_dump.py` + `full_surface/dump_ir.py`.

## 1. The reads are UNDER TAINTED CONTROL, not straight-line (contradicts the ticket)

The ticket says "exp2 declines on a **straight-line** DYNAMIC-index const-table read
(matchQramAccess fails)". Measured post-census-pipeline IR (`/tmp/irdump/*_inl.ll`) shows the
table reads sit in **conditionally-reached blocks** (control-dependent on a tainted branch):

```
exp   e_exp.c:138  %35 = getelementptr [2 x double], @ln2HI, 0, %33   in block `34: preds %31`
                    (reached via `br i1 %32, label %34, label %42` — %32 tainted)
fmod  e_fmod.c:48  %36 = getelementptr [2 x double], @Zero, 0, %35    in block `34: preds %32`
                    (%35 = lshr i64 %3, 63 — tainted sign bit; one arm of a diamond)
exp2  s_exp2.c:376 %42 = getelementptr [512 x double], @tbl, 0, %41   in block `30: preds %26,%20`
                    (a join reached from TWO arms — conditional, not the entry)
```

`matchQramAccess` does **not** "fail structurally" on these — they are clean array-decay geps
of a `[N x double]` const global with a tainted trailing index. The **sole** reason the carve
declines is `instUnderTaintedControl == true`. A genuinely straight-line dynamic-index
const-global read **already lowers today** (`lowering_qram_read_fp64.ll`,
`lowering_qram_read_const_global_i32.ll`). So there is no straight-line `matchQramAccess` gap
to widen.

## 2. Accepting the under-control read yields 0 new compiles (baseline vs throwaway probe)

A throwaway probe patch was built (accept a const-global gep+load under tainted control) and
run over the 16-cell "unsupported instruction" cluster. Result — **every cell reclassifies to
a DEEPER blocker; none compiles**:

| cell(s) | baseline (real pass) | with QROM-under-control accepted |
|---|---|---|
| exp exp2 cosh sinh erf erfc (+ expf exp2f coshf sinhf erff erfcf) | `unsupported instruction` (the QROM read) | `nested control flow under quantum control` (L6) |
| fmod remainder | `unsupported instruction` | `unknown callee` (inner call) |
| fmodf remainderf | `unsupported instruction` | `loop under quantum control` (7.3) |
| **COMPILES** | **0** | **0** |

Exact reclassified diagnostics (probe run): `exp` → `s_exp2.c`/`e_exp.c:116` nested control;
`fmod` → `e_fmod.c:99` unknown callee. The QROM read is the *first-tripped* instruction only
because `declineTaintEscapes` runs before `detectControlRegions` (CQLoweringPass.cpp L116 vs
L163).

## 3. Even a de-nested DEPTH-1 read-mux declines structurally (0-compiles is robust)

Independent `ArmClassify` trace: `if(q<k) r=tbl[q]; return measure(r);` — with the read
hoisted — still declines at detection because the load-result merge incoming has no accept
path (`walkValueChain` breaks on a `LoadInst`; `isValueChangingOp(load)` → `value-arm
swap-route` decline). So de-nesting does not unlock the widen; routing a copy-out data-mux is
L6-coupled reversal integration, not a QROM accept-shape gap.

## Conclusion

The 18-cell "unsupported instruction" bucket maps to **L6 (bd 3c6m.14)**, not L5. This
corrects bd memory `libm-full-surface-empirical-decline-2026-07-11` (which bucketed it as
"ACTUALLY L5-QROM"). The delivered change is a **precise decline signpost only** — no
accept-shape widening (a non-win + over-accept trap). Owner decision on how to finally dispose
3c6m.13 vs 3c6m.14 remains open (AskUserQuestion posed; owner away).
