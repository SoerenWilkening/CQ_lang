; lowering_qram_store_mixed_classical_separate.ll — ACCEPT (Phase 7.5 Inc 2, §2.2 /
; §6.6 "no spurious taint"): a function with TWO arrays — `%qarr` accessed with a
; tainted index (lowers to QRAM) and a SEPARATE `%carr` accessed only with a
; classical index. The carve fires ONLY on index-or-value taint, so `%carr` is never
; a candidate: its `alloca` + classical `store`/`load` are left BYTE-UNTOUCHED (no
; spurious taint, no qram lowering). The quantum array lowers as usual.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mixed_sep(i32 %u0, i32 %u1, i32 %k) {
entry:
  %qarr = alloca [8 x i32], align 16            ; quantum array (tainted index)
  %carr = alloca [4 x i32], align 16            ; classical array (constant index)
  call void @llvm.memset.p0.i64(ptr align 16 %qarr, i8 0, i64 32, i1 false)
  call void @llvm.memset.p0.i64(ptr align 16 %carr, i8 0, i64 16, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  ; quantum: qarr[q] = 7; v = qarr[p]; measure(v)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %qarr, i64 0, i64 %iq
  store i32 7, ptr %gq, align 4
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %qarr, i64 0, i64 %ip
  %v = load i32, ptr %gp, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ; classical: carr[2] = k (k is a plain arg, untainted); reload carr[2]
  %gc = getelementptr inbounds [4 x i32], ptr %carr, i64 0, i64 2
  store i32 %k, ptr %gc, align 4
  %cv = load i32, ptr %gc, align 4
  %sum = add i32 %m, %cv
  ret i32 %sum
}

; The quantum array lowers (its `%qarr` alloca is erased → an array handle); the
; classical array's alloca + store + load SURVIVE (untouched — the classical-index
; access stays classical):
; CHECK:     call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK-DAG: %carr = alloca [4 x i32]
; CHECK-DAG: store i32 %k, ptr %{{.*}}
; CHECK-DAG: %cv = load i32, ptr %{{.*}}
; CHECK-NOT: cq taint escape
