; control_predmux_accept_qrom_jumptable.ll — ACCEPT (3c6m.14 L6 Inc 3,
; DELIBERATE FLIP of control_swap_reject_switch_jumptable.ll): the many-case
; DATA switch clang -O1 folds to a @switch.table bounds-check diamond +
; gep/load. The tainted scrutinee's table read under the tainted `ult 4`
; guard is now a claimable QROM read (pow2 table, QromClaim::NeedsMask): the
; W4 witness claims the diamond, the flatten speculates the read with the
; index masked to `and idx, 3` (identity on every in-guard basis state;
; excluded states read a garbage row that the merge's ∧-with-block-predicate
; discards — PRD §4.4/§6.1), and the 7.5 QROM emitter + Phase-5 uncompute
; lower/reverse it. The jump-table fold is no longer a decline row; the
; surviving under-control declines are pinned by
; lowering_reject_qram_read_under_control_nonpow2.ll (bounds) and the
; _nonconst/_wide/_cohescape family (shape/width/no-cloning).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
@switch.table.example = private unnamed_addr constant [4 x i32] [i32 7, i32 9, i32 11, i32 13]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp ult i32 %q, 4
  br i1 %c, label %tbl, label %merge
tbl:
  %idx = zext i32 %q to i64
  %gep = getelementptr inbounds [4 x i32], ptr @switch.table.example, i64 0, i64 %idx
  %val = load i32, ptr %gep, align 4
  br label %merge
merge:
  %rm = phi i32 [ %val, %tbl ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:     %[[MSK:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 3)
; CHECK:     call i32 @cqrt_qram_load_i32(i32 %[[T]], i32 %[[MSK]])
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
