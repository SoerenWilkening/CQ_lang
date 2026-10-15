; control_regcond_inplace_ry_accept.ll — ACCEPT (bd test_C_libtooling-dm7f.77,
; dm7f.51 step 2, design D3 / shape V1): a REGISTER CONDITION (RegCondLeaf.h).
;
; Source (clang -O1 -include CQ.h):
;   bool a = 0, t = 0; cq_theta(&a, .4); cq_theta(&t, .3);
;   t ^= a; if (t) cq_theta(&a, .9); t ^= a;
;   return cq_measure(a) | (cq_measure(t) << 1);
;
; `%3 = xor %1, %2` is the condition AND `t`'s new value; the old `t` (%2) is
; dead after it, so it is committed as a register condition with target `t` and
; read as its own register: no network, no ancilla. The arm rotates `a`, the xor's
; SOURCE, which is off the condition's wire. On main 27aaf1e1 this declined
; `condition used outside the branch`. The stream is the textbook circuit
; CNOT(a,t); CRy(t -> a, .9); CNOT(a,t). Analytic (scratch tracecheck.py on the
; trace vs ref.py on the textbook circuit, identical to 12 digits):
; P(a,t) = 00: 0.939080164852, 01: 0.002156199704, 10: 0.057882212156,
; 11: 0.000881423288.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 4) i32 @main()
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[A]], double 4.000000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[T]], i32 %[[A]], double 9.000000e-01)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call i1 @cqrt_measure_i1(i32 %[[A]])
; CHECK-NOT:   cq_template_xor
; CHECK-NOT:   cqrt_free
; CHECK-NOT:   cq.regcond

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 4) i32 @main() local_unnamed_addr {
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
  ret i32 %13
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
