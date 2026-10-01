; lowering_qram_stale_index_lifted_phi_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.2): the accept twin of
; lowering_qram_reject_stale_index_lifted_phi.ll. Same one-register classical
; merge φ as the index, but the sibling `cq_theta` on the register runs AFTER the
; read. The post-lift re-sweep sees the emitted `cqrt_qram_load_*` reading the
; wire base and finds the gate provably after it: harmless, the module lowers.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: error
; CHECK: call i32 @cqrt_qram_load_i32(
; CHECK: call void @cqrt_ry_i64(i32 %{{[^,]+}}, double 3.000000e-01)

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)

define i32 @main(i32 %u, i1 %c) {
entry:
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  br label %merge
merge:
  %p  = phi i64 [ %q, %arm ], [ %q, %entry ]   ; one register, two SSA names
  %a  = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %p
  %v  = load i32, ptr %a, align 4               ; read first
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)   ; then rotate
  %m  = call i32 @cq_measure_si32(i32 %v)
  %n  = call i64 @cq_measure_sl(i64 %q2)
  %nt = trunc i64 %n to i32
  %s  = add i32 %m, %nt
  ret i32 %s
}
