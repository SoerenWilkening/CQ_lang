; lowering_classical_mux_phi_onereg_ifelse.ll — ACCEPT: one-register merge
; phi with BOTH arms gated, no straight-through edge (test_C_libtooling-5j5):
;     if (classical_c) q = cq_phi(q, a); else q = cq_phi(q, b);  measure(q);
;
; The lift predicate is per-edge, so a base-valued incoming is not required:
; each incoming resolves through its own single-block arm chain to the SAME
; base %q, and neither arm's gate can reach the other arm's terminator (each
; arm's only successor is the merge). Per shot exactly one of rz(a)/rz(b)
; fires — the executed source path's stream — and the phi renames the one
; register either way.
;
; This is NOT ControlDetect's if/else: the condition is CLASSICAL (detection
; keys strictly on condition taint), so no flag, no rails, no routing — the
; branch structure is left byte-untouched and only the renaming phi is erased.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; CHECK:      a:
; CHECK-NEXT:   call void @cqrt_rz_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      b:
; CHECK-NEXT:   call void @cqrt_rz_i32(i32 %[[H]], double 7.500000e-01)
; CHECK:      merge:
; CHECK-NEXT:   call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT:  phi i32
; Zero controlled gates and no routing — the condition is classical:
; CHECK-NOT:  cqrt_cswap
; CHECK-NOT:  _controlled

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 7, double 5.000000e-01)
  br i1 %c, label %a, label %b                  ; CLASSICAL condition
a:
  %ga = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
  br label %merge
b:
  %gb = call i32 @cq_phi_si32(i32 %q, double 7.500000e-01)
  br label %merge
merge:
  %p = phi i32 [ %ga, %a ], [ %gb, %b ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
