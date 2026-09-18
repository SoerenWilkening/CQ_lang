declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %in, %join ]
  %in = add i32 %i, 1
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %C, label %D
C:
  %cc = icmp slt i32 %q, 3
  br i1 %cc, label %D, label %join
D:
  %dd = icmp sgt i32 %q, 9
  br i1 %dd, label %C, label %join
join:
  %v = phi i32 [ 1, %C ], [ 2, %D ]
  %w = phi i32 [ 3, %C ], [ 4, %D ]
  %s = add i32 %v, %w
  %d2 = icmp eq i32 %in, 3
  br i1 %d2, label %exit, label %head
exit:
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
