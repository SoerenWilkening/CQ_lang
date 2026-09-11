define i32 @main() local_unnamed_addr {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %hdr
hdr:
  %i = phi i32 [ 0, %entry ], [ %in, %lat ]
  %acc = phi i32 [ 0, %entry ], [ %s, %lat ]
  %c = icmp eq i32 %q, 1
  br i1 %c, label %m, label %a
a:
  tail call void @cq_phi(double noundef 7.000000e-01)
  br label %m
m:
  %mux = phi i32 [ 5, %a ], [ 2, %hdr ]
  %mux2 = phi i32 [ 9, %a ], [ 4, %hdr ]
  %s = add nsw i32 %acc, %mux
  br label %lat
lat:
  %in = add nuw nsw i32 %i, 1
  %e = icmp eq i32 %in, 4
  br i1 %e, label %out, label %hdr
out:
  %r = tail call i32 @cq_measure_si32(i32 noundef %q)
  ret i32 %r
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)
