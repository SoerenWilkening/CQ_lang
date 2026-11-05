; cq-xhv4 (169's shape, CR rule 23): f, compiled without FENV_ACCESS, calls the strictfp h in a quantum
; arm. h carries the environment (E1); f does not: it runs in the default environment (mode literal 0,
; an empty flags seed), calls h unguarded (rule 19: no non-pure gate), merges h's new flags with the old
; under the arm's predicate and drops them (uncomputed, no output). In h, FORCE_EVAL's constrained fdiv
; of two literals under a quantum predicate is folded: its INVALID bit (1) enters the flags under the
; predicate, no host op; its volatile store to a local nothing reads is dead (rule 24: nothing).
; CHECK __cq_q_f_1: call fastcc { i32, i32 } @__cq_q_h_1(i32 %{{x}}, i32 0, i32 %{{f}})
; CHECK __cq_q_f_1: call i32 @cq_template_select_i32(
; CHECK __cq_q_h_1: call i32 @cq_template_select_i32_ll(i32 %{{p}}, i32 1, i32 0)
; CHECK-COUNT __cq_q_h_1: constrained.fdiv 0
; CHECK-COUNT __cq_q_h_1: store 0
; CHECK-COUNT __cq_q_f_1: fegetround 0
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define internal fastcc i32 @h(double %x) #1 {
  %tmp = alloca float, align 4
  %i = bitcast double %x to i64
  %z = icmp eq i64 %i, 0
  br i1 %z, label %zero, label %nz
zero:
  %q = call float @llvm.experimental.constrained.fdiv.f32(float 0.000000e+00, float 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  store volatile float %q, ptr %tmp, align 4
  br label %end
nz:
  %e = lshr i64 %i, 52
  %t = trunc i64 %e to i32
  br label %end
end:
  %r = phi i32 [ -2147483648, %zero ], [ %t, %nz ]
  ret i32 %r
}
define internal fastcc i32 @f(double %x) #2 {
  %c = fcmp olt double %x, 1.000000e+00
  br i1 %c, label %call, label %end
call:
  %r = call fastcc i32 @h(double %x) #0
  br label %end
end:
  %p = phi i32 [ %r, %call ], [ 7, %0 ]
  ret i32 %p
}
define i32 @g(double %x0, double %th) {
  %x = call double @cq_theta_f64(double %x0, double %th)
  %v = call fastcc i32 @f(double %x)
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare float @llvm.experimental.constrained.fdiv.f32(float, float, metadata, metadata)
attributes #0 = { strictfp }
attributes #1 = { noinline strictfp }
attributes #2 = { noinline }
