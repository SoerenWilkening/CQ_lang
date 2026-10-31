; cq-c9il, rules 7 and 20 (115, 178): `x[i] = 0; cq_theta(&x[i], t)` on a run-time-indexed bool array is
; store 0 then a store of the cq_theta result into the same cell. The stored 0 is dead (the same block
; overwrites the cell before anything reads the object): no seed is materialised for it, so nothing is
; kept beyond the two registers (the cq_theta mints of false).
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)

define i32 @sl2(i32 %n, i32 %i, i32 %j, double %t) {
  %nn = zext i32 %n to i64
  %x = alloca i8, i64 %nn, align 16
  %ii = sext i32 %i to i64
  %pi = getelementptr inbounds i8, ptr %x, i64 %ii
  store i8 0, ptr %pi, align 1
  %a = call zeroext i1 @cq_theta_i1(i1 zeroext false, double %t)
  %az = zext i1 %a to i8
  store i8 %az, ptr %pi, align 1
  %jj = sext i32 %j to i64
  %pj = getelementptr inbounds i8, ptr %x, i64 %jj
  store i8 0, ptr %pj, align 1
  %b = call zeroext i1 @cq_theta_i1(i1 zeroext false, double %t)
  %bz = zext i1 %b to i8
  store i8 %bz, ptr %pj, align 1
  %l = load i8, ptr %pi, align 1, !range !0, !noundef !1
  %lt = trunc nuw i8 %l to i1
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %lt)
  %m2 = call zeroext i1 @cq_measure_i1(i1 zeroext %b)
  %r1 = zext i1 %m1 to i32
  %r2 = zext i1 %m2 to i32
  %r = add i32 %r1, %r2
  ret i32 %r
}
!0 = !{i8 0, i8 2}
!1 = !{}
; CHECK-COUNT sl2: @cqrt_alloc_i1(i1 false) 2
; CHECK-COUNT sl2: @cqrt_ry_i1( 2
; CHECK-COUNT sl2: store i32 2
