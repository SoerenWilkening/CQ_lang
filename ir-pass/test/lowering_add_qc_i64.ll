; lowering_add_qc_i64.ll — Per-width Q+C add for the i64 ABI, OUT OF PLACE.
; Two theta-handle + i64-literal adds lower to `cq_template_add_i64_hl(handle,
; classical)`, each minting a FRESH rail that the whole-DAG spine then zeroes
; (`_unc`) and frees.
;
; THIS IS ALSO THE M-C FENCE-FALLBACK PIN AT THIS WIDTH (bd
; test_C_libtooling-6uqc, Increment 2a). Since M-C, a `q + c` whose parent
; handle is DEAD AFTER the op lowers IN PLACE to `cqrt_addc_i64` instead — see
; lowering_mc_addc_i64.ll, the positive twin. The SECOND add here is what keeps
; both sites out of place, and it is the boundary this file exists to hold:
;   * for `%c`, `%d` is a data use of `%a` AFTER it            -> G6 refuses;
;   * for `%d`, `%c` is a PRIOR use but it is a still-unlowered tainted opcode
;     the Phase-5 spine will adjoint later (reading `%a`)      -> G7 refuses.
; So a fan-out parent NEVER converts, at any width. Deleting the second add
; would silently move this file to the in-place stream and leave
; `cq_template_add_i64_hl` with no per-width coverage at all (MEASURED: at i1,
; i8 and i16 this file is the ONLY fixture that emits it).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i64(i64 51)
; CHECK:     call i32 @cq_template_add_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 1000000)
; CHECK:     call i32 @cq_template_add_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 7)
;
; CHECK-NOT: call i32 @cq_template_add_i64(i32 %{{.*}}, i32 %
; CHECK-NOT: cqrt_addc_
; CHECK-NOT: cq_theta_sll
; CHECK-NOT: add i64

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)

define void @example() {
entry:
  %a = call i64 @cq_theta_sll(i64 51, double 5.000000e-01)
  %c = add i64 %a, 1000000
  %d = add i64 %a, 7       ; fan-out: BOTH sites stay out of place
  ret void
}
