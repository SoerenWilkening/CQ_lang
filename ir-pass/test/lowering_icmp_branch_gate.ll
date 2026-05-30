; lowering_icmp_branch_gate.ll — Data-position GATE (PRD §2.8, risk R3). A
; tainted compare whose result feeds a `br i1` is NOT in pure data/measure
; position, so it is left COMPLETELY UNTOUCHED — it stays the original `i1`
; compare and is owned by Phase 4. `isDataPositionCompare` returns false for
; any branch-feeding compare, so the driver never enqueues it (never
; rewrites or erases it). The flag handle never reaches a terminator; `br
; i32` exists at no point.
;
; The theta source still lowers normally (rotation lowering is independent),
; so the `icmp` operand becomes the i32 alloc handle — but the `icmp` itself
; and its `br i1` survive verbatim. The IR stays well-typed and `opt -verify`
; clean WITHOUT any cross-type RAUW.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     icmp slt i32
; CHECK:     br i1
;
; CHECK-NOT: cq_template_icmp

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  ; Result feeds a branch → left untouched (Phase 4).
  %c = icmp slt i32 %a, 10
  br i1 %c, label %t, label %f
t:
  ret i32 1
f:
  ret i32 0
}
