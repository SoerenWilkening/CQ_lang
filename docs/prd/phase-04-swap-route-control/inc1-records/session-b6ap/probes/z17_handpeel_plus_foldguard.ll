; z08's module with the (foldable) classical guard removed and the mux phi ALREADY
; spelled as a select with its own compare clone — i.e. exactly what the peel
; produces. Run on the ORACLE this isolates whether the un-lowered `add` in z08's
; subject output belongs to the peel or to the pre-existing 4.4 out-rail path.
@g = internal global i32 0
define i32 @main() local_unnamed_addr {
entry:
  %k = load volatile i32, ptr @g, align 4
  %kc = icmp eq i32 %k, 9
  br i1 %kc, label %p2, label %p
p2:
  br label %p
p:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %m, label %a
a:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %m
m:
  %b1 = phi i32 [ %t, %a ], [ 0, %p ]
  %cc = icmp eq i32 %b0, 1
  %mux = select i1 %cc, i32 2, i32 5
  %x1 = tail call i32 @cq_measure_si32(i32 noundef %b1)
  %s = add nsw i32 %x1, %mux
  ret i32 %s
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
