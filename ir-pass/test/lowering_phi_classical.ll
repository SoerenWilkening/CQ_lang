; lowering_phi_classical.ll — Phi on a classical operand is deleted (no Rz,
; no alloc). The classical-only-phi module must still run so the phi is
; removed — else an unresolved @cq_phi_* extern is a Stage-3 link error.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     ret i32 %x
; CHECK-NOT: cqrt_rz
; CHECK-NOT: cq_phi_si32
; CHECK-NOT: cqrt_alloc
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"


define i32 @example(i32 %x) {
entry:
  ret i32 %x
}
