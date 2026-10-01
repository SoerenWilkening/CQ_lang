; lowering_reject_qram_index_width_shadow.ll — LOUD (libcqops handoff b6a): the
; local-array (`processShadowAlloca`) twin of lowering_reject_qram_index_width.ll.
; The store's i64 index resolves (trunc), the load's i48 index does not. The width
; check runs for EVERY access before any emission, so on a host that does not exit
; on `DS_Error` the alloca is never left half-lowered. Under `opt` the first error
; exits, so that property is not observable here: this fixture pins the message
; only (removing the pre-check leaves it green — recorded, round-1 review F4).
; Retire with its twin when the integer width grid grows.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i64 @cq_theta_sll(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @shadow_i48(i64 %u, i32 %x) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i64 @cq_theta_sll(i64 %u, double 5.000000e-01)
  %g0 = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %q
  store i32 %x, ptr %g0, align 4
  %t = trunc i64 %q to i48
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i48 %t
  %v = load i32, ptr %g, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: in function shadow_i48 {{.*}}: cq QRAM access: index has no cast to the i32 index width
