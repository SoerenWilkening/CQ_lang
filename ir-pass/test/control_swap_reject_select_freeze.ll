; control_swap_reject_select_freeze.ll — DECLINE: a freeze-mediated angle select
; is caught by the ESCAPE GUARD, not the select ladder (4.4 WI-1 boundary probe;
; adversarial review 2026-06-15). Documents WHY the §3.2 angle walk's carrier set
; correctly OMITS `freeze`.
;
; `(%qd>5) ? 0.25f : 0.75f` whose result is `freeze`d and `fpext`'d into a
; `cq_phi` arg-1 is a genuine angle-leak shape. But `freeze` is NOT in the set of
; ops `declineTaintEscapes` whitelists as benign tainted-value users
; (BinaryOperator/UnaryOperator/CmpInst/CastInst/PHINode/SelectInst); the select
; result is tainted (a tainted condition propagates taint to the select result),
; so `freeze %sel` is a tainted value reaching an unsupported instruction —
; declined LOUDLY at L64 (`kMsgOther`), BEFORE detection (L83) ever runs. Hence
; `selReachesRotationArg1` need not (and must not) cross `freeze`: adding it would
; be untestable dead code masked by this backstop. The angle never silently leaks.
;
; (If a future change ever whitelisted `freeze` in the escape guard, THIS fixture
; would flip from the escape string to an accept — the signal to add `freeze` to
; the gate-3 carrier set then. Regression guard for the boundary, per Rule 12.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value reaches an unsupported instruction
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_alloc
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd  = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c   = icmp sgt i32 %qd, 5
  %sel = select i1 %c, float 2.500000e-01, float 7.500000e-01
  %f   = freeze float %sel                       ; NOT escape-whitelisted -> L64 kMsgOther
  %w   = fpext float %f to double
  %q2  = call i32 @cq_phi_si32(i32 %qd, double %w)
  %m   = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}
