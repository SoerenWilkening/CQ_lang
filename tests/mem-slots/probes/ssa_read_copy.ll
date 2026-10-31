; cq-7hpb, CR rule 20 with C value semantics: b[j] = x stores the cq_theta result %x, which no other
; memory cell holds, while %x itself is still measured after the store. The cell gets its own rail, a
; basis copy (CR §0): alloc 0, copy_i32, so measuring b[j] and measuring x are two measurements of two
; rails (a move would make them one rail, and the C program's second measurement a re-read).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @ssa_read_copy(i32 %q0, double %t, i32 %j, i32 %k) {
  %b = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %b, i8 0, i64 16, i1 false)
  %x = call i32 @cq_theta_si32(i32 %q0, double %t)
  %jm = and i32 %j, 3
  %jj = zext i32 %jm to i64
  %pj = getelementptr inbounds [4 x i32], ptr %b, i64 0, i64 %jj
  store i32 %x, ptr %pj, align 4
  %km = and i32 %k, 3
  %kk = zext i32 %km to i64
  %pk = getelementptr inbounds [4 x i32], ptr %b, i64 0, i64 %kk
  %y = load i32, ptr %pk, align 4
  %z = call i32 @cq_theta_si32(i32 %y, double %t)
  store i32 %z, ptr %pk, align 4
  %bj = load i32, ptr %pj, align 4
  %r1 = call i32 @cq_measure_si32(i32 %bj)
  %r2 = call i32 @cq_measure_si32(i32 %x)
  %r = add i32 %r1, %r2
  ret i32 %r
}
; CHECK ssa_read_copy: call void @cqrt_copy_i32(i32 %{{x}}, i32 %{{c}})
; CHECK-COUNT ssa_read_copy: call void @cqrt_copy_i32( 2
; CHECK-COUNT ssa_read_copy: call i32 @cqrt_measure_i32( 2
