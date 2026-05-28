; lowering_add_qq_i1.ll — Per-width Q+Q add for the i1 ABI. Two
; tainted `qbool_mid_t` handles flow through `add i1` and must lower to
; `cq_template_add_i1(handle, handle)`. The handle stays i32 across
; every ABI width per PRD §"Width unification"; only the source op's
; operand type drives the per-width template selection.
;
; Originally the measure lowering was i32-only, so this fixture leaves the
; add result unused and returns void — the per-width add lowering is
; what we're pinning.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i1(i1 true)
; CHECK:     call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call i32 @cq_template_add_i1(

; CHECK-NOT: call i32 @cq_template_add_i1_hl(
; CHECK-NOT: cq_init_i1
; CHECK-NOT: add i1

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qbool_mid_t = type { i1 }

declare %qbool_mid_t @cq_init_i1(i1)

define void @example() {
entry:
  %a_struct = call %qbool_mid_t @cq_init_i1(i1 true)
  %a        = extractvalue %qbool_mid_t %a_struct, 0

  %b_struct = call %qbool_mid_t @cq_init_i1(i1 false)
  %b        = extractvalue %qbool_mid_t %b_struct, 0

  %c        = add i1 %a, %b
  ret void
}
