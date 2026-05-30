; lowering_zext_bridge_measure.ll — THE integration bridge (IMPLEMENTATION
; §1.3 worked example; the payoff of capture-before-RAUW, risk R1). A tainted
; data-position compare whose i1 result is `zext`'d to i32 and measured must
; lower FULLY, in three chained steps:
;
;   1. compare → `cq_template_fcmp_une_f32_hl(handle, 1.0)`  (the i32 FLAG)
;   2. zext    → `cq_template_zext_i1_to_i32(flag)`          (the BRIDGE)
;   3. measure → `cqrt_measure_i32(handle)`                  (the SINK)
;
; This is exactly Clang's `%c = fcmp …` → `%z = zext i1 %c to i32` →
; `cqrt_measure_i32(%z)` stream after `-O1`.
;
; WHY THIS PINS R1: the driver captures the zext's widths at COLLECTION time,
; in program order, BEFORE any rewrite. At that moment the zext is the
; well-typed `zext i1 %c to i32`, so its captured pair is (i1 → i32). The
; compare is rewritten first (it precedes the zext in program order), which
; RAUWs `%c`(i1) to the i32 flag handle — so by the time `rewriteCast` runs,
; the zext is the MALFORMED transient `zext i1 <i32-flag> to i32` and a live
; `getSrcTy()` read would yield i32. Because the symbol uses the CAPTURED
; `From` (= i1), cast lowering emits `cq_template_zext_i1_to_i32(flag)` — the
; correct bridge — and the driver erases the malformed zext. If the width were
; read at rewrite time it would wrongly be i32, emitting the garbage
; `cq_template_zext_i32_to_i32`; the CHECK-NOT below locks that out.
;
; All three i32 handles thread cleanly; the second RUN line GUARDS the two
; cross-type RAUWs in the chain (i1 compare result → flag, then the zext
; result → bridge handle; risk R2, assertions-OFF LLVM-19).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f32(float 2.000000e+00)
; CHECK:     call i32 @cq_template_fcmp_une_f32_hl(i32 %{{[a-zA-Z0-9_.]+}}, float 1.000000e+00)
; CHECK:     call i32 @cq_template_zext_i1_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; The malformed garbage symbol from a rewrite-time width read must NOT appear,
; and the bare `fcmp`/`zext` must be gone (both lowered).
; CHECK-NOT: cq_template_zext_i32_to_i32
; CHECK-NOT: = fcmp
; CHECK-NOT: = zext
; CHECK-NOT: cq_theta_f32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %a = call float @cq_theta_f32(float 2.0, double 5.000000e-01)
  ; Data-position compare (feeds a cast, not a branch) → HL flag template.
  %c = fcmp une float %a, 1.0
  ; Clang's i1→i32 bridge. Its (i1→i32) widths are captured BEFORE the compare
  ; RAUW rewrites %c to the i32 flag — the crux of R1.
  %z = zext i1 %c to i32
  ; Measure the i32 bridge handle (suffix si32 → ABI i32 → cqrt_measure_i32).
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
