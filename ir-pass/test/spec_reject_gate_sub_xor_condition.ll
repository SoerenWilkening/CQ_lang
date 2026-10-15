; spec_reject_gate_sub_xor_condition.ll — ACCEPT (file name is history).
; Flipped to accept by the dm7f.52 merge (2026-10-15); was a decline pinning the
; then-missing compound-condition lowering ("control flow under quantum
; control", bd test_C_libtooling-p3kd.21). CQ_FINDINGS F6's full
; ~/Desktop/alg_test/dicke/t10.c:
;
;   __attribute__((noinline)) static bool cry_eq(int c, int v, bool t, double th) {
;       if (c == v) cq_theta(&t, th);
;       return t;
;   }
;   c += q0; q1 = cry_eq(c, 1, q1, 0.4); c += q1;
;   q2 = cry_eq(c, 1, q2, 0.1); q2 = cry_eq(c, 2, q2, 0.3);
;
; Every call is compiled at its site (SpecializeGateInline.h, p3kd.21) and
; `-O1` rewrites `c == 1` / `c == 2` for `c = q0 + q1` into `xor i1` / `and i1`
; of the two rails. dm7f.52 lowers those conditions: the condition network is
; minted into a fresh |0> ancilla (two CNOTs for xor, one Toffoli for and), the
; in-place Ry fires as cqrt_ry_i1_controlled on that flag, the network is
; stripped in reverse order, and the ancilla (provably |0> again) is freed.
; The rotated target q2 is frozen (never reverse-played, never freed).
; Semantic evidence reviewed 2026-10-15 (R10): with a=q0, b=q1 after its
; controlled Ry(0.4), q2 receives Ry(0.1 + 0.1[a^b] + 0.3[a&b]), i.e. 0.1/0.2/
; 0.2/0.4 on ab=00/01/10/11, which is the source's unitary; stage 2b 6/6 frees
; verified. No cqrt_x call may appear (nothing is negated; no X on a user
; register).
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.ll
;
; CHECK-LABEL: define {{.*}}@main(
; CHECK:      [[Q0:%h[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[Q0]], double 1.000000e+00)
; CHECK-NEXT: [[Q1:%h[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[Q1]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 [[Q0]], i32 [[Q1]], double 4.000000e-01)
; CHECK-NEXT: [[Q2:%h[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[Q2]], double 1.000000e-01)
;   c == 1  ->  q0 ^ q1, minted, fired, stripped LIFO, freed
; CHECK-NEXT: [[X:%[a-z0-9_]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 [[Q0]], i32 [[X]])
; CHECK-NEXT: call void @cqrt_cnot(i32 [[Q1]], i32 [[X]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 [[X]], i32 [[Q2]], double 1.000000e-01)
; CHECK-NEXT: call void @cqrt_cnot(i32 [[Q1]], i32 [[X]])
; CHECK-NEXT: call void @cqrt_cnot(i32 [[Q0]], i32 [[X]])
; CHECK-NEXT: call void @cqrt_free(i32 [[X]])
;   c == 2  ->  q0 & q1
; CHECK-NEXT: [[A:%[a-z0-9_]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 [[Q0]], i32 [[Q1]], i32 [[A]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 [[A]], i32 [[Q2]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 [[Q0]], i32 [[Q1]], i32 [[A]])
; CHECK-NEXT: call void @cqrt_free(i32 [[A]])
;   c = q0 + q1 + q2 (the measured sum); its intermediates are uncomputed
; CHECK-NEXT: [[Z1:%[a-z0-9_]+]] = call i32 @cq_template_zext_i1_to_i32(i32 [[Q1]])
; CHECK-NEXT: [[Z0:%[a-z0-9_]+]] = call i32 @cq_template_zext_i1_to_i32(i32 [[Q0]])
; CHECK-NEXT: [[S:%[a-z0-9_]+]] = call i32 @cq_template_add_i32(i32 [[Z1]], i32 [[Z0]])
; CHECK-NEXT: [[Z2:%[a-z0-9_]+]] = call i32 @cq_template_zext_i1_to_i32(i32 [[Q2]])
; CHECK-NEXT: [[C:%[a-z0-9_]+]] = call i32 @cq_template_add_i32(i32 [[S]], i32 [[Z2]])
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 [[S]], i32 [[Z1]], i32 [[Z0]])
; CHECK-NEXT: call void @cqrt_free(i32 [[S]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 [[Z0]], i32 [[Q0]])
; CHECK-NEXT: call void @cqrt_free(i32 [[Z0]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 [[Z1]], i32 [[Q1]])
; CHECK-NEXT: call void @cqrt_free(i32 [[Z1]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 [[Z2]], i32 [[Q2]])
; CHECK-NEXT: call void @cqrt_free(i32 [[Z2]])
;   the rotated registers are frozen: measured, never freed or reverse-played
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 [[Q0]])
; CHECK:      call i1 @cqrt_measure_i1(i32 [[Q1]])
; CHECK:      call i1 @cqrt_measure_i1(i32 [[Q2]])
; CHECK:      call i32 @cqrt_measure_i32(i32 [[C]])
; CHECK-NOT:  @cqrt_free(
; CHECK-NOT:  _controlled_inv(
; CHECK:      ret i32 0
;
; (the pass leaves a dead `declare void @cqrt_x(i32)`; only a call counts)
; NOX-NOT: call void @cqrt_x(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [13 x i8] c"%d %d %d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00) #4
  %2 = zext i1 %1 to i32
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01) #4
  %4 = tail call fastcc zeroext i1 @cry_eq(i32 noundef %2, i32 noundef 1, i1 noundef zeroext %3, double noundef 4.000000e-01)
  %5 = zext i1 %4 to i32
  %6 = add nuw nsw i32 %5, %2
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e-01) #4
  %8 = tail call fastcc zeroext i1 @cry_eq(i32 noundef %6, i32 noundef 1, i1 noundef zeroext %7, double noundef 1.000000e-01)
  %9 = tail call fastcc zeroext i1 @cry_eq(i32 noundef %6, i32 noundef 2, i1 noundef zeroext %8, double noundef 3.000000e-01)
  %10 = zext i1 %9 to i32
  %11 = add nuw nsw i32 %6, %10
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #5
  %13 = zext i1 %12 to i32
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #5
  %15 = zext i1 %14 to i32
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9) #5
  %17 = zext i1 %16 to i32
  %18 = tail call i32 @cq_measure_si32(i32 noundef %11) #5
  %19 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %13, i32 noundef %15, i32 noundef %17, i32 noundef %18)
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc zeroext i1 @cry_eq(i32 noundef %0, i32 noundef %1, i1 noundef zeroext %2, double noundef %3) unnamed_addr #2 {
  %5 = icmp eq i32 %0, %1
  br i1 %5, label %6, label %8

6:                                                ; preds = %4
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef %3) #4
  br label %8

8:                                                ; preds = %6, %4
  %9 = phi i1 [ %7, %6 ], [ %2, %4 ]
  ret i1 %9
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
