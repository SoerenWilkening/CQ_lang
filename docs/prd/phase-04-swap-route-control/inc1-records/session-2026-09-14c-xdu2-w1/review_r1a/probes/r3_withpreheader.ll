; r2_nopreheader.ll — ONE rail bank whose write loop has NO DEDICATED PREHEADER
; (the header's only outside predecessor, %entry, has TWO successors, so
; Loop::getLoopPreheader() returns null). Everything else is the shipped
; railbank_promote_loop_n3.ll shape.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main(i32 %n) {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  %c = icmp sgt i32 %n, 0
  br i1 %c, label %pre, label %bail
pre:
  br label %head
bail:
  ret i32 0
head:
  %i = phi i64 [ 0, %pre ], [ %i.next, %latch ]
  %a = phi i32 [ 5, %pre ], [ %a.next, %latch ]
  %cmp = icmp sgt i32 %a, 2
  br i1 %cmp, label %arm, label %latch
arm:
  %g = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s = load i8, ptr %g, align 1
  %t = trunc nuw i8 %s to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %z = zext i1 %q to i8
  store i8 %z, ptr %g, align 1
  br label %latch
latch:
  %g2 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %r = load i8, ptr %g2, align 1
  %rt = trunc nuw i8 %r to i1
  %am3 = add nsw i32 %a, -3
  %a.next = select i1 %rt, i32 %am3, i32 %a
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %out, label %head
out:
  %m = call i32 @cq_measure_si32(i32 %a.next)
  ret i32 %m
}
