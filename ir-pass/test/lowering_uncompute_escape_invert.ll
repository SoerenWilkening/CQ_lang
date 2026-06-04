; lowering_uncompute_escape_invert.ll — Phase 5 Step 3 escape (PRD §4 bullet 6 /
; IMPLEMENTATION §4.3, decision 2.6; reconciliation §8.3). A tainted handle that
; flows into an explicit `cq_invert_*` region is owned by Phase 7's manual
; inversion (beads test_C_libtooling-42t), which supersedes Phase 5 there — so
; Phase 5 emits NO adjoint and NO `cqrt_free` for it, and NO diagnostic
; (`cq_invert_*` is a RECOGNIZED escape, silently skipped).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; The forward rotation still lowers, the invert handoff is preserved, but the
; handle is never freed by Phase 5:
; CHECK:     call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 2.500000e-01)
; CHECK:     call void @cq_invert_begin(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: cqrt_free
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare void @cq_invert_begin(i32)

define void @slice(i32 %x) {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  call void @cq_invert_begin(i32 %h)
  ret void
}
