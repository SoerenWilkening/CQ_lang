; control_angle_select_reject_fp_literal_seed_tree_pin.ll — DECLINE (bd
; test_C_libtooling-dm7f.54 round-2 review H5; plain C at -O1):
;
;     double x = u; cq_theta(&x, .5); _Bool b, c (rotated);
;     double t = 2.0;
;     if (x == 2.0 && b) { cq_theta(&t, c ? .3 : .7); }
;
; An fp literal seed (2.0) whose dominating edge pins a LIVE tainted `x` to 2.0
; through a LOGICAL-AND condition. The literal-seed pin's fp walk now reads every
; `fcmp` the edge FORCES (`forcedFcmpLeavesOf`, F2's dm7f.52 machinery, lifted),
; so it sees `x == 2.0` under `&&` exactly as the integer path's LVI sees an
; integer pin. Today the enclosing diamond declines `control flow` first and
; MASKS that fence (the fp fence has no branch-free pin to exercise it alone:
; LVI has no fp lattice and `llvm.assume` of a tainted condition is a taint
; escape). RETIREMENT TRIGGER: when a nested-arm widening admits this diamond,
; this file's string must become F2's `state prep seed is proven equal to the
; condition register` — never an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

define i32 @f(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FE6666666666666) #2
  %5 = fcmp oeq double %2, 2.000000e+00
  %6 = select i1 %5, i1 %3, i1 false
  br i1 %6, label %7, label %10

7:                                                ; preds = %1
  %8 = select i1 %4, double 3.000000e-01, double 0x3FE6666666666666
  %9 = tail call double @cq_theta_f64(double noundef 2.000000e+00, double noundef %8) #2
  br label %10

10:                                               ; preds = %1, %7
  %11 = phi double [ %9, %7 ], [ 2.000000e+00, %1 ]
  %12 = tail call double @cq_measure_f64(double noundef %11) #3
  %13 = fptosi double %12 to i32
  %14 = tail call double @cq_measure_f64(double noundef %2) #3
  %15 = fptosi double %14 to i32
  %16 = add nsw i32 %15, %13
  ret i32 %16
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
