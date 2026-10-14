; lowering_reject_railbank_nowidth_cell_runtime_trip.ll — DECLINE (bd `test_C_libtooling-01po.19`).
;
; clause C3, the other half: an `i96` cell, for which `abiWidthFromType` returns "", with a RUNTIME walk trip.
;
; WHY THIS FILE EXISTS. Runtime trips are in the 01po.19 scope (owner ruling
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`), so the clause must keep
; firing for them, not only for `lowering_reject_railbank_nowidth_cell.ll`'s constant trip. The rolled window model
; (RailWindow.h) REFUSES this array (its cells have no reversible integer copy, or
; one access is a byte view of a wider cell), so it never claims it and the
; rail-bank clause below still owns the decline. `CQ_RAILWINDOW_DBG` must print no
; claim. Same module as `lowering_reject_railbank_nowidth_cell.ll`, with the walk's exit compare `%done = icmp eq i64 %inc, 3`
; compared against `%cq.trip`, a classical value read from an external global.
;
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='CQ_RAILWINDOW_DBG' --implicit-check-not='tainted value stored to memory'
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
