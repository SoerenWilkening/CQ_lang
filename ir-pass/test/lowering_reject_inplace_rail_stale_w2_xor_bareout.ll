; lowering_reject_inplace_rail_stale_w2_xor_bareout.ll — DECLINE. bd
; test_C_libtooling-eqpx (P1). THE SECOND GROWTH EVENT: the immediate need not be
; DERIVED from the merge at all — the BARE 6.5 `%out` reaches the defect, and its
; taint arrives ONE PIPELINE STAGE EARLIER than the bd issue's own text says.
;
;     int ext_f(int a);                        /* a second TU: `return a+100;` */
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       int y=5; if (q>5) y=ext_f(7);          /* 6.5 CLASSICAL-CALL ARM -> %out */
;       for(int i=0;i<3;i++){ r = r ^ y; }     /* the BARE %out is the immediate */
;       return cq_measure(r)+cq_measure(y)+cq_measure(q); }
;
; `clang -O1`, two TUs `llvm-link`ed, `@main` dropped. `!llvm.loop` VERBATIM.
;
; TWO taint-growth events sit between the writer and the consumer, not one:
;   E1  `lowerControlRegions` (`CQLoweringPass.cpp:376`) — `ClassicalCallArmEmit.cpp:209`
;       does `taint.Tainted.insert(Out)` AT EMISSION, so the BARE merge value is a
;       quantum handle from that moment. THIS FIXTURE'S member. It is AFTER W1/W2
;       (`lowerLoops`, `:363`) and BEFORE W3/W4 (`:393`).
;   E2  `repropagateControlMerges` (`:409`) — everything DERIVED from `%out`
;       (the `..._w2_xor_derived.ll` member).
; A fence written only against E2 would leave this program silent.
;
; MEASURED on frozen `main`@16b15b3 (byte-identical on the oracle 52d7764):
;     %out = call i32 @cqrt_alloc_i32(i32 0)
;     call void @cqrt_xorc_i32(i32 %h2, i32 %out)     ; <- A RAIL IN THE IMM SLOT
; `opt` exit 0, verify-clean, STRICT stage 2b `0 violation(s)`, 20 trace lines.
;
; ⚠ WHICH MECHANISM PINS WHAT — round-1 lens finding F-E1-2, MEASURED, and read
; it before touching the RUN line. On a `DiagnosticInfoUnsupported(DS_Error)`
; decline `cq-opt` writes **0 BYTES TO STDOUT** (measured:
; `cq-opt -load-pass-plugin … -passes=cq-lowering -S %s >out 2>err` -> rc 1,
; `wc -c out` = 0, `err` = the one diagnostic line below plus a blank), and this
; RUN line pipes `2>&1`. So FileCheck sees the diagnostic and NOTHING ELSE:
; the `CHECK-NOT` pair below (`cqrt_xorc_i32`, `cq_template_xor_i32`) is
; STRUCTURALLY UNABLE TO FIRE and is NOT what pins "no silent out-of-place
; fallback". **THE `not` WRAPPER ON THE RUN LINE IS.** MEASURED with mutant M-B (the
; decline replaced by `taint.InPlaceRailOps.erase(BO)` + fall-through to the
; ordinary out-of-place lowering): all EIGHT of these decline fixtures go RED
; (`lit -s` 1698 Passed / 8 Failed) and nothing else in the corpus moves. The
; pair is KEPT as documentation of the forbidden output — the same house style
; as the pre-existing (1b) fixture
; `control_phase_kickback_reject_preloop_commit_stale.ll`, which carries the
; identical vacuous pair — but it is documentation, not an assertion.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: in-place rail op no longer provable at lowering

; (DOCUMENTATION OF THE FORBIDDEN OUTPUT, not a live assertion — F-E1-2 above:
; stdout is empty on a decline, so these two can never fire. The `not` wrapper does it.)
; CHECK-NOT: cqrt_xorc_i32
; CHECK-NOT: cq_template_xor_i32

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
  br label %15

9:                                                ; preds = %15
  %10 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %12 = add nsw i32 %11, %10
  %13 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %14 = add nsw i32 %12, %13
  ret i32 %14

15:                                               ; preds = %15, %7
  %16 = phi i32 [ 0, %7 ], [ %19, %15 ]
  %17 = phi i32 [ %3, %7 ], [ %18, %15 ]
  %18 = xor i32 %17, %8
  %19 = add nuw nsw i32 %16, 1
  %20 = icmp eq i32 %19, 3
  br i1 %20, label %9, label %15, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
