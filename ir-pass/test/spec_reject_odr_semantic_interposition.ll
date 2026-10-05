; spec_reject_odr_semantic_interposition.ll — DECLINE twin of
; spec_accept_odr_callee.ll (bd test_C_libtooling-p3kd.2). The widening admits an
; ODR linkage only while the definition is NOT interposable, and LLVM 19's
; `GlobalValue::isInterposable()` is not a function of the linkage alone: under the
; `SemanticInterposition` module flag (clang `-fsemantic-interposition` with
; `-fPIC` on ELF) a definition that is not `dso_local` may be replaced at LOAD
; time by an arbitrary body, ODR or not. This is the accepted `linkonce_odr`
; spelling plus that flag and without `dso_local`, so a predicate keyed on the
; linkage spelling instead of on `isInterposable()` would accept it. It declines,
; character for character.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define linkonce_odr i32 @shift_lodr(i32 %a) {
entry:
  %y = add i32 %a, 5
  ret i32 %y
}

define void @example(i32 %u1) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %r1 = call i32 @shift_lodr(i32 %q1)
  %m1 = call i32 @cq_measure_si32(i32 %r1)
  ret void
}

!llvm.module.flags = !{!0}
!0 = !{i32 1, !"SemanticInterposition", i32 1}

; CHECK: error{{.*}}in function shift_lodr{{.*}}cq specialization: callee has a non-link-exact definition (interposable/derefinable linkage); the linker may bind a different body
