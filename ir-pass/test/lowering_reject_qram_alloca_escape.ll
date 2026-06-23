; lowering_reject_qram_alloca_escape.ll — DECLINE (Phase 7.5 Inc 2, §2.8(iv)): the
; alloca-backed array's POINTER escapes to an opaque call. After a tainted-index
; store, the raw `alloca` pointer is passed to `@sink` — the backend cannot prove a
; single linear PtrOrigin / no aliasing once the pointer leaves (no-cloning /
; linearity, [[pointer-boundary-linearity-bennett]]); freeing or reversing a
; possibly-aliased array would be a use-after-free / double-free of cells. LOUD
; decline naming the escape.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare void @sink(ptr)

define void @alloca_escape(i32 %u0) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  store i32 7, ptr %gq, align 4                ; tainted-index store
  call void @sink(ptr %arr)                    ; the array POINTER escapes
  ret void
}

; CHECK: error{{.*}}cq QRAM store: alloca array escapes to an unsupported user
