; control_regcond_fresh_live_old_accept.ll — ACCEPT (bd test_C_libtooling-
; dm7f.77, design D5 / shape V3): the OLD value stays live, so the xor stays OUT
; OF PLACE and its fresh rail — the entangling copy `t' = a ^ t` (not a clone) —
; is the register condition (tag `kRegCondFresh`).
;
; Source (clang -O1 -include CQ.h):
;   bool a = 0, t = 0; cq_theta(&a, .4); cq_theta(&t, .3); bool t0 = t;
;   t ^= a; if (t) cq_theta(&a, .9); t ^= a;
;   return cq_measure(a) | (cq_measure(t) << 1) | (cq_measure(t0) << 2);
;
; The second `t ^= a` then goes in place onto that rail (E2′: a dead derived
; operand, InPlaceQQ.cpp), exactly D5's "%8 then in place on f's rail". On main
; 27aaf1e1 this declined `condition used outside the branch`. Analytic (trace vs
; textbook circuit with t0 a CNOT copy of t, identical to 12 digits):
; P(a,t,t0) = 000: 0.939080164852, 010: 0.007300672353, 011: 0.017392036218,
; 100: 0.031287407357, 101: 0.004058295931, 111: 0.000881423288.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 8) i32 @main()
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[A]], double 4.000000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT:  %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1(i32 %[[A]], i32 %[[T]])
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[A]], double 9.000000e-01)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[A]], i32 %[[F]]), !cq.inplace.qq
; CHECK-NEXT:  call i1 @cqrt_measure_i1(i32 %[[A]])
; CHECK:       call i1 @cqrt_measure_i1(i32 %[[F]])
; CHECK:       call i1 @cqrt_measure_i1(i32 %[[T]])
; CHECK-NOT:   cqrt_free

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 8) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  %3 = xor i1 %1, %2
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 9.000000e-01)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i1 [ %5, %4 ], [ %1, %0 ]
  %8 = xor i1 %3, %7
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7)
  %10 = zext i1 %9 to i32
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8)
  %12 = select i1 %11, i32 2, i32 0
  %13 = or disjoint i32 %12, %10
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2)
  %15 = select i1 %14, i32 4, i32 0
  %16 = or disjoint i32 %13, %15
  ret i32 %16
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
