; lowering_inplace_qq_decline_dependent_source.ll — DECLINE (bd r2j3.33 / dm7f.51
; step 1, R11 round 1; ruling ruling-dm7f51-step1-departures-2026-10-15 Q2).
;
; Source (clang -O1 -include CQ.h):
;   int q = 0; cq_theta(&q, .5); int f = q > 5; if (q > 5) cq_phi(.25);
;   return cq_measure(q + f);
;
; `q` is dead after `q + f` and the sum survives (measured), so `q`'s rotated rail
; is the in-place target — but the SOURCE `f` (the shared condition flag's zext)
; is a function of `q`'s OLD value. Once `q` is relabelled `f` can never be
; uncomputed, so no clean in-place form exists here; out of place keeps the old `q`
; recording beside the result (the r2j3.33 hazard). Before R11 round 1 this stayed
; out of place silently; the ruling makes it loud. Population (old vs new cq-opt,
; measured this round): 5 lit fixtures and 1 e2e golden hit this shape on
; 435b3bc1; each keeps its own subject by a live use of the operand (see their
; headers). RETIREMENT TRIGGER: a self-dependent in-place circuit (bd
; test_C_libtooling-dm7f.75; Bennett.jl arith.jl:210-258 copy-in operand choice).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq in-place lowering: quantum reassignment of a dead register is not provable in place

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %4

3:                                                ; preds = %0
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %4

4:                                                ; preds = %3, %0
  %5 = zext i1 %2 to i32
  %6 = add nsw i32 %1, %5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare void @cq_phi(double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

