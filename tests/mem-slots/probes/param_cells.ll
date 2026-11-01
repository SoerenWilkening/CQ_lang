; Rule 20, 60's shape at i32 cells: an entry's pointer parameter points at the caller's handle slots.
; q[i] is a load of the caller's handle; the rotation is in place; storing it back changes nothing.
declare i32 @cq_theta_si32(i32, double)

define void @param_cells(ptr %q, i32 %i, double %t) {
  %ii = sext i32 %i to i64
  %p = getelementptr inbounds i32, ptr %q, i64 %ii
  %h = load i32, ptr %p
  %x = call i32 @cq_theta_si32(i32 %h, double %t)
  store i32 %x, ptr %p
  ret void
}
; CHECK param_cells: %{{h}} = load i32, ptr %{{p}}, align 4
; CHECK param_cells: call void @cqrt_ry_i32(i32 %{{h}}, double %{{t}})
; CHECK-COUNT param_cells: store i32 0
; CHECK-COUNT param_cells: cqrt_alloc 0
; CHECK-COUNT param_cells: cqrt_free 0
