; lowering_inplace_qq_phi_target_accept.ll — ACCEPT (bd test_C_libtooling-
; dm7f.77, design D2(b): deadness over the target's WIRE): `q ^= x` whose dead
; `q` is the merge φ of a controlled-Ry region.
;
; Source (clang -O1 -include CQ.h):
;   bool a = 0, q = 0, x = 0; cq_theta(&a, .5); cq_theta(&q, .6); cq_theta(&x, .2);
;   if (a) cq_theta(&q, .7); q ^= x; cq_theta(&x, .3);
;   return cq_measure(a) | (cq_measure(q) << 1) | (cq_measure(x) << 2);
;
; A SILENT MISCOMPILE ON MAIN 27aaf1e1 (the r2j3.33 V6 class through a φ): step 1
; refused every φ target ("a φ can alias another live name"), so the xor went
; out of place and q's old rail stood beside `q'`, together recording x before its
; Ry: P(000) = 0.829340056674 emitted vs 0.821559680231 textbook. The φ
; `phi [Ry(%q), %q]` names ONE rail; deadness is now asked of every member of that
; rotation chain (`singleWirePhiDeadAfter`). Analytic (trace vs textbook,
; identical to 12 digits): P(a,q,x) = 000: 0.821559680231, 001: 0.027522513866,
; 010: 0.071767230426, 011: 0.017941856421, 100: 0.036686060047,
; 101: 0.001941742247, 110: 0.020841630609, 111: 0.001739286153.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 8) i32 @main()
; CHECK:       call void @cqrt_ry_i1_controlled(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %[[Q:[a-zA-Z0-9_.]+]], double 0x3FE6666666666666)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[X:[a-zA-Z0-9_.]+]], i32 %[[Q]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[X]], double 3.000000e-01)
; CHECK:       call i1 @cqrt_measure_i1(i32 %[[Q]])
; CHECK-NOT:   cq_template_xor

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 8) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 2.000000e-01)
  br i1 %1, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 0x3FE6666666666666)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i1 [ %5, %4 ], [ %2, %0 ]
  %8 = xor i1 %3, %7
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 3.000000e-01)
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %11 = zext i1 %10 to i32
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8)
  %13 = select i1 %12, i32 2, i32 0
  %14 = or disjoint i32 %13, %11
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9)
  %16 = select i1 %15, i32 4, i32 0
  %17 = or disjoint i32 %14, %16
  ret i32 %17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
