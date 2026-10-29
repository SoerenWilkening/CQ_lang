; cq-eog3, rules 20 and 21: a pointer whose tag is classical and whose idx is quantum (a GEP with a
; quantum index over a classical pointer) is rule 20's quantum-offset access of the object, not a
; fat-pointer access: a load of classical memory is ONE QROM load. The tag stays classical through a
; classical choice between tables. The zext of the index to i64 is address arithmetic and never
; emitted (the QROM reads the logical index rail); a zext with a value use is lowered as a value.
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
; CHECK-COUNT direct: call i32 @cq_template_qrom_load_i32( 1
; CHECK-COUNT direct: @cq_template_zext 0

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
; CHECK-COUNT chosen_table: call i32 @cq_template_qrom_load_i32( 1
; CHECK-COUNT chosen_table: @cq_template_zext 0

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
; CHECK-COUNT index_value: call i32 @cq_template_qrom_load_i32( 1
; CHECK-COUNT index_value: call i32 @cq_template_zext_i8_to_i32( 1
