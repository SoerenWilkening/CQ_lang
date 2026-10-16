; nested_loop_reject_subloop_operand_only.ll — DECLINE (bd
; `test_C_libtooling-01po.19.34.1`, R11 round 1 A-F1: invariant I1).
;
; HAND-BUILT (not reachable from C today: the reviewer's C spellings
; rN1A/p5_storeonly.c and p6_kick.c are fenced earlier by other declines). The
; inner loop's ONLY quantum content is a tainted OPERAND: it measures `%t`, a
; rail minted in the OUTER body, and defines no tainted value. The first
; spelling of `iterationLocalQualifies` recursed only into subloops that DEFINE
; a tainted value, and its own-block scan skips subloop blocks, so this subloop
; was never asked the operand clause: the OUTER loop was marked iteration-local
; with an outer value read K times per outer trip inside the subloop (measured
; on 94dc9f75: accepted, `%u`'s adjoint and free placed in the outer body).
; Now every subloop that TOUCHES a qubit (defines one, or any instruction reads
; one) must qualify on its own; this one reads `%t` from outside, so the outer
; loop stays unmarked and `%u`'s terminal keeps FreePoint's back-edge reject.
; ⚠ NOT A PERMANENT DECLINE (R1): lowering it is bd 8h7d.24's capability (an
; outer value read inside a quantum subloop).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function slice i32 (i32, i32): cq uncompute: tainted handle live range crosses a loop backedge

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %x, i32 %n) {
entry:
  br label %outer

outer:
  %i = phi i32 [ 0, %entry ], [ %in, %olatch ]
  %acc = phi i32 [ 0, %entry ], [ %acc2, %olatch ]
  %t = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %u = add i32 %t, 3
  br label %inner

inner:
  %j = phi i32 [ 0, %outer ], [ %jn, %inner ]
  %acci = phi i32 [ %acc, %outer ], [ %acc1, %inner ]
  %m = call i32 @cq_measure_si32(i32 %t)
  %acc1 = add i32 %acci, %m
  %jn = add nuw nsw i32 %j, 1
  %jc = icmp slt i32 %jn, %n
  br i1 %jc, label %inner, label %olatch

olatch:
  %acc2 = phi i32 [ %acc1, %inner ]
  %in = add nuw nsw i32 %i, 1
  %ic = icmp slt i32 %in, %n
  br i1 %ic, label %outer, label %exit

exit:
  ret i32 %acc2
}
