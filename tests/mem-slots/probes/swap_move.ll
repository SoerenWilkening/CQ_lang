; cq-dr4o, CR rule 20: a swap of two cells of one slot array is two moves. Each stored handle's other
; holder (its source cell) is overwritten before anything reads it, and no SSA value naming it is read
; after the store: the handles change cells, no copy.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @swap_move(i32 %i, i32 %j, i32 %m, double %t) {
  %q = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %q, i8 0, i64 16, i1 false)
  %ii = zext i32 %i to i64
  %pi = getelementptr inbounds [4 x i32], ptr %q, i64 0, i64 %ii
  %v = load i32, ptr %pi, align 4
  %x = call i32 @cq_theta_si32(i32 %v, double %t)
  store i32 %x, ptr %pi, align 4
  %jj = zext i32 %j to i64
  %pj = getelementptr inbounds [4 x i32], ptr %q, i64 0, i64 %jj
  %w = load i32, ptr %pj, align 4
  store i32 %w, ptr %pi, align 4
  store i32 %x, ptr %pj, align 4
  %mm = zext i32 %m to i64
  %pm = getelementptr inbounds [4 x i32], ptr %q, i64 0, i64 %mm
  %y = load i32, ptr %pm, align 4
  %z = call i32 @cq_theta_si32(i32 %y, double %t)
  store i32 %z, ptr %pm, align 4
  %a = load i32, ptr %pi, align 4
  %r = call i32 @cq_measure_si32(i32 %a)
  ret i32 %r
}
; CHECK swap_move: store i32 %{{w}}, ptr %{{pi}}, align 4
; CHECK swap_move: store i32 %{{x}}, ptr %{{pj}}, align 4
; CHECK-COUNT swap_move: call void @cqrt_copy_i32( 0

; -O1's order for `x = q[i]; q[i] = q[j]; q[j] = x`: both loads first. The second store's overwrite of
; its source cell q[i] stores a load of q[j], S's own cell: that load is the moved rail only when i == j,
; where the cells coincide.
define i32 @swap_loads_first(i32 %i, i32 %j, double %t) {
  %q = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %q, i8 0, i64 16, i1 false)
  %ii = zext i32 %i to i64
  %pi = getelementptr inbounds [4 x i32], ptr %q, i64 0, i64 %ii
  %v = load i32, ptr %pi, align 4
  %x = call i32 @cq_theta_si32(i32 %v, double %t)
  store i32 %x, ptr %pi, align 4
  %jj = zext i32 %j to i64
  %pj = getelementptr inbounds [4 x i32], ptr %q, i64 0, i64 %jj
  %a = load i32, ptr %pi, align 4
  %b = load i32, ptr %pj, align 4
  store i32 %b, ptr %pi, align 4
  store i32 %a, ptr %pj, align 4
  %c = load i32, ptr %pj, align 4
  %r = call i32 @cq_measure_si32(i32 %c)
  ret i32 %r
}
; CHECK swap_loads_first: store i32 %{{b}}, ptr %{{pi}}, align 4
; CHECK-COUNT swap_loads_first: call void @cqrt_copy_i32( 0
