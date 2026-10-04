; lowering_unroll_const_trip.ll — ACCEPT (3c6m.55 Inc 2 Lever B, ticket lf8s):
; the static-K force-unroll pre-pass (LoopUnrollPrepass.cpp) claims a PROVEN
; constant-trip tainted-accumulator polynomial loop — the openlibm `__polevll`
; Horner shape that previously X1-declined (`lowering_reject_loop_cross_iter.ll`
; documents the deferral this increment retires):
;     double acc = .., x = ..; cq_theta(&acc, ..); cq_theta(&x, ..);
;     for (int i = 2; i != 0; i--) acc = fma(acc, x, *++p);   // p over const C[]
;     return cq_measure(acc);
; The loop is marked `!llvm.loop.unroll.disable` (openlibm marks `__polevll`;
; that metadata is loop-unroll-PASS cost-model input the `UnrollLoop` UTILITY
; never reads — pinning that the pre-pass overrides it). SCEV proves the
; countdown trip (2) exactly; the body carries NO cq call, NO tainted control,
; NO in-place rail (the accumulator's latch incoming is an out-of-place fmuladd
; — exactly what makes the rolled form X1-unlowerable), and the loop-carried
; coefficient pointer phi over the internal-constant table mirrors the real
; `@P`/`@Q` walk. Post-unroll the body is the straight-line QQL fma stream the
; substrate already lowers: NO loop, NO phi, two `cq_template_fma_f64_qql`
; calls walking C[1] then C[2].
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CLEAN %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double %seed)
; CHECK:     call i32 @cqrt_alloc_f64(double %mul)
; The unrolled Horner steps, in iteration order (C[1] = 2.0, then C[2] = 3.0):
; CHECK:     call i32 @cq_template_fma_f64_qql(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double 2.000000e+00)
; CHECK:     call i32 @cq_template_fma_f64_qql(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double 3.000000e+00)
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; The loop is GONE: no conditional branch, no phi, no rolled fmuladd survive.
; CLEAN-NOT: br i1
; CLEAN-NOT: = phi
; CLEAN-NOT: call double @llvm.fmuladd

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@C = internal constant [3 x double] [double 1.000000e+00, double 2.000000e+00, double 3.000000e+00], align 8

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.fmuladd.f64(double, double, double)

define double @horner(double %seed, double %mul) {
entry:
  %acc0 = call double @cq_theta_f64(double %seed, double 5.000000e-01)
  %x = call double @cq_theta_f64(double %mul, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 2, %entry ], [ %dec, %loop ]
  %acc = phi double [ %acc0, %entry ], [ %fma, %loop ]
  %p = phi ptr [ @C, %entry ], [ %gep, %loop ]
  %gep = getelementptr inbounds i8, ptr %p, i64 8
  %c = load double, ptr %gep, align 8
  %fma = call double @llvm.fmuladd.f64(double %acc, double %x, double %c)
  %dec = add nsw i32 %i, -1
  %done = icmp eq i32 %dec, 0
  br i1 %done, label %exit, label %loop, !llvm.loop !0

exit:                                             ; preds = %loop
  %m = call double @cq_measure_f64(double %fma)
  ret double %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
