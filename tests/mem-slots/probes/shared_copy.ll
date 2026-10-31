; cq-dr4o, CR rule 20 with C value semantics: s[k] = q[j] stores the handle of an alias load of q while
; q[j] (and the cq_theta result %x, which may be the same rail when j == i) is still read after the
; store. The cell gets its own rail, a basis copy (CR §0): alloc 0, copy_i32; the in-place rotation of
; s[m] then never touches q's rail. The store of %x back into q[i] is a copy too (cq-7hpb): %x is still
; read (measured) after it, so x and q[i] are two C objects.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @shared_copy(i32 %i, i32 %j, i32 %k, i32 %m, double %t) {
  %q = alloca [4 x i32], align 16
  %s = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %q, i8 0, i64 16, i1 false)
  call void @llvm.memset.p0.i64(ptr align 16 %s, i8 0, i64 16, i1 false)
  %ii = zext i32 %i to i64
  %pi = getelementptr inbounds [4 x i32], ptr %q, i64 0, i64 %ii
  %v = load i32, ptr %pi, align 4
  %x = call i32 @cq_theta_si32(i32 %v, double %t)
  store i32 %x, ptr %pi, align 4
  %jj = zext i32 %j to i64
  %pj = getelementptr inbounds [4 x i32], ptr %q, i64 0, i64 %jj
  %w = load i32, ptr %pj, align 4
  %kk = zext i32 %k to i64
  %pk = getelementptr inbounds [4 x i32], ptr %s, i64 0, i64 %kk
  store i32 %w, ptr %pk, align 4
  %mm = zext i32 %m to i64
  %pm = getelementptr inbounds [4 x i32], ptr %s, i64 0, i64 %mm
  %y = load i32, ptr %pm, align 4
  %z = call i32 @cq_theta_si32(i32 %y, double %t)
  store i32 %z, ptr %pm, align 4
  %r = call i32 @cq_measure_si32(i32 %x)
  ret i32 %r
}
; CHECK shared_copy: %{{w}} = load i32, ptr %{{pj}}, align 4
; CHECK shared_copy: %{{c}} = call i32 @cqrt_alloc_i32(i32 0)
; CHECK shared_copy: call void @cqrt_copy_i32(i32 %{{w}}, i32 %{{c}})
; CHECK shared_copy: store i32 %{{c}}, ptr %{{pk}}, align 4
; CHECK-COUNT shared_copy: call void @cqrt_copy_i32( 2
