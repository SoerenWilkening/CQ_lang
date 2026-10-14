; railbank_readorder_reject_tainted_prune_runtime_trip.ll — DECLINE (bd `test_C_libtooling-01po.19`, review round 1 item 5).
;
; the read-order F-1 PRUNE conjunct (a tainted condition that prunes the read path), kept pinned with a RUNTIME trip on the READ loop `rd` (the walk keeps its constant trip).
;
; WHY THIS FILE EXISTS. `railbank_readorder_reject_tainted_prune.ll` pinned this clause with constant trips. Since bd
; 01po.19 that shape compiles: `unrollQuantumArrayWalks` (RailBankUnroll.h) unrolls the
; constant-trip loops that touch a quantum array the rolled bank does not own and SROA
; scalarizes it. The clause is still reachable whenever a variable cell index sits in a
; loop without a constant trip: the stage's trial fails and the module reaches the
; rail-bank verdict byte-untouched. This is the same module with `%rdone = icmp eq i64 %jnext, 3` compared against
; `%cq.trip`, a classical value read from an external global at entry.
;
; This decline is a gap, not a physics limit (NORTHSTAR goal 1). RETIREMENT TRIGGER:
; the rolled lowering of a runtime-trip walk (01po.19 follow-up) re-derives it.
;
; RUN: env CQ_CTRL_DBG=1 CQ_RAILBANK_UNROLL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='scalarized' --implicit-check-not='tainted value stored to memory'
; CHECK: CQ_CTRL_DBG: railbank C6 read-order refused:
; CHECK: cq rail bank: array has cells no iteration writes

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cq_trip = external global i64, align 8

define i32 @slice(i32 noundef %k) {
entry:
  %cq.trip = load i64, ptr @cq_trip, align 8
  %b = alloca [3 x i32], align 4
  %c = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  %pos = icmp sgt i32 %k, 0
  %big = icmp sgt i32 %k, 1
  br i1 %big, label %a, label %bb

a:
  %g = or i1 %pos, %c
  br i1 %g, label %w, label %r

bb:
  br i1 %pos, label %w, label %r

w:
  %i = phi i64 [ %inext, %w ], [ 0, %a ], [ 0, %bb ]
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %g1 = getelementptr inbounds [3 x i32], ptr %b, i64 0, i64 %i
  store i32 %t, ptr %g1, align 4
  %inext = add nuw nsw i64 %i, 1
  %wdone = icmp eq i64 %inext, 3
  br i1 %wdone, label %r, label %w

r:
  br i1 %pos, label %rd, label %exit

rd:
  %j = phi i64 [ %jnext, %rd ], [ 0, %r ]
  %s = phi i32 [ %s2, %rd ], [ 0, %r ]
  %gr = getelementptr inbounds [3 x i32], ptr %b, i64 0, i64 %j
  %cell = load i32, ptr %gr, align 4
  %mv = tail call i32 @cq_measure_si32(i32 noundef %cell)
  %s2 = add nsw i32 %mv, %s
  %jnext = add nuw nsw i64 %j, 1
  %rdone = icmp eq i64 %jnext, %cq.trip
  br i1 %rdone, label %exit, label %rd

exit:
  %res = phi i32 [ 0, %r ], [ %s2, %rd ]
  %mc = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %c)
  %mz = zext i1 %mc to i32
  %out = add nsw i32 %res, %mz
  ret i32 %out
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
