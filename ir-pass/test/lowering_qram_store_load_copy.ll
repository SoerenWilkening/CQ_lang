; lowering_qram_store_load_copy.ll — ACCEPT (Phase 7.5 Inc 3, PRD-7.5 §6.2 + bd
; 7z9k.3 over-decline hardening #2): the straight-line DEAD-LOAD-then-STORE shape
; `arr[p] = arr[q]` — a tainted-index load whose value is NOT observed (no measure /
; ret) feeds a later tainted-index store. Inc 2 captured the store's value operand
; at classify time; the load access then RAUW'd its original load to the new
; `cqrt_qram_load` and queued the original for erase, so the new store re-used the
; STALE original-load pointer → a dangling operand (a verify-fail / crash masked as
; the CONFUSING `kMsgDivergentArm`). The fix re-reads the value operand FRESH from
; the original store at emit time, so the new store consumes the NEW load — a clean
; ACCEPT. The array is a loaded register (not a terminal) → left allocated, never
; freed (a Rule-6 safe leak). NO measurement (Rule 5).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)

define void @copy(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  %vq = load i32, ptr %gq, align 4          ; load arr[q] — value NOT observed
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ip
  store i32 %vq, ptr %gp, align 4           ; arr[p] = arr[q]
  ret void
}

; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; The load produces a value the store CONSUMES (the fresh-read fix — not a stale
; dangling operand):
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[V]])
; CHECK-NOT: cq uncompute: dead chain spans divergent control-flow arms
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq QRAM access
