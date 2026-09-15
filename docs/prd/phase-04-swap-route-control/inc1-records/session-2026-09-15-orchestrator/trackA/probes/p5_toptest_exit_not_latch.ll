; p5_toptest_exit_not_latch.ll — Track A, 2026-09-15, bd `de8n`.
; C7(b)'s SINGLE-EXITING-BLOCK conjunct, and it is NOT a structural nicety: it
; catches a genuinely UNWRITTEN cell that C6's own counting cannot see.
;
; A TOP-TESTED loop: the exit test is in the HEADER, and the latch is a separate
; block that only increments. So `getExitingBlock()` is %head and `getLoopLatch()`
; is %latch, and they DIFFER — while the store in %body still DOMINATES the latch,
; so C7(b)'s other conjunct holds.
;
; THE HAZARD. The header runs BTC+1 = 4 times (i = 0,1,2,3) and the BODY runs only
; 3 (i = 0,1,2). SCEV's `Trips` is BTC+1 = 4 == N, so C6's `Trips != N` test PASSES
; — and CELL 3 IS NEVER WRITTEN. After the deferred [4 x i8] -> [4 x i32] rewrite
; it reads as handle 0, a LIVE RAIL. `Trips` counts HEADER executions; only when
; the single exiting block IS the latch do header executions and body executions
; coincide.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main() {
entry:
  %b = alloca [4 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 4, i1 false)
  br label %head
head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %latch ]
  %a = phi i32 [ 5, %entry ], [ %a.next, %latch ]
  %done = icmp eq i64 %i, 3
  br i1 %done, label %out, label %body
body:
  %g = getelementptr inbounds [4 x i8], ptr %b, i64 0, i64 %i
  %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %z = zext i1 %q to i8
  store i8 %z, ptr %g, align 1
  %am3 = add nsw i32 %a, -3
  %a.next = select i1 %q, i32 %am3, i32 %a
  br label %latch
latch:
  %i.next = add nuw nsw i64 %i, 1
  br label %head
out:
  %m = call i32 @cq_measure_si32(i32 %a)
  %g3 = getelementptr inbounds [4 x i8], ptr %b, i64 0, i64 3
  %r3 = load i8, ptr %g3, align 1
  %t3 = trunc nuw i8 %r3 to i1
  %m3 = call zeroext i1 @cq_measure_i1(i1 %t3)
  %z3 = zext i1 %m3 to i32
  %s = add nsw i32 %m, %z3
  ret i32 %s
}
