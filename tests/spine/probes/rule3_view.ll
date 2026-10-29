; cq-su3p: CR rule 3 views of a narrow register around a rule 10 merge. -O1 widens a bool register to
; a byte around its state-prep merges (113): the register stays one i1 rail, the i8 compares narrow
; to xor_i1, no select_i8 over copies of the rotated rail, and a compare that read the register
; before its in-place rotation but was sunk after it (113's %32) is lowered before the rotation.
declare double @llvm.acos.f64(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i8 @cq_measure_ui8(i8)

define range(i32 0, 16) i32 @dicke4() {
  %1 = tail call double @llvm.acos.f64(double 0x3FE6A09E667F3BCD)
  %2 = fmul double %1, 2.000000e+00
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %2)
  %4 = xor i1 %3, true
  br i1 %3, label %9, label %5

5:
  %6 = tail call double @llvm.acos.f64(double 0x3FE279A74590331C)
  %7 = fmul double %6, 2.000000e+00
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef %7)
  br label %9

9:
  %10 = phi i1 [ %8, %5 ], [ %3, %0 ]
  %11 = zext i1 %10 to i32
  %12 = xor i1 %10, %4
  %13 = select i1 %12, i32 2, i32 0
  %14 = or disjoint i32 %13, %11
  %15 = icmp eq i32 %14, 3
  br i1 %15, label %16, label %21

16:
  %17 = tail call double @llvm.acos.f64(double 0x3FEA20BD700C2C3E)
  %18 = fmul double %17, 2.000000e+00
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %18)
  %20 = zext i1 %19 to i8
  br label %21

21:
  %22 = phi i8 [ %20, %16 ], [ 0, %9 ]
  %23 = zext i1 %10 to i8
  %24 = icmp ne i8 %22, %23
  br i1 %24, label %25, label %29

25:
  %26 = trunc nuw i8 %22 to i1
  %27 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %26, double noundef %2)
  %28 = zext i1 %27 to i8
  br label %29

29:
  %30 = phi i8 [ %28, %25 ], [ %22, %21 ]
  %31 = zext i1 %12 to i8
  %32 = icmp ne i8 %22, %31
  %33 = trunc nuw i8 %30 to i1
  %34 = xor i1 %24, %33
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %33)
  %36 = zext i1 %35 to i32
  %37 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34)
  %38 = select i1 %37, i32 2, i32 0
  %39 = or disjoint i32 %38, %36
  %40 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %32)
  %41 = select i1 %40, i32 4, i32 0
  %42 = or disjoint i32 %39, %41
  %43 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4)
  %44 = select i1 %43, i32 8, i32 0
  %45 = or disjoint i32 %42, %44
  ret i32 %45
}
; CHECK-COUNT dicke4: select_i8 0
; CHECK-COUNT dicke4: zext_i1_to_i8 0
; CHECK-COUNT dicke4: icmp_ne_i8 0
; CHECK-COUNT dicke4: cqrt_alloc_i1 2
; CHECK-COUNT dicke4: cqrt_ry_i1_controlled 3
; CHECK dicke4: call void @cqrt_ry_i1_controlled(i32 %{{f}}, i32 %{{q1}}, double %{{a}})

; A view read wide (a byte measurement): one zext_i1_to_i8 of the register's rail, taken at the merge.
define i8 @wide(double %t) {
entry:
  %q = call i1 @cq_theta_i1(i1 false, double %t)
  br i1 %q, label %a, label %j
a:
  %r = call i1 @cq_theta_i1(i1 false, double %t)
  %z = zext i1 %r to i8
  br label %j
j:
  %p = phi i8 [ %z, %a ], [ 0, %entry ]
  %m = call i8 @cq_measure_ui8(i8 %p)
  ret i8 %m
}
; CHECK-COUNT wide: select_i8 0
; CHECK-COUNT wide: cq_template_zext_i1_to_i8( 1
; CHECK-COUNT wide: cqrt_alloc_i1 2
