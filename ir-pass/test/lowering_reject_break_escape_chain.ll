; lowering_reject_break_escape_chain.ll — DECLINE (bd test_C_libtooling-8h7d.17,
; review round 1 finding F1, the "same root" case; hand-written). Two 7.4 break
; loops in sequence. The first loop's escaping counter `%iex` is the zero-trip
; incoming of the second loop's escaping counter:
;
;     X1: %iex = phi [0, entry], [%in, L1]       ; loop 1's escape
;     X2: %jex = phi [%iex, X1], [%jn, L2]       ; loop 2's escape, Z = %iex
;
; MEASURED on 28e85906 (`cq-opt` exit 0): loop 1's E16 rewires `%iex`'s users to
; its register `cq.brk.esc.out`, so loop 2's escape becomes `%jex = phi
; [%cq.brk.esc.out, ...]`, and loop 2's exit consolidation materialised it
; classically (`cqrt_alloc_i32(%jex)`): the zero-trip value was a handle id.
; The order the loops are visited decides whether loop 2's round-1 E16 saw `%iex`
; or the register; either way the value is quantum at FINAL taint, and the
; re-ask in `emitOneBreak` declines (see
; lowering_reject_break_escape_zerotrip_merge_out.ll for the fence). Lowering it
; is a compiler gap (R1): the second loop would copy the first loop's register
; into its capture on the zero-trip edge.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break escape carries a quantum value from outside the loop

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @break_escape_chain(i32 noundef %x, i32 noundef %pseed, i32 noundef %n, i32 noundef %x2) local_unnamed_addr #0 {
entry:
  %p = tail call i32 @cq_theta_si32(i32 noundef %pseed, double noundef 5.000000e-01) #2
  %q = tail call i32 @cq_theta_si32(i32 noundef %x, double noundef 2.500000e-01) #2
  %g = icmp sgt i32 %n, 0
  br i1 %g, label %L1, label %X1

L1:
  %i = phi i32 [ %in, %L1 ], [ 0, %entry ]
  %r = phi i32 [ %r2, %L1 ], [ %q, %entry ]
  %r2 = xor i32 %r, 9
  %b = icmp eq i32 %r2, %p
  %in = add nuw nsw i32 %i, 1
  %bd = icmp eq i32 %in, %n
  %fu = select i1 %b, i1 true, i1 %bd
  br i1 %fu, label %X1, label %L1, !llvm.loop !6

X1:
  %ans = phi i32 [ %q, %entry ], [ %r2, %L1 ]
  %iex = phi i32 [ 0, %entry ], [ %in, %L1 ]
  %q2 = tail call i32 @cq_theta_si32(i32 noundef %x2, double noundef 3.500000e-01) #2
  br i1 %g, label %L2, label %X2

L2:
  %j = phi i32 [ %jn, %L2 ], [ 0, %X1 ]
  %s = phi i32 [ %s2, %L2 ], [ %q2, %X1 ]
  %s2 = xor i32 %s, 5
  %b2 = icmp eq i32 %s2, %p
  %jn = add nuw nsw i32 %j, 1
  %bd2 = icmp eq i32 %jn, %n
  %fu2 = select i1 %b2, i1 true, i1 %bd2
  br i1 %fu2, label %X2, label %L2, !llvm.loop !9

X2:
  %ans2 = phi i32 [ %q2, %X1 ], [ %s2, %L2 ]
  %jex = phi i32 [ %iex, %X1 ], [ %jn, %L2 ]
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %ans) #3
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %ans2) #3
  %m3 = tail call i32 @cq_measure_si32(i32 noundef %jex) #3
  %s12 = add i32 %m1, %m2
  %sum = add i32 %s12, %m3
  ret i32 %sum
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
