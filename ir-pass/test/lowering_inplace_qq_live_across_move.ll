; lowering_inplace_qq_live_across_move.ll — ACCEPT, IN PLACE (bd
; test_C_libtooling-r2j3.7 R11 pre-review finding, lane M batch 055).
;
; Source (clang -O1 -include CQ.h), in a noinline helper AND in `main`:
;   int a = 0, t = 0; cq_theta(&a,.5); cq_theta(&t,.4);
;   t ^= a; cq_theta(&a,.7); printf("%d", t); return cq_measure(a);
;
; `t`'s new value is read by the print AFTER the Ry on `a`: it is a record the
; PROGRAM keeps live across a non-permutation move of a register it was computed
; from (`recordLiveAcrossMove`), so no schedule discharges it before that Ry (owner
; ruling dead-record-live-across-move-ruling: leave it, it is the program's own
; entanglement). The reassignment must therefore be lowered IN PLACE (owner ruling
; owner-ruling-dm7f51-inplace-qq-2026-10-14): the old `t` must not stay live beside
; `t ^ a`.
;
; THE DEFECT (bd test_C_libtooling-r2j3.41; pre-existing in helpers, inherited by `main` once r2j3.7 removed its
; `Escaped` short-circuit): `InPlaceQQ::survives` asks `computeFreePoint` of the
; taped result, gets `Insert` (a free point after the print exists) and keeps it
; OUT OF PLACE, assuming the spine discharges it — but the spine's frontier planner
; then keeps it as a forced record. Result: old `t` rail AND `t ^ a` rail both live,
; `a` fully recorded. `cqrt_ry_i32` rotates EVERY qubit (backend.md §11.3) and the
; rest acts bitwise, so the numbers are per qubit of `a` (P(a==0) is their 32nd
; power): P(bit=0) = 0.835606 lowered vs 0.775469 in place (= sum_u |sum_a
; alpha_a beta_{u^a} <0|Ry(.7)|a>|^2, alpha = Ry(.5)|0>, beta = Ry(.4)|0>);
; P(a==0) = 0.00319 vs 0.000292. Replayed exactly on the `_Bool` twin. `opt` rc 0,
; stage 2b clean: a verify-clean silent miscompile.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @helper()
; CHECK:       %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 5.000000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT:  call void @cqrt_xor_i32(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 0x3FE6666666666666)
; CHECK-NEXT:  call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T]])
; CHECK-NOT:   call i32 @cq_template_xor_
;
; CHECK-LABEL: define i32 @main()
; CHECK:       %[[MA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[MA]], double 5.000000e-01)
; CHECK-NEXT:  %[[MT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[MT]], double 4.000000e-01)
; CHECK-NEXT:  call void @cqrt_xor_i32(i32 %[[MA]], i32 %[[MT]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[MA]], double 0x3FE6666666666666)
; CHECK-NEXT:  call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[MT]])
; CHECK-NOT:   call i32 @cq_template_xor_

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

define i32 @helper() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #0
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01) #0
  %3 = xor i32 %2, %1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666) #0
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %3)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %6
}

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #0
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01) #0
  %3 = xor i32 %2, %1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666) #0
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %3)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %7 = tail call i32 @helper()
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { nomerge nounwind }
