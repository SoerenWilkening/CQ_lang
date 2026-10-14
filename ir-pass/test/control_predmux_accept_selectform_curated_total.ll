; control_predmux_accept_selectform_curated_total.ll — ACCEPT (bd 3c6m.14.2).
; THE POSITIVE CONTROL for the whole 3c6m.14.2 tightening.
;
; A tightening that declines the bad input is worthless if it also declines the
; good one (bd memory [[gate-validation-not-corpus-silence-2026-07-31]]). This is
; the exact pair to control_predmux_reject_selectform_curated_poison_immarg.ll:
; the SAME module, the SAME caller, the ONLY difference being the `ctlz` immarg
; flipped `true` -> `false`. With the flag false, `ctlz` is a total function of
; its operand at every input including zero, so the shielded operand is defined
; on the basis states the canonicalized `and` newly observes, and the region must
; still claim, flatten and lower.
;
; It is also the fixture that keeps the CURATED disjunct honest after
; bd 3c6m.14.2 deleted the pure-callee one. That disjunct is what survives of the
; shielded-cone call admission, and it is the half with a measured population:
; across 248 real openlibm TUs at -O1, all 5 poison-shielded select-forms that
; carry a call in the shielded cone carry curated intrinsics and nothing else.
; Delete the disjunct and this file goes red while every reject_selectform_*
; fixture stays green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='select i1' < %t.cqd0.ll
; RUN: env CQ_PREDMUX_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG --allow-empty

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctlz.i32(i32, i1 immarg)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = call i32 @llvm.ctlz.i32(i32 %q, i1 false)   ; TOTAL — defined at %q == 0
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; The intrinsic lowers to its reversible template, and the SHIELDED conjunct
; must read THAT rail — `%[[R]]`, never `%[[Q]]`. Substituting the raw rail there
; is exactly the corruption the retpoison exhibit produced verify-clean, so this
; slot is bound and never a wildcard.
; CHECK: %u.stable = freeze i32 %u
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u.stable)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i32(i32 %[[Q]])
; CHECK:      %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 7)
; CHECK:      %[[MUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 3)

; Both conjuncts of the canonicalized `and`, in order, onto one |0> rail — the
; guard %a AND the SHIELDED %b. A regressed canonicalize that dropped the
; shielded cone would emit only one.
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[R]], i32 0)
; CHECK:      %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])

; Merge 1 (%p): flag=1 takes the ADD, ¬flag the rail.
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[ADD]], i32 %[[OUT]])
; CHECK:      call void @cqrt_x(i32 %[[G]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[OUT]])

; Merge 2 (%p2) takes the MUL — not the ADD. Crossing the two merges' arm values
; is verify-clean, so both sources are bound.
; CHECK:      %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK:      %[[B2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[R]], i32 0)
; CHECK:      %[[G2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_toffoli(i32 %[[A2]], i32 %[[B2]], i32 %[[G2]])
; CHECK:      %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %[[MUL]], i32 %[[OUT2]])
; CHECK:      call void @cqrt_x(i32 %[[G2]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %[[Q]], i32 %[[OUT2]])
; CHECK:      call i32 @cq_template_add_i32(i32 %[[OUT]], i32 %[[OUT2]])
; bd r2j3.32: the `add` (in the merge block, the straight-line successor) is
; both rails' last reader, so each is reversed there — its core re-emitted in
; reverse under the SAME rail G / G2, and only THEN (deferred) Rule 6's
; strip: the AND rail cleared by the same self-inverse Toffoli, each conjunct
; stripped by its out-first `_unc` naming the rail the next line frees — and
; freed.
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[ADD]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[B]], i32 %[[R]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[A]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G2]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %[[Q]], i32 %[[OUT2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G2]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %[[MUL]], i32 %[[OUT2]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A2]], i32 %[[B2]], i32 %[[G2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[B2]], i32 %[[R]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[A2]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT2]])

; Nothing left the region, at any gate.
; DBG-NOT: leave @probe
