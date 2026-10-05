; lowering_qram_lifted_index_own_arm_theta_accept.ll — ACCEPT (bd
; test_C_libtooling-dm7f.1; DECLINE->ACCEPT). The QRAM twin of
; lowering_lift_resweep_own_arm_theta_accept.ll and the accept side of
; lowering_qram_reject_stale_index_lifted_phi.ll: a bare i64 index that is a
; one-register lifted phi whose arm incoming is the register's OWN `cq_theta`.
;
;     long q = 0; cq_theta(&q, .5);
;     if (c) cq_theta(&q, .3);
;     int v = tbl[q];
;
; The emitted `cqrt_qram_load_i32` reads the lifted phi in its index slot, a
; recorded use; the arm's `%q2` is on that record. The stale twin (a SIBLING
; `cq_theta(%q, ·)` before the read) keeps declining.
;
; SEMANTIC EVIDENCE (hand trace). h = alloc(0); Ry(.5); [c] Ry(.3); the index
; bracket trunc(h) -> t; qram_load(tbl, t) reads the cell at the CURRENT q, which
; on each path is the record the phi names; the bracket strips t. The load is
; measured.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK-NEXT: call void @cqrt_ry_i64(i32 %[[H]], double 5.000000e-01)
; CHECK:      call void @cqrt_ry_i64(i32 %[[H]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_qram_load_i32(
; CHECK:      call i32 @cqrt_measure_i32(

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u, i1 %c) {
entry:
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)   ; the register's OWN gate
  br label %merge
merge:
  %p  = phi i64 [ %q2, %arm ], [ %q, %entry ]
  %a  = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %p
  %v  = load i32, ptr %a, align 4
  %m  = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
