; control_regcond_reject_arm_rotates_condition.ll — DECLINE, ADVERSARIAL (bd
; test_C_libtooling-dm7f.77, design shape Q7): the arm rotates the register
; condition ITSELF (`t ^= a; if (t) cq_theta(&t, θ)`).
;
; Source (clang -O1 -include CQ.h):
;   bool a = 0, t = 0; cq_theta(&a, .4); cq_theta(&t, .3);
;   t ^= a; if (t) cq_theta(&t, .9);
;   return cq_measure(a) | (cq_measure(t) << 1);
;
; -O1 knows `t` is 1 in the arm and turns the Ry into a state prep of `true`
; merged with the condition: no register condition can control a gate on its
; own wire. The delegated Q7 ruling's lowering (a CNOT-copied flag, kept and
; warned) is not built (follow-up filed under dm7f.51); it stays loud.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: state prep merged with a quantum register under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 4) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  %3 = xor i1 %1, %2
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 9.000000e-01)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i1 [ %5, %4 ], [ %3, %0 ]
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %9 = zext i1 %8 to i32
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7)
  %11 = select i1 %10, i32 2, i32 0
  %12 = or disjoint i32 %11, %9
  ret i32 %12
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
