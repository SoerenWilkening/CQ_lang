; cq-c9il: a _Bool cell load read both through its trunc to i1 (the rail itself) and at i8 (a widened
; copy) is unimplemented.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @mixed(ptr %q, i32 %k, double %t) {
  %kk = sext i32 %k to i64
  %p = getelementptr inbounds i8, ptr %q, i64 %kk
  %l = load i8, ptr %p, align 1, !range !0, !noundef !1
  %c = trunc nuw i8 %l to i1
  %a = call zeroext i1 @cq_theta_i1(i1 zeroext %c, double %t)
  %az = zext i1 %a to i8
  store i8 %az, ptr %p, align 1
  %w = zext nneg i8 %l to i32
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}
!0 = !{i8 0, i8 2}
!1 = !{}
; EXPECT-ERROR: a _Bool cell load read both as its i1 rail
