; A memset of a slot object whose loads all forward (static): its seeds would be freed at their store
; while the cell still holds them. Not built: an internal error.
; EXPECT-ERROR: mem-qram: a memset of a slot object no load reads back at a run-time cell
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @memset_static(i32 %y, double %t) {
  %a = alloca [2 x i32], align 4
  call void @llvm.memset.p0.i64(ptr align 4 %a, i8 0, i64 8, i1 false)
  %x = call i32 @cq_theta_si32(i32 %y, double %t)
  store i32 %x, ptr %a, align 4
  %v = load i32, ptr %a, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
