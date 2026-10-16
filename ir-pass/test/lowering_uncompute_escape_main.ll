; lowering_uncompute_escape_main.ll — `main` is NOT an escape (bd
; test_C_libtooling-r2j3.7, owner ruling owner-ruling-r2j3-7-main-dead-record-
; 2026-10-16: `main` runs the dead-record discipline exactly like a helper).
;
; HISTORY (L7): this file pinned the retired PRD §2.6 / decision 2.6 rule — "a
; tainted handle living in `main` is an ESCAPE … Phase 5 emits NO adjoint and NO
; `cqrt_free`" — which FreePoint spelt as `F.getName() == "main"` ⇒ `Escaped` for
; every handle. That rule is gone; the subject is now the helper's disposition.
;
; The dead terminal `%h` (`cq_theta` of seed 3, never read) is reverse-played right
; after its last use (its own definition): `Ry(-.25)` undoes the forward `Ry(.25)`.
; It is NOT freed: the rail holds |3>, not provably |0> (R5). The same body in a
; noinline helper emits the same stream.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @main()
; CHECK:       %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK-NEXT:  ret i32 0
; CHECK-NOT:   cqrt_free
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define i32 @main() {
entry:
  %h = call i32 @cq_theta_si32(i32 3, double 2.500000e-01)
  ret i32 0
}
