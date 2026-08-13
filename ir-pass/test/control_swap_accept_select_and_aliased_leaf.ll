; control_swap_accept_select_and_aliased_leaf.ll — ACCEPT (bd big5, 2026-07-31).
; THE COMPOSITION FIXTURE: an aliased-rail LEAF inside a COMPOUND `and i1`
; condition tree, so the aliased flag becomes a CONTROL of the 3-register node
; network (`cqrt_toffoli`). Added by the bd big5 Rule-13 round, which observed
; that no fixture composed the two axes even though the argument for KEEPING the
; self-operand NODE fence depends on exactly this composition being safe.
;
; WHAT IT PINS, and why it is the fixture that makes the kept node fence honest.
; `collectCondTree`'s NODE fence (SelectClassify.cpp) is deliberately RETAINED
; while its LEAF fence was removed, and the stated reason is:
;     "rail-aliasing cannot create the node shape either — every leaf mints its
;      OWN fresh flag rail, so two distinct leaves are never one rail."
; That is a claim about THIS input. Here `%q` and `%r = cq_phi(%q,·)` ARE one rail
; (the in-place Rz RAUW), and BOTH leaves read it — yet the emission is
;     %h_cmp  = cq_template_icmp_sgt_i32_hl(%h, 3)      ; leaf 1, fresh rail
;     %h_cmp1 = cq_template_icmp_slt_i32(%h, %h)        ; leaf 2, ALIASED, fresh rail
;     %g      = cqrt_alloc_i1(false)
;     cqrt_toffoli(%h_cmp, %h_cmp1, %g)                 ; THREE DISTINCT RAILS
; — because each leaf's mint is an independent `CreateCall`, so aliasing the leaf
; OPERANDS cannot merge the leaf OUTPUTS. Without this fixture, a future change to
; leaf-flag minting would have nothing standing between it and a toffoli with two
; aliased control slots.
;
; CASE A / CASE B: the aliased leaf is Case A (aliased INPUTS, fresh output rail).
; The toffoli is not aliased at all here — but note that even if its two CONTROLS
; did coincide it would still be Case A (`toffoli(c,c,G)` == `cnot(c,G)`), which is
; why the retained node fence is a SCOPED conservative decline and not a
; correctness requirement. The full partition is in
; control_swap_accept_select_rail_alias_cond.ll.
;
; SHIP FLOOR: this IR is the verbatim `clang -O1` output of
;     int q = cq_theta(x,.5); int r = cq_phi(q,.25);
;     int s = ((q > 3) & (q < r)) ? 11 : 22;
; Note the NON-short-circuit `&`. The `&&` spelling does NOT reach here: -O1 emits
; the poison-shielded `select i1 %4, i1 %5, i1 false` short-circuit form, which is
; off the `and i1`/`or i1` grammar and declines. MEASURED — do not assume `&&`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCASEB < %t.cqd0.ll
;
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 %{{[a-z0-9]+}})
; CHECK: call void @cqrt_rz_i32(i32 %h, double 2.500000e-01)
; Two leaves over ONE source rail mint TWO DISTINCT flag rails — the load-bearing
; fact:
; CHECK: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 3)
; CHECK: %h_cmp1 = call i32 @cq_template_icmp_slt_i32(i32 %h, i32 %h)
; CHECK: %g = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
; The merge is gated by the NODE ancilla %g, not by either leaf flag:
; CHECK: %out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %selop = call i32 @cqrt_alloc_i32(i32 11)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %g, i32 %selop, i32 %out)
; CHECK: call void @cqrt_x(i32 %g)
; CHECK: %selop2 = call i32 @cqrt_alloc_i32(i32 22)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %g, i32 %selop2, i32 %out)
; CHECK: call void @cqrt_x(i32 %g)
; Exact LIFO strip: the self-inverse node toffoli, then the ancilla free, then the
; leaves in reverse MINT order, each stripped then freed at a proven |0> (Rule 6):
; CHECK: call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
; CHECK: call void @cqrt_free(i32 %g)
; CHECK: call void @cq_template_icmp_slt_i32_unc(i32 %h_cmp1, i32 %h, i32 %h)
; CHECK: call void @cqrt_free(i32 %h_cmp1)
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 3)
; CHECK: call void @cqrt_free(i32 %h_cmp)
;
; CASE B must never appear. The toffoli slots in particular must stay three
; distinct rails — a toffoli whose TARGET is one of its controls is an erasure:
; NOCASEB-NOT: @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %h_cmp
; NOCASEB-NOT: @cqrt_toffoli(i32 %g, i32 %{{[a-z0-9_]+}}, i32 %g)
; NOCASEB-NOT: @cqrt_toffoli(i32 %{{[a-z0-9_]+}}, i32 %g, i32 %g)
; NOCASEB-NOT: @cq_template_icmp_slt_i32_unc(i32 %h, i32 %h
; NOCASEB-NOT: @cqrt_copy_i32_controlled(i32 %g, i32 %g
; NOCASEB-NOT: @cqrt_copy_i32_controlled(i32 %g, i32 %out, i32 %out)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define void @slice(i32 noundef %0) {
  %2 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = call i32 @cq_phi_si32(i32 noundef %2, double noundef 2.500000e-01)
  %4 = icmp sgt i32 %2, 3
  %5 = icmp slt i32 %2, %3          ; ALIASED leaf — %2 and %3 are ONE RAIL
  %6 = and i1 %4, %5                ; the NODE: two DISTINCT leaf flag rails
  %7 = select i1 %6, i32 11, i32 22
  %8 = call i32 @cq_measure_si32(i32 noundef %7)
  ret void
}
