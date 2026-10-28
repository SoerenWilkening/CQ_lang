; Rule 20, a heap block of f64 cells holding handles (75's shape, other element size): the block holds
; one i32 handle per cell, so malloc(n) becomes malloc(n / 8 * 4); free stays the classical call.
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare ptr @malloc(i64) allockind("alloc,uninitialized") allocsize(0)
declare void @free(ptr) allockind("free")

define double @heap_cells(i32 %n, i32 %i, i32 %j, double %x0, double %t) {
  %nn = zext i32 %n to i64
  %sz = shl i64 %nn, 3
  %a = call ptr @malloc(i64 %sz)
  %x = call double @cq_theta_f64(double %x0, double %t)
  %ii = sext i32 %i to i64
  %pi = getelementptr inbounds double, ptr %a, i64 %ii
  store double %x, ptr %pi
  %jj = sext i32 %j to i64
  %pj = getelementptr inbounds double, ptr %a, i64 %jj
  %w = load double, ptr %pj
  %r = call double @cq_measure_f64(double %w)
  call void @free(ptr %a)
  ret double %r
}
; CHECK heap_cells: %{{d}} = udiv i64 %{{sz}}, 8
; CHECK heap_cells: %{{m}} = mul i64 %{{d}}, 4
; CHECK heap_cells: %{{a}} = call ptr @malloc(i64 %{{m}})
; CHECK heap_cells: %{{pi}} = getelementptr inbounds i32, ptr %{{a}}, i64 %{{ii}}
; CHECK heap_cells: store i32 %{{x}}, ptr %{{pi}}, align 4
; CHECK heap_cells: %{{w}} = load i32, ptr %{{pj}}, align 4
; CHECK heap_cells: call void @free(ptr %{{a}})
