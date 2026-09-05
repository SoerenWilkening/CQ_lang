; control_swap_reject_switch_foreign_pred.ll — DECLINE: the merge block has a
; FOREIGN predecessor (%pre2, reached by a CLASSICAL branch, not a switch edge or
; case arm). The Rule-13 H4 over-accept: the N-way merge recovery dropped the
; br-path's 2-incoming structural bound, so a foreign incoming (`[0, %pre2]`) was
; silently admitted — it would dangle when WI-2/3/4 dissolves the phi and flattens.
; The foreign-pred guard re-imposes the bound: every phi incoming block must be the
; switch block or a case arm. (`%classical` is an untainted param, so the entry
; branch is NOT a tainted-control region and does not pre-empt the switch.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i1 %classical) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %classical, label %sw, label %pre2
sw:
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
pre2:
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
