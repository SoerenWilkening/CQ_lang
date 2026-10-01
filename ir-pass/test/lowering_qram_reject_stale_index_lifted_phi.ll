; lowering_qram_reject_stale_index_lifted_phi.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): the index is a ONE-REGISTER classical merge φ, and a
; SIBLING chained `cq_theta` rotates that register before the read. At the early
; sweep the φ hides the sibling (the wire closure stops at a φ). The one-register
; lift (`declineClassicalMuxes`) RAUWs the φ to its wire base AFTER both QRAM
; emitters ran, so it is the post-lift re-sweep (`declineLiftedStaleRecordOps`)
; that must ask about the EMITTED `cqrt_qram_load_*` call's index. QRAM twin of
; lowering_reject_classical_mux_phi_lift_stale.ll (bd 2qyz). MEASURED on the
; pre-fix binary: exit 0, `qram_load(a0, trunc(h1))` after both `ry(h1, ·)`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

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
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)   ; SIBLING Ry on %q's register
  %a  = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %p
  %v  = load i32, ptr %a, align 4               ; reads the PRE-Ry record
  %m  = call i32 @cq_measure_si32(i32 %v)
  %n  = call i64 @cq_measure_sl(i64 %q2)
  %nt = trunc i64 %n to i32
  %s  = add i32 %m, %nt
  ret i32 %s
}
