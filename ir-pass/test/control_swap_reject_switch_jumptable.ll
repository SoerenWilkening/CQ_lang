; control_swap_reject_switch_jumptable.ll — DECLINE (pre-detection): a many-case
; DATA switch clang -O1 folds to a @switch.table gep/load. The tainted scrutinee
; reaches the getelementptr — an unsupported instruction — so declineTaintEscapes
; (L64) fires BEFORE control detection (L83). Hand-written in the folded form.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}tainted value reaches an unsupported instruction
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
