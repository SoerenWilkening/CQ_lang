; spec_accept_clone_classical_cond.ll — ACCEPT (bd p3kd.7.2; was
; spec_reject_clone_classical_cond.ll, the 5po2 I2 over-accept probe): a CLASSICAL
; condition choosing between two QUANTUM arms in a lifted callee,
; `helper(b, k) = (k > 5) ? b+1 : b+2` with `b` quantum and `k` classical. Owner
; ruling 2026-10-06 (bd memory owner-ruling-clone-classical-control-2026-10-06):
; inside a Bennett clone a classical choice is a classical choice of RAIL. Both arms
; are computed; after `lowerOps` the select is retyped to choose between the two
; i32 handles (`rewriteRailSelects`, CloneRailSelect.h), its condition frozen (a
; classical value may be poison; `freeze` keeps the choice to one of the two
; rails). The wrap copies out the chosen rail and reverses BOTH arms on their own
; operands, so the reverse never reads the select and every rail is |0> at its
; free whatever `k` was.
;
; Trace check, |b> and classical k: out = (k>5) ? b+1 : b+2; reverse: add_unc on
; each arm's own rail, so both scratch rails return to |0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %k) {
entry:
  %c = icmp sgt i32 %k, 5
  %r1 = add i32 %b, 1
  %r2 = add i32 %b, 2
  %r = select i1 %c, i32 %r1, i32 %r2
  ret i32 %r
}

define i32 @example(i32 %u0, i32 %kk) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, i32 %kk)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}


; CHECK-LABEL: define internal i32 @__cq_q_helper_01(i32 %b, i32 %k)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[C:[a-zA-Z0-9_.]+]] = icmp sgt i32 %k, 5
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 1)
; CHECK-NEXT:  %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 2)
; CHECK-NEXT:  %[[FC:[a-zA-Z0-9_.]+]] = freeze i1 %[[C]]
; CHECK-NEXT:  %[[S:[a-zA-Z0-9_.]+]] = select i1 %[[FC]], i32 %[[A]], i32 %[[B]]
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[S]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[B]], i32 %b, i32 2)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[A]], i32 %b, i32 1)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[B]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
