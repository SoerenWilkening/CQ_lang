; Rule 20, a runtime-sized slot array (58's shape at i32 cells): `alloca i32, n` of handles; a classical
; store is a seed rail (homogeneity, rule 7); the load right after it forwards; the rotation is in place;
; the load at another run-time index is a load of the handle (an alias). The cells are registers: kept.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @dynamic_local(i32 %n, i32 %i, i32 %j, double %t) {
  %nn = zext i32 %n to i64
  %a = alloca i32, i64 %nn, align 16
  %ii = sext i32 %i to i64
  %pi = getelementptr inbounds i32, ptr %a, i64 %ii
  store i32 0, ptr %pi
  %v = load i32, ptr %pi
  %x = call i32 @cq_theta_si32(i32 %v, double %t)
  store i32 %x, ptr %pi
  %jj = sext i32 %j to i64
  %pj = getelementptr inbounds i32, ptr %a, i64 %jj
  %w = load i32, ptr %pj
  %r = call i32 @cq_measure_si32(i32 %w)
  ret i32 %r
}
; CHECK dynamic_local: %{{a}} = alloca i32, i64 %{{nn}}, align 16
; CHECK dynamic_local: %{{s}} = call i32 @cqrt_alloc_i32(i32 0)
; CHECK dynamic_local: store i32 %{{s}}, ptr %{{pi}}, align 4
; CHECK dynamic_local: call void @cqrt_ry_i32(i32 %{{s}}, double %{{t}})
; CHECK dynamic_local: %{{w}} = load i32, ptr %{{pj}}, align 4
; CHECK dynamic_local: call i32 @cqrt_measure_i32(i32 %{{w}})
; CHECK-COUNT dynamic_local: load i32 1
; CHECK-COUNT dynamic_local: call void @cqrt_free( 0
