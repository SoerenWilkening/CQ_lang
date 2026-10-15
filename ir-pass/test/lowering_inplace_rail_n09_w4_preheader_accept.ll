; lowering_inplace_rail_n09_w4_preheader_accept.ll — ACCEPT. bd
; test_C_libtooling-eqpx (P1), ACCEPT CONTROL 5 of 8: the W4 lane
; (`commitOutOfLoopInPlaceOps`, `LoopLowering.cpp:3124`) must be left ALONE. It
; already carries round 3's own two-part fence — the MONOTONE `isa<Constant>(Imm)`
; at the commit and the LOUD (1b) tripwire at `lowerOps` — and the eqpx re-ask
; deliberately EXCLUDES `taint.PreLoopCommittedInPlaceOps` so the two cannot both
; adjudicate one op under two different fences.
;
;     int ext_f(int a);                        /* a second TU: `return a+100;` */
;     int slice(int u){ int q=u; cq_theta(&q,0.5); int r=u; cq_theta(&r,0.3);
;       int y=5; if (q>5) y=ext_f(7);          /* 6.5 CLASSICAL-CALL ARM -> %out */
;       int w = y & 7;
;       int a = u; cq_theta(&a,0.7);
;       a = a ^ w;                             /* the PREHEADER op — W4's lane */
;       for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); cq_theta(&r,0.1); }
;       return cq_measure(a)+cq_measure(r)+cq_measure(y); }
;
; `clang -O1`, two TUs `llvm-link`ed, `@main` dropped. `!llvm.loop` VERBATIM.
;
; MEASURED on frozen `main`@16b15b3 AND here: W4's (1a) `isa<Constant>(Imm)`
; refuses this op at the commit (`w` is derived from `%out`, not a `Constant`), so
; it is never marked and lowers OUT OF PLACE as the correct Q+Q
; `cq_template_xor_i32(i32 %h4, i32 %h_op)` (SUPERSEDED by bd r2j3.33: now the
; in-place `cqrt_xor_i32(i32 %h_op, i32 %h4)`). ZERO in-place gates in the whole
; module, `railInImm=0`, STRICT stage 2b `0 violation(s)`, 47 trace lines, lowered
; module BYTE-IDENTICAL across the two binaries (`cmp`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=IMMCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll

; The preheader op. W4 never marks it (above); since bd r2j3.33 (dm7f.51 step 1)
; the QUANTUM-source round lowers it IN PLACE on `a`'s rail — `a`'s old value is
; dead and its new one is measured — with `w` in the SOURCE handle slot.
; CHECK: %[[W:.*]] = call i32 @cq_template_and_i32_hl(i32 %{{.*}}, i32 7)
; CHECK: %[[A:.*]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK: call void @cqrt_ry_i32(i32 %[[A]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_xor_i32(i32 %[[W]], i32 %[[A]]), !cq.inplace.qq

; ZERO classical-immediate in-place gates: neither (1b)'s lane nor eqpx's has
; anything to adjudicate (the one `cqrt_xor_i32` is the r2j3.33 round's).
; IMMCNT-NOT: call void @cqrt_xorc_i32(
; IMMCNT-NOT: call void @cqrt_addc_i32(
; IMMCNT-COUNT-1: call void @cqrt_xor_i32(
; IMMCNT-NOT: call void @cqrt_xor_i32(

; NOROUTE-NOT: in-place rail op no longer provable at lowering
; NOROUTE-NOT: pre-loop in-place op no longer provable at lowering
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: @cq_phi

; ── round-1 lens F-E1-3: the accept controls under-asserted. 48 injections
; over these 8 fixtures (a rail-immediate `cqrt_xorc_i32(i32 %h, i32 %rail)`,
; an extra out-of-place `cq_template_xor_i32`, an extra `cqrt_free`, each at
; head and tail) were caught 20/48 — every free MISSED by all 8, because no
; accept fixture carried a free count. The blocks below close that; the counts
; are DERIVED from this fixture's own pass output, not guessed.
; NOROUTE-NOT: call void @cqrt_xorc_i{{[0-9]+}}(
; NOROUTE-NOT: call void @cqrt_xorc_i{{[0-9]+}}(i32 %{{.*}}, i32 %{{.*}})
; NOROUTE-NOT: call void @cqrt_addc_i
; NOROUTE-NOT: call void @cqrt_addc_i{{[0-9]+}}(i32 %{{.*}}, i32 %{{.*}})
; NOROUTE-NOT: call i32 @cq_template_add_i32(
;
; FCNT — whole-file EXACT free count, MEASURED 3 (`grep -c 'call void @cqrt_free(' <pass output>`).
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  %4 = icmp sgt i32 %2, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ 5, %1 ]
  %9 = and i32 %8, 7
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 0x3FE6666666666666) #3
  %11 = xor i32 %10, %9
  br label %18

12:                                               ; preds = %25
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %26) #3
  %15 = add nsw i32 %14, %13
  %16 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %17 = add nsw i32 %15, %16
  ret i32 %17

18:                                               ; preds = %25, %7
  %19 = phi i32 [ 0, %7 ], [ %27, %25 ]
  %20 = phi i32 [ %3, %7 ], [ %26, %25 ]
  %21 = shl nuw nsw i32 1, %19
  %22 = and i32 %21, %11
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %25, label %24

24:                                               ; preds = %18
  tail call void @cq_phi(double noundef 2.000000e-01) #3
  br label %25

25:                                               ; preds = %24, %18
  %26 = tail call i32 @cq_theta_si32(i32 noundef %20, double noundef 1.000000e-01) #3
  %27 = add nuw nsw i32 %19, 1
  %28 = icmp eq i32 %27, 3
  br i1 %28, label %12, label %18, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
