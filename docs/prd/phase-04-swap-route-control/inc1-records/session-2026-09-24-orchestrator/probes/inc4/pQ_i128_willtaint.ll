; QROM says No (i128 has NO qram cell); the NEW classical arm says Yes (it does not
; ask widthHasQramCell).  The index is a REGION-INTERNAL phi the flatten will TAINT.
@c128 = constant [4 x i128] [i128 11, i128 22, i128 33, i128 44], align 16
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe() {
entry:
  %q  = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %Z  = call i32 @cq_theta_si32(i32 5, double 2.500000e-01)
  %P  = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 2
  br i1 %c1, label %A, label %M
A:
  %c2 = icmp sgt i32 %q, 7
  br i1 %c2, label %A1, label %A2
A1:
  br label %AJ
A2:
  br label %AJ
AJ:
  %idx = phi i64 [ 1, %A1 ], [ 2, %A2 ]
  %g   = getelementptr inbounds [4 x i128], ptr @c128, i64 0, i64 %idx
  %z   = load i128, ptr %g, align 16
  %zt  = trunc i128 %z to i32
  %Z1  = sub i32 %Z, %zt
  %P1  = add i32 %P, %zt
  br label %M
M:
  %Zn = phi i32 [ %Z, %entry ], [ %Z1, %AJ ]
  %Pn = phi i32 [ %P, %entry ], [ %P1, %AJ ]
  %m1 = call i32 @cq_measure_si32(i32 %Zn)
  %m2 = call i32 @cq_measure_si32(i32 %Pn)
  %s  = add i32 %m1, %m2
  ret i32 %s
}
