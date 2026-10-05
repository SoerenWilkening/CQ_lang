; lowering_stale_record_tainted_arm_hoisted_chain_discharged.ll — ACCEPT (bd
; test_C_libtooling-01po.7; a DECLINE->ACCEPT flip of
; `lowering_reject_stale_record_tainted_arm_hoisted_chain.ll`, bd r2j3.2 review
; round 2 F1). clang -O1 of the reviewer's q4:
;
;     int arr[8] = {0};
;     long q = 0L; cq_theta(&q, .5);  long j = 0L; cq_theta(&j, .9);  int c = 0; cq_theta(&c, .7);
;     if (c > 2) arr[j] = (int)(q ^ 6);        // pure chain on q in a TAINTED arm
;     long q2 = q; cq_theta(&q2, .3);           // in-place Ry on q after the merge
;
; The decline it shipped as was a stopgap for the hoisted chain: on d6ffaca3 the
; guarded-store region hoisted `trunc`/`xor` into the pred and nothing discharged
; them, so `trunc(q)` stood as a live copy of q on every branch across the Ry
; (measured P(q2=1) ≈ 0.081). Its retirement trigger was "when the hoisted value
; chain is discharged". Since bd r2j3.1 a store is an interior consumer of the
; rails it reads (`ChainWalk::isInteriorConsumer` (b″)), and nothing in `main` is
; reversed, so the spine discharges the chain right after the store. bd 01po.7 grants
; the read and RE-CHECKS that late: a granted read still live at a gate is an error
; (lowering_reject_tainted_arm_read_live_at_gate.ll), so this accept depends on the
; discharge it pins below, not on a prediction.
;
; SEMANTIC EVIDENCE (hand trace of the stream below). f = (c > 2) on its own rail;
; t = trunc(q), then t ^= 6 in place, on EVERY branch (hoisted); the controlled
; store copies t into arr[j] only when f = 1, the source's guarded write (bd 38t2).
; Then t is restored (`xorc 6`, `trunc_unc` against the unmoved q) and freed, BEFORE
; `Ry(.3)` fires on q: the hoisted copy is created and destroyed while q is
; unchanged, the identity on q, so on the f = 0 branch q carries no copy at the Ry,
; as in the source. On f = 1 the only copy left is the cell the source wrote.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; DIAG-NOT: live derived record
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[T]], i32 6)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T]])
; CHECK:      call void @cqrt_xorc_i32(i32 %[[T]], i32 6)
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[T]], i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK:      call void @cqrt_ry_i64(i32 %[[Q]], double 3.000000e-01)

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @main() {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr %arr, i8 0, i64 32, i1 false)
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %j = call i64 @cq_theta_sl(i64 0, double 9.000000e-01)
  %c = call i32 @cq_theta_si32(i32 0, double 0x3FE6666666666666)
  %cmp = icmp sgt i32 %c, 2                       ; TAINTED condition
  br i1 %cmp, label %arm, label %merge

arm:
  %t = trunc i64 %q to i32                        ; reads q inside the tainted arm
  %x = xor i32 %t, 6
  %ps = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %j
  store i32 %x, ptr %ps, align 4
  br label %merge

merge:
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)
  %pl = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %j
  %v = load i32, ptr %pl, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i64 @cq_measure_sl(i64 %q2)
  %nt = trunc i64 %n to i32
  %s = add nsw i32 %m, %nt
  %mc = call i32 @cq_measure_si32(i32 %c)
  %s2 = add nsw i32 %s, %mc
  ret i32 %s2
}
