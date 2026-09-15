; p3_inloop_read_uncond_nopreheader.ll — Track A, 2026-09-15, bd `de8n`.
; C7(a) IN ISOLATION. The store is UNCONDITIONAL and sits in the latch, so C7(b)
; holds; the body still READS the cell (%s, the per-trip seed), so C7(a) fails.
; The loop has NO DEDICATED PREHEADER (entry has two successors), which is why the
; promoter refuses and the read SURVIVES to the carve — the reachable-from-C shape
; `probes/g3_two_banks_onefn.c` takes for its SECOND bank.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main(i32 %n) {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  %c = icmp sgt i32 %n, 0
  br i1 %c, label %head, label %bail
bail:
  ret i32 0
head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %head ]
  %a = phi i32 [ 5, %entry ], [ %a.next, %head ]
  %g = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s = load i8, ptr %g, align 1
  %t = trunc nuw i8 %s to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %z = zext i1 %q to i8
  store i8 %z, ptr %g, align 1
  %am3 = add nsw i32 %a, -3
  %a.next = select i1 %q, i32 %am3, i32 %a
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %out, label %head
out:
  %m = call i32 @cq_measure_si32(i32 %a.next)
  ret i32 %m
}
