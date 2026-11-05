; Rules 20, 21: a tainted index over a classical base is one bus load at an address rail; a classical choice of the
; base stays classical (the _hl literal); an index narrower than i64 is sext to i64 where -O1 wrote no cast.
; quantum index over a classical pointer) is rule 20's quantum-offset access of the object, not a
@t = internal constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6]
@u = internal constant [8 x i32] [i32 2, i32 7, i32 1, i32 8, i32 2, i32 8, i32 1, i32 8]
declare i8 @cq_theta_ui8(i8, double)
declare i32 @cq_measure_si32(i32)

define i32 @direct(i8 %x0, double %th) {
  %x = call i8 @cq_theta_ui8(i8 %x0, double %th)
  %i = and i8 %x, 7
  %z = zext nneg i8 %i to i64
  %p = getelementptr inbounds [8 x i32], ptr @t, i64 0, i64 %z
  %v = load i32, ptr %p, align 4
  %r = call i32 @cq_measure_si32(i32 %v)
  ret i32 %r
}
; CHECK-COUNT direct: call i32 @cqrt_qram_load_i32( 1
; CHECK-COUNT direct: call i32 @cq_template_zext_i8_to_i64( 1
; USERCHECK direct

define i32 @chosen_table(i8 %x0, double %th, i1 %c) {
  %x = call i8 @cq_theta_ui8(i8 %x0, double %th)
  %i = and i8 %x, 7
  %z = zext nneg i8 %i to i64
  %b = select i1 %c, ptr @t, ptr @u
  %p = getelementptr inbounds [8 x i32], ptr %b, i64 0, i64 %z
  %v = load i32, ptr %p, align 4
  %r = call i32 @cq_measure_si32(i32 %v)
  ret i32 %r
}
; CHECK-COUNT chosen_table: call i32 @cqrt_qram_load_i32( 1
; CHECK-COUNT chosen_table: call i32 @cq_template_zext_i8_to_i64( 1
; USERCHECK chosen_table

define i32 @index_value(i8 %x0, double %th) {
  %x = call i8 @cq_theta_ui8(i8 %x0, double %th)
  %i = and i8 %x, 7
  %z = zext nneg i8 %i to i32
  %p = getelementptr inbounds [8 x i32], ptr @t, i64 0, i32 %z
  %v = load i32, ptr %p, align 4
  %s = add i32 %v, %z
  %r = call i32 @cq_measure_si32(i32 %s)
  ret i32 %r
}
; CHECK-COUNT index_value: call i32 @cqrt_qram_load_i32( 1
; CHECK-COUNT index_value: call i32 @cq_template_zext_i8_to_i32( 1
; CHECK-COUNT index_value: call i32 @cq_template_sext_i32_to_i64( 1
; USERCHECK index_value
