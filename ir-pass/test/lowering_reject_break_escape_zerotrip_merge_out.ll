; lowering_reject_break_escape_zerotrip_merge_out.ll — DECLINE (bd
; test_C_libtooling-8h7d.17, review round 1 finding F1; hand-written, the
; reviewer's probe rv-C1/p6). A 6.5 classical-call diamond `y = (s > 5) ?
; ext_f(7) : 5` precedes a 7.4 break loop, and the loop's escaping counter
; `%iex = phi [%y, guard], [i.next, latch]` is measured after the loop.
;
; THE MISCOMPILE THIS DECLINE REPLACES (measured on 28e85906: `cq-opt` exit 0).
; E16 asked "is the escape φ E untainted?" once, in `lowerLoops`, at round-1
; taint, when `%y` is still a classical φ. Round-1 control emission then RAUWs
; `%y` to the 6.5 merge register `%out` (a quantum register: y is entangled with
; s), and round 2 taints E, but E has no users left (they read `cq.brk.esc.out`),
; so `declineClassicalMuxes` skips it as dead. The exit consolidation then
; materialised E CLASSICALLY, `cqrt_alloc_i32(%iex)`, so on the zero-trip path
; `esc.out` held the register's handle id (4 in the n = 0 trace) where the
; source's `iex` is y in {5, 107}.
;
; THE FENCE (L1). `emitOneBreak` RE-ASKS at FINAL taint, after the round-2
; fixpoint in both entry points, that the escape φ and its zero-trip incoming are
; classical, and declines loudly before emitting any gate. A quantum zero-trip
; value is a valid program (a classical guard choosing between a register and a
; classical value); lowering it needs the register copied into the capture on the
; zero-trip edge, a compiler gap until built (R1), not a physics limit.
; The twin lowering_reject_break_escape_chain.ll reaches the same fence through a
; previous break loop's escape register.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break escape carries a quantum value from outside the loop

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @f(i32 noundef %x, i32 noundef %pseed, i32 noundef %n, i32 noundef %s) local_unnamed_addr #0 {
entry:
  %p = tail call i32 @cq_theta_si32(i32 noundef %pseed, double noundef 5.000000e-01) #2
  %q = tail call i32 @cq_theta_si32(i32 noundef %x, double noundef 2.500000e-01) #2
  %sq = tail call i32 @cq_theta_si32(i32 noundef %s, double noundef 3.000000e-01) #2
  %c = icmp sgt i32 %sq, 5
  br i1 %c, label %t, label %m

t:
  %e = tail call i32 @ext_f(i32 noundef 7) #4
  br label %m

m:
  %y = phi i32 [ %e, %t ], [ 5, %entry ]
  %g = icmp sgt i32 %n, 0
  br i1 %g, label %L, label %X

L:
  %i = phi i32 [ %in, %L ], [ 0, %m ]
  %r = phi i32 [ %r2, %L ], [ %q, %m ]
  %r2 = xor i32 %r, 9
  %b = icmp eq i32 %r2, %p
  %in = add nuw nsw i32 %i, 1
  %bd = icmp eq i32 %in, %n
  %fu = select i1 %b, i1 true, i1 %bd
  br i1 %fu, label %X, label %L, !llvm.loop !6

X:
  %ans = phi i32 [ %q, %m ], [ %r2, %L ]
  %iex = phi i32 [ %y, %m ], [ %in, %L ]
  %a = tail call i32 @cq_measure_si32(i32 noundef %ans) #3
  %bb = tail call i32 @cq_measure_si32(i32 noundef %iex) #3
  %sum = add i32 %a, %bb
  ret i32 %sum
}

define i32 @ext_f(i32 noundef %a) local_unnamed_addr #5 {
  %r = add nsw i32 %a, 100
  ret i32 %r
}

define i32 @main() #0 {
  %a = call i32 @f(i32 3, i32 5, i32 0, i32 9)
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
attributes #4 = { nounwind willreturn memory(none) }
attributes #5 = { noinline nounwind willreturn memory(none) mustprogress }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
