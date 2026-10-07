; p3kd.7.7.1: a source-untaken nested classical arm must not materialize
; raw poison in the fixed gate script. This is not an adjoint-pairing test:
; the merged result escapes, so the one xor literal has no inverse slot.
; One entry freeze supplies every moved use of this typed constant. A second
; function using LLVM's module-uniqued poison needs its own local SSA value.
; RUN: %cq-opt -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NO-RAW < %t.ll
; CHECK-LABEL: define i32 @main_shape(
; CHECK: [[S:%[^ ]+]] = freeze i32 poison
; CHECK-NOT: freeze i32 poison
; CHECK: call i32 @cq_template_xor_i32_hl(i32 {{[^,]+}}, i32 [[S]])
; CHECK: call i32 @cqrt_measure_i32
; CHECK-LABEL: define i32 @other_function(
; CHECK: [[T:%[^ ]+]] = freeze i32 poison
; CHECK-NOT: freeze i32 poison
; CHECK: call i32 @cq_template_xor_i32_hl(i32 {{[^,]+}}, i32 [[T]])
; CHECK: call i32 @cqrt_measure_i32
; NO-RAW-NOT: call {{.*}}i32 poison

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main_shape(i32 %x, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %g = icmp sgt i32 %q, 5
  br i1 %g, label %mid, label %merge
mid:
  %a = add i32 %q, 1
  %c = icmp sgt i32 %n, 3
  br i1 %c, label %arm, label %merge
arm:
  %b = xor i32 %q, poison
  br label %merge
merge:
  %r = phi i32 [ %q, %entry ], [ %a, %mid ], [ %b, %arm ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

define i32 @other_function(i32 %x, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %g = icmp sgt i32 %q, 5
  br i1 %g, label %mid, label %merge
mid:
  %a = add i32 %q, 1
  %c = icmp sgt i32 %n, 3
  br i1 %c, label %arm, label %merge
arm:
  %b = xor i32 %q, poison
  br label %merge
merge:
  %r = phi i32 [ %q, %entry ], [ %a, %mid ], [ %b, %arm ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
