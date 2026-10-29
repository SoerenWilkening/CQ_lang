; cq-sj2j, rules 3 and 20: only a _Bool slot object (mem-slots' boolCells: every i8 load carries
; !range [0, 2), every store stores a zext from i1 or 0 / 1) holds i1 rails behind i8 memory, where the
; i8 <-> i1 trunc / zext are representation changes (tests/mem-slots/probes/bool_cells.ll). A char
; object's cells hold i8 rails, so its trunc to i1 stays a template, also when its loads carry the
; _Bool range but a store does not store a zext from i1.
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i8 @cq_theta_ui8(i8, double)

define i32 @char_cells(ptr %q, i32 %i, double %t) {
  %ii = sext i32 %i to i64
  %p = getelementptr inbounds i8, ptr %q, i64 %ii
  %b = load i8, ptr %p, align 1
  %x = call i8 @cq_theta_ui8(i8 %b, double %t)
  store i8 %x, ptr %p, align 1
  %b2 = load i8, ptr %p, align 1
  %c = trunc i8 %b2 to i1
  %m = call zeroext i1 @cq_measure_i1(i1 zeroext %c)
  %r = zext i1 %m to i32
  ret i32 %r
}
; CHECK-COUNT char_cells: call i32 @cq_template_trunc_i8_to_i1( 1

define i32 @mixed_cells(ptr %q, i32 %i, double %t) {
  %ii = sext i32 %i to i64
  %p = getelementptr inbounds i8, ptr %q, i64 %ii
  %b = load i8, ptr %p, align 1, !range !0, !noundef !1
  %x = call i8 @cq_theta_ui8(i8 %b, double %t)
  store i8 %x, ptr %p, align 1
  %b2 = load i8, ptr %p, align 1, !range !0, !noundef !1
  %c = trunc nuw i8 %b2 to i1
  %m = call zeroext i1 @cq_measure_i1(i1 zeroext %c)
  %r = zext i1 %m to i32
  ret i32 %r
}
; CHECK-COUNT mixed_cells: call i32 @cq_template_trunc_i8_to_i1( 1
!0 = !{i8 0, i8 2}
!1 = !{}
