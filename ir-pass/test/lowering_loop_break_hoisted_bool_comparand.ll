; lowering_loop_break_hoisted_bool_comparand.ll — POSITIVE emission (bd
; test_C_libtooling-8h7d.15; the issue's reproducer, found by the bd 3by9 Rule-11
; review round 2). A 7.4 value-arm `break` on `q == (int)b`, `b` a `_Bool`
; register that also carries a kickback before and after the loop. The module
; below is `clang -O1`'s output for this C, unedited apart from the ModuleID /
; source_filename lines:
;
;     int break_hoisted_bool_comparand(int x, int bseed, int n) {
;         _Bool b = bseed & 1; cq_theta(&b, 0.5);
;         if (b) cq_phi(0.3);
;         int q = x; cq_theta(&q, 0.25);
;         for (int i = 0; i < n; i++) { q = q ^ 9; if (q == (int)b) break; }
;         if (b) cq_phi(0.7);
;         return cq_measure(q);
;     }
;
; LICM hoists the invariant `zext i1 b to i32` (%12) into a DEDICATED preheader
; (%11), which E17 of `emitBreakForward` now hoists into the guard (%8); see
; lowering_loop_break_hoisted_comparand.ll for the mechanism. Before the fix this
; declined `cq loop lowering: early break body is not a provable rolled
; single-rail loop`.
;
; THE TRACE ARGUMENT for the stream pinned below (R2; no simulator).
;  (1) Both kickbacks key on the bare `_Bool` register: b IS the flag, so each
;      lowers to one `cqrt_rz_i1(b, θ)` with no flag mint, no bracket and no free:
;      D(θ) = diag(1, e^{iθ}) on b, up to a global phase.
;  (2) `cq_template_zext_i1_to_i32(b)` writes b into a fresh |0> i32 register c
;      (a basis permutation); b is untouched. The hoist puts it in the guard, so
;      it also runs on the zero-trip path, where nothing reads c.
;  (3) The break construct U is the gate sequence of
;      lowering_loop_break_qq_derived.ll with c as the comparand: c appears only
;      as the second operand of `cq_template_icmp_eq_i32` and its `_unc` (forward
;      body and the `cq.brk.rev` clone), and b does not appear in U at all. So U
;      is block-diagonal in b's basis and commutes with D(0.3) and D(0.7).
;  (4) The post-loop kickback is a later gate whose key is b, a register the
;      construct never writes, so it holds the source's value there (the 3by9 L5
;      condition). It lands in `cq.brk.tail` after the R/idx frees.
; So the stream is D(0.3), then the zext, then U, then D(0.7): the source's
; unitary on (b, q, out), with c and the rail left allocated (never freed, R5; c
; is the comparand-template leak lowering_loop_break_hoisted_comparand.ll
; discloses).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=PHASE < %t.ll
;
; CHECK-LABEL: define i32 @break_hoisted_bool_comparand(
; CHECK: [[B:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 [[B]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: [[RAIL:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[RAIL]], double 2.500000e-01)
; CHECK-NEXT: [[G:%[0-9]+]] = icmp sgt i32 %2, 0
; CHECK-NEXT: [[C:%[a-z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 [[B]])
; CHECK-NEXT: %cq.brk.R = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %cq.brk.idx = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %cq.brk.out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: br i1 [[G]], label %[[PH:[0-9]+]], label %{{[0-9]+}}
; CHECK: [[PH]]:
; CHECK-NEXT: br label %{{[0-9]+}}
; CHECK: call void @cqrt_xorc_i32(i32 [[RAIL]], i32 9)
; CHECK-NEXT: [[FCMP:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32(i32 [[RAIL]], i32 [[C]])
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 [[FCMP]], i32 [[RAIL]], i32 [[C]])
; CHECK: call void @cqrt_copy_i32(i32 %cq.brk.R, i32 %cq.brk.out)
; CHECK: br i1 [[G]], label %cq.brk.rev, label %cq.brk.tail
; CHECK: cq.brk.rev:
; CHECK: [[BCMP:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32(i32 [[RAIL]], i32 [[C]])
; CHECK: cq.brk.tail:
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.R)
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 [[B]], double 0x3FE6666666666666), !cq.branchphase
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
;
; --- exactly the two kickbacks, no phase gate inside the construct, no bracket
; PHASE-COUNT-2: call void @cqrt_rz_
; PHASE-NOT: call void @cqrt_rz_
; PHASE-NOT: call void @cqrt_x(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @break_hoisted_bool_comparand(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = and i32 %1, 1
  %5 = icmp ne i32 %4, 0
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %5, double noundef 5.000000e-01) #2
  br i1 %6, label %7, label %8

7:                                                ; preds = %3
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %8

8:                                                ; preds = %7, %3
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %10 = icmp sgt i32 %2, 0
  br i1 %10, label %11, label %21

11:                                               ; preds = %8
  %12 = zext i1 %6 to i32
  br label %13

13:                                               ; preds = %13, %11
  %14 = phi i32 [ 0, %11 ], [ %18, %13 ]
  %15 = phi i32 [ %9, %11 ], [ %16, %13 ]
  %16 = xor i32 %15, 9
  %17 = icmp eq i32 %16, %12
  %18 = add nuw nsw i32 %14, 1
  %19 = icmp eq i32 %18, %2
  %20 = select i1 %17, i1 true, i1 %19
  br i1 %20, label %21, label %13, !llvm.loop !6

21:                                               ; preds = %13, %8
  %22 = phi i32 [ %9, %8 ], [ %16, %13 ]
  br i1 %6, label %23, label %24

23:                                               ; preds = %21
  tail call void @cq_phi(double noundef 0x3FE6666666666666) #3
  br label %24

24:                                               ; preds = %23, %21
  %25 = tail call i32 @cq_measure_si32(i32 noundef %22) #3
  ret i32 %25
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
