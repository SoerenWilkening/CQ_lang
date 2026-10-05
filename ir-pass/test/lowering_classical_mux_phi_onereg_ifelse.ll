; lowering_classical_mux_phi_onereg_ifelse.ll — ACCEPT: one-register merge
; phi over an if/else, no straight-through edge (test_C_libtooling-5j5):
;     if (classical_c) q = cq_phi(q, a); else q = cq_phi(q, b);  measure(q);
; (pre-3qlq register form). The 3qlq migration deleted both phases (a phase under
; a classical condition is a global phase), so both arms are now EMPTY and the
; merge is `phi [q, a], [q, b]`. The lift predicate is per-edge: each incoming
; resolves to the SAME base %q and the renaming phi is erased.
;
; This is NOT ControlDetect's if/else: the condition is CLASSICAL (detection
; keys strictly on condition taint), so no flag, no rails, no routing — the
; branch structure is left byte-untouched and only the renaming phi is erased.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; CHECK:      a:
; CHECK:      b:
; CHECK:      merge:
; CHECK-NEXT:   call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT:  phi i32
; Zero controlled gates and no routing — the condition is classical:
; CHECK-NOT:  cqrt_cswap
; CHECK-NOT:  _controlled
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 7, double 5.000000e-01)
  br i1 %c, label %a, label %b                  ; CLASSICAL condition
a:
  br label %merge
b:
  br label %merge
merge:
  %p = phi i32 [ %q, %a ], [ %q, %b ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
