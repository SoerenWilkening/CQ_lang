; lowering_live_record_source_theta_accept.ll — ACCEPT: a SOURCE `cq_theta` is
; not a guard site (M-A Increment 1, bd test_C_libtooling-6uqc).
;
; ONE OPERAND apart, this is
; lowering_reject_live_record_derived_cond_theta.ll: the second theta's arg-0 is
; the CLASSICAL `%u0` instead of the quantum wire `%q`. Everything the reject
; fixture declines over is still here and still live — the emitted stream has
; `sitofp`/`fadd`/`sqrt`/`fcmp` rails of `%h`, none uncomputed, none freed —
; but the second rotation ALLOCATES ITS OWN wire `%h1` and rotates that, so no
; record of `%h1` exists (a source theta mints its wire; nothing can have been
; derived from it yet).
;
; TWO PROPERTIES IN ONE FIXTURE, and both are load-bearing: the guard keys on
; the CHAINED half of the emitter-recorded split (`RotationLowering` knows which
; branch it took, so this is a fact and not an inference), and it keys on the
; gate's OWN wire rather than on "some record is live somewhere in the module".
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.sqrt.f64(double)

define i32 @slice(i32 %u0) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %cast = sitofp i32 %q to double
  %add  = fadd double %cast, 3.000000e+00
  %rt   = call double @llvm.sqrt.f64(double %add)
  %cmp  = fcmp ole double %rt, 5.000000e+00
  %f    = zext i1 %cmp to i32
  %m    = call i32 @cq_measure_si32(i32 %f)
  %q2   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)  ; SOURCE theta — fresh wire
  %m2   = call i32 @cq_measure_si32(i32 %q2)
  %r    = add nsw i32 %m2, %m
  ret i32 %r
}

; The records of the FIRST wire are all still standing at the second rotation:
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[CAST:.*]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[H]])
; CHECK-NEXT: %[[OP:.*]] = call i32 @cq_template_fadd_f64_hl(i32 %[[CAST]], double 3.000000e+00)
; CHECK-NEXT: %[[SQ:.*]] = call i32 @cq_template_sqrt_f64(i32 %[[OP]])
; CHECK:      %[[H2:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
