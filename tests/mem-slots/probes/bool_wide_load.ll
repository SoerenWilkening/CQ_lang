; cq-c9il: a _Bool cell's i8 load read at i8 (178's `x[i] << i` after the promotion, sl4's shl) reads the
; cell's i1 rail widened: zext_i1_to_i8 into a fresh rail, then the i8 templates over it.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @sl4(i32 %n, i32 %i, i32 %k, double %t) {
  %nn = zext i32 %n to i64
  %x = alloca i8, i64 %nn, align 16
  %ii = sext i32 %i to i64
  %pi = getelementptr inbounds i8, ptr %x, i64 %ii
  store i8 0, ptr %pi, align 1
  %a = call zeroext i1 @cq_theta_i1(i1 zeroext false, double %t)
  %az = zext i1 %a to i8
  store i8 %az, ptr %pi, align 1
  %kk = sext i32 %k to i64
  %pk = getelementptr inbounds i8, ptr %x, i64 %kk
  %l = load i8, ptr %pk, align 1, !range !0, !noundef !1
  %s = shl nuw nsw i8 %l, 3
  %w = zext nneg i8 %s to i32
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}
!0 = !{i8 0, i8 2}
!1 = !{}
; CHECK sl4: %{{h}} = load i32, ptr %{{p}}, align 4
; CHECK sl4: %{{w}} = call i32 @cq_template_zext_i1_to_i8(i32 %{{h}})
; CHECK sl4: @cq_template_shl_i8_hl(i32 %{{w}}, i8 3)
; CHECK-COUNT sl4: @cqrt_alloc_i1(i1 false) 1
