; spec_reject_gate_sub_mixed_return.ll — DECLINE (bd test_C_libtooling-p3kd.21, R11 r1
; item 4; reviewer probe revS3/p6_mixed_ret.ll). An i64 export that returns a
; register on one path and the classical `0` on the other:
;
;   i64 mixed(i64 x, i1 k) { if (k) return 0; return cq_theta(x, 0.25); }
;
; Its caller reads a handle on one path and a number on the other, and cannot tell
; them apart (`0` reads as handle 0). Loud until the classical exit is
; materialized as a register (follow-up filed from bd p3kd.21). The decline is
; asked before lowering by `declineTaintEscapes` for the export population the
; handle widening adds; the widening's own backstop (`widenQuantumExportReturns`,
; a non-handle `ret` beside a handle) would decline it after lowering with the
; non-i32 string. ⚠ The i32 twin (`ret i32 0` beside `ret i32 %h`) still
; ACCEPTS: a PRE-EXISTING ambiguity shared by dm7f.5's classical-exit accepts
; (control_multiexit_musttail_classical_exit_alloca.ll), filed for the owner.
; Mirrors the diagnostic character-for-character.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function mixed i64 (i64, i1): cq taint escape: register returned on one path and a classical value on another

declare i64 @cq_theta_sll(i64, double)

define i64 @mixed(i64 %x, i1 %k) {
entry:
  br i1 %k, label %early, label %rot
early:
  ret i64 0
rot:
  %q = call i64 @cq_theta_sll(i64 %x, double 2.500000e-01)
  ret i64 %q
}
