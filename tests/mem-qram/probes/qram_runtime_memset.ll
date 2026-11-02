; A run-time-length memset into a QRAM (cq-k65d, f684858, rule 22): a classical loop over the cells, each
; trip's store under its classical guard (the run covers the cell) as a seed flag (rules 7, 8); the reverse
; loop pops the stores, last trip first, after the object's later accesses (F1b), reading the trip's
; handles back from the host buffer the forward trip saved them in.
; CHECK rtm: %{{c}} = udiv i64 %{{s}}, 4
; CHECK rtm: %{{f}} = call i32 @cqrt_alloc_i1(i1 %{{g}})
; CHECK rtm: call ptr @malloc(
; CHECK-COUNT rtm: call void @cqrt_qram_store_i32_hl_controlled( 1
; CHECK-COUNT rtm: call void @cqrt_qram_store_i32_hl_controlled_unc( 1
; CHECK rtm: call void @free(ptr
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @rtm(i32 %x0, double %t, i32 %v, i64 %n) {
  %a = alloca [4 x i32], align 16
  %n4 = and i64 %n, 12
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 0, i64 %n4, i1 false)
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds [4 x i32], ptr %a, i64 0, i64 %iz
  store i32 %v, ptr %p, align 4
  %r = load i32, ptr %a, align 4
  %m = call i32 @cq_measure_ui32(i32 %r)
  ret i32 %m
}
