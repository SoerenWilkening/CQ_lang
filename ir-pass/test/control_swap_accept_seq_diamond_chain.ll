; control_swap_accept_seq_diamond_chain.ll — ACCEPT (bd hcrg): THREE sequential
; tainted-condition phase diamonds, each region's merge hosting the next
; region's branch.
;
; `if(q>5){rz a}; if(q>3){rz b}; if(q>1){rz c}` — the two-region accept
; (control_swap_accept_seq_ifelse_then_diamond.ll) generalized, and the reason
; the emission order is a topological SORT and not a hard-coded "reverse".
; The precedence edges are R3→R2→R1 (each region names the previous one's merge
; as its Pred), so Kahn schedules [R3, R2, R1]; each flatten then splices its
; merge — carrying every already-emitted later region along with it — into a
; pred that is still live.
;
; THE LOAD-BEARING ASSERTION IS ORDER: the gate stream must read 5, then 3, then
; 1 — SOURCE order — even though the emitters ran 1, 3, 5. Every SSA name below
; is a regex capture for exactly that reason (the un-suffixed `%rail`/`%h_cmp`
; belong to the LAST region in the source, which was emitted FIRST). A
; regression that emitted in plan order would still verify clean and still pair
; every free; only this ordering, and the golden traces, would catch it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b, double %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  call void @cq_phi(double %a)
  br label %m1
m1:
  %c2 = icmp sgt i32 %q, 3
  br i1 %c2, label %arm2, label %m2
arm2:
  call void @cq_phi(double %b)
  br label %m2
m2:
  %c3 = icmp sgt i32 %q, 1
  br i1 %c3, label %arm3, label %m3
arm3:
  call void @cq_phi(double %c)
  br label %m3
m3:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
;
; region 1 (q>5) — first in the stream.
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[Q]], double %a)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
;
; region 2 (q>3) — second, on the same wire, after region 1's flag is gone.
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[Q]], double %b)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
;
; region 3 (q>1) — third.
; CHECK:     %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 1)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F3]], i32 %[[Q]], double %c)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F3]], i32 %[[Q]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[F3]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
;
; CHECK-NOT: phi
; CHECK-NOT: br i1
;
; Exactly three flag mints and three strips — one per region. A duplicate mint
; (or a region emitted twice by a broken topological order) shows up here. Since
; drbq Inc 2a each region's arm is ONE `cqrt_rz_i32_controlled` on %[[Q]] in place
; of its route quintuple; the mint/strip/free spine is unchanged.
; CNT-COUNT-3:  = call i32 @cq_template_icmp_sgt_i32_hl(
; CNT-NOT:      = call i32 @cq_template_icmp_sgt_i32_hl(
; CNT2-COUNT-3: call void @cq_template_icmp_sgt_i32_hl_unc(
; CNT2-NOT:     call void @cq_template_icmp_sgt_i32_hl_unc(

; No swap route survives on any of the three regions — window `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
