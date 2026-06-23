; lowering_reject_qram_aliasing.ll — DECLINE (Phase 7.5 Inc 3, the §2.8(iv) /
; §6.3 pattern-naming decline matrix): a tainted-index address with ALIASING
; FAN-OUT — a single `getelementptr` (one cell address) consumed by MORE THAN ONE
; memory op (here a read-modify-write `arr[q] += 1`: the shared gep feeds both a
; load and a store). Two memory views of the same cell break the strict-LIFO tape
; pairing the reversible store reversal relies on (a use-after-free / double-free of
; cells, §6.3) — reversibility cannot be proven, so DECLINE. The single-use address
; gep is the invariant the accept rests on; a shared address loud-declines NAMING
; the fan-out. (Inc 2 already declined this generically; Inc 3 names it.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)

define void @rmw(i32 %u0) {
entry:
  %a = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 %iq   ; SHARED address
  %v = load i32, ptr %g, align 4                                  ; user 1
  %s = add i32 %v, 1
  store i32 %s, ptr %g, align 4                                   ; user 2
  ret void
}

; CHECK: error{{.*}}cq QRAM access: array address has aliasing fan-out
