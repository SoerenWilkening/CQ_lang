; control_swap_select_and2.ll — ACCEPT (3c6m.12 L4): the `and i1` compound —
; the shape `control_swap_reject_select_badcond.ll` pinned as a decline until
; this increment (deliberate Rule-12 re-pin, the fpdata precedent; badcond now
; pins the still-declined non-tree condition). AND needs NO cnots: ONE
; `cqrt_toffoli(f1, f2, g)` computes g = f1∧f2 on the `|0⟩` ancilla; its strip
; is the same self-inverse toffoli (compound-cond-select-PRD §1/§3).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c2  = icmp slt i32 %q, 100
  %c   = and i1 %c1, %c2
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 100)
; CHECK:     %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; the AND node is a single toffoli — CHECK-NOT pins that no cnot precedes it:
; CHECK-NOT: cqrt_cnot
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[XH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G]])
; strip: the self-inverse toffoli, ancilla free, then leaf strips (f2 first):
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK:     call void @cqrt_free(i32 %[[G]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 100)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NOT: cqrt_cnot
; CHECK-NOT: cq_template_and_i1
; CHECK-NOT: select i1
