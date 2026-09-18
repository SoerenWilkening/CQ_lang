; QROM refuses this read ONLY because its value coherently escapes to `ret`
; (the no-cloning fence).  The NEW classical arm does not ask that question.
; The index is a REGION-INTERNAL phi the flatten will TAINT.
@c = constant [4 x i32] [i32 11, i32 22, i32 33, i32 44], align 16
declare i32 @cq_theta_si32(i32, double)
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
  %g   = getelementptr inbounds [4 x i32], ptr @c, i64 0, i64 %idx
  %z   = load i32, ptr %g, align 4
  %Z1  = sub i32 %Z, %z
  %P1  = add i32 %P, %z
  br label %M
M:
  %Zn = phi i32 [ %Z, %entry ], [ %Z1, %AJ ]
  %Pn = phi i32 [ %P, %entry ], [ %P1, %AJ ]
  %r  = add i32 %Zn, %Pn
  ret i32 %r
}
