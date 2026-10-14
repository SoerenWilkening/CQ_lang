; lowering_reject_railbank_nowidth_cell_runtime_trip.ll — DECLINE (bd `test_C_libtooling-01po.19`, review round 1 item 5).
;
; clause C3, the other half (an `i96` cell, for which `abiWidthFromType` returns ""), kept pinned with a RUNTIME trip on the walk.
;
; WHY THIS FILE EXISTS. `lowering_reject_railbank_nowidth_cell.ll` pinned this clause with constant trips. Since bd
; 01po.19 that shape compiles: `unrollQuantumArrayWalks` (RailBankUnroll.h) unrolls the
; constant-trip loops that touch a quantum array the rolled bank does not own and SROA
; scalarizes it. The clause is still reachable whenever a variable cell index sits in a
; loop without a constant trip: the stage's trial fails and the module reaches the
; rail-bank verdict byte-untouched. This is the same module with `%done = icmp eq i64 %inc, 3` compared against
; `%cq.trip`, a classical value read from an external global at entry.
;
; This decline is a gap, not a physics limit (NORTHSTAR goal 1). RETIREMENT TRIGGER:
; the rolled lowering of a runtime-trip walk (01po.19 follow-up) re-derives it.
;
; RUN: env CQ_RAILBANK_UNROLL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='scalarized' --implicit-check-not='tainted value stored to memory'
; CHECK: cq rail bank: array element is not a reversible rail cell

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cq_trip = external global i64, align 8

define i32 @slice() {
entry:
  %cq.trip = load i64, ptr @cq_trip, align 8
  %b = alloca [3 x i96], align 16
  br label %loop

loop:                                             ; preds = %loop, %entry
  %i = phi i64 [ 0, %entry ], [ %inc, %loop ]
  %g = getelementptr inbounds [3 x i96], ptr %b, i64 0, i64 %i
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %w = zext i32 %q to i96
  store i96 %w, ptr %g, align 16
  %inc = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %inc, %cq.trip
  br i1 %done, label %out, label %loop

out:                                              ; preds = %loop
  ret i32 0
}

declare i32 @cq_theta_si32(i32, double)
