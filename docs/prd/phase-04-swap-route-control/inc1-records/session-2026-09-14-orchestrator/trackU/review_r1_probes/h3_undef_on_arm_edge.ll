; F-U1 attack: the undef incoming sits on the ARM edge, not the straight-through
; edge. Normalizing it turns a quantum-register-vs-undef merge into a
; register-vs-zero data mux.
target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_i32(i32)

define i1 @example() {
entry:
  %t = call i1 @cq_theta_i1(i1 undef, double 5.000000e-01)
  br i1 %t, label %arm, label %j
arm:
  br label %j
j:
  %m = phi i1 [ %t, %entry ], [ undef, %arm ]
  %r = call i1 @cq_measure_i1(i1 %m)
  ret i1 %r
}
