; lowering_inplace_qq_decline_dicke_block.ll — DECLINE (owner ruling
; owner-ruling-dm7f51-inplace-qq-2026-10-14 Q1; bd test_C_libtooling-r2j3.33,
; dm7f.51 step 1, design shape V5 = the 3-qubit Dicke SCS block).
;
; Source (clang -O1 -include CQ.h):
;   bool q2 = 0, q3 = 0, q4 = 0; cq_theta(&q2, .5); cq_theta(&q3, .6);
;   cq_theta(&q4, .4);
;   q4 ^= q2; int s = 2 * q4 + q3; if (s == 3) cq_theta(&q2, .9); q4 ^= q2;
;   cq_measure(q2); cq_measure(q3); cq_measure(q4);
;
; BEFORE r2j3.33 this lowered rc 0 and SILENTLY WRONG: the first xor out of place
; (`cq_template_xor_i1(h2, h4)`) left the old q4 rail and the xor rail standing;
; together they record q2, and the controlled Ry on q2 is dephased (design
; analytic: P(q2,q3,q4)=(0,1,1) emitted 0.00101 vs textbook 0.00011).
;
; WHY IT IS LOUD AND NOT YET IN PLACE: -O1 folds `2*q4+q3 == 3` into a 4.4 select
; whose condition is the xor itself, and the condition-tree emitter decomposes
; that xor into its two LEAVES, re-reading the OLD q4 rail AFTER the xor's
; position (`cqrt_cnot(h4, g)` in the flag network). So the old q4 is dead in the
; user's IR (`!cq.qq.dead`) but the fence's G6 finds a later reader, and the first
; xor's result survives (it is the dead operand of the second xor, which is
; measured). RETIREMENT TRIGGER: dm7f.51 step 2, bd test_C_libtooling-dm7f.77
; (design D3: commit the QQ xor in
; place BEFORE control detection, so the condition reads q4's relabelled rail as
; a rail leaf) flips this fixture to an accept with an analytic check.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq in-place lowering: quantum reassignment of a dead register is not provable in place

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define noundef i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01)
  %4 = xor i1 %1, %3
  %5 = select i1 %4, i32 2, i32 0
  %6 = zext i1 %2 to i32
  %7 = or disjoint i32 %5, %6
  %8 = icmp eq i32 %7, 3
  br i1 %8, label %9, label %11

9:                                                ; preds = %0
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 9.000000e-01)
  br label %11

11:                                               ; preds = %9, %0
  %12 = phi i1 [ %10, %9 ], [ %1, %0 ]
  %13 = xor i1 %4, %12
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %12)
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2)
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13)
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr

