; 102 (program slot): a load of the slot in an entry that no guarded clone call of the entry wrote reads the
; slot's content at the entry's start (another entry of the shot may have left a rail there): not built.
; EXPECT-ERROR: that no guarded clone call of this entry wrote
target triple = "x86_64-apple-macosx16.0.0"
@hit = internal global i32 0, align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @raise(i32)
declare ptr @signal(i32, ptr)

define internal void @h(i32 %s) {
  store volatile i32 %s, ptr @hit, align 4
  ret void
}

define i32 @peek() {
  %v = load volatile i32, ptr @hit, align 4
  ret i32 %v
}

define i32 @raise_h(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %old = call ptr @signal(i32 30, ptr @h)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %r = call i32 @raise(i32 30)
  br label %done
done:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
