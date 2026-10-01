; lowering_reject_stale_record_tainted_arm_hoisted_chain.ll — DECLINE (bd
; test_C_libtooling-r2j3.2, review round 2 F1: an introduced wrong unitary on
; d6ffaca3). clang -O1 of the reviewer's q4:
;
;     int arr[8] = {0};
;     long q = cq_theta(0L, .5);  long j = cq_theta(0L, .9);  int c = cq_theta(0, .7);
;     if (c > 2) arr[j] = (int)(q ^ 6);        // pure chain on q in a TAINTED arm
;     long q2 = cq_theta(q, .3);                // in-place Ry on q after the merge
;
; The `trunc`/`xor` read `q` before the Ry on every CFG trace, and the Ry
; post-dominates them, so the post-dominance grant accepted it (rc 0, only the M-A
; warning). But the guarded-store region HOISTS the arm's pure chain into the pred,
; where it runs UNCONDITIONALLY, and nothing discharges it: `trunc(h1)` stays a live
; CNOT copy of q on every branch across the later Ry (measured P(q2=1) ≈ 0.081 against
; the source's sin²(0.4) ≈ 0.152). So a read inside a tainted arm is granted only
; when the emitter issues it in place (a QRAM access); a pure op there declines here,
; with main's message. RETIREMENT TRIGGER: when GuardedStoreArmEmit discharges a
; hoisted value chain (filed by the coordinator with review F2), re-derive this.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

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
