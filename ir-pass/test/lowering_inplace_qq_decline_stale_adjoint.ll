; lowering_inplace_qq_decline_stale_adjoint.ll — DECLINE, HAND-WRITTEN (bd r2j3.33 /
; dm7f.51 step 1, R11 round 1 finding C-F3: `kMsgInPlaceQQStaleAdjoint` was pinned
; by nothing).
;
; The POSTCONDITION `declineStaleInPlaceQQReads`, asked after `uncompute` as a GATE
; SET: no call after an in-place QQ gate may read the gate's target (or an alias)
; to write a compiler RECORD minted BEFORE the gate — the shape of every adjoint,
; strip and merge replay of a computation that read the target's OLD value — unless
; the gate's own adjoint ran in between. No C program reaches it today (the round's
; fence refuses first), so the module is written by hand: a pre-tagged
; `cqrt_xor_i32(%a, %t)` sits between a `cqrt_cnot(%t, %rec)` that records `t` and
; the `cqrt_cnot(%t, %rec)` meant to zero `%rec` again — which, after the relabel,
; XORs `t ^ a` into it instead. The second cnot is NOT an `_unc` (b12d4452's check
; scanned the `_unc` suffix only and passed this module, rc 0).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; R11 round 2b: the cnot is a RECORD write (not a recipe adjoint), so it fails
; with the record message — one diagnostic per cause.
; CHECK: cq in-place lowering: a gate writes a record of a register's old value after its in-place quantum reassignment

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_cnot(i32, i32)
declare void @cqrt_xor_i32(i32, i32)
declare void @cqrt_free(i32)

define i32 @stale() {
entry:
  %t = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  %a = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %rec = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_cnot(i32 %t, i32 %rec)
  call void @cqrt_xor_i32(i32 %a, i32 %t), !cq.inplace.qq !0
  call void @cqrt_cnot(i32 %t, i32 %rec)
  call void @cqrt_free(i32 %rec)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

!0 = !{}
