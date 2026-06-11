; lowering_reject_taint_escape_return_phase_diamond.ll — DECLINE: a phase-arm
; diamond whose merge result is RETURNED at NON-i32 width
; (test_C_libtooling-udw, member 2/3).
;
; `if (q > 5) { rz(q,a); rz(q,b); } return q;` — the i32-width twin of this shape
; is the ACCEPT fixture control_swap_ifelse_escape.ll (the merge phi RAUWs to the
; escaping handle q and the boolean is stripped). At i64 width the answer rail q is
; an i32 runtime handle but the function returns i64, so the merge ret leaves
; `ret i64 <i32 handle>` and the verifier aborts ("Broken module found") instead of
; declining. declineTaintEscapes catches the tainted non-i32 ret BEFORE control
; detection runs, so the diamond is never emitted — a clean, source-located decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_phi_sll(i64, double)

define i64 @example(i64 %u0, double %a, double %b) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %c = icmp sgt i64 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i64 @cq_phi_sll(i64 %q,  double %a)
  %q2 = call i64 @cq_phi_sll(i64 %q1, double %b)
  br label %merge
merge:
  %qm = phi i64 [ %q2, %arm ], [ %q, %entry ]
  ret i64 %qm                                      ; non-i32 escape — cannot launder
}

; CHECK: error{{.*}}cq taint escape: tainted value returned at non-i32 width
