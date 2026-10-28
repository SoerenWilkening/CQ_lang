; Rule 22 over a rule-20 slot array, 58's shape at char cells: `signed char q[n]` zeroed by llvm.memset of
; a run-time length. The memset is a classical loop over the n cells, each storing its own |0> seed
; cqrt_alloc_i8(i8 0) into its handle cell. The object is read back at run-time cells (dynamic), so the
; seeds are registers: nothing is freed. (58 itself has _Bool cells, whose zext store is cq-sj2j's.)
declare i8 @cq_theta_si8(i8, double)
declare i8 @cq_measure_si8(i8)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i8 @memset_runtime_char(i32 %n, i32 %i, i32 %j, double %t) {
  %nn = zext i32 %n to i64
  %q = alloca i8, i64 %nn, align 16
  call void @llvm.memset.p0.i64(ptr align 16 %q, i8 0, i64 %nn, i1 false)
  %ii = sext i32 %i to i64
  %p = getelementptr inbounds i8, ptr %q, i64 %ii
  %b = load i8, ptr %p, align 1
  %x = call i8 @cq_theta_si8(i8 %b, double %t)
  store i8 %x, ptr %p, align 1
  %jj = sext i32 %j to i64
  %pj = getelementptr inbounds i8, ptr %q, i64 %jj
  %b2 = load i8, ptr %pj, align 1
  %m = call i8 @cq_measure_si8(i8 %b2)
  ret i8 %m
}
; CHECK memset_runtime_char: %{{q}} = alloca i32, i64 %{{nn}}, align 16
; CHECK memset_runtime_char: %{{j}} = phi i64 [ 0, %{{pre}} ], [ %{{j1}}, %{{body}} ]
; CHECK memset_runtime_char: %{{s}} = call i32 @cqrt_alloc_i8(i8 0)
; CHECK memset_runtime_char: store i32 %{{s}}, ptr %{{cell}}, align 4
; CHECK-COUNT memset_runtime_char: @cqrt_alloc_i8( 1
; CHECK-COUNT memset_runtime_char: call void @cqrt_free( 0
; CHECK memset_runtime_char: call void @cqrt_ry_i8(i32 %{{h}}, double %{{t}})
