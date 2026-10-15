; railbank_readorder_reject_tainted_prune.ll — DECLINE (bd `xdu2.10`, Rule-13 round 2 F-1, P2).
;
; The PRUNE half of F-1, isolated from the fact half and from the read-side
; region guard (`readInsideTaintedRegion`; round 3 replaced
; `instUnderTaintedControl`). `%a` branches on the TAINTED `%g = or (k>0), %c`
; whose FALSE edge would imply `k <= 0` — refuting the read's classical fact
; `k > 0` — so a walk that trusted it would prune `%a → %r` and, with the classical
; `%bb` false edge also refuted, answer "every path passes the write header".
; But a tainted branch is FLATTENED by control lowering: both of its successors
; run, so its false edge is no evidence about any execution. The fixed walk
; FOLLOWS every edge of a tainted branch.
;
; ⚠ HAND IR — built so the tainted branch does NOT dominate the read (the read
; is reachable through `%bb` too), so the read is in no tainted branch's region
; (`readInsideTaintedRegion(read)` is false): only the prune-side taint
; conjunct can decline it. (Since round 3 the C spelling of the tainted-guarded
; write, `if ((k>0)|c) write; if (k>0) read`, is ALSO caught only by the prune
; conjunct: its tainted branch merges at the write loop's exit, before the read.)
;
; What pins it: on the pre-fix binary (`afda09e0`) the carve answers
; `railbank [Bank]` and the module declines LATER, elsewhere; the fixed binary
; fires the read-order anchor and the C6 string. The final verdict is a decline
; either way, so the debug trace is the witness.
;
;
; ⚠ bd `test_C_libtooling-01po.19` S1-S3 (2026-10-15, owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15` and
; `owner-ruling-01po19-rolled-design-2026-10-15`): the rolled WINDOW model
; (RailWindow.h) now claims this array, because it is a well-formed quantum array
; the one-store rail bank does not own. The rail-bank clause this file used to
; decline on protects the one-store model only; the window model replaces it, and
; until S4-S7 land the array declines with the list of steps it still needs
; (DECLINE -> DECLINE; the message below is mirrored character-for-character).
; RETIREMENT TRIGGER: each of S4-S7 that lands drops its name from the list; when
; the list empties this file becomes an ACCEPT with an analytic trace check.
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='railbank [Bank]'
; CHECK: CQ_CTRL_DBG: railbank C6 read-order refused:
; CHECK: cq rail window: quantum array not lowered yet (bd 01po.19), needs S6 quantum control on cells

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %k) {
entry:
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
  %rdone = icmp eq i64 %jnext, 3
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
