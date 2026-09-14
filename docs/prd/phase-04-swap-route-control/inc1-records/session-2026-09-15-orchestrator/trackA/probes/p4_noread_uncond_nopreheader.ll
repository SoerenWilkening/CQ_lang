; p4_noread_uncond_nopreheader.ll — Track A, 2026-09-15, bd `de8n`.
; THE CONTROL FOR p3. Byte-identical to `p3_inloop_read_uncond_nopreheader.ll`
; except that the theta reads a LITERAL `false` instead of the cell, so C7(a)
; holds as well as C7(b) and the verdict stays `Bank`. Its only job is to make p3
; an ISOLATION of C7(a) rather than a measurement of the missing preheader — which
; both modules share and neither is refused for.
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
  %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
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
