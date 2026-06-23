; lowering_qram_store_flat_gep.ll — ACCEPT (Phase 7.5 Inc 3): a tainted-index
; store+load through a FLAT element gep (`getelementptr i32, ptr %a, %idx`), the
; shape clang -O1 emits for a POINTER-indirected access (`int *b = arr; b[q]`) —
; distinct from the array-decay `[N x iW], 0, %idx` form Inc 1/2 handled. The Inc 3
; provenance walk resolves the flat gep's single origin (the `alloca [8 x i32]`)
; with a provable zero offset and lowers it on the Shadow path exactly like the
; array-decay form. NO measurement inserted beyond the user's (Rule 5).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @flat(i32 %u0, i32 %u1) {
entry:
  %a = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds i32, ptr %a, i64 %iq        ; FLAT gep (no array-decay)
  store i32 7, ptr %gq, align 4
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds i32, ptr %a, i64 %ip        ; FLAT gep
  %v = load i32, ptr %gp, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK:     call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:     call void @cqrt_qram_store_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_qram_load_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: getelementptr
; CHECK-NOT: cq taint escape
; CHECK-NOT: cq QRAM access
